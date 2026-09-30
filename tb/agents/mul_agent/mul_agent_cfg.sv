// =============================================================================
// mul_agent_cfg.sv  (included inside mul_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   The configuration object (the "cfg") of the MUL agent. It holds the KNOBS
//   the agent uses at runtime: the virtual interface handle, safety limits and
//   verbosity. Following the architecture picture, the MUL agent is PASSIVE
//   (monitor only - no driver, no sequencer), so the cfg has no driver knobs:
//   the only stimulus is the instruction stream from the Instructions agent.
// =============================================================================
class mul_agent_cfg extends uvm_object;

  // ---- the handle to the interface -----------------------------------------
  // "virtual interface" = a runtime handle to our alu_mul_if instance.
  // Who fills it? Either the env/test directly, or the agent looks it up in
  // the UVM config db under key "alu_mul_vif" (published by alu_mul_bind.sv).
  virtual alu_mul_if vif;

  // ---- active or passive? ---------------------------------------------------
  // By architecture it is ALWAYS passive. We still keep this field so that if
  // someone sets it to UVM_ACTIVE in the env, the agent prints a clear error
  // instead of silently doing something weird.
  uvm_active_passive_enum is_active = UVM_PASSIVE;

  // ---- protocol sanity checks (each failed check = `uvm_error) --------------
  // Checks: illegal operator encoding for RV32IM, alu_en and mult_en at the
  // same time, operands changing while the op is in EX, mult_en dropping
  // before ex_valid, and a hang detector.
  bit check_protocol = 1;

  // ---- hang detector limit --------------------------------------------------
  // A MUL-unit instruction must leave EX within this many cycles. The
  // multiplier needs at most MULH_LATENCY (5) real cycles; anything extra is
  // an LSU/WB stall (Data agent wait states). Raise this if the Data agent is
  // configured with very long response delays.
  int unsigned max_cycles_in_ex = 64;

  // ---- tagging --------------------------------------------------------------
  // When 1, the monitor attaches pc/instr (from the ID issue pulse one cycle
  // earlier) to every transaction - the scoreboard prints them as a tag.
  bit tag_enable = 1;

  // ---- verbosity ------------------------------------------------------------
  // When 1, the monitor prints every completed transaction at UVM_HIGH level.
  bit verbose = 0;

  // ---- UVM field automation -------------------------------------------------
  // These macros register every field so UVM can do copy/print/compare for us.
  `uvm_object_utils_begin(mul_agent_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int (check_protocol,    UVM_ALL_ON)              // bit -> on/off
    `uvm_field_int (max_cycles_in_ex,  UVM_ALL_ON | UVM_DEC)    // print as decimal
    `uvm_field_int (tag_enable,        UVM_ALL_ON)
    `uvm_field_int (verbose,           UVM_ALL_ON)
  `uvm_object_utils_end

  // Standard constructor: call parent constructor, keep the instance name.
  function new(string name = "mul_agent_cfg");
    super.new(name);
  endfunction

endclass : mul_agent_cfg
