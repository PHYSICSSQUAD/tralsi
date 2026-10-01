// =============================================================================
// alu_mul_if.sv
// =============================================================================
// WHAT THIS FILE IS:
//   This file defines ONE SystemVerilog interface called "alu_mul_if".
//   In the architecture picture (tb_architecture/arch.jpg) the Env talks to
//   the DUT through 6 interfaces:
//
//     1. Instruction interface   -> Instructions agent (active)
//     2. Data interface          -> Data agent (reactive)
//     3. Interrupt_Debug interface -> Interrupt_Debug agent (active)
//     4. Reset interface         -> Reset agent (active)
//     5. Reg_file interface      -> reg_file agent (passive)
//     6. ALU_MUL interface       -> MUL agent + ALU agent (both passive)
//                                    *** THIS IS #6 - WE BUILD ONLY THIS ONE ***
//
//   So this interface is 1 out of 6. Everything else in the picture
//   (Instruction / Data / ... interfaces) belongs to other people's work.
//   BOTH the MUL agent and the ALU agent read from THIS same interface.
//
// HOW IT IS CONNECTED (white-box / passive):
//   Every port below is an INPUT. The signals are hooked to the DUT by the
//   bind statement in alu_mul_bind.sv. Nothing in this file can drive the
//   DUT, so this probe can never change DUT behaviour. Both agents are
//   UVM_PASSIVE: they only watch (monitor), they never drive pins.
//
// SIGNAL TABLE  (all sources are inside cv32e40p_top.core_i, RV32IM config:
//                FPU=0, ZFINX=0, COREV_PULP=0, COREV_CLUSTER=0)
//
//   group     | signal              | DUT source (file)          | what it does
//   ----------+---------------------+----------------------------+-------------
//   handshake | ex_ready            | ex_ready (cv32e40p_ex_stage)| EX stage can accept a NEW op this cycle
//   handshake | ex_valid            | ex_valid (cv32e40p_ex_stage)| result of current op is VALID this cycle
//   handshake | lsu_ready_ex        | lsu_ready_ex (core)         | 0 = LSU holds EX (load/store in flight)
//   handshake | wb_ready            | wb_ready_wb (core)          | 0 = write-back stage holds EX
//   handshake | branch_in_ex        | branch_in_ex (core)         | 1 = current EX op is a branch/jump
//   handshake | lsu_en              | data_req_ex (core)          | 1 = ALU computes a load/store ADDRESS
//   handshake | data_misaligned_ex  | data_misaligned_ex (core)   | 1 = 2nd half of misaligned ld/st (addr+4)
//   ALU       | alu_en              | alu_en_ex (ID/EX reg)       | 1 = ALU unit is doing some work
//   ALU       | alu_operator        | alu_operator_ex (ID/EX reg) | which ALU op (ADD, SLT, DIV, ... enum)
//   ALU       | alu_operand_a/b/c   | alu_operand_a/b/c_ex        | 32-bit inputs a, b, c to the ALU
//   ALU       | alu_result          | ex_stage_i.alu_result       | ALU output (arith/logic/shift/div result)
//   ALU       | alu_cmp_result      | ex_stage_i.alu_cmp_result   | comparator output = branch decision
//   ALU       | alu_ready           | ex_stage_i.alu_ready        | 0 while divider is running (blocks EX)
//   MUL       | mult_en             | mult_en_ex (ID/EX reg)      | 1 = multiplier unit is doing work
//   MUL       | mult_operator       | mult_operator_ex            | MUL_MAC32 (=MUL) or MUL_H (=MULH*)
//   MUL       | mult_signed_mode    | mult_signed_mode_ex         | 11 both signed, 01 a signed, 00 none
//   MUL       | mult_operand_a/b/c  | mult_operand_a/b/c_ex       | inputs; c = accumulator for MULH
//   MUL       | mult_sel_subword    | mult_sel_subword_ex         | PULP subword mul - must be 0 for us
//   MUL       | mult_imm            | mult_imm_ex                 | PULP immediate  - must be 0 for us
//   MUL       | mult_result         | ex_stage_i.mult_result      | multiplier output
//   MUL       | mult_ready          | ex_stage_i.mult_ready       | 0 during MULH FSM middle cycles
//   MUL       | mult_multicycle     | mult_multicycle             | 1 in MULH STEP0..2 (tells ID to hold c)
//   MUL       | mulh_active         | ex_stage_i.mulh_active      | 1 while MULH FSM is not IDLE
//   RF write  | rf_alu_we           | regfile_alu_we_fw (core)    | write enable of RF port b (per cycle!)
//   RF write  | rf_alu_waddr        | regfile_alu_waddr_fw        | destination register x0..x31 (bit5=FP)
//   RF write  | rf_alu_wdata        | regfile_alu_wdata_fw        | value written to the register file
//   tag       | id_valid            | id_valid (core)             | ID stage holds a valid instruction
//   tag       | is_decoding         | is_decoding (core)          | instruction not killed (ctrl FSM OK)
//   tag       | pc_id               | pc_id (core)                | PC of instruction in ID (for messages)
//   tag       | instr_id            | instr_rdata_id (core)       | 32-bit instruction word in ID
//
// TIMING REFERENCE (notes/mul_plan.md section 0.2):
//   MUL   : 1 cycle in EX (mult_ready=1, ex_valid in same cycle unless stalled)
//   MULH* : 5 cycles in EX (IDLE, STEP0, STEP1, STEP2, FINISH), ex_valid in FINISH only
// =============================================================================
interface alu_mul_if
  import cv32e40p_pkg::*;   // bring in alu_opcode_e, mul_opcode_e enum types
(
  // --- clock and reset (1 clock for the whole SoC) --------------------------
  input logic clk,          // free-running clock of the core
  input logic rst_n,        // active-LOW reset; 0 = core is being reset

  // --- EX stage handshake ---------------------------------------------------
  // "handshake" = the standard valid/ready pair that says when data moves.
  input logic ex_ready,          // EX stage is FREE: it can accept a new operation
  input logic ex_valid,          // EX stage has a FINISHED result in this cycle
  input logic lsu_ready_ex,      // 0 = load/store unit is holding EX busy
  input logic wb_ready,          // 0 = write-back stage is holding EX busy
  input logic branch_in_ex,      // 1 = the op now in EX is a branch/jump decision
  input logic lsu_en,            // = data_req_ex: 1 = ALU output is an address for ld/st
  input logic data_misaligned_ex,// 1 = 2nd pass of a misaligned ld/st (ALU gets addr+4)

  // --- ALU group (everything about the integer ALU + divider) ---------------
  input logic        alu_en,          // 1 = ALU unit is active this cycle
  input alu_opcode_e alu_operator,    // which ALU op the decoder chose (enum)
  input logic [31:0] alu_operand_a,   // ALU input A (for DIV: this is the divisor/rs2)
  input logic [31:0] alu_operand_b,   // ALU input B (for DIV: this is the dividend/rs1)
  input logic [31:0] alu_operand_c,   // ALU input C (used by some PULP ops; RV32IM: unused)
  input logic [31:0] alu_result,      // ALU output value (arith/logic/shift/div)
  input logic        alu_cmp_result,  // comparator output (0/1) = branch taken/not-taken
  input logic        alu_ready,       // 0 while divider is busy -> EX is blocked

  // --- MUL group (everything about the multiplier) --------------------------
  input logic        mult_en,          // 1 = multiplier unit is active this cycle
  input mul_opcode_e mult_operator,    // MUL_MAC32 => MUL, MUL_H => MULH/MULHSU/MULHU
  input logic [ 1:0] mult_signed_mode, // which operands are signed (see table above)
  input logic [31:0] mult_operand_a,   // multiplier input A (= architectural rs1)
  input logic [31:0] mult_operand_b,   // multiplier input B (= architectural rs2)
  input logic [31:0] mult_operand_c,   // accumulator input for MULH (0 in our config)
  input logic        mult_sel_subword, // PULP feature - must stay 0 for RV32IM
  input logic [ 4:0] mult_imm,         // PULP feature - must stay 0 for RV32IM
  input logic [31:0] mult_result,      // multiplier output value
  input logic        mult_ready,       // 0 in middle cycles of MULH FSM
  input logic        mult_multicycle,  // 1 in MULH STEP0..2 -> ID must keep op_c
  input logic        mulh_active,      // 1 while MULH FSM is busy (not IDLE)

  // --- register-file ALU write port (port b) + forwarding value ------------
  input logic        rf_alu_we,    // write enable: 1 in EVERY EX cycle (qualify w/ ex_valid!)
  input logic [ 5:0] rf_alu_waddr, // destination register address (bit5 = FP reg, = 0 here)
  input logic [31:0] rf_alu_wdata, // value written to register file (also EX->ID forward)

  // --- tag: instruction issue pulse from the decode stage ------------------
  input logic        id_valid,     // ID stage holds a valid instruction
  input logic        is_decoding,  // instruction is NOT killed by the controller FSM
  input logic [31:0] pc_id,        // PC of the instruction currently in ID
  input logic [31:0] instr_id      // the 32-bit instruction word currently in ID
);

  // -----------------------------------------------------------------------------
  // Clocking block: defines HOW and WHEN the monitor samples the signals.
  // "input #1step" = sample 1 time-step BEFORE the active clock edge, so the
  // monitor sees exactly the values the DUT held during the cycle that is
  // ENDING at this edge (the stable, race-free values).
  // -----------------------------------------------------------------------------
  clocking mon_cb @(posedge clk);
    default input #1step output #0;   // sample before edge, drive never (passive)
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

  // modport = the "view" the monitor gets: it may read the clocking block,
  // the clock and the reset. No output direction -> monitor cannot drive.
  modport MON (clocking mon_cb, input clk, input rst_n);

  // -----------------------------------------------------------------------------
  // Helper function: "issue pulse".
  // TRUE when the instruction that sits in the decode stage RIGHT NOW will
  // really move to the EX stage at the next clock edge.
  // Condition = id_valid && is_decoding (both must be 1; a killed instruction
  // has id_valid=1 but is_decoding=0).
  // -----------------------------------------------------------------------------
  function automatic bit issue_pulse();
    return (mon_cb.id_valid === 1'b1) && (mon_cb.is_decoding === 1'b1);
  endfunction

  // -----------------------------------------------------------------------------
  // Helper function: "mul_in_ex".
  // TRUE when the multiplier unit is active in the CURRENT cycle.
  // The ID/EX pipeline register clears mult_en whenever EX is free and ID has
  // nothing, so after an ex_valid the next cycle with mult_en=1 always belongs
  // to a NEW instruction - this is how the monitor starts a new transaction.
  // -----------------------------------------------------------------------------
  function automatic bit mul_in_ex();
    return (mon_cb.mult_en === 1'b1);
  endfunction

endinterface : alu_mul_if
