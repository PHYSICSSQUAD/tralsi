// =============================================================================
// mul_demo_pkg.sv   (part of the runnable MUL environment — tb/task_mul_env/)
// -----------------------------------------------------------------------------
// The smallest UVM environment that exercises ONLY the MUL task deliverable
// from tb/task_mul/ (its exact files, not copies):
//
//   mul_agent (passive) --ap--> mul_scoreboard.mul_imp   (task_mul/env/)
//                       --ap--> mul_cov.analysis_export  (task_mul/fcov/)
//
// The virtual interface comes from the SAME config_db key the team env will
// use ("alu_mul_vif"); end of test = the global uvm_event "smoke_done"
// triggered by the top — both contracts identical to the integrated bench.
//
// Compile after: uvm_pkg, cv32e40p_pkg, rv32m_ref_pkg, mul_program_pkg,
//                alu_mul_if, mul_agent_pkg, mul_scoreboard_pkg, mul_cov_pkg
// =============================================================================
package mul_demo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import rv32m_ref_pkg::*;
  import mul_agent_pkg::*;
  import mul_scoreboard_pkg::*;
  import mul_cov_pkg::*;

  class mul_demo_env extends uvm_env;
    `uvm_component_utils(mul_demo_env)
    mul_agent       m_mul_agent;
    mul_scoreboard  m_sb;
    mul_cov         m_cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_mul_agent = mul_agent::type_id::create("m_mul_agent", this);
      m_sb        = mul_scoreboard::type_id::create("m_sb", this);
      m_cov       = mul_cov::type_id::create("m_cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      m_mul_agent.ap.connect(m_sb.mul_imp);
      m_mul_agent.ap.connect(m_cov.analysis_export);
    endfunction
  endclass : mul_demo_env

  class mul_demo_test extends uvm_test;
    `uvm_component_utils(mul_demo_test)
    mul_demo_env m_env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_env = mul_demo_env::type_id::create("m_env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      uvm_event #(uvm_object) done_ev;
      phase.raise_objection(this, "MUL demo program running");
      done_ev = uvm_event_pool::get_global("smoke_done");
      done_ev.wait_on();
      #10ns;
      phase.drop_objection(this, "MUL demo program finished");
    endtask

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("TASK_MUL", $sformatf("TASK_MUL SUMMARY: monitor txns=%0d scoreboard txns=%0d errors=%0d killed=%0d coverage samples=%0d",
                                      m_env.m_mul_agent.mon.n_txn, m_env.m_sb.n_mul_txn,
                                      m_env.m_sb.n_mul_err, m_env.m_sb.n_mul_killed,
                                      m_env.m_cov.n_sampled), UVM_LOW)
      if (m_env.m_sb.n_mul_err != 0)
        `uvm_error("TASK_MUL", "scoreboard reported errors")
      if (m_env.m_sb.n_mul_txn == 0)
        `uvm_error("TASK_MUL", "scoreboard saw no MUL transactions - agent/interface plumbing broken")
    endfunction
  endclass : mul_demo_test
endpackage : mul_demo_pkg
