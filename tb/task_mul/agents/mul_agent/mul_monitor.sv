// =============================================================================
// mul_monitor.sv  (included inside mul_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   The BRAIN of the MUL agent. It is a passive watcher: every clock edge it
//   reads the shared ALU_MUL interface (alu_mul_if) and rebuilds one mul_txn
//   per MUL/MULH/MULHSU/MULHU instruction that runs in the EX stage, then
//   publishes it on `ap` in the cycle the instruction completes (ex_valid).
//
// THE CYCLE MODEL IT IMPLEMENTS (notes/mul_plan.md section 0.2):
//   start    : first cycle with mult_en==1 while nothing is in flight.
//              (The ID/EX register clears mult_en<=0 whenever EX is ready and
//              ID has nothing valid, so after a completion the next cycle
//              with mult_en==1 is always a NEW instruction.)
//   progress : total_cycles++ every cycle while in EX
//              stall_cycles++ when mult_ready && !ex_valid  (multiplier is
//              done but EX is held by LSU/WB = data-side wait state)
//              multicycle_len++ when mult_multicycle==1 (MULH STEP0..STEP2)
//   complete : ex_valid==1 -> capture result + write port, publish the txn
//   reset    : rst_n==0 while in flight -> publish with killed_by_reset=1
//
//   NOTE: nothing in EX is ever killed in this configuration (a taken branch
//   flushes IF/ID only, illegal-instruction flush waits for ex_valid, no IRQ/
//   debug), so every started instruction completes unless RESET intervenes.
//
// TAG RULE: the "issue pulse" (id_valid && is_decoding) in cycle N means the
//   instruction in ID will be in EX during cycle N+1. So the pulse seen in
//   the CURRENT cycle belongs to the NEXT instruction - therefore the tag is
//   attached to a transaction BEFORE we record this cycle's pulse.
// =============================================================================
class mul_monitor extends uvm_monitor;
  `uvm_component_utils(mul_monitor)   // register with the UVM factory

  mul_agent_cfg               cfg;    // knobs (set by the agent)
  uvm_analysis_port #(mul_txn) ap;    // output port: publishes every txn

  // ---- statistics (printed at the end of simulation in report_phase) -------
  int unsigned n_txn;            // total transactions published
  int unsigned n_mul;            // how many were plain MUL
  int unsigned n_mulh;           // how many were MULH/MULHSU/MULHU
  int unsigned n_killed;         // how many died by reset
  int unsigned max_stall_seen;   // biggest external stall recorded

  // ---- internal state (protected = private to this class) -----------------
  protected virtual alu_mul_if vif;     // shortcut to the interface handle
  protected mul_txn            cur;     // the transaction being built now
  protected bit                in_flight;      // 1 = we are inside an instruction
  protected bit                tag_valid;      // 1 = tag_pc/tag_instr are good
  protected bit [31:0]         tag_pc;         // PC of last issued instruction
  protected bit [31:0]         tag_instr;      // word of last issued instruction
  protected int unsigned       cycle_cnt;      // free-running cycle counter
                                               // (NOT cleared by reset, so
                                               // cycle_end-start stays correct)

  // Constructor: call parent, then create the output port.
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // ---------------------------------------------------------------------------
  // build_phase: get the cfg and the interface handle. Both are REQUIRED -
  // missing cfg or vif = `uvm_fatal (simulation stops with a clear message).
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin      // agent may have set cfg directly...
      if (!uvm_config_db#(mul_agent_cfg)::get(this, "", "cfg", cfg))  // ...else config db
        `uvm_fatal("MUL_MON", "no mul_agent_cfg (field 'cfg' not set and not in config_db)")
    end
    if (cfg.vif == null)        // without an interface we cannot see anything
      `uvm_fatal("MUL_MON", "mul_agent_cfg.vif is null")
    vif = cfg.vif;              // local shortcut used everywhere below
  endfunction

  // ---------------------------------------------------------------------------
  // run_phase: the endless sampling loop (a "task", because it consumes time).
  //   forever  = loop without end
  //   @(vif.mon_cb) = wake up on every rising clock edge, signals already
  //                   sampled race-free (input #1step in the clocking block)
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    reset_state();              // start clean
    forever begin               // run until the simulation ends
      @(vif.mon_cb);            // wait for next clock edge (values pre-sampled)
      cycle_cnt++;              // count this cycle
      if (vif.rst_n !== 1'b1) begin  // reset active? (case-equality, X-safe)
        handle_reset();         //   close any in-flight txn as "killed"
        continue;               //   skip normal sampling this cycle
      end
      sample_cycle();           // normal: start/progress/finish logic
    end
  endtask

  // Clear the "building" state back to idle.
  protected function void reset_state();
    in_flight = 0;              // nothing in EX anymore
    cur       = null;           // drop the half-built transaction
    tag_valid = 0;              // no tag waiting
  endfunction

  // ---------------------------------------------------------------------------
  // handle_reset: reset was sampled active at a clock edge.
  // A MUL-unit instruction that was in EX is DROPPED by the DUT. We still
  // publish the transaction, but flagged killed_by_reset=1, so the scoreboard
  // can skip checking it and the coverage can count "reset during MULH".
  // ---------------------------------------------------------------------------
  protected function void handle_reset();
    if (in_flight) begin                 // only if an instruction was running
      cur.killed_by_reset = 1;           // flag it
      cur.t_end           = $time;       // close the timing fields
      cur.cycle_end       = cycle_cnt;
      n_killed++;                        // statistics
      `uvm_info("MUL_MON", {"dropped by reset: ", cur.convert2string()}, UVM_MEDIUM)
      ap.write(cur);                     // publish the killed transaction
    end
    reset_state();                       // go back to idle either way
  endfunction

  // ---------------------------------------------------------------------------
  // sample_cycle: called once per healthy clock edge. Three steps:
  // ---------------------------------------------------------------------------
  protected function void sample_cycle();
    // ---- step 1: did a NEW instruction enter the multiplier unit? ----------
    if (!in_flight && (vif.mon_cb.mult_en === 1'b1)) begin
      start_txn();             // yes -> open a new transaction now
    end

    // ---- step 2: progress and possible completion of the current one -------
    if (in_flight) begin
      cur.total_cycles++;      // we spent one more cycle in EX
      // multiplier finished but EX not free => external stall (LSU/WB wait)
      if ((vif.mon_cb.mult_ready === 1'b1) && (vif.mon_cb.ex_valid !== 1'b1)) cur.stall_cycles++;
      // MULH multicycle window (STEP0..STEP2) -> count it
      if (vif.mon_cb.mult_multicycle === 1'b1)                                cur.multicycle_len++;

      if (cfg.check_protocol) check_in_flight();   // invariants while inside EX

      if (vif.mon_cb.ex_valid === 1'b1) begin
        finish_txn();          // result valid -> close and publish
      end else if (cur.total_cycles > cfg.max_cycles_in_ex) begin
        // HANG: far too long in EX -> report as error and give up on it
        `uvm_error("MUL_MON", $sformatf("instruction stuck in EX for %0d cycles (max_cycles_in_ex=%0d): %s",
                                        cur.total_cycles, cfg.max_cycles_in_ex, cur.convert2string()))
        in_flight = 0;         // stop tracking (avoid endless error spam)
        cur       = null;
      end
    end

    // ---- step 3: record this cycle's issue pulse (it belongs to the NEXT op)
    //            - done LAST so the tag attached at start_txn is the pulse
    //            of the PREVIOUS cycle, i.e. of the instruction that just
    //            arrived in EX.
    if (cfg.tag_enable && (vif.mon_cb.id_valid === 1'b1) && (vif.mon_cb.is_decoding === 1'b1)) begin
      tag_valid = 1;                      // remember: a tag is pending
      tag_pc    = vif.mon_cb.pc_id;       // save its PC
      tag_instr = vif.mon_cb.instr_id;    // save its instruction word
    end
  endfunction

  // ---------------------------------------------------------------------------
  // start_txn: create a fresh mul_txn and fill it from the interface signals
  // sampled in THIS cycle (the first EX cycle of the instruction).
  // ---------------------------------------------------------------------------
  protected function void start_txn();
    rv32m_op_e op;   // decoded opcode (output of decode_ctrl)
    bit        ok;   // 1 = decode succeeded (combinaton the decoder can make)

    cur = mul_txn::type_id::create("mul_txn");               // make the object
    ok  = mul_txn::decode_ctrl(vif.mon_cb.mult_operator,     // decode MUL/MULH...
                               vif.mon_cb.mult_signed_mode, op);
    cur.op               = op;                               // clean opcode
    cur.mult_operator    = vif.mon_cb.mult_operator;         // raw control fields
    cur.mult_signed_mode = vif.mon_cb.mult_signed_mode;
    cur.mult_sel_subword = vif.mon_cb.mult_sel_subword;
    cur.mult_imm         = vif.mon_cb.mult_imm;
    cur.rs1_val          = vif.mon_cb.mult_operand_a;        // operands (first cycle)
    cur.rs2_val          = vif.mon_cb.mult_operand_b;
    cur.op_c_start       = vif.mon_cb.mult_operand_c;
    cur.t_start          = $time;                            // when it started
    cur.cycle_start      = cycle_cnt;
    cur.tag_valid        = tag_valid;                        // attach saved tag
    cur.pc               = tag_pc;
    cur.instr            = tag_instr;
    in_flight            = 1;                                // we are now inside

    // ---- protocol checks at the START of an instruction --------------------
    if (cfg.check_protocol) begin
      if (!ok)   // decode failed: a control combination RV32IM never produces
        `uvm_error("MUL_MON", $sformatf("operator/sign-mode combination not producible by the RV32IM decoder: operator=%s signed_mode=%0b",
                                        vif.mon_cb.mult_operator.name(), vif.mon_cb.mult_signed_mode))
      if (vif.mon_cb.alu_en === 1'b1)  // ALU and MUL never work at the same time
        `uvm_error("MUL_MON", "alu_en and mult_en asserted in the same cycle")
      if (vif.mon_cb.mult_sel_subword !== 1'b0 || vif.mon_cb.mult_imm !== 5'd0)
        `uvm_error("MUL_MON", $sformatf("PULP-only multiplier controls active: mult_sel_subword=%0b mult_imm=%0d",
                                        vif.mon_cb.mult_sel_subword, vif.mon_cb.mult_imm))
      if (vif.mon_cb.mult_operand_c !== 32'h0)   // RV32IM always starts with c=0
        `uvm_error("MUL_MON", $sformatf("mult_operand_c must be 0 at the start of a MUL-unit instruction (REGC_ZERO), got 0x%08h",
                                        vif.mon_cb.mult_operand_c))
      if (tag_valid && cfg.tag_enable && !is_rv32m_instr(tag_instr))
        `uvm_warning("MUL_MON", $sformatf("tagged instruction 0x%08h @0x%08h is not an RV32M encoding - tag tracking out of sync?",
                                          tag_instr, tag_pc))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // check_in_flight: invariants that must hold EVERY cycle while the
  // instruction sits in EX (the same rules exist in mul_sva; duplicated here
  // so the agent alone - without the SVA module - still finds these bugs).
  // ---------------------------------------------------------------------------
  protected function void check_in_flight();
    if (vif.mon_cb.mult_en !== 1'b1)   // unit must stay enabled until done
      `uvm_error("MUL_MON", {"mult_en dropped before ex_valid: ", cur.convert2string()})
    if (vif.mon_cb.mult_operand_a !== cur.rs1_val || vif.mon_cb.mult_operand_b !== cur.rs2_val)
      `uvm_error("MUL_MON", $sformatf("operands changed while in EX: a=0x%08h b=0x%08h (started with 0x%08h / 0x%08h)",
                                      vif.mon_cb.mult_operand_a, vif.mon_cb.mult_operand_b, cur.rs1_val, cur.rs2_val))
    if (vif.mon_cb.mult_operator !== cur.mult_operator || vif.mon_cb.mult_signed_mode !== cur.mult_signed_mode)
      `uvm_error("MUL_MON", "operator / signed_mode changed while in EX")
    if ((vif.mon_cb.mult_ready !== 1'b1) && (vif.mon_cb.ex_ready === 1'b1))
      `uvm_error("MUL_MON", "ex_ready asserted while the multiplier is busy (mult_ready=0)")
  endfunction

  // ---------------------------------------------------------------------------
  // finish_txn: ex_valid seen -> capture the completion data and publish.
  // ---------------------------------------------------------------------------
  protected function void finish_txn();
    cur.result      = vif.mon_cb.mult_result;      // what the multiplier produced
    cur.wdata       = vif.mon_cb.rf_alu_wdata;     // what was written to the RF
    cur.waddr       = vif.mon_cb.rf_alu_waddr;     // destination register
    cur.we          = vif.mon_cb.rf_alu_we;        // write enable
    cur.mult_cycles = cur.total_cycles - cur.stall_cycles;  // real (net) cycles
    cur.t_end       = $time;                       // close timing fields
    cur.cycle_end   = cycle_cnt;

    n_txn++;                                       // statistics...
    if (cur.op == MUL) n_mul++; else n_mulh++;
    if (cur.stall_cycles > max_stall_seen) max_stall_seen = cur.stall_cycles;

    if (cfg.verbose)                               // optional per-txn print
      `uvm_info("MUL_MON", cur.convert2string(), UVM_HIGH)

    ap.write(cur);                                 // PUBLISH to SB + coverage
    in_flight = 0;                                 // back to idle
    cur       = null;
  endfunction

  // ---------------------------------------------------------------------------
  // report_phase: UVM calls this at the end of simulation -> print summary.
  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MUL_MON", $sformatf("MUL-unit instructions observed: %0d (MUL %0d, MULH* %0d), killed by reset %0d, max external stall %0d cycles",
                                   n_txn, n_mul, n_mulh, n_killed, max_stall_seen), UVM_LOW)
  endfunction

endclass : mul_monitor
