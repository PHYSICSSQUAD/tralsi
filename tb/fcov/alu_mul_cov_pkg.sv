// =============================================================================
// alu_mul_cov_pkg.sv
// -----------------------------------------------------------------------------
// Functional-coverage subscribers of the two EX units, instantiated inside the
// `coverage_collector` of the TB architecture:
//   mul_cov  <- MUL agent analysis port (mul_txn)
//   alu_cov  <- ALU agent analysis port (alu_txn)
//
// Compile after: uvm_pkg, cv32e40p_pkg, rv32m_ref_pkg, alu_ref_pkg,
//                mul_agent_pkg, alu_agent_pkg
//
// NOTE: this directory is called tb/fcov (not "coverage") on purpose - the
// Arena workspace snapshot drops directories named "coverage".
// =============================================================================
package alu_mul_cov_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
  import mul_agent_pkg::*;
  import alu_agent_pkg::*;

  `include "mul_cov.sv"
  `include "alu_cov.sv"

endpackage : alu_mul_cov_pkg
