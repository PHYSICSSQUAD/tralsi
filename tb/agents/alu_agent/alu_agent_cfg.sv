// =============================================================================
// alu_agent_cfg.sv  (part of alu_agent_pkg)
// -----------------------------------------------------------------------------
// Configuration object of the (passive) ALU agent. Same shape as
// mul_agent_cfg; both agents share the same virtual alu_mul_if instance.
// =============================================================================
class alu_agent_cfg extends uvm_object;

  // shared passive interface (alu_mul_bind.sv publishes it as "alu_mul_vif")
  virtual alu_mul_if vif;

  // the agent is passive by architecture; anything else is forced back
  uvm_active_passive_enum is_active = UVM_PASSIVE;

  // protocol checks inside the monitor (duplicated in alu_sva for waveform debug)
  bit check_protocol = 1;

  // hang guard: the divider needs at most DIV_LATENCY_MAX (35) cycles, plus the
  // external stalls of the LSU/WB (OBI wait states)
  int unsigned max_cycles_in_ex = 128;

  // the ALU monitor NEEDS the issue tag to tell pipeline bubbles (alu_en=1,
  // ALU_SLTU, we=0, no instruction) from real instructions; with tag_enable=0
  // the bubble pattern itself is used as the discriminator (weaker)
  bit tag_enable = 1;

  // count / report bubbles and per-class statistics at UVM_HIGH
  bit verbose = 0;

  `uvm_object_utils_begin(alu_agent_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int (check_protocol,    UVM_ALL_ON)
    `uvm_field_int (max_cycles_in_ex,  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (tag_enable,        UVM_ALL_ON)
    `uvm_field_int (verbose,           UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "alu_agent_cfg");
    super.new(name);
  endfunction

endclass : alu_agent_cfg
