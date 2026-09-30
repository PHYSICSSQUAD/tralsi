// =============================================================================
// mul_agent_pkg.sv
// =============================================================================
// WHAT THIS FILE IS:
//   A package = a container that groups classes/params so other files can
//   import them. This one groups the whole MUL agent (transaction, config,
//   monitor, agent). It is compiled AFTER its dependencies (listed below).
//
// Dependencies (must be compiled BEFORE this file):
//   rtl/package/cv32e40p_pkg.sv  -> gives us the enum mul_opcode_e (MUL_MAC32, MUL_H)
//   tb/common/rv32m_ref_pkg.sv   -> gives us rv32m_op_e + reference functions
//   tb/interfaces/alu_mul_if.sv  -> the shared ALU_MUL interface (the 1 of 6)
//   uvm_pkg                      -> all UVM base classes
// =============================================================================
package mul_agent_pkg;

  import uvm_pkg::*;                    // bring in all UVM classes (uvm_agent...)
  `include "uvm_macros.svh"             // bring in `uvm_info / `uvm_error macros

  // Import ONLY the enum type and the 2 values we need from the RTL package.
  import cv32e40p_pkg::mul_opcode_e;    // the type of mult_operator
  import cv32e40p_pkg::MUL_MAC32;       // value meaning "plain MUL"
  import cv32e40p_pkg::MUL_H;           // value meaning "MULH/MULHSU/MULHU"
  import rv32m_ref_pkg::*;              // ISA reference (rv32m_ref function...)

  // ---------------------------------------------------------------------------
  // TIMING EXPECTATIONS of the multiplier unit (DUT-specific numbers).
  // Source: databook pipeline chapter says "MUL 1 cycle, MULH* 5 cycles";
  // rtl/cv32e40p_mult.sv FSM = IDLE -> STEP0 -> STEP1 -> STEP2 -> FINISH,
  // multicycle_o=1 in STEP0..2, ready_o=1 only in IDLE and FINISH.
  // These live HERE (agent package) and not in rv32m_ref_pkg because they are
  // properties of THIS RTL, not of the RISC-V ISA.
  // ---------------------------------------------------------------------------
  localparam int unsigned MUL_LATENCY         = 1;  // EX cycles for MUL (net of stalls)
  localparam int unsigned MULH_LATENCY        = 5;  // EX cycles for MULH*
  localparam int unsigned MULH_MULTICYCLE_LEN = 3;  // cycles mult_multicycle stays 1

  // The 4 class files are textually included INSIDE the package (so they see
  // the imports above without importing anything themselves).
  `include "mul_txn.sv"        // the transaction item (data object)
  `include "mul_agent_cfg.sv"  // configuration object (knobs)
  `include "mul_monitor.sv"    // the passive watcher (the brain of the agent)
  `include "mul_agent.sv"      // the agent itself (builds + connects monitor)

endpackage : mul_agent_pkg
