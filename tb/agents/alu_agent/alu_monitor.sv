// =============================================================================
// alu_monitor.sv  (included inside alu_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   The BRAIN of the ALU agent - a passive watcher of the ALU + divider
//   (rtl/cv32e40p_alu.sv + cv32e40p_alu_div.sv) through the shared alu_mul_if.
//   It rebuilds ONE alu_txn per instruction that uses the ALU in EX and
//   publishes it on `ap` in the cycle the instruction LEAVES EX.
//
//   IMPORTANT: tb/sim/smoke/alu_smoke_checker.sv implements the SAME
//   algorithm for the Verilator smoke bench - the two must stay identical.
//
// THE CYCLE MODEL (validated on the RTL):
//   issue   : id_valid && is_decoding in cycle N  =>  the ID instruction is
//             in EX during cycle N+1 (that is when we tag pc/instr).
//             The tag is good for ONE cycle only.
//   start   : alu_en && !in_flight
//               + preceded by an issue      -> real instruction (tagged)
//               + not preceded but
//                 data_misaligned_ex==1     -> 2nd EX pass of a misaligned
//                                              load/store: ID reloaded the ALU
//                                              with a = first address (forwarded
//                                              from EX), b = 4, we = 0, and
//                                              id_valid is 0 during that stall.
//                                              Published as misaligned_2nd=1,
//                                              inheriting the first pass tag.
//               + not preceded otherwise    -> pipeline BUBBLE: rtl/cv32e40p_id_stage
//                                              loads alu_en=1, ALU_SLTU, we=0,
//                                              branch_in_ex=0 whenever EX is
//                                              ready and ID has nothing valid.
//                                              COUNTED, not published.
//   progress: total_cycles++ each cycle;
//             stall_cycles++ when alu_ready && !ex_ready (unit done, EX held
//             by LSU/WB = external wait state)
//   finish  : ex_ready==1 -> instruction leaves EX.
//             ex_ready == ex_valid EXCEPT branches: branch_in_ex forces
//             ex_ready, so a branch can leave with ex_valid=0 (no write).
//   reset   : rst_n==0 while in flight -> publish with killed_by_reset=1
//
//   In the RV32IM scope nothing in EX is ever killed (no IRQ/debug; a taken
//   branch flushes IF/ID only), so every started instruction completes unless
//   reset intervenes.
// =============================================================================
class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)   // register with the UVM factory

  alu_agent_cfg                cfg;   // knobs (given by the agent)
  uvm_analysis_port #(alu_txn) ap;    // output port: publishes every txn

  // ---- statistics (printed in report_phase at end of sim) ------------------
  int unsigned n_txn;                  // total published transactions
  int unsigned n_by_class [7];         // per alu_op_class_e class counter
  int unsigned n_bubbles;              // idle bubbles seen (not published)
  int unsigned n_misaligned_2nd;       // misaligned 2nd passes published
  int unsigned n_killed;               // transactions killed by reset
  int unsigned n_branch_no_valid;      // branches that left EX with ex_valid=0
  int unsigned max_stall_seen;         // biggest external stall recorded
  int unsigned div_lat_min = 99, div_lat_max = 0;  // divider net-latency range

  // ---- internal state (protected = private to this class) ------------------
  protected virtual alu_mul_if vif;    // shortcut to the interface handle
  protected alu_txn            cur;    // transaction being built right now
  protected bit                in_flight;      // 1 = inside an instruction
  protected bit                issued_prev;    // issue pulse in PREVIOUS cycle
  protected bit [31:0]         tag_pc;         // PC of last issued instruction
  protected bit [31:0]         tag_instr;      // word of last issued instruction
  protected bit                last_tag_valid; // tag of the PREVIOUS item...
  protected bit [31:0]         last_pc;        // ...(misaligned 2nd pass
  protected bit [31:0]         last_instr;      //      inherits them)
  protected bit [31:0]         last_result;    // result of previous item
                                               // (1st address of misaligned)
  protected int unsigned       cycle_cnt;      // free-running cycle counter
                                               // (not cleared by reset)

  // Constructor: call parent, create the output port.
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // ---------------------------------------------------------------------------
  // build_phase: fetch cfg + virtual interface; both are REQUIRED or fatal.
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin     // agent may set cfg directly...
      if (!uvm_config_db#(alu_agent_cfg)::get(this, "", "cfg", cfg))  // ...else db
        `uvm_fatal("ALU_MON", "no alu_agent_cfg (field 'cfg' not set and not in config_db)")
    end
    if (cfg.vif == null)       // no interface -> we are blind -> stop
      `uvm_fatal("ALU_MON", "alu_agent_cfg.vif is null")
    vif = cfg.vif;             // local shortcut used everywhere below
  endfunction

  // ---------------------------------------------------------------------------
  // run_phase: endless sampling loop (task because it consumes time).
  //   @(vif.mon_cb) = wake on each rising edge, race-free pre-sampled values.
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    reset_state();             // start clean
    forever begin              // run until simulation ends
      @(vif.mon_cb);           // next clock edge (values already sampled)
      cycle_cnt++;             // count this cycle
      if (vif.rst_n !== 1'b1) begin   // reset active? (X-safe case equality)
        handle_reset();        //   close in-flight txn as "killed"
        continue;              //   skip normal sampling
      end
      sample_cycle();          // normal start/progress/finish logic
    end
  endtask

  // Clear the "building" state back to idle.
  protected function void reset_state();
    in_flight   = 0;           // nothing in EX anymore
    cur         = null;        // drop half-built transaction
    issued_prev = 0;           // no pending issue pulse
  endfunction

  // ---------------------------------------------------------------------------
  // handle_reset: reset sampled active at a clock edge.
  // The DUT drops the instruction that was in EX. We still publish it, flagged
  // killed_by_reset=1, so the scoreboard can skip it and coverage can count
  // "reset during DIV/ALU".
  // ---------------------------------------------------------------------------
  protected function void handle_reset();
    if (in_flight) begin                 // only if an instruction was running
      cur.killed_by_reset = 1;           // flag it
      cur.t_end           = $time;       // close timing fields
      cur.cycle_end       = cycle_cnt;
      n_killed++;                        // statistics
      `uvm_info("ALU_MON", {"dropped by reset: ", cur.convert2string()}, UVM_MEDIUM)
      ap.write(cur);                     // publish killed transaction
    end
    reset_state();                       // back to idle either way
  endfunction

  // ---------------------------------------------------------------------------
  // looks_like_bubble: does the current ALU activity match the ID stage's
  // idle pattern? When EX is ready and ID has nothing valid, the ID stage
  // loads: alu_en=1, operator=ALU_SLTU, we=0, branch_in_ex=0.
  // This is the fallback discriminator when tag_enable=0.
  // ---------------------------------------------------------------------------
  protected function bit looks_like_bubble();
    return (vif.mon_cb.alu_operator === ALU_SLTU) && (vif.mon_cb.rf_alu_we !== 1'b1) &&
           (vif.mon_cb.branch_in_ex !== 1'b1);
  endfunction

  // ---------------------------------------------------------------------------
  // sample_cycle: called once per healthy clock edge. Three steps:
  // ---------------------------------------------------------------------------
  protected function void sample_cycle();
    bit is_instr;              // local flag: is this a real instruction?

    // ---- step 1: new instruction / misaligned 2nd pass / bubble? ------------
    if (!in_flight && (vif.mon_cb.alu_en === 1'b1)) begin
      // Decide "real instruction": with tags use the issue pulse of the
      // PREVIOUS cycle; without tags fall back to the bubble signature.
      is_instr = cfg.tag_enable ? issued_prev : !looks_like_bubble();
      if (vif.mon_cb.data_misaligned_ex === 1'b1) begin
        start_txn(.misaligned_2nd(1));     // 2nd pass of a split ld/st
      end else if (is_instr) begin
        start_txn(.misaligned_2nd(0));     // real instruction -> open txn
      end else begin
        n_bubbles++;                       // idle bubble: count, don't publish
        // If it does NOT even look like a bubble, something is wrong:
        // ALU activity with no instruction behind it.
        if (cfg.check_protocol && !looks_like_bubble())
          `uvm_error("ALU_MON", $sformatf("ALU activity without an issued instruction: %s we=%0b branch_in_ex=%0b",
                                          vif.mon_cb.alu_operator.name(), vif.mon_cb.rf_alu_we, vif.mon_cb.branch_in_ex))
      end
    end else if (!in_flight && cfg.tag_enable && issued_prev && cfg.check_protocol &&
                 (vif.mon_cb.alu_en !== 1'b1) && (vif.mon_cb.mult_en !== 1'b1)) begin
      // An instruction was issued but NEITHER unit is active -> it must be
      // outside RV32IM scope (ECALL/CSR/... are NOT supposed to appear).
      `uvm_error("ALU_MON", $sformatf("issued instruction 0x%08h @0x%08h uses neither the ALU nor the multiplier (out of RV32IM scope?)",
                                      tag_instr, tag_pc))
    end

    // ---- step 2: progress / completion of the current transaction -----------
    if (in_flight) begin
      cur.total_cycles++;      // spent one more cycle in EX
      // unit finished but EX not free => external stall (LSU/WB wait state)
      if ((vif.mon_cb.alu_ready === 1'b1) && (vif.mon_cb.ex_ready !== 1'b1)) cur.stall_cycles++;

      if (cfg.check_protocol) check_in_flight();   // invariants while inside EX

      if (vif.mon_cb.ex_ready === 1'b1) begin
        finish_txn();          // instruction left EX -> close + publish
      end else if (cur.total_cycles > cfg.max_cycles_in_ex) begin
        // HANG: way too long in EX -> report error and stop tracking it
        `uvm_error("ALU_MON", $sformatf("instruction stuck in EX for %0d cycles (max_cycles_in_ex=%0d): %s",
                                        cur.total_cycles, cfg.max_cycles_in_ex, cur.convert2string()))
        in_flight = 0;
        cur       = null;
      end
    end

    // ---- step 3: record THIS cycle's issue pulse (belongs to the NEXT op) ----
    // Done last, so start_txn (step 1) still sees the PREVIOUS cycle's pulse.
    issued_prev = (vif.mon_cb.id_valid === 1'b1) && (vif.mon_cb.is_decoding === 1'b1);
    if (issued_prev) begin
      tag_pc    = vif.mon_cb.pc_id;      // save PC of instruction in ID
      tag_instr = vif.mon_cb.instr_id;   // save its instruction word
    end
  endfunction

  // ---------------------------------------------------------------------------
  // start_txn: open a new alu_txn from the signals sampled THIS cycle.
  //   misaligned_2nd=0 : normal instruction -> tag from previous cycle's pulse
  //   misaligned_2nd=1 : 2nd pass of split ld/st -> inherit the FIRST pass tag
  // ---------------------------------------------------------------------------
  protected function void start_txn(bit misaligned_2nd);
    cur = alu_txn::type_id::create("alu_txn");            // make the object
    cur.op             = vif.mon_cb.alu_operator;         // which ALU op
    cur.a              = vif.mon_cb.alu_operand_a;        // raw operand A
    cur.b              = vif.mon_cb.alu_operand_b;        // raw operand B
    cur.c              = vif.mon_cb.alu_operand_c;        // raw operand C
    cur.lsu_en         = (vif.mon_cb.lsu_en === 1'b1);    // address op?
    cur.misaligned_2nd = misaligned_2nd;                  // flag the 2nd pass
    cur.t_start        = $time;                           // when it started
    cur.cycle_start    = cycle_cnt;
    if (misaligned_2nd) begin
      // inherit the tag of the FIRST pass (the ld/st instruction itself)
      cur.tag_valid = last_tag_valid;
      cur.pc        = last_pc;
      cur.instr     = last_instr;
    end else begin
      // normal: tag = issue pulse of the PREVIOUS cycle
      cur.tag_valid = cfg.tag_enable && issued_prev;
      cur.pc        = tag_pc;
      cur.instr     = tag_instr;
    end
    in_flight = 1;                                        // we are now inside

    // ---- checks at the START of a transaction --------------------------------
    if (cfg.check_protocol) begin
      if (misaligned_2nd) begin
        n_misaligned_2nd++;                               // statistics
        // The 2nd pass must NOT have an issue pulse behind it (it is a replay)
        if (issued_prev)
          `uvm_error("ALU_MON", "data_misaligned_ex together with an issue pulse in the previous cycle")
        // The 2nd pass must be exactly: ADD(first_address, 4), lsu_en=1, we=0
        if ((cur.op != ALU_ADD) || (cur.b != 32'd4) || (cur.a != last_result) || !cur.lsu_en || (vif.mon_cb.rf_alu_we === 1'b1))
          `uvm_error("ALU_MON", $sformatf("misaligned 2nd pass malformed: %s a=0x%08h (1st address 0x%08h) b=0x%08h lsu_en=%0b we=%0b",
                                          cur.op.name(), cur.a, last_result, cur.b, cur.lsu_en, vif.mon_cb.rf_alu_we))
      end
      // The operator must be one the RV32IM decoder can actually produce
      if (!alu_op_in_scope(cur.op))
        `uvm_error("ALU_MON", $sformatf("alu_operator %s is not producible by the RV32IM decoder (pc 0x%08h instr 0x%08h)",
                                        cur.op.name(), tag_pc, tag_instr))
      // ALU and MUL must never work in the same cycle
      if (vif.mon_cb.mult_en === 1'b1)
        `uvm_error("ALU_MON", "alu_en and mult_en asserted in the same cycle")
      // Divider: alu_ready (=div_ready) must be 0 in the FIRST cycle...
      if (is_div_operator(cur.op) && (vif.mon_cb.alu_ready === 1'b1))
        `uvm_error("ALU_MON", "alu_ready (div_ready) high in the first cycle of a DIV/REM")
      // ...and single-cycle ops must have alu_ready=1 right away
      if (!is_div_operator(cur.op) && (vif.mon_cb.alu_ready !== 1'b1))
        `uvm_error("ALU_MON", $sformatf("alu_ready low for single-cycle operator %s", cur.op.name()))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // check_in_flight: invariants that must hold EVERY cycle while the
  // instruction sits in EX (same rules are duplicated in alu_sva so that the
  // agent alone - without the SVA module - still catches these bugs).
  // ---------------------------------------------------------------------------
  protected function void check_in_flight();
    if (vif.mon_cb.alu_en !== 1'b1)    // unit must stay enabled until it leaves
      `uvm_error("ALU_MON", {"alu_en dropped before the instruction left EX: ", cur.convert2string()})
    if (vif.mon_cb.alu_operand_a !== cur.a || vif.mon_cb.alu_operand_b !== cur.b)
      `uvm_error("ALU_MON", $sformatf("operands changed while in EX: a=0x%08h b=0x%08h (started with 0x%08h / 0x%08h)",
                                      vif.mon_cb.alu_operand_a, vif.mon_cb.alu_operand_b, cur.a, cur.b))
    if (vif.mon_cb.alu_operator !== cur.op)
      `uvm_error("ALU_MON", "alu_operator changed while in EX")
    // While the divider is busy (alu_ready=0), EX must not declare ready/valid
    if ((vif.mon_cb.alu_ready !== 1'b1) && (vif.mon_cb.ex_ready === 1'b1))
      `uvm_error("ALU_MON", "ex_ready asserted while the divider is busy (alu_ready=0)")
    if ((vif.mon_cb.alu_ready !== 1'b1) && (vif.mon_cb.ex_valid === 1'b1))
      `uvm_error("ALU_MON", "ex_valid asserted while the divider is busy (alu_ready=0)")
  endfunction

  // ---------------------------------------------------------------------------
  // finish_txn: ex_ready seen -> instruction leaves EX: capture + publish.
  // ---------------------------------------------------------------------------
  protected function void finish_txn();
    alu_op_class_e cls;                // class of this op (for statistics)
    cur.result       = vif.mon_cb.alu_result;      // ALU/div output value
    cur.cmp          = vif.mon_cb.alu_cmp_result;  // comparator/branch decision
    cur.wdata        = vif.mon_cb.rf_alu_wdata;    // value written to RF
    cur.waddr        = vif.mon_cb.rf_alu_waddr;    // destination register
    cur.we           = vif.mon_cb.rf_alu_we;       // write enable
    cur.ex_valid     = vif.mon_cb.ex_valid;        // valid flag at exit
    cur.branch_in_ex = vif.mon_cb.branch_in_ex;    // was it a branch?
    cur.alu_cycles   = cur.total_cycles - cur.stall_cycles;  // net cycles
    cur.t_end        = $time;                      // close timing
    cur.cycle_end    = cycle_cnt;

    cls = alu_op_class(cur.op);        // classify for the histogram
    n_txn++;                           // update statistics...
    n_by_class[cls]++;
    if (cur.stall_cycles > max_stall_seen) max_stall_seen = cur.stall_cycles;
    if (!cur.ex_valid && is_branch_operator(cur.op)) n_branch_no_valid++;
    if (is_div_operator(cur.op)) begin                // track divider latency
      if (cur.alu_cycles < div_lat_min) div_lat_min = cur.alu_cycles;
      if (cur.alu_cycles > div_lat_max) div_lat_max = cur.alu_cycles;
    end

    if (cfg.verbose)                   // optional per-txn print
      `uvm_info("ALU_MON", cur.convert2string(), UVM_HIGH)

    // Save this item's tag + result: a coming misaligned 2nd pass inherits
    // them (its "first address" == our result).
    last_tag_valid = cur.tag_valid;
    last_pc        = cur.pc;
    last_instr     = cur.instr;
    last_result    = cur.result;

    ap.write(cur);                     // PUBLISH to scoreboard + coverage
    in_flight = 0;                     // back to idle
    cur       = null;
  endfunction

  // ---------------------------------------------------------------------------
  // report_phase: end-of-simulation summary line.
  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("ALU_MON", $sformatf("ALU instructions observed: %0d (arith %0d, logic %0d, shift %0d, slt %0d, branch %0d [%0d left EX w/o ex_valid], div %0d [net latency %0d..%0d], misaligned 2nd passes %0d), bubbles %0d, killed by reset %0d, max external stall %0d cycles",
                                   n_txn, n_by_class[ALU_CLS_ARITH], n_by_class[ALU_CLS_LOGIC], n_by_class[ALU_CLS_SHIFT],
                                   n_by_class[ALU_CLS_SLT], n_by_class[ALU_CLS_BRANCH], n_branch_no_valid, n_by_class[ALU_CLS_DIV],
                                   div_lat_min, div_lat_max, n_misaligned_2nd, n_bubbles, n_killed, max_stall_seen), UVM_LOW)
  endfunction

endclass : alu_monitor
