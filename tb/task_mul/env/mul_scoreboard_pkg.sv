// =============================================================================
// mul_scoreboard_pkg.sv   (part of the MUL task deliverable — tb/task_mul/)
// -----------------------------------------------------------------------------
// MUL-ONLY scoreboard: the "MUL side" portion of tb/env/alu_mul_scoreboard.sv
// extracted into its own package so the MUL task stands alone (the team merges
// everyone's parts later into the integrated alu_mul_scoreboard).
//
// Checks (same contract as the integrated scoreboard — vplan risc_m_00/01,
// risc_dec_01).  لكل فحص هنا سبب من الـ ISA/الداتا بوك مش مجرد رقم عشوائي:
//
//   SB_MUL_RESULT   result == rv32m_ref(op, rs1, rs2)      (golden model)
//       السبب: الـ ISA بيحدد بدقة النتيجة (MUL = low 32 لجدوبة rs1*rs2،
//       MULH/MULHSU/MULHU = الـ upper 32 بطرق التوقيع المختلفة) — لو الداتا
//       بوك رجّع أي حاجة تانية يبقى في bug في حساب المضاعف نفسه.
//
//   SB_MUL_LATENCY  mult_cycles == 1 (MUL) / 5 (MULH*) net of external
//                   stalls; multicycle window == 0 / 3
//       السبب: ده جدول الداتا بوك نفسه (pipeline.rst: "1 (mul)",
//       "5 (mulh, mulhsu, mulhu)") — اللااتنسية جزء من المواصفة، مش أداء.
//       الـ "net of external stalls" عشان LSU/WB ماسكين EX مالهمش علاقة
//       بسرعة المضاعف، ونافذة mult_multicycle (3 دورات) هي الـ FSM بتاع
//       MULH اللي بيقول لـ ID "سيبلي operand_c ثابت".
//
//   SB_MUL_WB       rf_alu_we == 1, rf_alu_wdata == mult_result,
//                   rf_alu_waddr[5] == 0
//       السبب: النتيجة مفيدها لوحدها لو وصلت الريجستر فايل صح — الداتا بوك
//       بيقول الكتابة بتحصل من EX مباشرة، فلازم في نفس دورة ex_valid:
//       we=1، والـ mux يوصل mult_result لـ wdata، ومفيش FP file في
//       RV32IM (waddr[5] لازم 0).
//
//   SB_MUL_TAG      tagged instruction word = RV32M encoding whose funct3
//                   matches the executed op and whose rd matches waddr
//       السبب: بينصحح pipeline desync — تعليمة اتفرّعت من ID لازم تكون
//       هي نفسها اللي نفّذها EX (نفس funct3 → نفس op، ونفس rd → نفس
//       الريجستر اللي اتكتب). أي mismatch = الـ decode/forwarding اتلخبط.
//
// Compile after: uvm_pkg, cv32e40p_pkg, rv32m_ref_pkg, mul_agent_pkg
// =============================================================================
package mul_scoreboard_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import mul_agent_pkg::*;

  class mul_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mul_scoreboard)

    // Single input port: the MUL agent calls write(mul_txn) for every
    // transaction it publishes on its analysis port.
    uvm_analysis_imp #(mul_txn, mul_scoreboard) mul_imp;

    // ---- knobs: which check groups are active -------------------------------
    // (set from the test/env via uvm_config_db, default = everything ON)
    bit check_result  = 1;   // compare results against the golden model
    bit check_latency = 1;   // compare cycle counts (1/5 net of stalls)
    bit check_wb_port = 1;   // check register-file write port behaviour
    bit check_tag     = 1;   // cross-check tagged instruction word vs execution

    // ---- statistics (printed in report_phase) -------------------------------
    int unsigned n_mul_txn;              // transactions checked
    int unsigned n_mul_killed;           // transactions killed by reset
    int unsigned n_mul_err;              // transactions with >=1 error
    int unsigned n_per_op [rv32m_op_e];  // per-opcode counter (MUL, MULH, ...)
    int unsigned max_stall_cycles;       // biggest external stall seen

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mul_imp = new("mul_imp", this);   // without new() the port stays null
      void'(uvm_config_db#(bit)::get(this, "", "check_result",  check_result));
      void'(uvm_config_db#(bit)::get(this, "", "check_latency", check_latency));
      void'(uvm_config_db#(bit)::get(this, "", "check_wb_port", check_wb_port));
      void'(uvm_config_db#(bit)::get(this, "", "check_tag",     check_tag));
    endfunction

    // ---------------------------------------------------------------------------
    // write: called by the MUL agent for every mul_txn it publishes.
    // "ok" tracks whether this transaction passed all checks (for the counter).
    // (Body kept byte-equivalent to write_mul() of alu_mul_scoreboard.sv.)
    // ---------------------------------------------------------------------------
    virtual function void write(mul_txn t);
      bit ok = 1;                 // start optimistic: assume the txn is good

      // Reset-killed transactions never completed - nothing to check, just count.
      if (t.killed_by_reset) begin
        n_mul_killed++;
        `uvm_info("SB_MUL", {"ignored (killed by reset): ", t.convert2string()}, UVM_MEDIUM)
        return;                   // leave without checking
      end

      n_mul_txn++;                                 // statistics...
      n_per_op[t.op]++;
      if (t.stall_cycles > max_stall_cycles) max_stall_cycles = t.stall_cycles;

      // -- CHECK 1: the result equals the golden model ------------------------
      // exp_result() = rv32m_ref(op, rs1, rs2) from rv32m_ref_pkg.
      if (check_result && (t.result !== t.exp_result())) begin
        ok = 0;
        `uvm_error(t.is_mulh() ? "SB_MULH_RESULT" : "SB_MUL_RESULT",
                   $sformatf("%s result mismatch: got 0x%08h expected 0x%08h | %s",
                             t.op.name(), t.result, t.exp_result(), t.convert2string()))
      end

      // -- CHECK 2: the register-file write port behaved correctly ------------
      //   we   must be 1 in the ex_valid cycle,
      //   wdata must equal the multiplier result (EX result mux is right),
      //   waddr[5] must be 0 (FP register file does not exist in RV32IM).
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

      // -- CHECK 3: timing ------------------------------------------------------
      // mult_cycles (total minus external stalls) must be 1 for MUL / 5 for MULH*,
      // and the mult_multicycle window must be 0 for MUL / 3 for MULH*.
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

      // -- CHECK 4: the tagged instruction word matches what EX executed -------
      // The tag comes from the ID stage one cycle before EX. It must be a real
      // RV32M encoding, its funct3 must decode to the executed op, and its rd
      // field must equal the address the DUT wrote.
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

      // Bookkeeping: any failed check above set ok=0 -> count an error here.
      if (!ok) n_mul_err++;
      else `uvm_info("SB_MUL", {"OK ", t.convert2string()}, UVM_HIGH)  // per-txn OK line
    endfunction

    // ---------------------------------------------------------------------------
    // report_phase: end-of-simulation summary - counters per opcode, and a
    // warning if the unit saw NO traffic (coverage hole / plumbing broken).
    // ---------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
      string s;
      super.report_phase(phase);
      s = $sformatf("MUL side: %0d transactions checked, %0d with errors, %0d killed by reset, max external stall %0d cycles\n",
                    n_mul_txn, n_mul_err, n_mul_killed, max_stall_cycles);
      foreach (n_per_op[op]) s = {s, $sformatf("    %-6s : %0d\n", op.name(), n_per_op[op])};
      `uvm_info("SB_MUL", s, UVM_LOW)
      if (n_mul_txn == 0)
        `uvm_warning("SB_MUL", "no MUL-unit instruction was observed in this test")
    endfunction

  endclass : mul_scoreboard

endpackage : mul_scoreboard_pkg
