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
// uvm_subscriber #(mul_txn) gives us: an analysis_export input port + a pure
// virtual write(mul_txn) method that the framework calls for every txn.
class mul_cov extends uvm_subscriber #(mul_txn);
  `uvm_component_utils(mul_cov)

  // ---- class members: the "current sample" the coverpoints read -------------
  // (we copy the txn fields into these, then call sample() on each group)
  rv32m_op_e      op;            // which of the 8 RV32M ops
  operand_class_e a_cls, b_cls;  // operand CLASS of rs1 / rs2 (zero, -1, ...)
  bit             a_neg, b_neg;  // sign bit of rs1 / rs2
  bit [31:0]      res;           // result value the DUT produced
  bit             res_zero, res_ones, res_msb;  // result is 0 / all-ones / MSB=1
  bit             sov, uov;      // signed/unsigned product does not fit 32 bits
  int unsigned    mult_cycles, stall_cycles;    // timing fields of the txn
  bit [4:0]       rd, rs1, rs2;  // register fields (from write port + instr word)
  bit             tag_valid;     // is the instr word available?
  // sequence context = info about the PREVIOUS MUL-unit op (for gap/RAW bins)
  bit             have_prev;     // 1 = we have a previous op to compare against
  rv32m_op_e      prev_op;       // op code of the previous MUL-unit instruction
  bit [4:0]       prev_rd;       // rd of the previous op
  int unsigned    gap;           // cycles between prev completion and this start
                                 // (1 = back-to-back, no idle cycle between)
  bit             raw_prev;      // 1 = this op reads the previous op's rd (RAW)
  // reset context = info used only when a txn is killed by reset
  int unsigned    cycles_done_at_reset;   // how many EX cycles before the reset
  int unsigned    prev_cycle_end;         // cycle_end of the previous op
  bit             killed;                 // flag: current sample is a kill

  int unsigned    n_sampled, n_killed;    // statistics for report_phase

  // ---- 1. operation x operand classes --------------------------------------------
  // GROUP 1: operation x operand classes (vplan risc_dec_01 / risc_m_00/01)
  covergroup cg_op_operands;
    option.per_instance = 1;     // coverage counted per instance (not merged)
    cp_op   : coverpoint op   { bins mul = {MUL}; bins mulh = {MULH}; bins mulhsu = {MULHSU}; bins mulhu = {MULHU}; }
    cp_a    : coverpoint a_cls;      // operand A class: zero/one/-1/max/min/...
    cp_b    : coverpoint b_cls;      // operand B class
    cp_a_neg: coverpoint a_neg;      // A negative? (0/1)
    cp_b_neg: coverpoint b_neg;      // B negative?
    x_op_a     : cross cp_op, cp_a;          // every op x every A class
    x_op_b     : cross cp_op, cp_b;          // every op x every B class
    x_op_sign  : cross cp_op, cp_a_neg, cp_b_neg;  // 4 sign cells per op
    x_op_corners: cross cp_op, cp_a, cp_b {
      // Keep only EXACT corner values on both sides. Without this the cross
      // would explode (12 x 12 bins per op) because the range classes are
      // already covered by x_op_a / x_op_b above.
      ignore_bins ranges = x_op_corners with (cp_a inside {OPC_POS_SMALL, OPC_POS_LARGE, OPC_NEG_SMALL, OPC_NEG_LARGE, OPC_POW2} ||
                                              cp_b inside {OPC_POS_SMALL, OPC_POS_LARGE, OPC_NEG_SMALL, OPC_NEG_LARGE, OPC_POW2});
    }
  endgroup

  // ---- 2. result classes --------------------------------------------------------
  // GROUP 2: RESULT classes (vplan risc_m_00: zero / all-ones / overflow)
  covergroup cg_result;
    option.per_instance = 1;
    cp_op      : coverpoint op;
    cp_res_zero: coverpoint res_zero;   // result == 0x00000000?
    cp_res_ones: coverpoint res_ones;   // result == 0xFFFFFFFF?
    cp_res_msb : coverpoint res_msb;    // result has MSB set (negative signed)?
    cp_sov     : coverpoint sov;        // signed product > 32 bits (MUL truncated it)
    cp_uov     : coverpoint uov;        // unsigned product > 32 bits
    x_op_res   : cross cp_op, cp_res_zero, cp_res_ones, cp_res_msb {
      // A result cannot be zero AND all-ones at the same time -> drop that combo
      ignore_bins impossible = x_op_res with (cp_res_zero && (cp_res_ones || cp_res_msb));
    }
    // Signed/unsigned overflow only makes sense for MUL (MULH* return the high word)
    x_mul_sov  : cross cp_op, cp_sov { ignore_bins not_mul = x_mul_sov with (cp_op != MUL); }
    x_mul_uov  : cross cp_op, cp_uov { ignore_bins not_mul = x_mul_uov with (cp_op != MUL); }
  endgroup

  // ---- 3. latency x external stall --------------------------------------------
  // GROUP 3: latency x external stall (vplan risc_m_00/01 timing)
  covergroup cg_timing;
    option.per_instance = 1;
    cp_op    : coverpoint op;
    cp_lat   : coverpoint mult_cycles { bins one = {1}; bins five = {5}; illegal_bins other = default; }
      // ONLY 1 (MUL) and 5 (MULH*) are legal -> anything else = DUT bug = illegal bin
    cp_stall : coverpoint stall_cycles { bins none = {0}; bins one = {1}; bins two_three = {[2:3]}; bins four_plus = {[4:$]}; }
      // how many cycles the LSU/WB held EX (0, 1, 2-3, 4+)
    x_op_stall: cross cp_op, cp_stall;      // e.g. MULH held in FINISH by slow data
  endgroup

  // ---- 4. register fields (from the tagged instruction word) -------------------
  // GROUP 4: register-field corners (vplan risc_m_01: x0, overlaps)
  covergroup cg_regs;
    option.per_instance = 1;
    cp_op  : coverpoint op;
    cp_rd  : coverpoint rd  { bins x0 = {0}; bins x1_x31[] = {[1:31]}; }
      // x0 separate, then ONE bin per register x1..x31 (auto-bin [] syntax)
    cp_rs1 : coverpoint rs1 { bins x0 = {0}; bins others = {[1:31]}; }
    cp_rs2 : coverpoint rs2 { bins x0 = {0}; bins others = {[1:31]}; }
    cp_rs1_eq_rs2 : coverpoint (rs1 == rs2);              // same source twice
    cp_rd_eq_rs1  : coverpoint (rd == rs1 && rd != 0);    // write back to a source (RAW)
    cp_rd_eq_rs2  : coverpoint (rd == rs2 && rd != 0);
    x_op_rd : cross cp_op, cp_rd { option.weight = 4; }   // light weight: 8x32 is big
    x_op_overlap : cross cp_op, cp_rs1_eq_rs2, cp_rd_eq_rs1, cp_rd_eq_rs2;
  endgroup

  // ---- 5. sequence: previous MUL-unit op -> this op ------------------------------
  // GROUP 5: SEQUENCE context - previous MUL-unit op -> this op
  // (vplan risc_m_01 "dependent consumer", risc_m_04 multicycle+distance,
  //  risc_haz_00 RAW distance through forwarding)
  covergroup cg_sequence;
    option.per_instance = 1;
    cp_prev : coverpoint prev_op;     // op code of previous MUL-unit instr
    cp_cur  : coverpoint op;          // op code of current one
    cp_gap  : coverpoint gap { bins b2b = {1}; bins two = {2}; bins three_plus = {[3:$]}; }
      // gap 1 = back-to-back (no idle cycle), 2, then 3+
    cp_raw  : coverpoint raw_prev;    // does the current op read prev's rd? (RAW hazard)
    x_prev_cur : cross cp_prev, cp_cur;              // every pair of ops in sequence
    x_b2b      : cross cp_prev, cp_cur, cp_gap;      // pairs at each distance
    x_dep_gap  : cross cp_cur, cp_raw, cp_gap {
      // a non-dependent op at distance 3 is uninteresting -> drop it
      ignore_bins no_dep_far = x_dep_gap with (!cp_raw && cp_gap == 3);
    }
  endgroup

  // ---- 6. reset while in EX --------------------------------------------------
  // GROUP 6: RESET while the op is in EX (vplan risc_rst_02: WHICH cycle)
  covergroup cg_reset;
    option.per_instance = 1;
    cp_op    : coverpoint op;
    cp_stage : coverpoint cycles_done_at_reset {
      bins first  = {1};          // first EX cycle (MUL or MULH IDLE->STEP0)
      bins step   = {[2:4]};      // MULH STEP0..STEP2
      bins finish = {[5:$]};      // FINISH held by an external stall
    }
    x_op_stage : cross cp_op, cp_stage {
      // MUL only ever lasts 1 cycle, so MUL + late stage is impossible
      ignore_bins mul_late = x_op_stage with (cp_op == MUL && cp_stage != 1);
    }
  endgroup

  // Constructor: build all 6 covergroups (covergroups are classes too).
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_op_operands = new();
    cg_result      = new();
    cg_timing      = new();
    cg_regs        = new();
    cg_sequence    = new();
    cg_reset       = new();
  endfunction

  // write(): called by the UVM framework for EVERY mul_txn the agent publishes.
  // Steps: unpack the txn into the members above, then sample() the groups.
  virtual function void write(mul_txn t);
    op = t.op;                              // start with the op code
    if (t.killed_by_reset) begin            // reset-killed txn: only group 6
      n_killed++;
      cycles_done_at_reset = t.total_cycles;  // which EX cycle the reset hit
      killed = 1;
      cg_reset.sample();                    // sample ONLY the reset group
      return;                               // skip all normal groups
    end
    n_sampled++;                            // normal sample from here on
    a_cls = classify_operand(t.rs1_val);    // classify both operands
    b_cls = classify_operand(t.rs2_val);
    a_neg = t.rs1_val[31];                  // sign bits
    b_neg = t.rs2_val[31];
    res      = t.result;                    // result flags for group 2
    res_zero = (res == 32'h0);
    res_ones = (res == 32'hFFFF_FFFF);
    res_msb  = res[31];
    sov = mul_signed_overflow(t.rs1_val, t.rs2_val);   // overflow helpers
    uov = mul_unsigned_overflow(t.rs1_val, t.rs2_val);
    mult_cycles  = t.mult_cycles;           // timing for group 3
    stall_cycles = t.stall_cycles;
    tag_valid = t.tag_valid;
    rd  = t.waddr[4:0];                     // registers (write port + instr)
    rs1 = t.instr_rs1();
    rs2 = t.instr_rs2();

    cg_op_operands.sample();                // sample groups 1..3 always
    cg_result.sample();
    cg_timing.sample();
    if (tag_valid) cg_regs.sample();        // group 4 needs the instr word

    if (have_prev) begin                    // group 5 needs a previous op
      // gap = idle cycles between previous completion and this start
      // (clamped to 1 - can't be 0 because cycles are integers here)
      gap      = (t.cycle_start > prev_cycle_end) ? (t.cycle_start - prev_cycle_end) : 1;
      // RAW: this op reads the register the previous op wrote (and rd != x0)
      raw_prev = tag_valid && (prev_rd != 0) && ((rs1 == prev_rd) || (rs2 == prev_rd));
      cg_sequence.sample();
    end
    have_prev      = 1;                     // remember THIS op for the next one
    prev_op        = op;
    prev_rd        = rd;
    prev_cycle_end = t.cycle_end;
  endfunction

  // report_phase: print how much of each group was hit (end of simulation).
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MUL coverage: %0d items sampled, %0d killed by reset | op_operands %.1f%% result %.1f%% timing %.1f%% regs %.1f%% sequence %.1f%% reset %.1f%%",
              n_sampled, n_killed, cg_op_operands.get_inst_coverage(), cg_result.get_inst_coverage(), cg_timing.get_inst_coverage(),
              cg_regs.get_inst_coverage(), cg_sequence.get_inst_coverage(), cg_reset.get_inst_coverage()), UVM_LOW)
  endfunction

endclass : mul_cov
