// =============================================================================
// alu_monitor.sv  (part of alu_agent_pkg)
// -----------------------------------------------------------------------------
// Passive monitor of the ALU (rtl/cv32e40p_alu.sv + cv32e40p_alu_div.sv)
// through alu_mul_if. Reconstructs one alu_txn per instruction that uses the
// ALU in EX and publishes it on `ap` in the cycle the instruction leaves EX.
//
// Cycle model (validated on the RTL with tb/sim/smoke/alu_smoke_checker.sv,
// which must stay algorithmically identical to this class):
//
//   issue    : id_valid && is_decoding in cycle N  => the ID instruction is in
//              EX in cycle N+1 (tag pc/instr). The tag is valid for ONE cycle.
//   start    : alu_en && !in_flight
//                preceded by an issue  -> new instruction (tagged)
//                not preceded, data_misaligned_ex=1 -> 2nd EX pass of a misaligned
//                                         load/store (a = first address forwarded
//                                         from EX, b = 4, we = 0; id_valid is 0
//                                         during the misaligned stall). Published
//                                         as misaligned_2nd=1 with the tag of the
//                                         first pass.
//                not preceded, otherwise -> pipeline BUBBLE: rtl/cv32e40p_id_stage.sv
//                                         loads alu_en=1, alu_operator=ALU_SLTU,
//                                         regfile_alu_we=0, branch_in_ex=0 whenever
//                                         EX is ready and ID has nothing valid
//                                         (after taken branches, load-use / jr
//                                         stalls, instruction-fetch wait states).
//                                         Counted, not published.
//   progress : total_cycles++; stall_cycles++ when alu_ready && !ex_ready
//              (single-cycle op or divider finished, EX held by LSU/WB)
//   finish   : ex_ready - the instruction leaves EX.
//              ex_ready == ex_valid except for branches: branch_in_ex forces
//              ex_ready so a branch may leave EX with ex_valid=0 when WB is
//              not ready (nothing to write anyway).
//   reset    : rst_n==0 while in flight -> publish with killed_by_reset=1
//
// Nothing in EX is ever killed in the RV32IM scope (no IRQ/debug, taken
// branches flush IF/ID only), so every started instruction completes unless
// reset intervenes.
// =============================================================================
class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)

  alu_agent_cfg                cfg;
  uvm_analysis_port #(alu_txn) ap;

  // statistics (printed in report_phase)
  int unsigned n_txn;
  int unsigned n_by_class [7];       // alu_op_class_e
  int unsigned n_bubbles;
  int unsigned n_misaligned_2nd;
  int unsigned n_killed;
  int unsigned n_branch_no_valid;
  int unsigned max_stall_seen;
  int unsigned div_lat_min = 99, div_lat_max = 0;

  // internal state
  protected virtual alu_mul_if vif;
  protected alu_txn            cur;
  protected bit                in_flight;
  protected bit                issued_prev;   // issue pulse in the previous cycle
  protected bit [31:0]         tag_pc;
  protected bit [31:0]         tag_instr;
  protected bit                last_tag_valid;  // tag / result of the previous item
  protected bit [31:0]         last_pc;         // (misaligned 2nd pass inherits them)
  protected bit [31:0]         last_instr;
  protected bit [31:0]         last_result;
  protected int unsigned       cycle_cnt;     // free-running (not reset by rst_n)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin
      if (!uvm_config_db#(alu_agent_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("ALU_MON", "no alu_agent_cfg (field 'cfg' not set and not in config_db)")
    end
    if (cfg.vif == null)
      `uvm_fatal("ALU_MON", "alu_agent_cfg.vif is null")
    vif = cfg.vif;
  endfunction

  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    reset_state();
    forever begin
      @(vif.mon_cb);
      cycle_cnt++;
      if (vif.rst_n !== 1'b1) begin
        handle_reset();
        continue;
      end
      sample_cycle();
    end
  endtask

  // ---------------------------------------------------------------------------
  protected function void reset_state();
    in_flight   = 0;
    cur         = null;
    issued_prev = 0;
  endfunction

  protected function void handle_reset();
    if (in_flight) begin
      cur.killed_by_reset = 1;
      cur.t_end           = $time;
      cur.cycle_end       = cycle_cnt;
      n_killed++;
      `uvm_info("ALU_MON", {"dropped by reset: ", cur.convert2string()}, UVM_MEDIUM)
      ap.write(cur);
    end
    reset_state();
  endfunction

  // Bubble signature loaded by the ID stage when EX is ready and ID is not valid
  protected function bit looks_like_bubble();
    return (vif.mon_cb.alu_operator === ALU_SLTU) && (vif.mon_cb.rf_alu_we !== 1'b1) &&
           (vif.mon_cb.branch_in_ex !== 1'b1);
  endfunction

  // ---------------------------------------------------------------------------
  protected function void sample_cycle();
    bit is_instr;

    // ---- 1. start of a new ALU instruction / misaligned 2nd pass / bubble ------------
    if (!in_flight && (vif.mon_cb.alu_en === 1'b1)) begin
      is_instr = cfg.tag_enable ? issued_prev : !looks_like_bubble();
      if (vif.mon_cb.data_misaligned_ex === 1'b1) begin
        start_txn(.misaligned_2nd(1));
      end else if (is_instr) begin
        start_txn(.misaligned_2nd(0));
      end else begin
        n_bubbles++;
        if (cfg.check_protocol && !looks_like_bubble())
          `uvm_error("ALU_MON", $sformatf("ALU activity without an issued instruction: %s we=%0b branch_in_ex=%0b",
                                          vif.mon_cb.alu_operator.name(), vif.mon_cb.rf_alu_we, vif.mon_cb.branch_in_ex))
      end
    end else if (!in_flight && cfg.tag_enable && issued_prev && cfg.check_protocol &&
                 (vif.mon_cb.alu_en !== 1'b1) && (vif.mon_cb.mult_en !== 1'b1)) begin
      `uvm_error("ALU_MON", $sformatf("issued instruction 0x%08h @0x%08h uses neither the ALU nor the multiplier (out of RV32IM scope?)",
                                      tag_instr, tag_pc))
    end

    // ---- 2. progress / completion ---------------------------------------------------
    if (in_flight) begin
      cur.total_cycles++;
      if ((vif.mon_cb.alu_ready === 1'b1) && (vif.mon_cb.ex_ready !== 1'b1)) cur.stall_cycles++;

      if (cfg.check_protocol) check_in_flight();

      if (vif.mon_cb.ex_ready === 1'b1) begin
        finish_txn();
      end else if (cur.total_cycles > cfg.max_cycles_in_ex) begin
        `uvm_error("ALU_MON", $sformatf("instruction stuck in EX for %0d cycles (max_cycles_in_ex=%0d): %s",
                                        cur.total_cycles, cfg.max_cycles_in_ex, cur.convert2string()))
        in_flight = 0;
        cur       = null;
      end
    end

    // ---- 3. issue pulse of this cycle (belongs to the NEXT EX instruction) ------------
    issued_prev = (vif.mon_cb.id_valid === 1'b1) && (vif.mon_cb.is_decoding === 1'b1);
    if (issued_prev) begin
      tag_pc    = vif.mon_cb.pc_id;
      tag_instr = vif.mon_cb.instr_id;
    end
  endfunction

  // ---------------------------------------------------------------------------
  protected function void start_txn(bit misaligned_2nd);
    cur = alu_txn::type_id::create("alu_txn");
    cur.op             = vif.mon_cb.alu_operator;
    cur.a              = vif.mon_cb.alu_operand_a;
    cur.b              = vif.mon_cb.alu_operand_b;
    cur.c              = vif.mon_cb.alu_operand_c;
    cur.lsu_en         = (vif.mon_cb.lsu_en === 1'b1);
    cur.misaligned_2nd = misaligned_2nd;
    cur.t_start        = $time;
    cur.cycle_start    = cycle_cnt;
    if (misaligned_2nd) begin
      cur.tag_valid = last_tag_valid;
      cur.pc        = last_pc;
      cur.instr     = last_instr;
    end else begin
      cur.tag_valid = cfg.tag_enable && issued_prev;
      cur.pc        = tag_pc;
      cur.instr     = tag_instr;
    end
    in_flight = 1;

    if (cfg.check_protocol) begin
      if (misaligned_2nd) begin
        n_misaligned_2nd++;
        if (issued_prev)
          `uvm_error("ALU_MON", "data_misaligned_ex together with an issue pulse in the previous cycle")
        if ((cur.op != ALU_ADD) || (cur.b != 32'd4) || (cur.a != last_result) || !cur.lsu_en || (vif.mon_cb.rf_alu_we === 1'b1))
          `uvm_error("ALU_MON", $sformatf("misaligned 2nd pass malformed: %s a=0x%08h (1st address 0x%08h) b=0x%08h lsu_en=%0b we=%0b",
                                          cur.op.name(), cur.a, last_result, cur.b, cur.lsu_en, vif.mon_cb.rf_alu_we))
      end
      if (!alu_op_in_scope(cur.op))
        `uvm_error("ALU_MON", $sformatf("alu_operator %s is not producible by the RV32IM decoder (pc 0x%08h instr 0x%08h)",
                                        cur.op.name(), tag_pc, tag_instr))
      if (vif.mon_cb.mult_en === 1'b1)
        `uvm_error("ALU_MON", "alu_en and mult_en asserted in the same cycle")
      if (is_div_operator(cur.op) && (vif.mon_cb.alu_ready === 1'b1))
        `uvm_error("ALU_MON", "alu_ready (div_ready) high in the first cycle of a DIV/REM")
      if (!is_div_operator(cur.op) && (vif.mon_cb.alu_ready !== 1'b1))
        `uvm_error("ALU_MON", $sformatf("alu_ready low for single-cycle operator %s", cur.op.name()))
    end
  endfunction

  // Invariants while the instruction sits in EX (duplicated in alu_sva)
  protected function void check_in_flight();
    if (vif.mon_cb.alu_en !== 1'b1)
      `uvm_error("ALU_MON", {"alu_en dropped before the instruction left EX: ", cur.convert2string()})
    if (vif.mon_cb.alu_operand_a !== cur.a || vif.mon_cb.alu_operand_b !== cur.b)
      `uvm_error("ALU_MON", $sformatf("operands changed while in EX: a=0x%08h b=0x%08h (started with 0x%08h / 0x%08h)",
                                      vif.mon_cb.alu_operand_a, vif.mon_cb.alu_operand_b, cur.a, cur.b))
    if (vif.mon_cb.alu_operator !== cur.op)
      `uvm_error("ALU_MON", "alu_operator changed while in EX")
    if ((vif.mon_cb.alu_ready !== 1'b1) && (vif.mon_cb.ex_ready === 1'b1))
      `uvm_error("ALU_MON", "ex_ready asserted while the divider is busy (alu_ready=0)")
    if ((vif.mon_cb.alu_ready !== 1'b1) && (vif.mon_cb.ex_valid === 1'b1))
      `uvm_error("ALU_MON", "ex_valid asserted while the divider is busy (alu_ready=0)")
  endfunction

  // ---------------------------------------------------------------------------
  protected function void finish_txn();
    alu_op_class_e cls;
    cur.result       = vif.mon_cb.alu_result;
    cur.cmp          = vif.mon_cb.alu_cmp_result;
    cur.wdata        = vif.mon_cb.rf_alu_wdata;
    cur.waddr        = vif.mon_cb.rf_alu_waddr;
    cur.we           = vif.mon_cb.rf_alu_we;
    cur.ex_valid     = vif.mon_cb.ex_valid;
    cur.branch_in_ex = vif.mon_cb.branch_in_ex;
    cur.alu_cycles   = cur.total_cycles - cur.stall_cycles;
    cur.t_end        = $time;
    cur.cycle_end    = cycle_cnt;

    cls = alu_op_class(cur.op);
    n_txn++;
    n_by_class[cls]++;
    if (cur.stall_cycles > max_stall_seen) max_stall_seen = cur.stall_cycles;
    if (!cur.ex_valid && is_branch_operator(cur.op)) n_branch_no_valid++;
    if (is_div_operator(cur.op)) begin
      if (cur.alu_cycles < div_lat_min) div_lat_min = cur.alu_cycles;
      if (cur.alu_cycles > div_lat_max) div_lat_max = cur.alu_cycles;
    end

    if (cfg.verbose)
      `uvm_info("ALU_MON", cur.convert2string(), UVM_HIGH)

    last_tag_valid = cur.tag_valid;
    last_pc        = cur.pc;
    last_instr     = cur.instr;
    last_result    = cur.result;

    ap.write(cur);
    in_flight = 0;
    cur       = null;
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("ALU_MON", $sformatf("ALU instructions observed: %0d (arith %0d, logic %0d, shift %0d, slt %0d, branch %0d [%0d left EX w/o ex_valid], div %0d [net latency %0d..%0d], misaligned 2nd passes %0d), bubbles %0d, killed by reset %0d, max external stall %0d cycles",
                                   n_txn, n_by_class[ALU_CLS_ARITH], n_by_class[ALU_CLS_LOGIC], n_by_class[ALU_CLS_SHIFT],
                                   n_by_class[ALU_CLS_SLT], n_by_class[ALU_CLS_BRANCH], n_branch_no_valid, n_by_class[ALU_CLS_DIV],
                                   div_lat_min, div_lat_max, n_misaligned_2nd, n_bubbles, n_killed, max_stall_seen), UVM_LOW)
  endfunction

endclass : alu_monitor
