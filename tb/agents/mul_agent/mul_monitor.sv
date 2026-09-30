// =============================================================================
// mul_monitor.sv  (part of mul_agent_pkg)
// -----------------------------------------------------------------------------
// Passive monitor of the multiplier unit (rtl/cv32e40p_mult.sv) through
// alu_mul_if. Reconstructs one mul_txn per MUL/MULH/MULHSU/MULHU instruction
// that executes in the EX stage and publishes it on `ap` in the cycle the
// instruction completes (ex_valid).
//
// Cycle model (notes/mul_plan.md 0.2, alu_mul_if.sv header):
//
//   start     : first cycle with mult_en==1 while nothing is in flight.
//               (The ID/EX register is cleared - mult_en<=0 - whenever EX is
//               ready and ID has no valid instruction, so after a completion
//               the next cycle with mult_en==1 is always a NEW instruction.)
//   progress  : total_cycles++ every cycle in EX
//               stall_cycles++ when mult_ready && !ex_valid  (multiplier done,
//               EX held by lsu_ready_ex / wb_ready - a data-side wait state)
//               multicycle_len++ when mult_multicycle (STEP0..STEP2 of MULH)
//   complete  : ex_valid==1 -> capture result / write port, publish
//   reset     : rst_n==0 while in flight -> publish with killed_by_reset=1
//
//   Nothing in EX is ever killed in this scope (a taken branch flushes IF/ID
//   only, the illegal-instruction flush waits for ex_valid, no IRQ/debug),
//   so every started instruction completes unless reset intervenes.
//
// Tag: the "issue pulse" id_valid && is_decoding in cycle N means the
// instruction in ID is in EX in cycle N+1. The pulse of the cycle that starts
// a transaction belongs to the NEXT instruction, therefore the tag is attached
// before the pulse of the current cycle is recorded.
// =============================================================================
class mul_monitor extends uvm_monitor;
  `uvm_component_utils(mul_monitor)

  mul_agent_cfg               cfg;
  uvm_analysis_port #(mul_txn) ap;

  // statistics (printed in report_phase)
  int unsigned n_txn;
  int unsigned n_mul;
  int unsigned n_mulh;
  int unsigned n_killed;
  int unsigned max_stall_seen;

  // internal state
  protected virtual alu_mul_if vif;
  protected mul_txn            cur;
  protected bit                in_flight;
  protected bit                tag_valid;
  protected bit [31:0]         tag_pc;
  protected bit [31:0]         tag_instr;
  protected int unsigned       cycle_cnt;   // free-running clock-cycle counter (not reset by rst_n)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin
      if (!uvm_config_db#(mul_agent_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("MUL_MON", "no mul_agent_cfg (field 'cfg' not set and not in config_db)")
    end
    if (cfg.vif == null)
      `uvm_fatal("MUL_MON", "mul_agent_cfg.vif is null")
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
    in_flight = 0;
    cur       = null;
    tag_valid = 0;
  endfunction

  // Reset asserted (sampled at the clock edge). A MUL-unit instruction that
  // was in EX is dropped by the DUT: publish it flagged so the scoreboard can
  // ignore it and the coverage can record "reset during MULH".
  protected function void handle_reset();
    if (in_flight) begin
      cur.killed_by_reset = 1;
      cur.t_end           = $time;
      cur.cycle_end       = cycle_cnt;
      n_killed++;
      `uvm_info("MUL_MON", {"dropped by reset: ", cur.convert2string()}, UVM_MEDIUM)
      ap.write(cur);
    end
    reset_state();
  endfunction

  // ---------------------------------------------------------------------------
  protected function void sample_cycle();
    // ---- 1. start of a new instruction in the multiplier unit --------------
    if (!in_flight && (vif.mon_cb.mult_en === 1'b1)) begin
      start_txn();
    end

    // ---- 2. progress / completion -------------------------------------------
    if (in_flight) begin
      cur.total_cycles++;
      if ((vif.mon_cb.mult_ready === 1'b1) && (vif.mon_cb.ex_valid !== 1'b1)) cur.stall_cycles++;
      if (vif.mon_cb.mult_multicycle === 1'b1)                                cur.multicycle_len++;

      if (cfg.check_protocol) check_in_flight();

      if (vif.mon_cb.ex_valid === 1'b1) begin
        finish_txn();
      end else if (cur.total_cycles > cfg.max_cycles_in_ex) begin
        `uvm_error("MUL_MON", $sformatf("instruction stuck in EX for %0d cycles (max_cycles_in_ex=%0d): %s",
                                        cur.total_cycles, cfg.max_cycles_in_ex, cur.convert2string()))
        in_flight = 0;
        cur       = null;
      end
    end

    // ---- 3. record the issue pulse of this cycle (belongs to the NEXT EX op)
    if (cfg.tag_enable && (vif.mon_cb.id_valid === 1'b1) && (vif.mon_cb.is_decoding === 1'b1)) begin
      tag_valid = 1;
      tag_pc    = vif.mon_cb.pc_id;
      tag_instr = vif.mon_cb.instr_id;
    end
  endfunction

  // ---------------------------------------------------------------------------
  protected function void start_txn();
    rv32m_op_e op;
    bit        ok;

    cur = mul_txn::type_id::create("mul_txn");
    ok  = mul_txn::decode_ctrl(vif.mon_cb.mult_operator, vif.mon_cb.mult_signed_mode, op);
    cur.op               = op;
    cur.mult_operator    = vif.mon_cb.mult_operator;
    cur.mult_signed_mode = vif.mon_cb.mult_signed_mode;
    cur.mult_sel_subword = vif.mon_cb.mult_sel_subword;
    cur.mult_imm         = vif.mon_cb.mult_imm;
    cur.rs1_val          = vif.mon_cb.mult_operand_a;
    cur.rs2_val          = vif.mon_cb.mult_operand_b;
    cur.op_c_start       = vif.mon_cb.mult_operand_c;
    cur.t_start          = $time;
    cur.cycle_start      = cycle_cnt;
    cur.tag_valid        = tag_valid;
    cur.pc               = tag_pc;
    cur.instr            = tag_instr;
    in_flight            = 1;

    if (cfg.check_protocol) begin
      if (!ok)
        `uvm_error("MUL_MON", $sformatf("operator/sign-mode combination not producible by the RV32IM decoder: operator=%s signed_mode=%0b",
                                        vif.mon_cb.mult_operator.name(), vif.mon_cb.mult_signed_mode))
      if (vif.mon_cb.alu_en === 1'b1)
        `uvm_error("MUL_MON", "alu_en and mult_en asserted in the same cycle")
      if (vif.mon_cb.mult_sel_subword !== 1'b0 || vif.mon_cb.mult_imm !== 5'd0)
        `uvm_error("MUL_MON", $sformatf("PULP-only multiplier controls active: mult_sel_subword=%0b mult_imm=%0d",
                                        vif.mon_cb.mult_sel_subword, vif.mon_cb.mult_imm))
      if (vif.mon_cb.mult_operand_c !== 32'h0)
        `uvm_error("MUL_MON", $sformatf("mult_operand_c must be 0 at the start of a MUL-unit instruction (REGC_ZERO), got 0x%08h",
                                        vif.mon_cb.mult_operand_c))
      if (tag_valid && cfg.tag_enable && !is_rv32m_instr(tag_instr))
        `uvm_warning("MUL_MON", $sformatf("tagged instruction 0x%08h @0x%08h is not an RV32M encoding - tag tracking out of sync?",
                                          tag_instr, tag_pc))
    end
  endfunction

  // Invariants while the instruction sits in EX (also covered by mul_sva,
  // duplicated here so the agent is self-sufficient without the SVA module).
  protected function void check_in_flight();
    if (vif.mon_cb.mult_en !== 1'b1)
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
  protected function void finish_txn();
    cur.result      = vif.mon_cb.mult_result;
    cur.wdata       = vif.mon_cb.rf_alu_wdata;
    cur.waddr       = vif.mon_cb.rf_alu_waddr;
    cur.we          = vif.mon_cb.rf_alu_we;
    cur.mult_cycles = cur.total_cycles - cur.stall_cycles;
    cur.t_end       = $time;
    cur.cycle_end   = cycle_cnt;

    n_txn++;
    if (cur.op == MUL) n_mul++; else n_mulh++;
    if (cur.stall_cycles > max_stall_seen) max_stall_seen = cur.stall_cycles;

    if (cfg.verbose)
      `uvm_info("MUL_MON", cur.convert2string(), UVM_HIGH)

    ap.write(cur);
    in_flight = 0;
    cur       = null;
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MUL_MON", $sformatf("MUL-unit instructions observed: %0d (MUL %0d, MULH* %0d), killed by reset %0d, max external stall %0d cycles",
                                   n_txn, n_mul, n_mulh, n_killed, max_stall_seen), UVM_LOW)
  endfunction

endclass : mul_monitor
