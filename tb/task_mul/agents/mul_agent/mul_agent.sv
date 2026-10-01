// =============================================================================
// mul_agent.sv  (included inside mul_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   The MUL agent itself. In the architecture picture (arch.jpg) the
//   "MUL agent (passive)" box = a Monitor + a cfg tag + a virtual interface
//   - NO driver, NO sequencer (passive agents only observe).
//   The agent's job: build the monitor, give it the cfg, and expose an
//   analysis port `ap` that broadcasts every mul_txn to the scoreboard and
//   the coverage collector.
//
// Config lookup order (how the agent finds its cfg and interface):
//   1. cfg handle assigned by the env directly (before build_phase)
//   2. uvm_config_db#(mul_agent_cfg) key "cfg"
//   3. create a default cfg; then get the virtual interface from
//      uvm_config_db#(virtual alu_mul_if) key "alu_mul_vif"
//      (published once at time 0 by alu_mul_bind.sv's registrar)
//
// 📖 بالعربي (Arabic): الاجينت = **صندوق توصيل** بس، مش بيسوق حاجة:
//   - هو اللي بيبني المونيتور ويديه الـ cfg والـ vif (لو مفيش → fatal).
//   - الـ ap بتاعه = مخرج واحد بيتباع ليهم اتنين: السكور بورد والكفر
//     (نفس بورت الـ analysis ينفع يتصل لأكتر من واحد → كده الكل بيشوف
//      نفس الـ txn مرة واحدة).
//   - مفيش driver/sequencer عشان اتفاقنا: الاجينتات passive كلها (وال instruction
//     agent هو الوحيد active في البيئة الكبيرة — مش جوّه التاسك ده).
//   - ترتيب find الـ cfg: handle مباشر من الـ env ← config_db "cfg" ←
//     default object + الـ vif من "alu_mul_vif".
// =============================================================================
class mul_agent extends uvm_agent;
  `uvm_component_utils(mul_agent)   // register this class with the UVM factory

  mul_agent_cfg                cfg;   // this agent's configuration object
  mul_monitor                  mon;   // the passive watcher (the only child)
  uvm_analysis_port #(mul_txn) ap;    // broadcast port: one txn -> many readers

  // Constructor: only call the parent constructor (UVM builds the rest later).
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  // build_phase: CREATE objects here (never connect them - that is connect_phase)
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);   // let UVM do its own bookkeeping first

    // Step 1: find the cfg (env handle -> config db -> fresh default object).
    if (cfg == null) begin
      if (!uvm_config_db#(mul_agent_cfg)::get(this, "", "cfg", cfg)) begin
        cfg = mul_agent_cfg::type_id::create("cfg");   // make a default one
        `uvm_info("MUL_AGT", "no mul_agent_cfg provided - using defaults", UVM_MEDIUM)
      end
    end

    // Step 2: the cfg must have a virtual interface, or the monitor cannot
    // see any DUT signal. Look in the config db under "alu_mul_vif";
    // if not found -> `uvm_fatal = stop the simulation immediately.
    if (cfg.vif == null) begin
      if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", cfg.vif))
        `uvm_fatal("MUL_AGT", "virtual interface not found: set mul_agent_cfg.vif or uvm_config_db key \"alu_mul_vif\" (alu_mul_bind.sv publishes it)")
    end

    // Step 3: architecture says PASSIVE. If somebody configured us active,
    // warn loudly and force passive instead of silently driving the DUT.
    if (cfg.is_active != UVM_PASSIVE) begin
      `uvm_warning("MUL_AGT", "mul_agent is passive by architecture (monitor only); forcing UVM_PASSIVE")
      cfg.is_active = UVM_PASSIVE;
    end
    is_active = UVM_PASSIVE;   // tell the UVM base class as well

    // Step 4: create our children and wire the data path.
    ap  = new("ap", this);                              // analysis port of the agent
    mon = mul_monitor::type_id::create("mon", this);    // monitor via factory
    mon.cfg = cfg;                                      // give monitor the cfg handle
    uvm_config_db#(mul_agent_cfg)::set(this, "mon", "cfg", cfg);  // and publish it too
  endfunction

  // ---------------------------------------------------------------------------
  // connect_phase: wire the ports together (objects already exist).
  // Monitor's port -> agent's port -> (env connects this ap to SB + coverage).
  // ---------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);   // every txn the monitor publishes goes out of the agent
  endfunction

endclass : mul_agent
