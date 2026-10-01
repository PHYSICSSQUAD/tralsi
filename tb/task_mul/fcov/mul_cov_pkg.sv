// =============================================================================
// mul_cov_pkg.sv   (part of the MUL task deliverable — tb/task_mul/)
// -----------------------------------------------------------------------------
// MUL-only functional-coverage package: wraps mul_cov.sv (the 6 MUL
// covergroups) without the ALU coverage classes, so the MUL task can compile
// stand-alone. The integrated environment keeps using tb/fcov/alu_mul_cov_pkg.
//
// Compile after: uvm_pkg, cv32e40p_pkg, rv32m_ref_pkg, mul_agent_pkg
// =============================================================================
package mul_cov_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import mul_agent_pkg::*;

  `include "mul_cov.sv"

endpackage : mul_cov_pkg
