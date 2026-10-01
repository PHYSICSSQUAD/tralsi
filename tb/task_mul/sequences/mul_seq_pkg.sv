// =============================================================================
// mul_seq_pkg.sv - MUL-directed stimulus for the V_Sequence layer
// Compile after uvm_pkg, rv32m_ref_pkg and mul_program_pkg
// (+incdir+tb/sequences).
// =============================================================================
package mul_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import rv32m_ref_pkg::*;
  import mul_program_pkg::*;

  `include "mul_program_seq.sv"
endpackage : mul_seq_pkg
