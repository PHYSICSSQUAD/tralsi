// =============================================================================
// alu_mul_sb_pkg.sv
// -----------------------------------------------------------------------------
// Package of the ALU_MUL Scoreboard. Kept separate from the agents so the env
// can import it directly (or the env package may `include the class instead).
//
// Compile after: uvm_pkg, cv32e40p_pkg, rv32m_ref_pkg, alu_ref_pkg, mul_agent_pkg,
//                alu_agent_pkg
// =============================================================================
package alu_mul_sb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
  import mul_agent_pkg::*;
  import alu_agent_pkg::*;

  `include "alu_mul_scoreboard.sv"

endpackage : alu_mul_sb_pkg
