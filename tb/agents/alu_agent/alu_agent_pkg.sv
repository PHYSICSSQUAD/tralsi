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

  import uvm_pkg::*;               // all UVM base classes
  `include "uvm_macros.svh"        // `uvm_info / `uvm_error macros

  import cv32e40p_pkg::*;          // alu_opcode_e + literals (ALU_ADD, ALU_DIV...)
  import rv32m_ref_pkg::*;         // div/rem golden-model functions
  import alu_ref_pkg::*;           // alu_ref, div_latency_ref, alu_expect_of_instr

  // Class files textually included INSIDE the package, in dependency order
  // (each file sees all imports above without importing anything itself):
  `include "alu_txn.sv"            // data object (one ALU instruction in EX)
  `include "alu_agent_cfg.sv"      // configuration knobs
  `include "alu_monitor.sv"        // the passive watcher (the brain)
  `include "alu_agent.sv"          // the agent (builds + connects the monitor)

endpackage : alu_agent_pkg
