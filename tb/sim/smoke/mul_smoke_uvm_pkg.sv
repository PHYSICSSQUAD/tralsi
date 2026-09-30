// =============================================================================
// mul_smoke_uvm_pkg.sv
// -----------------------------------------------------------------------------
// Minimal UVM environment used by tb_smoke (compiled with -DSMOKE_UVM) to run
// the REAL multiplier verification classes on the real RTL:
//   mul_agent (passive) --ap--> alu_mul_scoreboard.mul_imp
//                       --ap--> mul_cov.analysis_export
//   alu_agent (passive) --ap--> alu_mul_scoreboard.alu_imp
//                       --ap--> alu_cov.analysis_export
// The virtual interface is obtained the way the team environment will get it:
// from the config_db key "alu_mul_vif", set by the registrar in alu_mul_bind.sv.
// End of test: the top triggers the global uvm_event "smoke_done".
// =============================================================================
package mul_smoke_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
  import mul_agent_pkg::*;
  import alu_agent_pkg::*;
  import alu_mul_sb_pkg::*;
  import alu_mul_cov_pkg::*;

  class mul_smoke_env extends uvm_env;
    `uvm_component_utils(mul_smoke_env)
    mul_agent          m_mul_agent;
    alu_agent          m_alu_agent;
    alu_mul_scoreboard m_sb;
    mul_cov            m_cov;
    alu_cov            m_alu_cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_mul_agent = mul_agent::type_id::create("m_mul_agent", this);
      m_alu_agent = alu_agent::type_id::create("m_alu_agent", this);
      m_sb        = alu_mul_scoreboard::type_id::create("m_sb", this);
      m_cov       = mul_cov::type_id::create("m_cov", this);
      m_alu_cov   = alu_cov::type_id::create("m_alu_cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      m_mul_agent.ap.connect(m_sb.mul_imp);
      m_mul_agent.ap.connect(m_cov.analysis_export);
      m_alu_agent.ap.connect(m_sb.alu_imp);
      m_alu_agent.ap.connect(m_alu_cov.analysis_export);
    endfunction
  endclass : mul_smoke_env

  class mul_smoke_test extends uvm_test;
    `uvm_component_utils(mul_smoke_test)
    mul_smoke_env m_env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_env = mul_smoke_env::type_id::create("m_env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      uvm_event #(uvm_object) done_ev;
      phase.raise_objection(this, "smoke program running");
      done_ev = uvm_event_pool::get_global("smoke_done");
      done_ev.wait_on();
      #10ns;
      phase.drop_objection(this, "smoke program finished");
    endtask

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("SMOKE", $sformatf("UVM stack summary: MUL monitor txns=%0d scoreboard txns=%0d errors=%0d killed=%0d coverage samples=%0d | ALU monitor txns=%0d bubbles=%0d scoreboard txns=%0d errors=%0d killed=%0d coverage samples=%0d",
                                   m_env.m_mul_agent.mon.n_txn, m_env.m_sb.n_mul_txn, m_env.m_sb.n_mul_err,
                                   m_env.m_sb.n_mul_killed, m_env.m_cov.n_sampled,
                                   m_env.m_alu_agent.mon.n_txn, m_env.m_alu_agent.mon.n_bubbles, m_env.m_sb.n_alu_txn, m_env.m_sb.n_alu_err,
                                   m_env.m_sb.n_alu_killed, m_env.m_alu_cov.n_sampled), UVM_LOW)
      if (m_env.m_sb.n_mul_err != 0 || m_env.m_sb.n_alu_err != 0)
        `uvm_error("SMOKE", "scoreboard reported errors")
      if (m_env.m_sb.n_mul_txn == 0)
        `uvm_error("SMOKE", "scoreboard saw no MUL transactions - agent/interface plumbing broken")
      if (m_env.m_sb.n_alu_txn == 0)
        `uvm_error("SMOKE", "scoreboard saw no ALU transactions - agent/interface plumbing broken")
    endfunction
  endclass : mul_smoke_test
endpackage : mul_smoke_uvm_pkg
