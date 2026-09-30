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

  // ---- shorthand nets: short local names for the interface signals ------------
  wire              clk            = vif.clk;         // core clock
  wire              rst_n          = vif.rst_n;       // active-low reset
  wire              ex_ready       = vif.ex_ready;    // EX free to take a new op
  wire              ex_valid       = vif.ex_valid;    // result valid this cycle
  wire              branch_in_ex   = vif.branch_in_ex;// op in EX is a branch
  wire              lsu_en         = vif.lsu_en;      // ALU computes ld/st address
  wire              misaligned_2nd = vif.data_misaligned_ex;  // 2nd pass of split ld/st
  wire              alu_en         = vif.alu_en;      // ALU unit active
  alu_opcode_e      alu_operator;
  assign            alu_operator   = vif.alu_operator;      // enum needs assign
  wire [31:0]       alu_operand_a  = vif.alu_operand_a;     // input A (= divisor for DIV)
  wire [31:0]       alu_operand_b  = vif.alu_operand_b;     // input B (= dividend for DIV)
  wire [31:0]       alu_result     = vif.alu_result;        // ALU output value
  wire              alu_cmp_result = vif.alu_cmp_result;    // comparator / branch bit
  wire              alu_ready      = vif.alu_ready;         // 0 while divider runs
  wire              mult_en        = vif.mult_en;           // multiplier active (excl check)
  wire              rf_alu_we      = vif.rf_alu_we;         // RF write enable
  wire [5:0]        rf_alu_waddr   = vif.rf_alu_waddr;      // dest register
  wire [31:0]       rf_alu_wdata   = vif.rf_alu_wdata;      // write data
  wire              id_valid       = vif.id_valid;          // ID holds valid instr
  wire              is_decoding    = vif.is_decoding;       // instr not killed

  // Derived helpers used by many properties:
  wire is_div_op   = alu_en && is_div_operator(alu_operator);   // a DIV/REM is in EX
  wire is_branch_op= alu_en && is_branch_operator(alu_operator);// a compare/branch is in EX
  wire is_single   = alu_en && !is_div_operator(alu_operator);  // single-cycle op in EX
  wire issue_pulse = id_valid && is_decoding;   // instruction moves ID -> EX next cycle

  // "first cycle of a DIV in EX": a DIV is in EX now AND (in the previous cycle
  // no DIV was in EX, or the previous DIV left EX via ex_ready).
  // The three *_prev signals are registered (one-cycle delayed) copies.
  logic div_prev, ex_ready_prev, issue_prev;
  always_ff @(posedge clk or negedge rst_n) begin   // async reset to 0
    if (!rst_n) begin
      div_prev      <= 1'b0;
      ex_ready_prev <= 1'b0;
      issue_prev    <= 1'b0;
    end else begin
      div_prev      <= is_div_op;       // remember what was in EX last cycle
      ex_ready_prev <= ex_ready;
      issue_prev    <= issue_pulse;
    end
  end
  wire div_first = is_div_op && (!div_prev || ex_ready_prev);  // this cycle starts a new DIV

  // "default clocking" = all properties use posedge clk unless overridden.
  default clocking sva_cb @(posedge clk); endclocking
  // "disable iff" = while rst_n is LOW no assertion is checked
  // (exception: A_RESET_DIV_IDLE below re-enables itself to watch reset).
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

  // ---- exact data-dependent divider latency (TWO implementations) ------------
  // Version A (SVA local variable - needs VCS/Xcelium/Questa, NOT Verilator):
  // at div_first, compute expected cycles; then require !alu_ready for exactly
  // that many cycles, ending with alu_ready when the counter hits 0.
`ifndef VERILATOR
  property p_div_latency_exact;
    int n;   // local countdown variable (sequence local vars unsupported in Verilator)
    (div_first, n = div_latency_ref(alu_operator, alu_operand_a) - 1)   // init at start
    |-> ((!alu_ready, n = n - 1) [*1:DIV_LATENCY_MAX]) ##1 (alu_ready && (n == 0));
  endproperty
  A_DIV_LATENCY_EXACT: assert property (p_div_latency_exact)
    else $error("alu_sva: divider latency differs from div_latency_ref (%s, divisor=%h)", alu_operator.name(), alu_operand_a);
`endif

  // Version B (plain counter - runs EVERYWHERE, incl. Verilator):
  // div_cycles counts the busy cycles; the moment alu_ready rises, check
  // div_cycles + 1 == div_latency_ref(...). Same expectation, procedural style.
  int unsigned div_cycles;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) div_cycles <= 0;                            // reset clears the count
    else if (div_first) div_cycles <= 1;                    // first busy cycle of a DIV
    else if (is_div_op && !alu_ready) div_cycles <= div_cycles + 1;  // still busy: count
    else if (!is_div_op) div_cycles <= 0;                   // not a DIV: idle
  end
  // Immediate assertion: fires only in the cycle the divider becomes ready.
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

  // Reset puts the divider back to IDLE (alu_ready high again).
  // "disable iff (1'b0)" = never disable -> we WANT to check during reset.
  A_RESET_DIV_IDLE: assert property (@(posedge clk) disable iff (1'b0) (!rst_n |=> alu_ready))
    else $error("alu_sva: divider not idle after reset");

  // ---------------------------------------------------------------------------
  // COVERS: goals for the STIMULUS (we WANT these scenarios to happen).
  // ---------------------------------------------------------------------------
  C_DIV_MIN_LATENCY:        cover property (div_first && (div_latency_ref(alu_operator, alu_operand_a) == DIV_LATENCY_MIN)); // a 3-cycle DIV
  C_DIV_MAX_LATENCY:        cover property (div_first && (alu_operand_a == 32'h0));     // divide by zero (35 cycles)
  C_DIV_FINISH_STALLED:     cover property (is_div_op && alu_ready && !ex_ready);       // FINISH held by LSU/WB
  C_DIV_BACK_TO_BACK:       cover property ((is_div_op && ex_ready) ##1 div_first);     // DIV right after a DIV
  C_DIV_THEN_BRANCH:        cover property ((is_div_op && ex_ready) ##1 branch_in_ex);  // branch right after DIV
  C_BRANCH_TAKEN:           cover property (branch_in_ex && alu_cmp_result);            // branch taken
  C_BRANCH_NOT_TAKEN:       cover property (branch_in_ex && !alu_cmp_result);           // branch not taken
  C_BRANCH_WITHOUT_EX_VALID:cover property (branch_in_ex && ex_ready && !ex_valid);     // branch leaves w/o ex_valid
  C_ALU_STALLED_BY_LSU_WB:  cover property (is_single && !ex_ready);                    // single-cycle op stalled
  C_BUBBLE:                 cover property (alu_en && !issue_prev && !misaligned_2nd && (alu_operator == ALU_SLTU) && !rf_alu_we); // idle bubble
  C_MISALIGNED_2ND_PASS:    cover property (alu_en && misaligned_2nd);                  // split ld/st 2nd pass
  C_RESET_DURING_DIV:       cover property (@(posedge clk) disable iff (1'b0) ((is_div_op && !alu_ready) ##1 !rst_n));  // reset mid-DIV

endmodule : alu_sva

// Plug this assertion module into the core; its port connects to the interface
// instance alu_mul_if_i (bound by alu_mul_bind.sv - compile that first).
// Define ALU_SVA_NO_BIND to skip this automatic bind.
`ifndef ALU_SVA_NO_BIND
bind cv32e40p_core alu_sva alu_sva_i (.vif(alu_mul_if_i));
`endif
