// =============================================================================
// alu_mul_bind.sv
// -----------------------------------------------------------------------------
// Binds the shared ALU/MUL passive interface into every cv32e40p_core instance
// (there is exactly one: cv32e40p_top.core_i). The port connections are
// resolved in the scope of cv32e40p_core, therefore:
//   * plain names        -> wires declared in rtl/cv32e40p_core.sv
//   * ex_stage_i.<name>  -> internal wires of rtl/cv32e40p_ex_stage.sv
//
// After binding, the interface instance is reachable as
//   cv32e40p_top.core_i.alu_mul_if_i        (e.g. dut.core_i.alu_mul_if_i)
// and - unless ALU_MUL_NO_UVM is defined - it is also published through
//   uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", ...)
// by the small registrar module bound next to it, so top_tb does not have to
// know the hierarchical path. top_tb may still set the same key explicitly.
//
// Compile order: rtl/package/cv32e40p_pkg.sv, rtl/..., tb/interfaces/alu_mul_if.sv,
//                (uvm_pkg), tb/interfaces/alu_mul_bind.sv
// =============================================================================

bind cv32e40p_core alu_mul_if alu_mul_if_i (
  .clk              (clk_i),
  .rst_n            (rst_ni),

  // EX stage handshake
  .ex_ready         (ex_ready),
  .ex_valid         (ex_valid),
  .lsu_ready_ex     (lsu_ready_ex),
  .wb_ready         (lsu_ready_wb),
  .branch_in_ex     (branch_in_ex),
  .lsu_en           (data_req_ex),
  .data_misaligned_ex (data_misaligned_ex),

  // ALU group (ID/EX pipeline registers -> cv32e40p_alu)
  .alu_en           (alu_en_ex),
  .alu_operator     (alu_operator_ex),
  .alu_operand_a    (alu_operand_a_ex),
  .alu_operand_b    (alu_operand_b_ex),
  .alu_operand_c    (alu_operand_c_ex),
  .alu_result       (ex_stage_i.alu_result),
  .alu_cmp_result   (ex_stage_i.alu_cmp_result),
  .alu_ready        (ex_stage_i.alu_ready),

  // MUL group (ID/EX pipeline registers -> cv32e40p_mult)
  .mult_en          (mult_en_ex),
  .mult_operator    (mult_operator_ex),
  .mult_signed_mode (mult_signed_mode_ex),
  .mult_operand_a   (mult_operand_a_ex),
  .mult_operand_b   (mult_operand_b_ex),
  .mult_operand_c   (mult_operand_c_ex),
  .mult_sel_subword (mult_sel_subword_ex),
  .mult_imm         (mult_imm_ex),
  .mult_result      (ex_stage_i.mult_result),
  .mult_ready       (ex_stage_i.mult_ready),
  .mult_multicycle  (mult_multicycle),
  .mulh_active      (ex_stage_i.mulh_active),

  // register-file ALU write port / forwarding value
  .rf_alu_we        (regfile_alu_we_fw),
  .rf_alu_waddr     (regfile_alu_waddr_fw),
  .rf_alu_wdata     (regfile_alu_wdata_fw),

  // tag (instruction issue from ID)
  .id_valid         (id_valid),
  .is_decoding      (is_decoding),
  .pc_id            (pc_id),
  .instr_id         (instr_rdata_id)
);

`ifndef ALU_MUL_NO_UVM
// Publishes the bound interface in the UVM configuration database.
// The interface port is connected (in the core scope) to the sibling bound
// instance alu_mul_if_i, so this module never uses hierarchical names.
module alu_mul_if_registrar (alu_mul_if vif);
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  initial begin
    uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", vif);
  end
endmodule : alu_mul_if_registrar

bind cv32e40p_core alu_mul_if_registrar alu_mul_if_registrar_i (.vif(alu_mul_if_i));
`endif
