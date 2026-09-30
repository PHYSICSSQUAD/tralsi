// =============================================================================
// alu_sva.sv
// -----------------------------------------------------------------------------
// ALU / divider group of the "Assertions" block (tb_architecture/arch.jpg),
// bound into cv32e40p_core next to mul_sva on the shared alu_mul_if instance.
// Properties are derived from rtl/cv32e40p_alu.sv, rtl/cv32e40p_alu_div.sv,
// rtl/cv32e40p_ex_stage.sv, rtl/cv32e40p_id_stage.sv and rtl/cv32e40p_decoder.sv
// for the RV32IM configuration (COREV_PULP=0, FPU=0).
// Requires alu_mul_bind.sv. Define ALU_SVA_NO_BIND to compile without the bind
// statement at the end of the file.
// Naming: A_* assertions, C_* covers.
//
// The data-dependent divider latency (3..35 cycles, alu_ref_pkg::div_latency_ref)
// is checked twice: A_DIV_LATENCY_EXACT uses an SVA local variable (VCS/Xcelium/
// Questa) and A_DIV_LATENCY_CNT is a procedural counter with an immediate
// assertion (also runs under Verilator, which has no local-variable support).
// =============================================================================
module alu_sva
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
(
  alu_mul_if vif
);

  // ---- shorthand nets ----------------------------------------------------------
  wire              clk            = vif.clk;
  wire              rst_n          = vif.rst_n;
  wire              ex_ready       = vif.ex_ready;
  wire              ex_valid       = vif.ex_valid;
  wire              branch_in_ex   = vif.branch_in_ex;
  wire              lsu_en         = vif.lsu_en;
  wire              misaligned_2nd = vif.data_misaligned_ex;
  wire              alu_en         = vif.alu_en;
  alu_opcode_e      alu_operator;
  assign            alu_operator   = vif.alu_operator;
  wire [31:0]       alu_operand_a  = vif.alu_operand_a;
  wire [31:0]       alu_operand_b  = vif.alu_operand_b;
  wire [31:0]       alu_result     = vif.alu_result;
  wire              alu_cmp_result = vif.alu_cmp_result;
  wire              alu_ready      = vif.alu_ready;
  wire              mult_en        = vif.mult_en;
  wire              rf_alu_we      = vif.rf_alu_we;
  wire [5:0]        rf_alu_waddr   = vif.rf_alu_waddr;
  wire [31:0]       rf_alu_wdata   = vif.rf_alu_wdata;
  wire              id_valid       = vif.id_valid;
  wire              is_decoding    = vif.is_decoding;

  wire is_div_op   = alu_en && is_div_operator(alu_operator);
  wire is_branch_op= alu_en && is_branch_operator(alu_operator);
  wire is_single   = alu_en && !is_div_operator(alu_operator);
  wire issue_pulse = id_valid && is_decoding;

  // "first cycle of a DIV in EX": a DIV is in EX now and in the previous cycle
  // either no DIV was in EX or the previous DIV left EX (ex_ready).
  logic div_prev, ex_ready_prev, issue_prev;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      div_prev      <= 1'b0;
      ex_ready_prev <= 1'b0;
      issue_prev    <= 1'b0;
    end else begin
      div_prev      <= is_div_op;
      ex_ready_prev <= ex_ready;
      issue_prev    <= issue_pulse;
    end
  end
  wire div_first = is_div_op && (!div_prev || ex_ready_prev);

  default clocking sva_cb @(posedge clk); endclocking
  default disable iff (!rst_n);

  // ---------------------------------------------------------------------------
  // Encoding / configuration invariants (decoder, RV32IM only)
  // ---------------------------------------------------------------------------
  // Only the 20 RV32IM operators reach the ALU (bubbles use ALU_SLTU).
  A_RV32IM_OPERATORS: assert property (alu_en |-> alu_op_in_scope(alu_operator))
    else $error("alu_sva: alu_operator %s is not producible by the RV32IM decoder", alu_operator.name());

  A_ALU_EXCL_MUL: assert property (alu_en |-> !mult_en)
    else $error("alu_sva: alu_en and mult_en asserted together");

  // Whatever enters EX (previous cycle ex_ready) without an issue pulse is a
  // bubble (SLTU, no write, no branch, no LSU) or the second pass of a
  // misaligned access (ADD, lsu_en, no write). The ID/EX register only changes
  // when ex_ready=1 (rtl/cv32e40p_id_stage.sv ID_EX_PIPE_REGISTERS).
  A_NO_ISSUE_IS_BUBBLE: assert property (
      (alu_en && ex_ready_prev && !issue_prev)
      |-> (misaligned_2nd ? ((alu_operator == ALU_ADD) && lsu_en && !rf_alu_we)
                          : ((alu_operator == ALU_SLTU) && !rf_alu_we && !branch_in_ex && !lsu_en)))
    else $error("alu_sva: ALU activity without an issued instruction: %s we=%0b lsu_en=%0b misaligned=%0b",
                alu_operator.name(), rf_alu_we, lsu_en, misaligned_2nd);

  // Misaligned second pass: address + 4, computed from the first pass' result.
  A_MISALIGNED_2ND_PASS: assert property ((alu_en && misaligned_2nd) |-> ((alu_operator == ALU_ADD) && (alu_operand_b == 32'd4) && lsu_en && !rf_alu_we))
    else $error("alu_sva: misaligned 2nd pass is not ADD(addr, 4): %s b=%h", alu_operator.name(), alu_operand_b);

  // ---------------------------------------------------------------------------
  // Single-cycle operators: ready, combinational result
  // ---------------------------------------------------------------------------
  A_SINGLE_CYCLE_READY: assert property (is_single |-> alu_ready)
    else $error("alu_sva: alu_ready=0 for single-cycle operator %s", alu_operator.name());

  A_ALU_RESULT: assert property ((is_single && alu_op_in_scope(alu_operator)) |-> (alu_result == alu_ref(alu_operator, alu_operand_a, alu_operand_b)))
    else $error("alu_sva: %s result %h wrong (a=%h b=%h, expected %h)", alu_operator.name(), alu_result,
                alu_operand_a, alu_operand_b, alu_ref(alu_operator, alu_operand_a, alu_operand_b));

  A_BRANCH_DECISION: assert property (is_branch_op |-> (alu_cmp_result == alu_cmp_ref(alu_operator, alu_operand_a, alu_operand_b)))
    else $error("alu_sva: %s comparison %0b wrong (a=%h b=%h)", alu_operator.name(), alu_cmp_result, alu_operand_a, alu_operand_b);

  // Branch operators come only with branch_in_ex, and vice versa; a branch never writes the RF.
  A_BRANCH_OP_IFF_BRANCH_IN_EX: assert property (alu_en |-> (is_branch_operator(alu_operator) == branch_in_ex))
    else $error("alu_sva: branch_in_ex=%0b with operator %s", branch_in_ex, alu_operator.name());

  A_BRANCH_NO_WRITE: assert property (branch_in_ex |-> !rf_alu_we)
    else $error("alu_sva: rf_alu_we during a branch");

  // Branches leave EX immediately (ex_ready forced by branch_in_ex).
  A_BRANCH_LEAVES_EX: assert property (branch_in_ex |-> ex_ready)
    else $error("alu_sva: branch held in EX");

  // ---------------------------------------------------------------------------
  // Divider (cv32e40p_alu_div: IDLE -> DIVIDE (div_shift + 1 cycles) -> FINISH)
  // ---------------------------------------------------------------------------
  A_DIV_START_BUSY: assert property (div_first |-> !alu_ready)
    else $error("alu_sva: divider ready in the first cycle of %s", alu_operator.name());

  A_DIV_BUSY_IMPLIES_DIV: assert property (!alu_ready |-> is_div_op)
    else $error("alu_sva: alu_ready=0 without a DIV/REM in EX");

  A_DIV_BUSY_BLOCKS_EX: assert property (!alu_ready |-> (!ex_ready && !ex_valid))
    else $error("alu_sva: ex_ready/ex_valid asserted while the divider is busy");

  A_DIV_OPERANDS_STABLE: assert property ((is_div_op && !ex_ready) |=> (is_div_op && $stable(alu_operator) && $stable(alu_operand_a) && $stable(alu_operand_b)))
    else $error("alu_sva: divider inputs changed while the division runs");

  A_DIV_FINISH_HOLD: assert property ((is_div_op && alu_ready && !ex_ready) |=> (is_div_op && alu_ready))
    else $error("alu_sva: divider left FINISH while ex_ready=0");

  A_DIV_RESULT: assert property ((is_div_op && alu_ready) |-> (alu_result == alu_ref(alu_operator, alu_operand_a, alu_operand_b)))
    else $error("alu_sva: %s result %h wrong (divisor=%h dividend=%h, expected %h)", alu_operator.name(), alu_result,
                alu_operand_a, alu_operand_b, alu_ref(alu_operator, alu_operand_a, alu_operand_b));

  // Exact, data-dependent latency: alu_ready is low for div_latency_ref-1 cycles, then high.
`ifndef VERILATOR
  property p_div_latency_exact;
    int n;
    (div_first, n = div_latency_ref(alu_operator, alu_operand_a) - 1)
    |-> ((!alu_ready, n = n - 1) [*1:DIV_LATENCY_MAX]) ##1 (alu_ready && (n == 0));
  endproperty
  A_DIV_LATENCY_EXACT: assert property (p_div_latency_exact)
    else $error("alu_sva: divider latency differs from div_latency_ref (%s, divisor=%h)", alu_operator.name(), alu_operand_a);
`endif

  // Same check as a counter (portable): cycles since the first cycle when alu_ready rises.
  int unsigned div_cycles;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) div_cycles <= 0;
    else if (div_first) div_cycles <= 1;
    else if (is_div_op && !alu_ready) div_cycles <= div_cycles + 1;
    else if (!is_div_op) div_cycles <= 0;
  end
  always @(posedge clk) if (rst_n && is_div_op && alu_ready && (div_cycles != 0)) begin
    A_DIV_LATENCY_CNT: assert (div_cycles + 1 == div_latency_ref(alu_operator, alu_operand_a))
      else $error("alu_sva: %s took %0d cycles to become ready, expected %0d (divisor=%h)",
                  alu_operator.name(), div_cycles + 1, div_latency_ref(alu_operator, alu_operand_a), alu_operand_a);
  end

  // ---------------------------------------------------------------------------
  // EX stage interaction / write port
  // ---------------------------------------------------------------------------
  // The ID/EX register is frozen while EX cannot advance.
  A_HOLD_UNTIL_EX_READY: assert property ((alu_en && !ex_ready) |=> (alu_en && $stable(alu_operator) && $stable(alu_operand_a) && $stable(alu_operand_b)))
    else $error("alu_sva: ALU inputs changed while ex_ready=0");

  // Write port: data is the ALU result; never the FP register file; a write needs ex_valid to matter.
  A_WB_DATA_IS_RESULT: assert property ((alu_en && rf_alu_we) |-> ((rf_alu_wdata == alu_result) && !rf_alu_waddr[5]))
    else $error("alu_sva: rf_alu_wdata/waddr inconsistent with the ALU result");

  // Load/store address computation never writes through the ALU port.
  A_LSU_NO_ALU_WRITE: assert property ((alu_en && lsu_en) |-> !rf_alu_we)
    else $error("alu_sva: rf_alu_we during a load/store address computation");

  // Reset puts the divider back to IDLE (alu_ready high) - checked without the default disable.
  A_RESET_DIV_IDLE: assert property (@(posedge clk) disable iff (1'b0) (!rst_n |=> alu_ready))
    else $error("alu_sva: divider not idle after reset");

  // ---------------------------------------------------------------------------
  // Covers
  // ---------------------------------------------------------------------------
  C_DIV_MIN_LATENCY:        cover property (div_first && (div_latency_ref(alu_operator, alu_operand_a) == DIV_LATENCY_MIN));
  C_DIV_MAX_LATENCY:        cover property (div_first && (alu_operand_a == 32'h0));
  C_DIV_FINISH_STALLED:     cover property (is_div_op && alu_ready && !ex_ready);
  C_DIV_BACK_TO_BACK:       cover property ((is_div_op && ex_ready) ##1 div_first);
  C_DIV_THEN_BRANCH:        cover property ((is_div_op && ex_ready) ##1 branch_in_ex);
  C_BRANCH_TAKEN:           cover property (branch_in_ex && alu_cmp_result);
  C_BRANCH_NOT_TAKEN:       cover property (branch_in_ex && !alu_cmp_result);
  C_BRANCH_WITHOUT_EX_VALID:cover property (branch_in_ex && ex_ready && !ex_valid);
  C_ALU_STALLED_BY_LSU_WB:  cover property (is_single && !ex_ready);
  C_BUBBLE:                 cover property (alu_en && !issue_prev && !misaligned_2nd && (alu_operator == ALU_SLTU) && !rf_alu_we);
  C_MISALIGNED_2ND_PASS:    cover property (alu_en && misaligned_2nd);
  C_RESET_DURING_DIV:       cover property (@(posedge clk) disable iff (1'b0) ((is_div_op && !alu_ready) ##1 !rst_n));

endmodule : alu_sva

`ifndef ALU_SVA_NO_BIND
bind cv32e40p_core alu_sva alu_sva_i (.vif(alu_mul_if_i));
`endif
