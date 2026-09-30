// =============================================================================
// mul_cov.sv  (part of alu_mul_cov_pkg)
// -----------------------------------------------------------------------------
// Functional coverage of the multiplier path (MUL / MULH / MULHSU / MULHU).
// A uvm_subscriber that lives inside the `coverage_collector` of the TB
// architecture and is connected to the MUL agent analysis port:
//
//   m_mul_agent.ap.connect(m_coverage_collector.m_mul_cov.analysis_export);
//
// It never fails a test: checking is done in alu_mul_scoreboard. Sampling is
// per completed mul_txn (killed_by_reset items go to cg_reset only).
//
// vplan mapping (verification_plan, "coverage" column, corrected names):
//   risc_dec_01  every RV32M mnemonic x operand corner classes   -> cg_op_operands
//   risc_m_00    MUL operand corners, result classes, overflow   -> cg_op_operands, cg_result
//   risc_m_01    MULH* sign modes x corners, dependent consumer  -> cg_op_operands, cg_sequence, cg_regs
//   risc_m_00/01 latency x external stalls                       -> cg_timing
//   risc_m_01    MUL-unit op followed by MUL-unit op (gap, RAW)  -> cg_sequence
//   risc_m_04    multicycle + dependency distance                -> cg_sequence
//   risc_haz_00  RAW distance 1 / 2 through forwarding           -> cg_sequence.x_dep_gap
//   risc_rst_02  reset while a MUL-unit op is in EX (which cycle)-> cg_reset
// =============================================================================
class mul_cov extends uvm_subscriber #(mul_txn);
  `uvm_component_utils(mul_cov)

  // ---- sampled values -------------------------------------------------------
  rv32m_op_e      op;
  operand_class_e a_cls, b_cls;
  bit             a_neg, b_neg;
  bit [31:0]      res;
  bit             res_zero, res_ones, res_msb;
  bit             sov, uov;                   // exact product does not fit 32 bits
  int unsigned    mult_cycles, stall_cycles;
  bit [4:0]       rd, rs1, rs2;
  bit             tag_valid;
  // sequence context (previous MUL-unit op)
  bit             have_prev;
  rv32m_op_e      prev_op;
  bit [4:0]       prev_rd;
  int unsigned    gap;                         // cycles between prev completion and this start (1 = back-to-back)
  bit             raw_prev;                    // this op reads the previous op's rd
  // reset context
  int unsigned    cycles_done_at_reset;
  int unsigned    prev_cycle_end;
  bit             killed;

  int unsigned    n_sampled, n_killed;

  // ---- 1. operation x operand classes --------------------------------------------
  covergroup cg_op_operands;
    option.per_instance = 1;
    cp_op   : coverpoint op   { bins mul = {MUL}; bins mulh = {MULH}; bins mulhsu = {MULHSU}; bins mulhu = {MULHU}; }
    cp_a    : coverpoint a_cls;
    cp_b    : coverpoint b_cls;
    cp_a_neg: coverpoint a_neg;
    cp_b_neg: coverpoint b_neg;
    x_op_a     : cross cp_op, cp_a;
    x_op_b     : cross cp_op, cp_b;
    x_op_sign  : cross cp_op, cp_a_neg, cp_b_neg;   // 4 sign cells per op (MULH/MULHSU/MULHU semantics)
    x_op_corners: cross cp_op, cp_a, cp_b {
      // keep only the exact corner values on both sides (12x12 per op would be too much)
      ignore_bins ranges = x_op_corners with (cp_a inside {OPC_POS_SMALL, OPC_POS_LARGE, OPC_NEG_SMALL, OPC_NEG_LARGE, OPC_POW2} ||
                                              cp_b inside {OPC_POS_SMALL, OPC_POS_LARGE, OPC_NEG_SMALL, OPC_NEG_LARGE, OPC_POW2});
    }
  endgroup

  // ---- 2. result classes --------------------------------------------------------
  covergroup cg_result;
    option.per_instance = 1;
    cp_op      : coverpoint op;
    cp_res_zero: coverpoint res_zero;
    cp_res_ones: coverpoint res_ones;
    cp_res_msb : coverpoint res_msb;
    cp_sov     : coverpoint sov;     // signed product needs more than 32 bits (MUL truncates)
    cp_uov     : coverpoint uov;     // unsigned product needs more than 32 bits
    x_op_res   : cross cp_op, cp_res_zero, cp_res_ones, cp_res_msb {
      ignore_bins impossible = x_op_res with (cp_res_zero && (cp_res_ones || cp_res_msb));
    }
    x_mul_sov  : cross cp_op, cp_sov { ignore_bins not_mul = x_mul_sov with (cp_op != MUL); }
    x_mul_uov  : cross cp_op, cp_uov { ignore_bins not_mul = x_mul_uov with (cp_op != MUL); }
  endgroup

  // ---- 3. latency x external stall --------------------------------------------
  covergroup cg_timing;
    option.per_instance = 1;
    cp_op    : coverpoint op;
    cp_lat   : coverpoint mult_cycles { bins one = {1}; bins five = {5}; illegal_bins other = default; }
    cp_stall : coverpoint stall_cycles { bins none = {0}; bins one = {1}; bins two_three = {[2:3]}; bins four_plus = {[4:$]}; }
    x_op_stall: cross cp_op, cp_stall;      // MULH held in FINISH / MUL held by a slow data response
  endgroup

  // ---- 4. register fields (from the tagged instruction word) -------------------
  covergroup cg_regs;
    option.per_instance = 1;
    cp_op  : coverpoint op;
    cp_rd  : coverpoint rd  { bins x0 = {0}; bins x1_x31[] = {[1:31]}; }
    cp_rs1 : coverpoint rs1 { bins x0 = {0}; bins others = {[1:31]}; }
    cp_rs2 : coverpoint rs2 { bins x0 = {0}; bins others = {[1:31]}; }
    cp_rs1_eq_rs2 : coverpoint (rs1 == rs2);
    cp_rd_eq_rs1  : coverpoint (rd == rs1 && rd != 0);
    cp_rd_eq_rs2  : coverpoint (rd == rs2 && rd != 0);
    x_op_rd : cross cp_op, cp_rd { option.weight = 4; }
    x_op_overlap : cross cp_op, cp_rs1_eq_rs2, cp_rd_eq_rs1, cp_rd_eq_rs2;
  endgroup

  // ---- 5. sequence: previous MUL-unit op -> this op ------------------------------
  covergroup cg_sequence;
    option.per_instance = 1;
    cp_prev : coverpoint prev_op;
    cp_cur  : coverpoint op;
    cp_gap  : coverpoint gap { bins b2b = {1}; bins two = {2}; bins three_plus = {[3:$]}; }
    cp_raw  : coverpoint raw_prev;
    x_prev_cur : cross cp_prev, cp_cur;
    x_b2b      : cross cp_prev, cp_cur, cp_gap;
    x_dep_gap  : cross cp_cur, cp_raw, cp_gap { ignore_bins no_dep_far = x_dep_gap with (!cp_raw && cp_gap == 3); }
  endgroup

  // ---- 6. reset while in EX --------------------------------------------------
  covergroup cg_reset;
    option.per_instance = 1;
    cp_op    : coverpoint op;
    cp_stage : coverpoint cycles_done_at_reset {
      bins first  = {1};          // MUL / MULH first cycle (IDLE -> STEP0)
      bins step   = {[2:4]};      // STEP0..STEP2 of MULH*
      bins finish = {[5:$]};      // FINISH held by an external stall
    }
    x_op_stage : cross cp_op, cp_stage { ignore_bins mul_late = x_op_stage with (cp_op == MUL && cp_stage != 1); }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_op_operands = new();
    cg_result      = new();
    cg_timing      = new();
    cg_regs        = new();
    cg_sequence    = new();
    cg_reset       = new();
  endfunction

  virtual function void write(mul_txn t);
    op = t.op;
    if (t.killed_by_reset) begin
      n_killed++;
      cycles_done_at_reset = t.total_cycles;
      killed = 1;
      cg_reset.sample();
      return;
    end
    n_sampled++;
    a_cls = classify_operand(t.rs1_val);
    b_cls = classify_operand(t.rs2_val);
    a_neg = t.rs1_val[31];
    b_neg = t.rs2_val[31];
    res      = t.result;
    res_zero = (res == 32'h0);
    res_ones = (res == 32'hFFFF_FFFF);
    res_msb  = res[31];
    sov = mul_signed_overflow(t.rs1_val, t.rs2_val);
    uov = mul_unsigned_overflow(t.rs1_val, t.rs2_val);
    mult_cycles  = t.mult_cycles;
    stall_cycles = t.stall_cycles;
    tag_valid = t.tag_valid;
    rd  = t.waddr[4:0];
    rs1 = t.instr_rs1();
    rs2 = t.instr_rs2();

    cg_op_operands.sample();
    cg_result.sample();
    cg_timing.sample();
    if (tag_valid) cg_regs.sample();

    if (have_prev) begin
      gap      = (t.cycle_start > prev_cycle_end) ? (t.cycle_start - prev_cycle_end) : 1;
      raw_prev = tag_valid && (prev_rd != 0) && ((rs1 == prev_rd) || (rs2 == prev_rd));
      cg_sequence.sample();
    end
    have_prev      = 1;
    prev_op        = op;
    prev_rd        = rd;
    prev_cycle_end = t.cycle_end;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MUL coverage: %0d items sampled, %0d killed by reset | op_operands %.1f%% result %.1f%% timing %.1f%% regs %.1f%% sequence %.1f%% reset %.1f%%",
              n_sampled, n_killed, cg_op_operands.get_inst_coverage(), cg_result.get_inst_coverage(), cg_timing.get_inst_coverage(),
              cg_regs.get_inst_coverage(), cg_sequence.get_inst_coverage(), cg_reset.get_inst_coverage()), UVM_LOW)
  endfunction

endclass : mul_cov
