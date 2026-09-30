// =============================================================================
// alu_agent.sv  (part of alu_agent_pkg)
// -----------------------------------------------------------------------------
// Passive ALU agent (TB architecture: "ALU agent", monitor only). Shares the
// alu_mul_if instance with the MUL agent; both are bound into cv32e40p_core by
// tb/interfaces/alu_mul_bind.sv which publishes the virtual interface under
// the uvm_config_db key "alu_mul_vif".
//
// Env hook-up:
//   m_alu_agent = alu_agent::type_id::create("m_alu_agent", this);
//   m_alu_agent.ap.connect(m_alu_mul_sb.alu_imp);
//   m_alu_agent.ap.connect(m_coverage_collector.m_alu_cov.analysis_export);
// =============================================================================
class alu_agent extends uvm_agent;
  `uvm_component_utils(alu_agent)

  alu_agent_cfg                cfg;
  alu_monitor                  mon;
  uvm_analysis_port #(alu_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (cfg == null) begin
      if (!uvm_config_db#(alu_agent_cfg)::get(this, "", "cfg", cfg)) begin
        cfg = alu_agent_cfg::type_id::create("cfg");
        `uvm_info("ALU_AGT", "no alu_agent_cfg provided - using defaults", UVM_MEDIUM)
      end
    end

    if (cfg.vif == null) begin
      if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", cfg.vif))
        `uvm_fatal("ALU_AGT", "virtual interface not found: set alu_agent_cfg.vif or uvm_config_db key \"alu_mul_vif\" (alu_mul_bind.sv publishes it)")
    end

    if (cfg.is_active != UVM_PASSIVE) begin
      `uvm_warning("ALU_AGT", "alu_agent is passive by architecture (monitor only); forcing UVM_PASSIVE")
      cfg.is_active = UVM_PASSIVE;
    end
    is_active = UVM_PASSIVE;

    ap  = new("ap", this);
    mon = alu_monitor::type_id::create("mon", this);
    mon.cfg = cfg;
    uvm_config_db#(alu_agent_cfg)::set(this, "mon", "cfg", cfg);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
  endfunction

endclass : alu_agent
