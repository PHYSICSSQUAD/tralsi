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
  `uvm_component_utils(alu_agent)   // register with the UVM factory

  alu_agent_cfg                cfg;   // knobs of this agent
  alu_monitor                  mon;   // the passive watcher (only child)
  uvm_analysis_port #(alu_txn) ap;    // broadcasts every alu_txn outwards

  // Constructor: only call the parent constructor (UVM builds later).
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  // build_phase: CREATE objects (connections happen in connect_phase).
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);   // UVM bookkeeping first

    // Step 1: find the cfg (env handle -> config db -> fresh default object).
    if (cfg == null) begin
      if (!uvm_config_db#(alu_agent_cfg)::get(this, "", "cfg", cfg)) begin
        cfg = alu_agent_cfg::type_id::create("cfg");   // make a default one
        `uvm_info("ALU_AGT", "no alu_agent_cfg provided - using defaults", UVM_MEDIUM)
      end
    end

    // Step 2: we MUST have the virtual interface, or the monitor is blind.
    // Look in the config db under "alu_mul_vif" (published by alu_mul_bind.sv).
    // Not found -> `uvm_fatal = stop the simulation with a clear message.
    if (cfg.vif == null) begin
      if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", cfg.vif))
        `uvm_fatal("ALU_AGT", "virtual interface not found: set alu_agent_cfg.vif or uvm_config_db key \"alu_mul_vif\" (alu_mul_bind.sv publishes it)")
    end

    // Step 3: architecture says PASSIVE (monitor only). If somebody set the
    // cfg to active, warn and force passive - never drive the DUT here.
    if (cfg.is_active != UVM_PASSIVE) begin
      `uvm_warning("ALU_AGT", "alu_agent is passive by architecture (monitor only); forcing UVM_PASSIVE")
      cfg.is_active = UVM_PASSIVE;
    end
    is_active = UVM_PASSIVE;   // tell the UVM base class too

    // Step 4: create children and hand the cfg to the monitor.
    ap  = new("ap", this);                            // agent's output port
    mon = alu_monitor::type_id::create("mon", this);  // monitor via factory
    mon.cfg = cfg;                                    // direct handle...
    uvm_config_db#(alu_agent_cfg)::set(this, "mon", "cfg", cfg);  // ...+ config db
  endfunction

  // ---------------------------------------------------------------------------
  // connect_phase: wire the ports (objects already exist).
  // monitor's port -> agent's port -> env connects this to SB + coverage.
  // ---------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);   // every txn from the monitor leaves through `ap
  endfunction

endclass : alu_agent
