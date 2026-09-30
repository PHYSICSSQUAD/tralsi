// =============================================================================
// alu_agent_cfg.sv  (included inside alu_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   Configuration object (the "cfg" / knobs) of the ALU agent. Same shape as
//   mul_agent_cfg - both agents are PASSIVE and share the SAME virtual
//   alu_mul_if instance (interface #6 of the architecture picture).
// =============================================================================
class alu_agent_cfg extends uvm_object;

  // Handle to the shared interface. Filled by the env/test, or found in the
  // UVM config db under key "alu_mul_vif" (published by alu_mul_bind.sv).
  virtual alu_mul_if vif;

  // The agent is passive by architecture (monitor only). Anything else set
  // in the env is forced back to UVM_PASSIVE with a warning.
  uvm_active_passive_enum is_active = UVM_PASSIVE;

  // Turn ON/OFF the protocol sanity checks inside the monitor (each failure
  // = `uvm_error). The same rules also exist in alu_sva for waveform debug.
  bit check_protocol = 1;

  // Hang guard: a transaction staying in EX longer than this = error.
  // The divider needs at most DIV_LATENCY_MAX (35) real cycles; the rest of
  // the budget covers external stalls (LSU/WB OBI wait states).
  int unsigned max_cycles_in_ex = 128;

  // The ALU monitor NEEDS the issue tag (pc/instr from the ID stage) to tell
  // PIPELINE BUBBLES (alu_en=1, ALU_SLTU, we=0, no real instruction) apart
  // from real instructions. If tag_enable=0 the monitor falls back to the
  // weaker bubble-signature pattern matching (less reliable).
  bit tag_enable = 1;

  // When 1: print per-transaction lines and bubble/extra statistics at
  // UVM_HIGH verbosity.
  bit verbose = 0;

  // UVM field automation: register every field for print/copy/compare.
  // UVM_ALL_ON = use in all ops; UVM_DEC = print numbers in decimal.
  `uvm_object_utils_begin(alu_agent_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int (check_protocol,    UVM_ALL_ON)
    `uvm_field_int (max_cycles_in_ex,  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (tag_enable,        UVM_ALL_ON)
    `uvm_field_int (verbose,           UVM_ALL_ON)
  `uvm_object_utils_end

  // Standard constructor: call the parent with the instance name.
  function new(string name = "alu_agent_cfg");
    super.new(name);
  endfunction

endclass : alu_agent_cfg
