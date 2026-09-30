// =============================================================================
// mul_agent_pkg.sv
// -----------------------------------------------------------------------------
// MUL agent (passive) of the CV32E40P RV32IM testbench.
//
// Dependencies (compile before this file):
//   rtl/package/cv32e40p_pkg.sv     - mul_opcode_e (MUL_MAC32, MUL_H, ...)
//   tb/common/rv32m_ref_pkg.sv      - rv32m_op_e, reference functions
//   tb/interfaces/alu_mul_if.sv     - the shared ALU/MUL passive interface
//   uvm_pkg
// =============================================================================
package mul_agent_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::mul_opcode_e;
  import cv32e40p_pkg::MUL_MAC32;
  import cv32e40p_pkg::MUL_H;
  import rv32m_ref_pkg::*;

  // ---------------------------------------------------------------------------
  // Timing expectations of the multiplier unit (DUT-specific, therefore here
  // and not in the ISA-level rv32m_ref_pkg)
  //   databook, pipeline chapter: "MUL 1 cycle, MULH/MULHSU/MULHU 5 cycles"
  //   rtl/cv32e40p_mult.sv: FSM IDLE -> STEP0 -> STEP1 -> STEP2 -> FINISH,
  //   multicycle_o = 1 in STEP0..STEP2, ready_o = 1 only in IDLE / FINISH
  // ---------------------------------------------------------------------------
  localparam int unsigned MUL_LATENCY         = 1;  // cycles in EX, net of external stalls
  localparam int unsigned MULH_LATENCY        = 5;
  localparam int unsigned MULH_MULTICYCLE_LEN = 3;  // cycles with mult_multicycle == 1

  `include "mul_txn.sv"
  `include "mul_agent_cfg.sv"
  `include "mul_monitor.sv"
  `include "mul_agent.sv"

endpackage : mul_agent_pkg
