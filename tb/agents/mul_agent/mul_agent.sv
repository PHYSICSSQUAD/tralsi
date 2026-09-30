// =============================================================================
// mul_agent.sv  (part of mul_agent_pkg)
// -----------------------------------------------------------------------------
// MUL agent of tb_architecture/arch.jpg: passive, monitor only, connected to
// the shared ALU_MUL interface (alu_mul_if, bound into cv32e40p_core).
//
// Configuration lookup order:
//   1. cfg handle assigned by the env before build_phase
//   2. uvm_config_db#(mul_agent_cfg)  key "cfg"
//   3. default object; the virtual interface is then taken from
//      uvm_config_db#(virtual alu_mul_if) key "alu_mul_vif" (see alu_mul_bind.sv)
//
// Output: `ap` (uvm_analysis_port #(mul_txn)) - connect to the ALU_MUL
// Scoreboard and to the coverage_collector.
// =============================================================================
class mul_agent extends uvm_agent;
  `uvm_component_utils(mul_agent)

  mul_agent_cfg                cfg;
  mul_monitor                  mon;
  uvm_analysis_port #(mul_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (cfg == null) begin
      if (!uvm_config_db#(mul_agent_cfg)::get(this, "", "cfg", cfg)) begin
        cfg = mul_agent_cfg::type_id::create("cfg");
        `uvm_info("MUL_AGT", "no mul_agent_cfg provided - using defaults", UVM_MEDIUM)
      end
    end

    if (cfg.vif == null) begin
      if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", cfg.vif))
        `uvm_fatal("MUL_AGT", "virtual interface not found: set mul_agent_cfg.vif or uvm_config_db key \"alu_mul_vif\" (alu_mul_bind.sv publishes it)")
    end

    if (cfg.is_active != UVM_PASSIVE) begin
      `uvm_warning("MUL_AGT", "mul_agent is passive by architecture (monitor only); forcing UVM_PASSIVE")
      cfg.is_active = UVM_PASSIVE;
    end
    is_active = UVM_PASSIVE;

    ap  = new("ap", this);
    mon = mul_monitor::type_id::create("mon", this);
    mon.cfg = cfg;
    uvm_config_db#(mul_agent_cfg)::set(this, "mon", "cfg", cfg);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
  endfunction

endclass : mul_agent
