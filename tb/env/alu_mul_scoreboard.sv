// =============================================================================
// alu_mul_scoreboard.sv  (part of alu_mul_sb_pkg)
// -----------------------------------------------------------------------------
// "ALU_MUL Scoreboard" of tb_architecture/arch.jpg - block-level checker of
// the two execution units in EX. It is fed by the passive MUL agent (`_mul`
// import, mul_txn) and by the passive ALU agent (`_alu` import, alu_txn).
//
// What it checks (MUL side) - vplan risc_m_00 / risc_m_01 / risc_dec_01:
//   SB_MUL_RESULT   result == rv32m_ref(op, rs1, rs2)      (sb_mul_result_match /
//                                                           sb_mulh_result_match)
//   SB_MUL_LATENCY  mult_cycles == 1 (MUL) / 5 (MULH*) net of external stalls,
//                   multicycle_len == 0 / 3                (sb_mul_latency)
//   SB_MUL_WB       rf_alu_we == 1, rf_alu_wdata == mult_result,
//                   rf_alu_waddr[5] == 0                   (sb_mul_wb_port)
//   SB_MUL_TAG      the tagged instruction word is an RV32M encoding whose
//                   funct3 matches the executed op and whose rd matches the
//                   write-port address                     (issue/EX tracking)
//
// What it checks (ALU side) - vplan risc_m_02 / risc_m_03 / risc_dec_01 /
// risc_alu_* rows:
//   SB_ALU_RESULT   alu_result == alu_ref(op, a, b) on the RAW unit operands
//                   (DIV/REM: dividend = b, divisor = a - decoder swap), and
//                   alu_cmp_result == alu_cmp_ref for branch operators
//   SB_DIV_LATENCY  DIV/DIVU/REM/REMU: alu_cycles == div_latency_ref(op, divisor)
//                   (3..35 = leading-zero/one count model of cv32e40p_alu_div)
//                   net of external stalls; every other operator: 1 cycle
//   SB_ALU_WB       rf_alu_we == expectation of the tagged instruction,
//                   rf_alu_wdata == alu_result, rf_alu_waddr[5] == 0,
//                   waddr == rd; non-branch ops leave EX only with ex_valid
//   SB_ALU_TAG      decoder cross-check: the tagged instruction word must map
//                   to the executed alu_operator (alu_expect_of_instr), to
//                   lsu_en (data_req), LUI / AUIPC / JAL / JALR operand
//                   sourcing (imm_u, pc, pc+4); misaligned 2nd pass = ADD +4
//
// What it does NOT check (by design - other components do):
//   * that rs1/rs2 are the architecturally correct operand values and that rd
//     ends up with the right value in the register file -> Predictor +
//     Scoreboard + reg_file Scoreboard (the expected value here is computed
//     from the operands the DUT actually used, so this is a datapath/FSM check).
//   * "no spurious write-back during the stall window" at the RF-port level:
//     with COREV_PULP=0 the ALU write port is enabled in every EX cycle of a
//     multicycle op (rtl/cv32e40p_ex_stage.sv, regfile_alu_we_fw_o), so the
//     meaningful property is "exactly one ex_valid per instruction" - which
//     the monitor structure enforces and mul_sva asserts.
// =============================================================================
`uvm_analysis_imp_decl(_mul)
`uvm_analysis_imp_decl(_alu)

class alu_mul_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_mul_scoreboard)

  uvm_analysis_imp_mul #(mul_txn, alu_mul_scoreboard) mul_imp;
  uvm_analysis_imp_alu #(alu_txn, alu_mul_scoreboard) alu_imp;

  // ---- knobs (set via uvm_config_db int fields or directly by the env) ------
  bit check_result  = 1;
  bit check_latency = 1;
  bit check_wb_port = 1;
  bit check_tag     = 1;

  // ---- statistics ---------------------------------------------------------------
  int unsigned n_mul_txn;
  int unsigned n_mul_killed;
  int unsigned n_mul_err;
  int unsigned n_per_op [rv32m_op_e];
  int unsigned max_stall_cycles;
  int unsigned n_alu_txn;
  int unsigned n_alu_killed;
  int unsigned n_alu_err;
  int unsigned n_alu_per_op [alu_opcode_e];
  int unsigned n_div_lat [36];          // divider latency histogram (3..35)
  int unsigned max_alu_stall_cycles;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mul_imp = new("mul_imp", this);
    void'(uvm_config_db#(bit)::get(this, "", "check_result",  check_result));
    void'(uvm_config_db#(bit)::get(this, "", "check_latency", check_latency));
    void'(uvm_config_db#(bit)::get(this, "", "check_wb_port", check_wb_port));
    void'(uvm_config_db#(bit)::get(this, "", "check_tag",     check_tag));
  endfunction

  // ---------------------------------------------------------------------------
  // MUL side
  // ---------------------------------------------------------------------------
  virtual function void write_mul(mul_txn t);
    bit ok = 1;

    if (t.killed_by_reset) begin
      n_mul_killed++;
      `uvm_info("SB_MUL", {"ignored (killed by reset): ", t.convert2string()}, UVM_MEDIUM)
      return;
    end

    n_mul_txn++;
    n_per_op[t.op]++;
    if (t.stall_cycles > max_stall_cycles) max_stall_cycles = t.stall_cycles;

    // -- result ---------------------------------------------------------------
    if (check_result && (t.result !== t.exp_result())) begin
      ok = 0;
      `uvm_error(t.is_mulh() ? "SB_MULH_RESULT" : "SB_MUL_RESULT",
                 $sformatf("%s result mismatch: got 0x%08h expected 0x%08h | %s",
                           t.op.name(), t.result, t.exp_result(), t.convert2string()))
    end

    // -- write port ---------------------------------------------------------------
    if (check_wb_port) begin
      if (t.we !== 1'b1) begin
        ok = 0;
        `uvm_error("SB_MUL_WB", {"rf_alu_we not asserted in the ex_valid cycle | ", t.convert2string()})
      end
      if (t.wdata !== t.result) begin
        ok = 0;
        `uvm_error("SB_MUL_WB", $sformatf("rf_alu_wdata (0x%08h) != mult_result (0x%08h) - EX result mux | %s",
                                          t.wdata, t.result, t.convert2string()))
      end
      if (t.waddr[5] !== 1'b0) begin
        ok = 0;
        `uvm_error("SB_MUL_WB", $sformatf("rf_alu_waddr[5]=1 (FP register file selected) in an RV32IM configuration | %s",
                                          t.convert2string()))
      end
    end

    // -- latency ----------------------------------------------------------------
    if (check_latency) begin
      if (t.mult_cycles != t.exp_mult_cycles()) begin
        ok = 0;
        `uvm_error("SB_MUL_LATENCY", $sformatf("%s took %0d multiplier cycles (total %0d, external stall %0d), expected %0d | %s",
                                               t.op.name(), t.mult_cycles, t.total_cycles, t.stall_cycles,
                                               t.exp_mult_cycles(), t.convert2string()))
      end
      if (t.multicycle_len != t.exp_multicycle_len()) begin
        ok = 0;
        `uvm_error("SB_MUL_LATENCY", $sformatf("%s: mult_multicycle asserted for %0d cycles, expected %0d | %s",
                                               t.op.name(), t.multicycle_len, t.exp_multicycle_len(), t.convert2string()))
      end
    end

    // -- tag consistency ----------------------------------------------------------
    if (check_tag && t.tag_valid) begin
      if (!is_rv32m_instr(t.instr)) begin
        ok = 0;
        `uvm_error("SB_MUL_TAG", $sformatf("tagged word 0x%08h @0x%08h is not an RV32M instruction | %s",
                                           t.instr, t.pc, t.convert2string()))
      end else begin
        if (rv32m_op_of(t.instr) != t.op) begin
          ok = 0;
          `uvm_error("SB_MUL_TAG", $sformatf("decoder/EX mismatch: instruction funct3 says %s, EX executed %s | %s",
                                             rv32m_op_of(t.instr).name(), t.op.name(), t.convert2string()))
        end
        if (t.instr_rd() != t.rd()) begin
          ok = 0;
          `uvm_error("SB_MUL_TAG", $sformatf("write-port rd x%0d != instruction rd x%0d | %s",
                                             t.rd(), t.instr_rd(), t.convert2string()))
        end
      end
    end

    if (!ok) n_mul_err++;
    else `uvm_info("SB_MUL", {"OK ", t.convert2string()}, UVM_HIGH)
  endfunction

  // ---------------------------------------------------------------------------
  // ALU side
  // ---------------------------------------------------------------------------
  virtual function void write_alu(alu_txn t);
    bit          ok = 1;
    alu_expect_t e;

    if (t.killed_by_reset) begin
      n_alu_killed++;
      `uvm_info("SB_ALU", {"ignored (killed by reset): ", t.convert2string()}, UVM_MEDIUM)
      return;
    end

    n_alu_txn++;
    n_alu_per_op[t.op]++;
    if (t.stall_cycles > max_alu_stall_cycles) max_alu_stall_cycles = t.stall_cycles;
    if (t.is_div() && (t.alu_cycles <= DIV_LATENCY_MAX)) n_div_lat[t.alu_cycles]++;

    if (!alu_op_in_scope(t.op)) begin
      n_alu_err++;
      `uvm_error("SB_ALU_RESULT", $sformatf("operator %s is outside the RV32IM decoder output - no reference | %s", t.op.name(), t.convert2string()))
      return;
    end

    // -- result ---------------------------------------------------------------
    if (check_result) begin
      if (t.result !== t.exp_result()) begin
        ok = 0;
        `uvm_error(t.is_div() ? "SB_DIV_RESULT" : "SB_ALU_RESULT",
                   $sformatf("%s result mismatch: got 0x%08h expected 0x%08h | %s",
                             t.op.name(), t.result, t.exp_result(), t.convert2string()))
      end
      if (t.is_branch() && (t.cmp !== t.exp_cmp())) begin
        ok = 0;
        `uvm_error("SB_ALU_RESULT", $sformatf("%s branch decision %0b expected %0b | %s",
                                              t.op.name(), t.cmp, t.exp_cmp(), t.convert2string()))
      end
    end

    // -- latency ----------------------------------------------------------------
    if (check_latency && (t.alu_cycles != t.exp_alu_cycles())) begin
      ok = 0;
      `uvm_error(t.is_div() ? "SB_DIV_LATENCY" : "SB_ALU_LATENCY",
                 $sformatf("%s took %0d ALU cycles (total %0d, external stall %0d), expected %0d | %s",
                           t.op.name(), t.alu_cycles, t.total_cycles, t.stall_cycles, t.exp_alu_cycles(), t.convert2string()))
    end

    // -- completion / write port ---------------------------------------------------
    if (check_wb_port) begin
      if (!t.is_branch() && !t.ex_valid) begin
        ok = 0;
        `uvm_error("SB_ALU_WB", {"non-branch instruction left EX without ex_valid | ", t.convert2string()})
      end
      if (t.is_branch() != t.branch_in_ex) begin
        ok = 0;
        `uvm_error("SB_ALU_WB", $sformatf("branch_in_ex=%0b for operator %s | %s", t.branch_in_ex, t.op.name(), t.convert2string()))
      end
      if (t.we && !t.ex_valid) begin
        ok = 0;
        `uvm_error("SB_ALU_WB", {"rf_alu_we asserted in a cycle that leaves EX without ex_valid | ", t.convert2string()})
      end
      if (t.we) begin
        if (t.wdata !== t.result) begin
          ok = 0;
          `uvm_error("SB_ALU_WB", $sformatf("rf_alu_wdata (0x%08h) != alu_result (0x%08h) - EX result mux | %s", t.wdata, t.result, t.convert2string()))
        end
        if (t.waddr[5] !== 1'b0) begin
          ok = 0;
          `uvm_error("SB_ALU_WB", {"rf_alu_waddr[5]=1 (FP register file selected) in an RV32IM configuration | ", t.convert2string()})
        end
      end
    end

    // -- misaligned second pass (ID re-issues addr + 4 through the ALU) ------------------
    if (t.misaligned_2nd && ((t.op != ALU_ADD) || (t.b != 32'd4) || !t.lsu_en || t.we)) begin
      ok = 0;
      `uvm_error("SB_ALU_WB", {"misaligned 2nd pass must be ADD(first address, 4) with lsu_en=1 and no RF write | ", t.convert2string()})
    end

    // -- tag / decoder consistency ----------------------------------------------------
    if (check_tag && t.tag_valid) begin
      e = t.expect_of_tag();
      if (!e.in_scope) begin
        ok = 0;
        `uvm_error("SB_ALU_TAG", $sformatf("tagged word 0x%08h @0x%08h is not an RV32IM instruction | %s", t.instr, t.pc, t.convert2string()))
      end else if (!e.alu_en) begin
        ok = 0;
        `uvm_error("SB_ALU_TAG", $sformatf("tagged word 0x%08h @0x%08h is a multiplier instruction - issue/EX tracking out of sync | %s", t.instr, t.pc, t.convert2string()))
      end else begin
        if (e.op != t.op) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("decoder/EX mismatch: instruction 0x%08h expects %s, EX executed %s | %s", t.instr, e.op.name(), t.op.name(), t.convert2string()))
        end
        if (e.is_lsu != t.lsu_en) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("decoder/EX mismatch: instruction 0x%08h is_lsu=%0b but data_req_ex=%0b | %s", t.instr, e.is_lsu, t.lsu_en, t.convert2string()))
        end
        if (check_wb_port && t.ex_valid && (t.we != e.we)) begin
          ok = 0;
          `uvm_error("SB_ALU_WB", $sformatf("rf_alu_we=%0b, instruction 0x%08h expects %0b | %s", t.we, t.instr, e.we, t.convert2string()))
        end
        if (check_wb_port && t.we && (t.rd() != e.rd)) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("write-port rd x%0d != instruction rd x%0d | %s", t.rd(), e.rd, t.convert2string()))
        end
        if (e.is_lui && (t.result != instr_imm_u(t.instr))) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("LUI result 0x%08h != imm_u 0x%08h | %s", t.result, instr_imm_u(t.instr), t.convert2string()))
        end
        if (e.is_auipc && (t.result != t.pc + instr_imm_u(t.instr))) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("AUIPC result 0x%08h != pc + imm_u 0x%08h | %s", t.result, t.pc + instr_imm_u(t.instr), t.convert2string()))
        end
        if (e.is_jump && ((t.a != t.pc) || (t.b != 32'd4) || (t.result != t.pc + 32'd4))) begin
          ok = 0;
          `uvm_error("SB_ALU_TAG", $sformatf("JAL/JALR link value: a=0x%08h b=0x%08h res=0x%08h, pc=0x%08h | %s", t.a, t.b, t.result, t.pc, t.convert2string()))
        end
      end
    end

    if (!ok) n_alu_err++;
    else `uvm_info("SB_ALU", {"OK ", t.convert2string()}, UVM_HIGH)
  endfunction

  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    string s;
    super.report_phase(phase);
    s = $sformatf("MUL side: %0d transactions checked, %0d with errors, %0d killed by reset, max external stall %0d cycles\n",
                  n_mul_txn, n_mul_err, n_mul_killed, max_stall_cycles);
    foreach (n_per_op[op]) s = {s, $sformatf("    %-6s : %0d\n", op.name(), n_per_op[op])};
    s = {s, $sformatf("ALU side: %0d transactions checked, %0d with errors, %0d killed by reset, max external stall %0d cycles\n",
                      n_alu_txn, n_alu_err, n_alu_killed, max_alu_stall_cycles)};
    foreach (n_alu_per_op[op]) s = {s, $sformatf("    %-9s : %0d\n", op.name(), n_alu_per_op[op])};
    s = {s, "    divider latency histogram (net cycles:count):"};
    for (int i = DIV_LATENCY_MIN; i <= DIV_LATENCY_MAX; i++) if (n_div_lat[i] != 0) s = {s, $sformatf(" %0d:%0d", i, n_div_lat[i])};
    s = {s, "\n"};
    `uvm_info("SB_ALU_MUL", s, UVM_LOW)
    if (n_mul_txn == 0)
      `uvm_warning("SB_ALU_MUL", "no MUL-unit instruction was observed in this test")
    if (n_alu_txn == 0)
      `uvm_warning("SB_ALU_MUL", "no ALU instruction was observed in this test")
  endfunction

endclass : alu_mul_scoreboard
