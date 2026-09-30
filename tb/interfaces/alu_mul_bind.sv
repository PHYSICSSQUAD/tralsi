// =============================================================================
// alu_mul_bind.sv
// =============================================================================
// WHAT THIS FILE IS:
//   "bind" = a SystemVerilog feature that PLUGS an interface into an existing
//   module WITHOUT editing that module's source code. Here we plug alu_mul_if
//   into cv32e40p_core (the DUT core). There is exactly one core instance:
//   cv32e40p_top.core_i.
//
// HOW NAMES ARE RESOLVED:
//   The port connections below are written INSIDE the scope of cv32e40p_core,
//   therefore:
//     * plain name (ex_ready)     -> a wire that exists in rtl/cv32e40p_core.sv
//     * dotted name (ex_stage_i.alu_result) -> an internal wire of the EX stage
//       submodule (rtl/cv32e40p_ex_stage.sv), reachable because we are in core scope.
//
// AFTER BINDING the interface instance lives at:
//     cv32e40p_top.core_i.alu_mul_if_i
// and - unless the define ALU_MUL_NO_UVM is set - the small registrar module
// at the bottom of this file publishes it in the UVM config db under the key
// "alu_mul_vif", so agents can do: uvm_config_db#(virtual alu_mul_if)::get(...).
//
// COMPILE ORDER: rtl packages first, then alu_mul_if.sv, (uvm_pkg), then this file.
// =============================================================================

// "bind <target_module> <interface_type> <instance_name> ( .port(signal), ... );"
// Target  = cv32e40p_core           (every instance of this module gets a copy)
// Type    = alu_mul_if              (the interface we defined in alu_mul_if.sv)
// Instance= alu_mul_if_i            (how the monitor finds it later)
bind cv32e40p_core alu_mul_if alu_mul_if_i (
  .clk              (clk_i),          // core clock input pin
  .rst_n            (rst_ni),         // core active-low reset input pin

  // --- EX stage handshake ---------------------------------------------------
  .ex_ready         (ex_ready),             // core wire: EX free to take new op
  .ex_valid         (ex_valid),             // core wire: EX result valid now
  .lsu_ready_ex     (lsu_ready_ex),         // core wire: LSU holding EX? (0=hold)
  .wb_ready         (wb_ready_wb),          // core wire: WB holding EX? (0=hold)
  .branch_in_ex     (branch_in_ex),         // core wire: op in EX is a branch
  .lsu_en           (data_req_ex),          // core wire: ld/st address request
  .data_misaligned_ex (data_misaligned_ex), // core wire: 2nd half of misaligned ld/st

  // --- ALU group (ID/EX pipeline register outputs -> cv32e40p_alu) ----------
  .alu_en           (alu_en_ex),            // ID/EX reg: ALU active
  .alu_operator     (alu_operator_ex),      // ID/EX reg: which ALU op
  .alu_operand_a    (alu_operand_a_ex),     // ID/EX reg: operand A
  .alu_operand_b    (alu_operand_b_ex),     // ID/EX reg: operand B
  .alu_operand_c    (alu_operand_c_ex),     // ID/EX reg: operand C
  .alu_result       (ex_stage_i.alu_result),    // inside EX stage: ALU output
  .alu_cmp_result   (ex_stage_i.alu_cmp_result),// inside EX stage: comparator out
  .alu_ready        (ex_stage_i.alu_ready),     // inside EX stage: 0 while divider runs

  // --- MUL group (ID/EX pipeline register outputs -> cv32e40p_mult) --------
  .mult_en          (mult_en_ex),           // ID/EX reg: multiplier active
  .mult_operator    (mult_operator_ex),     // ID/EX reg: MUL vs MULH*
  .mult_signed_mode (mult_signed_mode_ex),  // ID/EX reg: signedness of operands
  .mult_operand_a   (mult_operand_a_ex),    // ID/EX reg: multiplicand (= rs1)
  .mult_operand_b   (mult_operand_b_ex),    // ID/EX reg: multiplier (= rs2)
  .mult_operand_c   (mult_operand_c_ex),    // ID/EX reg: accumulator for MULH
  .mult_sel_subword (mult_sel_subword_ex),  // ID/EX reg: PULP flag, must be 0
  .mult_imm         (mult_imm_ex),          // ID/EX reg: PULP imm, must be 0
  .mult_result      (ex_stage_i.mult_result),   // inside EX stage: MUL output
  .mult_ready       (ex_stage_i.mult_ready),    // inside EX stage: 0 in MULH middle
  .mult_multicycle  (mult_multicycle),      // core wire: 1 in MULH STEP0..2
  .mulh_active      (ex_stage_i.mulh_active),   // inside EX: MULH FSM busy flag

  // --- register-file write port b (value also used to forward to ID) -------
  .rf_alu_we        (regfile_alu_we_fw),    // core wire: RF write enable (fwd'd)
  .rf_alu_waddr     (regfile_alu_waddr_fw), // core wire: RF write address
  .rf_alu_wdata     (regfile_alu_wdata_fw), // core wire: RF write data / forward

  // --- tag: instruction in the decode stage --------------------------------
  .id_valid         (id_valid),             // core wire: ID holds valid instr
  .is_decoding      (is_decoding),          // core wire: instr not killed
  .pc_id            (pc_id),                // core wire: PC in ID
  .instr_id         (instr_rdata_id)        // core wire: instruction word in ID
);

`ifndef ALU_MUL_NO_UVM
// -----------------------------------------------------------------------------
// Registrar: a 6-line helper module whose ONLY job is to put the bound
// interface into the UVM config database so agents can find it by name.
// It receives the interface through its port (connected to alu_mul_if_i in the
// core scope) - no hierarchical paths are needed inside the module.
// Key used everywhere: "alu_mul_vif".
// -----------------------------------------------------------------------------
module alu_mul_if_registrar (alu_mul_if vif);
  import uvm_pkg::*;                        // for uvm_config_db
  `include "uvm_macros.svh"                 // for any uvm macro (safety)
  initial begin                              // runs once at time 0
    // publish: any UVM component, anywhere ("*"), may get() the interface
    uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", vif);
  end
endmodule : alu_mul_if_registrar

// Plug the registrar into the core too; its .vif port connects to alu_mul_if_i
// (the interface instance bound above), so it is filled automatically.
bind cv32e40p_core alu_mul_if_registrar alu_mul_if_registrar_i (.vif(alu_mul_if_i));
`endif
