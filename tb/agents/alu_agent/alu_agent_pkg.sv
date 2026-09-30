// =============================================================================
// alu_agent_pkg.sv
// -----------------------------------------------------------------------------
// ALU agent (passive) of the CV32E40P RV32IM testbench - twin of mul_agent_pkg
// for the ALU / divider path (RV32I ALU ops, branches, LUI/AUIPC, JAL/JALR
// link, load/store address, DIV/DIVU/REM/REMU).
//
// Dependencies (compile before this file):
//   rtl/package/cv32e40p_pkg.sv     - alu_opcode_e
//   tb/common/rv32m_ref_pkg.sv      - div/rem reference functions
//   tb/common/alu_ref_pkg.sv        - alu_ref, div_latency_ref, alu_expect_of_instr
//   tb/interfaces/alu_mul_if.sv     - the shared ALU/MUL passive interface
//   uvm_pkg
// =============================================================================
package alu_agent_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;

  `include "alu_txn.sv"
  `include "alu_agent_cfg.sv"
  `include "alu_monitor.sv"
  `include "alu_agent.sv"

endpackage : alu_agent_pkg
