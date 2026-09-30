// =============================================================================
// alu_mul_if.sv
// -----------------------------------------------------------------------------
// Shared passive interface of the ALU agent and the MUL agent (block
// "ALU_MUL interface" in tb_architecture/arch.jpg).
//
// It is a pure white-box probe on the EX stage of cv32e40p_core: every port is
// an INPUT driven by the bind statement in alu_mul_bind.sv, nothing is ever
// driven into the DUT. Both agents are UVM_PASSIVE (monitor only).
//
// Signal sources (all inside cv32e40p_top.core_i, RV32IM configuration:
// FPU=0, ZFINX=0, COREV_PULP=0, COREV_CLUSTER=0 - guidelines Team 2/4):
//
//   group      | interface signal          | cv32e40p_core signal (file)
//   -----------+---------------------------+-----------------------------------------------
//   handshake  | ex_ready                  | ex_ready        (cv32e40p_ex_stage.sv l.474)
//              | ex_valid                  | ex_valid        (cv32e40p_ex_stage.sv l.476)
//              | lsu_ready_ex, wb_ready    | lsu_ready_ex, lsu_ready_wb (why EX is stalled)
//              | branch_in_ex              | branch_in_ex    (ALU compare feeds branch_decision)
//   ALU        | alu_en                    | alu_en_ex       (ID/EX pipeline register)
//              | alu_operator              | alu_operator_ex (alu_opcode_e, incl. ALU_DIV/DIVU/REM/REMU)
//              | alu_operand_a/b/c         | alu_operand_a/b/c_ex
//              | alu_result                | ex_stage_i.alu_result
//              | alu_cmp_result            | ex_stage_i.alu_cmp_result (== branch_decision_o)
//              | alu_ready                 | ex_stage_i.alu_ready (0 while the divider runs)
//   MUL        | mult_en                   | mult_en_ex
//              | mult_operator             | mult_operator_ex (MUL_MAC32 = MUL, MUL_H = MULH*)
//              | mult_signed_mode          | mult_signed_mode_ex (11 MULH, 01 MULHSU, 00 MULHU;
//              |                           |   bit0 = operand a signed, bit1 = operand b signed)
//              | mult_operand_a/b/c        | mult_operand_a/b/c_ex (c = accumulator during MULH)
//              | mult_sel_subword, mult_imm| mult_sel_subword_ex, mult_imm_ex (PULP only -> must be 0)
//              | mult_result               | ex_stage_i.mult_result
//              | mult_ready                | ex_stage_i.mult_ready (0 in IDLE->STEP2 of the MULH FSM)
//              | mult_multicycle           | mult_multicycle (1 in STEP0..STEP2, tells ID to feed op_c)
//              | mulh_active               | ex_stage_i.mulh_active (1 in STEP0..FINISH)
//   write-back | rf_alu_we                 | regfile_alu_we_fw    (RF port b enable - toggles EVERY
//              |                           |   cycle of a stalled/multicycle op, qualify with ex_valid!)
//              | rf_alu_waddr[5:0]         | regfile_alu_waddr_fw (bit5 = FP regfile, must be 0)
//              | rf_alu_wdata              | regfile_alu_wdata_fw (= mult_result when mult_en,
//              |                           |   = alu_result when alu_en; also the EX->ID forwarding value)
//   LSU flags  | lsu_en                    | data_req_ex (ALU result is a load/store address, no RF write)
//              | data_misaligned_ex        | data_misaligned_ex (2nd half of a misaligned access: the ALU
//              |                           |   op is re-issued by ID as addr + 4 WITHOUT an issue pulse)
//   tag        | id_valid, is_decoding     | id_valid, is_decoding ("issue pulse": the instruction in
//              |                           |   ID moves to EX at the next edge; killed instructions
//              |                           |   have is_decoding=0, cv32e40p_controller.sv DECODE)
//              | pc_id, instr_id           | pc_id, instr_rdata_id (PC / word of the instruction in ID)
//
// Timing reference (notes/mul_plan.md section 0.2):
//   MUL   : 1 cycle in EX  (mult_ready=1, ex_valid in the same cycle unless LSU/WB stall)
//   MULH* : 5 cycles in EX (IDLE, STEP0, STEP1, STEP2, FINISH), ex_valid only in FINISH
// =============================================================================
interface alu_mul_if
  import cv32e40p_pkg::*;
(
  input logic clk,
  input logic rst_n,

  // --- EX stage handshake ----------------------------------------------------
  input logic ex_ready,
  input logic ex_valid,
  input logic lsu_ready_ex,
  input logic wb_ready,
  input logic branch_in_ex,
  input logic lsu_en,             // data_req_ex: the ALU computes a load/store address
  input logic data_misaligned_ex, // second half of a misaligned access re-uses the ALU (addr + 4)

  // --- ALU group ---------------------------------------------------------------
  input logic        alu_en,
  input alu_opcode_e alu_operator,
  input logic [31:0] alu_operand_a,
  input logic [31:0] alu_operand_b,
  input logic [31:0] alu_operand_c,
  input logic [31:0] alu_result,
  input logic        alu_cmp_result,
  input logic        alu_ready,

  // --- MUL group ---------------------------------------------------------------
  input logic        mult_en,
  input mul_opcode_e mult_operator,
  input logic [ 1:0] mult_signed_mode,
  input logic [31:0] mult_operand_a,
  input logic [31:0] mult_operand_b,
  input logic [31:0] mult_operand_c,
  input logic        mult_sel_subword,
  input logic [ 4:0] mult_imm,
  input logic [31:0] mult_result,
  input logic        mult_ready,
  input logic        mult_multicycle,
  input logic        mulh_active,

  // --- register-file ALU write port (port b) + forwarding value --------------
  input logic        rf_alu_we,
  input logic [ 5:0] rf_alu_waddr,
  input logic [31:0] rf_alu_wdata,

  // --- tag: instruction issue pulse from ID --------------------------------
  input logic        id_valid,
  input logic        is_decoding,
  input logic [31:0] pc_id,
  input logic [31:0] instr_id
);

  // Monitor clocking block: sample just before the active edge, i.e. the value
  // the DUT held during the cycle that ends at this edge.
  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input ex_ready, ex_valid, lsu_ready_ex, wb_ready, branch_in_ex, lsu_en, data_misaligned_ex;
    input alu_en, alu_operator, alu_operand_a, alu_operand_b, alu_operand_c,
          alu_result, alu_cmp_result, alu_ready;
    input mult_en, mult_operator, mult_signed_mode,
          mult_operand_a, mult_operand_b, mult_operand_c,
          mult_sel_subword, mult_imm,
          mult_result, mult_ready, mult_multicycle, mulh_active;
    input rf_alu_we, rf_alu_waddr, rf_alu_wdata;
    input id_valid, is_decoding, pc_id, instr_id;
  endclocking : mon_cb

  modport MON (clocking mon_cb, input clk, input rst_n);

  // ---------------------------------------------------------------------------
  // Convenience: "issue pulse" - the instruction currently in ID is accepted
  // and will be in EX during the next cycle.
  // ---------------------------------------------------------------------------
  function automatic bit issue_pulse();
    return (mon_cb.id_valid === 1'b1) && (mon_cb.is_decoding === 1'b1);
  endfunction

  // A new MUL-unit instruction is present in EX this cycle. The ID/EX register
  // is cleared (mult_en <= 0) whenever EX is ready and ID has nothing valid, so
  // after ex_valid the next cycle with mult_en=1 is always a new instruction.
  function automatic bit mul_in_ex();
    return (mon_cb.mult_en === 1'b1);
  endfunction

endinterface : alu_mul_if
