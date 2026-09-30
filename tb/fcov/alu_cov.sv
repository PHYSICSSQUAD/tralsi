// =============================================================================
// alu_cov.sv  (part of alu_mul_cov_pkg)
// -----------------------------------------------------------------------------
// Functional coverage of the ALU / divider path, sampled per alu_txn. Lives in
// the `coverage_collector` next to mul_cov and is fed by the ALU agent:
//
//   m_alu_agent.ap.connect(m_coverage_collector.m_alu_cov.analysis_export);
//
// vplan mapping (corrected component names):
//   risc_dec_01  every RV32I/RV32M-div mnemonic reaches the ALU with the right
//                operator (decoder) -> cg_op (operator x instruction class)
//   risc_m_02    DIV/DIVU/REM/REMU operand corners, divide by zero, INT_MIN/-1,
//                divider latency 3..35 x external stall -> cg_div, cg_div_timing
//   risc_m_03    div followed by dependent consumer / branch -> cg_seq
//   risc_alu_*   arithmetic / logic / shift / compare operand classes, shift
//                amounts, branch decisions taken/not taken -> cg_alu_operands,
//                cg_shift, cg_branch
//   risc_rst_02  reset while a DIV is in EX (which cycle) -> cg_reset
// =============================================================================
// uvm_subscriber #(alu_txn): framework gives us analysis_export + write().
// The env connects: m_alu_agent.ap -> m_coverage_collector.m_alu_cov.analysis_export
class alu_cov extends uvm_subscriber #(alu_txn);
  `uvm_component_utils(alu_cov)

  // ---- "current sample" members that the coverpoints read -------------------
  alu_opcode_e    op;            // which ALU operator (ADD, DIV, ...)
  alu_op_class_e  cls;           // its class (ARITH/LOGIC/SHIFT/SLT/BRANCH/DIV)
  operand_class_e a_cls, b_cls;  // operand class of raw inputs a / b
  bit             a_neg, b_neg;  // sign bits of a / b
  bit [4:0]       shamt;         // shift amount = b[4:0]
  bit             shift_in_msb;  // source MSB (SRA fills with it, SRL with 0)
  bit             cmp;           // branch decision the DUT produced (0/1)
  bit             a_eq_b;        // a == b (interesting for compares)
  bit             ex_valid;      // ex_valid at completion (0 possible: branch)
  int unsigned    alu_cycles, stall_cycles;   // timing fields of the txn
  bit             we;            // did it write the register file?
  bit [4:0]       rd;            // destination register
  bit             tag_valid;     // instruction word available?
  bit             is_lui, is_auipc, is_jump, is_lsu;  // decoder flags from tag
  bit             lsu_en, misaligned_2nd;     // LSU flags from the interface
  // divider-specific sample fields
  int unsigned    div_lat;             // net divider latency (3..35)
  bit             div_by_zero, div_overflow;  // corners (spec Table 7.1)
  operand_class_e dividend_cls, divisor_cls;  // classes AFTER un-swapping
  bit             divisor_neg, dividend_neg;
  // sequence context = facts about the PREVIOUS ALU op (for cg_seq)
  bit             have_prev;
  alu_opcode_e    prev_op;
  bit             prev_was_div;  // previous op was a DIV/REM
  bit [4:0]       prev_rd;       // register previous op wrote (0 = none)
  int unsigned    gap;           // idle cycles between prev end and this start
  bit             raw_prev;      // this op reads prev's rd (RAW hazard)
  // reset context (used only by cg_reset)
  int unsigned    cycles_done_at_reset;
  int unsigned    prev_cycle_end;

  int unsigned    n_sampled, n_killed;    // statistics for report_phase

  // GROUP 1: which operator reached the ALU (decoder-reach, vplan risc_dec_01)
  covergroup cg_op;
    option.per_instance = 1;
    cp_op : coverpoint op {
      bins add  = {ALU_ADD};  bins sub  = {ALU_SUB};
      bins and_ = {ALU_AND};  bins or_  = {ALU_OR};   bins xor_ = {ALU_XOR};
      bins sll  = {ALU_SLL};  bins srl  = {ALU_SRL};  bins sra  = {ALU_SRA};
      bins slts = {ALU_SLTS}; bins sltu = {ALU_SLTU};
      bins eq   = {ALU_EQ};   bins ne   = {ALU_NE};   bins lts  = {ALU_LTS}; bins ges = {ALU_GES};
      bins ltu  = {ALU_LTU};  bins geu  = {ALU_GEU};
      bins div  = {ALU_DIV};  bins divu = {ALU_DIVU}; bins rem  = {ALU_REM}; bins remu = {ALU_REMU};
      illegal_bins out_of_scope = default;   // any other enum value = BUG
    }
    // Which instruction FORMAT drove the ALU this time? (one-hot flags)
    cp_src : coverpoint {is_lui, is_auipc, is_jump, is_lsu} {
      bins reg_imm = {4'b0000};   // normal register/immediate op
      bins lui     = {4'b1000};   // LUI
      bins auipc   = {4'b0100};   // AUIPC
      bins jump    = {4'b0010};   // JAL / JALR (link value)
      bins lsu     = {4'b0001};   // load/store address
    }
    cp_we : coverpoint we;        // did the ALU write port fire?
    // {lsu_en, misaligned_2nd}: normal address pass = 10, 2nd pass = 11,
    // "misaligned without lsu" = 01 is IMPOSSIBLE -> illegal bin
    cp_lsu : coverpoint {lsu_en, misaligned_2nd} {
      bins no_lsu          = {2'b00};
      bins lsu_addr        = {2'b10};
      bins lsu_misaligned2 = {2'b11};
      illegal_bins bad     = {2'b01};
    }
    // For LSU-address ops only: how long EX waited for the data side.
    cp_lsu_stall : coverpoint stall_cycles iff (lsu_en) { bins none = {0}; bins gnt_wait = {[1:$]}; }
    x_lsu_stall : cross cp_lsu, cp_lsu_stall { ignore_bins no_lsu = x_lsu_stall with (cp_lsu == 2'b00); }
    x_op_we : cross cp_op, cp_we {
      // Branch/LSU ops never write through the ALU port (we must be 0);
      // that combo is dropped as impossible.
      ignore_bins branch_we = x_op_we with (cp_op inside {ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU} && cp_we);
    }
  endgroup

  // GROUP 2: operand classes for every SINGLE-CYCLE op class (vplan risc_alu_*)
  covergroup cg_alu_operands;
    option.per_instance = 1;
    cp_cls  : coverpoint cls { bins arith = {ALU_CLS_ARITH}; bins logic_ = {ALU_CLS_LOGIC};
                               bins shift = {ALU_CLS_SHIFT}; bins slt = {ALU_CLS_SLT}; bins branch = {ALU_CLS_BRANCH}; }
    cp_a    : coverpoint a_cls;      // class of operand a
    cp_b    : coverpoint b_cls;      // class of operand b
    cp_a_neg: coverpoint a_neg;      // a's sign bit
    cp_b_neg: coverpoint b_neg;      // b's sign bit
    cp_eq   : coverpoint a_eq_b;     // a == b?
    x_cls_a    : cross cp_cls, cp_a;
    x_cls_b    : cross cp_cls, cp_b;
    x_cls_sign : cross cp_cls, cp_a_neg, cp_b_neg;  // sign corners per class
    x_slt_eq   : cross cp_cls, cp_eq {
      // a==b only matters for SLT and branch classes -> drop the rest
      ignore_bins not_cmp = x_slt_eq with (!(cp_cls inside {ALU_CLS_SLT, ALU_CLS_BRANCH}));
    }
  endgroup

  // GROUP 3: shifts - amount corners x source MSB (vplan risc_alu_shift)
  covergroup cg_shift;
    option.per_instance = 1;
    cp_op    : coverpoint op { bins sll = {ALU_SLL}; bins srl = {ALU_SRL}; bins sra = {ALU_SRA}; }
    cp_shamt : coverpoint shamt { bins zero = {0}; bins one = {1}; bins mid = {[2:30]}; bins max = {31}; }
      // 0, 1, 2-30, 31: corners that exercise the barrel shifter wiring
    cp_msb   : coverpoint shift_in_msb;   // source MSB: 0 or 1
      // matters for SRA (arithmetic fill) vs SRL and the last bit shifted out
    x_op_shamt_msb : cross cp_op, cp_shamt, cp_msb;
  endgroup

  // GROUP 4: branch decisions (vplan risc_branch: taken/not-taken per compare)
  covergroup cg_branch;
    option.per_instance = 1;
    cp_op    : coverpoint op { bins eq = {ALU_EQ}; bins ne = {ALU_NE}; bins lts = {ALU_LTS};
                               bins ges = {ALU_GES}; bins ltu = {ALU_LTU}; bins geu = {ALU_GEU}; }
    cp_taken : coverpoint cmp;       // 1 = taken, 0 = not taken
    cp_valid : coverpoint ex_valid;  // 0 = branch left EX while WB not ready
    cp_sign  : coverpoint {a_neg, b_neg};   // sign corners of both operands
    x_op_taken      : cross cp_op, cp_taken;          // every compare both ways
    x_op_taken_sign : cross cp_op, cp_taken, cp_sign;  // ...at every sign combo
    x_op_valid      : cross cp_op, cp_valid;          // ...and both ex_valid ways
  endgroup

  // GROUP 5: divider corners (vplan risc_m_02: /0, INT_MIN/-1, operand classes)
  covergroup cg_div;
    option.per_instance = 1;
    cp_op       : coverpoint op { bins div = {ALU_DIV}; bins divu = {ALU_DIVU}; bins rem = {ALU_REM}; bins remu = {ALU_REMU}; }
    cp_dividend : coverpoint dividend_cls;    // class of rs1 (dividend)
    cp_divisor  : coverpoint divisor_cls;     // class of rs2 (divisor)
    cp_zero     : coverpoint div_by_zero;     // divide by zero (spec Table 7.1)
    cp_ovf      : coverpoint div_overflow;    // INT_MIN / -1 (signed ops only)
    cp_sign     : coverpoint {dividend_neg, divisor_neg};
    x_op_dividend : cross cp_op, cp_dividend;
    x_op_divisor  : cross cp_op, cp_divisor;
    x_op_zero     : cross cp_op, cp_zero;
    x_op_ovf      : cross cp_op, cp_ovf {
      // overflow only exists for signed ops -> drop DIVU/REMU combinations
      ignore_bins unsigned_ops = x_op_ovf with (cp_op inside {ALU_DIVU, ALU_REMU} && cp_ovf);
    }
    x_op_sign     : cross cp_op, cp_sign;
  endgroup

  // GROUP 6: divider LATENCY x external stall (vplan risc_m_02 timing, 3..35)
  covergroup cg_div_timing;
    option.per_instance = 1;
    cp_op   : coverpoint op { bins div = {ALU_DIV}; bins divu = {ALU_DIVU}; bins rem = {ALU_REM}; bins remu = {ALU_REMU}; }
    cp_lat  : coverpoint div_lat {
      bins min      = {3};             // divisor 0x80000000 (6-bit clb wrap!)
      bins short    = {[4:10]};        // few leading zeros
      bins mid      = {[11:30]};       // typical divisors
      bins long     = {[31:33]};       // divisor 1 / -1 territory
      bins max_m1   = {34};            // signed -1
      bins max      = {35};            // divide by zero
      illegal_bins other = default;    // any other cycle count = DUT bug
    }
    cp_stall: coverpoint stall_cycles { bins none = {0}; bins one = {1}; bins two_three = {[2:3]}; bins four_plus = {[4:$]}; }
    x_op_lat       : cross cp_op, cp_lat;         // latency classes per op
    x_lat_stall    : cross cp_lat, cp_stall;      // stalled at each latency
  endgroup

  // GROUP 7: SEQUENCE - what came right after a divider op (vplan risc_m_03)
  covergroup cg_seq;
    option.per_instance = 1;
    cp_prev_div : coverpoint prev_was_div;   // previous op was DIV/REM?
    cp_cur_cls  : coverpoint cls;            // class of the current op
    cp_gap      : coverpoint gap { bins b2b = {1}; bins two = {2}; bins three_plus = {[3:$]}; }
    cp_raw      : coverpoint raw_prev;       // current reads prev's rd (RAW)
    x_div_then     : cross cp_prev_div, cp_cur_cls, cp_gap {
      // keep only rows where the previous op really was a divider op
      ignore_bins not_after_div = x_div_then with (!cp_prev_div);
    }
    x_div_then_raw : cross cp_prev_div, cp_raw, cp_gap  {
      ignore_bins not_after_div = x_div_then_raw with (!cp_prev_div);
    }
  endgroup

  // GROUP 8: RESET while an op is in EX - which cycle? (vplan risc_rst_02)
  covergroup cg_reset;
    option.per_instance = 1;
    cp_cls   : coverpoint cls;
    cp_stage : coverpoint cycles_done_at_reset {
      bins first  = {1};        // first EX cycle
      bins divide = {[2:34]};   // middle of the divider
      bins finish = {[35:$]};   // last divider cycle / stall
    }
    x_cls_stage : cross cp_cls, cp_stage {
      // single-cycle ops only exist at stage 1 -> drop "late" combos
      ignore_bins single_late = x_cls_stage with (cp_cls != ALU_CLS_DIV && cp_stage != 1);
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_op           = new();
    cg_alu_operands = new();
    cg_shift        = new();
    cg_branch       = new();
    cg_div          = new();
    cg_div_timing   = new();
    cg_seq          = new();
    cg_reset        = new();
  endfunction

  // write(): called for EVERY alu_txn the ALU agent publishes.
  virtual function void write(alu_txn t);
    alu_expect_t e;            // decoder expectations of the tagged instr
    op  = t.op;                // unpack txn -> sample members
    cls = alu_op_class(t.op);
    if (t.killed_by_reset) begin        // reset kill -> only group 8
      n_killed++;
      cycles_done_at_reset = t.total_cycles;  // which EX cycle the reset hit
      cg_reset.sample();
      return;
    end
    if (!alu_op_in_scope(t.op)) return; // out-of-scope op: nothing to sample
    n_sampled++;

    a_cls = classify_operand(t.a);
    b_cls = classify_operand(t.b);
    a_neg = t.a[31];
    b_neg = t.b[31];
    a_eq_b = (t.a == t.b);
    shamt  = t.b[4:0];
    shift_in_msb = t.a[31];
    cmp      = t.cmp;
    ex_valid = t.ex_valid;
    alu_cycles   = t.alu_cycles;
    stall_cycles = t.stall_cycles;
    we  = t.we;
    rd  = t.waddr[4:0];
    tag_valid = t.tag_valid;
    is_lui = 0; is_auipc = 0; is_jump = 0; is_lsu = 0;   // defaults...
    lsu_en = t.lsu_en; misaligned_2nd = t.misaligned_2nd;
    if (tag_valid) begin           // refine flags from the instruction word
      e = t.expect_of_tag();
      if (e.in_scope) begin
        is_lui = e.is_lui; is_auipc = e.is_auipc; is_jump = e.is_jump; is_lsu = e.is_lsu;
      end
    end

    cg_op.sample();                // group 1 always
    case (cls)                     // sample the group(s) matching this class
      ALU_CLS_ARITH, ALU_CLS_LOGIC, ALU_CLS_SLT: cg_alu_operands.sample();
      ALU_CLS_SHIFT:  begin cg_alu_operands.sample(); cg_shift.sample(); end
      ALU_CLS_BRANCH: begin cg_alu_operands.sample(); cg_branch.sample(); end
      ALU_CLS_DIV: begin
        // NOTE: DUT operand order - a = divisor (rs2), b = dividend (rs1),
        // so swap them back here to name the divider fields correctly.
        dividend_cls = b_cls;  divisor_cls = a_cls;
        dividend_neg = b_neg;  divisor_neg = a_neg;
        div_by_zero  = (t.a == 32'h0);                               // divisor == 0
        div_overflow = (t.b == 32'h8000_0000) && (t.a == 32'hFFFF_FFFF);   // INT_MIN/-1
        div_lat      = alu_cycles;                                   // net latency
        cg_div.sample();              // group 5
        cg_div_timing.sample();       // group 6
      end
      default: ;
    endcase

    if (have_prev) begin           // group 7 needs a previous ALU op
      gap      = (t.cycle_start > prev_cycle_end) ? (t.cycle_start - prev_cycle_end) : 1;
      // RAW: this op reads the register the previous op wrote (and not x0)
      raw_prev = tag_valid && (prev_rd != 0) && ((t.instr_rs1() == prev_rd) || (t.instr_rs2() == prev_rd));
      cg_seq.sample();
    end
    have_prev      = 1;            // remember THIS op for the next sample
    prev_op        = op;
    prev_was_div   = (cls == ALU_CLS_DIV);
    prev_rd        = we ? rd : 5'd0;   // only remember rd if it really wrote
    prev_cycle_end = t.cycle_end;
  endfunction

  // report_phase: print each group's hit percentage at end of simulation.
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("ALU coverage: %0d items sampled, %0d killed by reset | op %.1f%% operands %.1f%% shift %.1f%% branch %.1f%% div %.1f%% div_timing %.1f%% seq %.1f%% reset %.1f%%",
              n_sampled, n_killed, cg_op.get_inst_coverage(), cg_alu_operands.get_inst_coverage(), cg_shift.get_inst_coverage(),
              cg_branch.get_inst_coverage(), cg_div.get_inst_coverage(), cg_div_timing.get_inst_coverage(),
              cg_seq.get_inst_coverage(), cg_reset.get_inst_coverage()), UVM_LOW)
  endfunction

endclass : alu_cov
