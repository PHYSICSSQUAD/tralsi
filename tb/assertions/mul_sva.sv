// =============================================================================
// mul_sva.sv
// -----------------------------------------------------------------------------
// MUL group of the "Assertions" block (tb_architecture/arch.jpg), bound into
// cv32e40p_core next to the shared ALU/MUL interface. All properties are
// derived from rtl/cv32e40p_mult.sv, rtl/cv32e40p_ex_stage.sv and
// rtl/cv32e40p_decoder.sv for the RV32IM configuration (COREV_PULP=0, FPU=0).
//
// Requires alu_mul_bind.sv (the interface instance alu_mul_if_i must exist in
// the core scope). Define MUL_SVA_NO_BIND to compile the module without the
// bind statement at the end of this file.
//
// Naming: A_* assertions, C_* covers. Assertion failures are reported through
// $error by the simulator; wrap with a UVM report catcher if the flow needs
// UVM-style counting.
// =============================================================================
module mul_sva
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
(
  alu_mul_if vif
);

  // ---- shorthand nets ----------------------------------------------------------
  wire              clk              = vif.clk;
  wire              rst_n            = vif.rst_n;
  wire              ex_ready         = vif.ex_ready;
  wire              ex_valid         = vif.ex_valid;
  wire              alu_en           = vif.alu_en;
  wire              mult_en          = vif.mult_en;
  mul_opcode_e      mult_operator;
  assign            mult_operator    = vif.mult_operator;
  wire [1:0]        mult_signed_mode = vif.mult_signed_mode;
  wire [31:0]       mult_operand_a   = vif.mult_operand_a;
  wire [31:0]       mult_operand_b   = vif.mult_operand_b;
  wire [31:0]       mult_operand_c   = vif.mult_operand_c;
  wire              mult_sel_subword = vif.mult_sel_subword;
  wire [4:0]        mult_imm         = vif.mult_imm;
  wire [31:0]       mult_result      = vif.mult_result;
  wire              mult_ready       = vif.mult_ready;
  wire              mult_multicycle  = vif.mult_multicycle;
  wire              mulh_active      = vif.mulh_active;
  wire              rf_alu_we        = vif.rf_alu_we;
  wire [5:0]        rf_alu_waddr     = vif.rf_alu_waddr;
  wire [31:0]       rf_alu_wdata     = vif.rf_alu_wdata;

  wire is_mul  = mult_en && (mult_operator == MUL_MAC32);
  wire is_mulh = mult_en && (mult_operator == MUL_H);

  default clocking sva_cb @(posedge clk); endclocking
  default disable iff (!rst_n);

  // ---------------------------------------------------------------------------
  // Encoding / configuration invariants (decoder, RV32IM only)
  // ---------------------------------------------------------------------------
  // Only MUL (MUL_MAC32) and MULH/MULHSU/MULHU (MUL_H) reach the multiplier.
  A_RV32IM_OPERATORS: assert property (mult_en |-> (mult_operator inside {MUL_MAC32, MUL_H}))
    else $error("mul_sva: multiplier operator %s is not an RV32IM encoding", mult_operator.name());

  // MULH sign modes: 11 (MULH), 01 (MULHSU), 00 (MULHU); 10 is never produced.
  A_SIGNED_MODE_LEGAL: assert property (is_mulh |-> (mult_signed_mode != 2'b10))
    else $error("mul_sva: MUL_H with signed_mode 2'b10");

  // PULP-only controls stay inactive.
  A_NO_PULP_MODES: assert property (mult_en |-> (!mult_sel_subword && (mult_imm == 5'd0)))
    else $error("mul_sva: mult_sel_subword/mult_imm active in RV32IM configuration");

  // The multiplier and the ALU are never enabled together (mul: alu_en=0 in the decoder).
  A_MUL_EXCL_ALU: assert property (mult_en |-> !alu_en)
    else $error("mul_sva: alu_en and mult_en asserted together");

  // ---------------------------------------------------------------------------
  // MUL (single cycle)
  // ---------------------------------------------------------------------------
  // MUL never enters the MULH FSM and accumulates 0 (REGC_ZERO -> op_c = 0).
  A_MUL_SINGLE_CYCLE: assert property (is_mul |-> (mult_ready && !mult_multicycle && !mulh_active && (mult_operand_c == 32'h0)))
    else $error("mul_sva: MUL not single-cycle / op_c != 0 (ready=%0b mc=%0b active=%0b op_c=%h)",
                mult_ready, mult_multicycle, mulh_active, mult_operand_c);

  // Datapath: low 32 bits of the product, every cycle the MUL sits in EX.
  A_MUL_RESULT: assert property (is_mul |-> (mult_result == mul_ref(mult_operand_a, mult_operand_b)))
    else $error("mul_sva: MUL result %h != %h (a=%h b=%h)",
                mult_result, mul_ref(mult_operand_a, mult_operand_b), mult_operand_a, mult_operand_b);

  // ---------------------------------------------------------------------------
  // MULH / MULHSU / MULHU (5-cycle FSM: IDLE, STEP0, STEP1, STEP2, FINISH)
  // ---------------------------------------------------------------------------
  // First cycle (IDLE with a MUL_H request): not ready, not multicycle.
  A_MULH_START: assert property ((is_mulh && !mulh_active) |-> (!mult_ready && !mult_multicycle))
    else $error("mul_sva: MULH first cycle must have mult_ready=0 and mult_multicycle=0");

  // Shape: IDLE -> 3 cycles STEP0..STEP2 (multicycle, active, not ready) -> FINISH (ready, not multicycle).
  A_MULH_FSM_SHAPE: assert property (
      (is_mulh && !mulh_active)
      |=> (mult_multicycle && mulh_active && !mult_ready) [*3]
      ##1 (mult_ready && !mult_multicycle && mulh_active))
    else $error("mul_sva: MULH FSM did not follow IDLE->STEP0->STEP1->STEP2->FINISH");

  // FINISH is held while EX cannot advance, and left exactly when it can.
  A_MULH_FINISH_HOLD: assert property ((mulh_active && mult_ready && !ex_ready) |=> (mulh_active && mult_ready))
    else $error("mul_sva: MULH left FINISH while ex_ready=0");

  A_MULH_FINISH_EXIT: assert property ((mulh_active && mult_ready && ex_ready) |=> !mulh_active)
    else $error("mul_sva: MULH FSM did not return to IDLE after FINISH && ex_ready");

  // mult_multicycle only exists inside a MULH.
  A_MULTICYCLE_IMPLIES_MULH: assert property (mult_multicycle |-> (is_mulh && mulh_active))
    else $error("mul_sva: mult_multicycle without an active MULH");

  // Operands and controls are frozen while the FSM runs (ID/EX register not updated: ex_ready=0).
  A_MULH_OPERANDS_STABLE: assert property (mulh_active |-> (mult_en && $stable(mult_operand_a) && $stable(mult_operand_b)
                                                            && $stable(mult_operator) && $stable(mult_signed_mode)))
    else $error("mul_sva: multiplier inputs changed while the MULH FSM is active");

  // Datapath in FINISH: high word according to the sign mode (same as the RTL's own CV32E40P_ASSERT_ON checks).
  A_MULH_RESULT: assert property (
      (is_mulh && mulh_active && mult_ready) |->
      (mult_result == ((mult_signed_mode == 2'b11) ? mulh_ref  (mult_operand_a, mult_operand_b) :
                       (mult_signed_mode == 2'b01) ? mulhsu_ref(mult_operand_a, mult_operand_b) :
                                                     mulhu_ref (mult_operand_a, mult_operand_b))))
    else $error("mul_sva: MULH* result %h wrong for mode %b (a=%h b=%h)",
                mult_result, mult_signed_mode, mult_operand_a, mult_operand_b);

  // ---------------------------------------------------------------------------
  // EX stage interaction
  // ---------------------------------------------------------------------------
  // A busy multiplier blocks the EX stage.
  A_BUSY_BLOCKS_EX: assert property (!mult_ready |-> (!ex_ready && !ex_valid))
    else $error("mul_sva: ex_ready/ex_valid asserted while mult_ready=0");

  // A MUL-unit instruction that does not complete stays in EX unchanged (nothing kills EX in this scope).
  A_HOLD_UNTIL_VALID: assert property ((mult_en && !ex_valid) |=> (mult_en && $stable(mult_operand_a) && $stable(mult_operand_b)
                                                                    && $stable(mult_operator) && $stable(mult_signed_mode)))
    else $error("mul_sva: MUL-unit instruction left EX without ex_valid");

  // Completion: the ALU write port carries the multiplier result to an integer register.
  A_WB_PORT_ON_VALID: assert property ((mult_en && ex_valid) |-> (rf_alu_we && (rf_alu_wdata == mult_result) && !rf_alu_waddr[5]))
    else $error("mul_sva: write port inconsistent at MUL completion (we=%0b wdata=%h result=%h waddr=%h)",
                rf_alu_we, rf_alu_wdata, mult_result, rf_alu_waddr);

  // Reset puts the FSM back to IDLE (checked without the default disable).
  A_RESET_IDLE: assert property (@(posedge clk) disable iff (1'b0) (!rst_n |-> !mulh_active))
    else $error("mul_sva: mulh_active during reset");

  // ---------------------------------------------------------------------------
  // Covers (scenarios the stimulus must reach)
  // ---------------------------------------------------------------------------
  C_MUL_STALLED_BY_LSU_WB:  cover property (is_mul && mult_ready && !ex_valid);
  C_MULH_FINISH_STALLED:    cover property (mulh_active && mult_ready && !ex_ready);
  C_MUL_BACK_TO_BACK:       cover property ((is_mul && ex_valid) ##1 is_mul);
  C_MULH_BACK_TO_BACK:      cover property ((mulh_active && mult_ready && ex_ready) ##1 is_mulh);
  C_MULH_THEN_MUL:          cover property ((mulh_active && mult_ready && ex_ready) ##1 is_mul);
  C_MUL_THEN_MULH:          cover property ((is_mul && ex_valid) ##1 is_mulh);
  C_MULH_RD_X0:             cover property (is_mulh && mulh_active && mult_ready && ex_valid && (rf_alu_waddr[4:0] == 5'd0));
  C_RESET_DURING_MULH:      cover property (@(posedge clk) disable iff (1'b0) (mulh_active ##1 !rst_n));

endmodule : mul_sva

`ifndef MUL_SVA_NO_BIND
bind cv32e40p_core mul_sva mul_sva_i (.vif(alu_mul_if_i));
`endif
