// =============================================================================
// alu_smoke_checker.sv
// -----------------------------------------------------------------------------
// Plain-SystemVerilog twin of alu_monitor + the ALU side of alu_mul_scoreboard
// (tb/agents/alu_agent, tb/env/alu_mul_scoreboard.sv), used by tb_smoke.sv to
// validate the reconstruction algorithm, alu_ref_pkg and the divider latency
// model against the real RTL with Verilator.
//
// Algorithm (keep identical to alu_monitor.sv):
//   issue   : id_valid && is_decoding in cycle N  => the ID instruction is in
//             EX in cycle N+1 (tag pc/instr). Valid for exactly one cycle.
//   start   : alu_en && !in_flight
//               with an issue in the previous cycle -> new instruction
//               without, data_misaligned_ex=1       -> 2nd half of a misaligned
//               load/store: ID re-loads the ALU with a = first address (EX
//               forward), b = 4, we = 0, no issue pulse (id_valid=0 during the
//               misaligned stall) -> a transaction flagged misaligned_2nd that
//               inherits the tag of the first half
//               without, otherwise                  -> must be a pipeline
//               bubble (rtl/cv32e40p_id_stage.sv loads alu_en=1,
//               alu_operator=ALU_SLTU, regfile_alu_we=0 when EX is ready and
//               ID has nothing) -> counted, not a transaction
//   progress: total++, stall++ when alu_ready && !ex_ready (EX held by LSU/WB)
//   finish  : ex_ready (the instruction leaves EX). ex_valid == ex_ready except
//             for branches (branch_in_ex forces ex_ready while ex_valid may be
//             0 when WB is not ready) -> check result / latency / write port /
//             decoder expectations from the tagged instruction word.
//   reset   : in-flight instruction dropped (killed_by_reset)
// =============================================================================
module alu_smoke_checker
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
(
  alu_mul_if vif,
  input bit  verbose
);

  // statistics visible to the top
  int unsigned n_txn, n_err, n_killed, n_bubbles;
  int unsigned n_cls [7];              // by alu_op_class_e
  int unsigned n_div, n_div_stalled, div_lat_min = 99, div_lat_max = 0;
  int unsigned n_div_lat [36];         // histogram of net divider latency
  int unsigned n_branch, n_branch_taken, n_branch_no_valid;
  int unsigned n_stalled, max_stall;
  int unsigned n_misaligned_2nd, n_lsu;

  // state
  bit           in_flight;
  alu_opcode_e  op;
  bit [31:0]    a, b;
  int unsigned  total, stall;
  bit           issued_prev;           // issue pulse seen in the previous cycle
  bit [31:0]    tag_pc, tag_instr;
  bit           cur_tag_valid;
  bit [31:0]    cur_pc, cur_instr;
  alu_expect_t  cur_exp;
  bit           cur_misaligned_2nd;
  bit [31:0]    last_result;          // result of the previous transaction (misaligned 1st half address)
  int unsigned  cycle_cnt;

  task automatic err(input string msg);
    n_err++;
    $display("[%0t] ALU_CHECK ERROR: %s", $time, msg);
  endtask

  bit trace;
  initial trace = $test$plusargs("trace_alu");

  always @(posedge vif.clk) begin
    cycle_cnt++;
    if (trace && vif.rst_n)
      $display("[%0t] TRACE alu_en=%0b %-9s a=%08h b=%08h res=%08h rdy=%0b | mult_en=%0b | ex_ready=%0b ex_valid=%0b lsu_rdy=%0b wb_rdy=%0b br=%0b lsu_en=%0b misal=%0b | we=%0b x%0d | issue=%0b%0b pc_id=%08h",
               $time, vif.alu_en, vif.alu_operator.name(), vif.alu_operand_a, vif.alu_operand_b, vif.alu_result, vif.alu_ready, vif.mult_en,
               vif.ex_ready, vif.ex_valid, vif.lsu_ready_ex, vif.wb_ready, vif.branch_in_ex, vif.lsu_en, vif.data_misaligned_ex,
               vif.rf_alu_we, vif.rf_alu_waddr[4:0], vif.id_valid, vif.is_decoding, vif.pc_id);
    if (!vif.rst_n) begin
      if (in_flight) begin
        n_killed++;
        $display("[%0t] ALU_CHECK: %s killed by reset after %0d cycles", $time, op.name(), total);
      end
      in_flight   = 0;
      issued_prev = 0;
    end else begin
      // ---- 1. start ---------------------------------------------------------------
      if (!in_flight && vif.alu_en) begin
        if (issued_prev || vif.data_misaligned_ex) begin
          op            = vif.alu_operator;
          a             = vif.alu_operand_a;
          b             = vif.alu_operand_b;
          total         = 0; stall = 0;
          cur_misaligned_2nd = !issued_prev;
          if (issued_prev) begin
            cur_tag_valid = 1;
            cur_pc        = tag_pc;
            cur_instr     = tag_instr;
            cur_exp       = alu_expect_of_instr(tag_instr);
          end
          // else: 2nd half keeps cur_tag_valid / cur_pc / cur_instr / cur_exp of the 1st half
          in_flight     = 1;
          if (cur_misaligned_2nd) begin
            n_misaligned_2nd++;
            if (op != ALU_ADD || b != 32'd4 || a != last_result || !vif.lsu_en || vif.rf_alu_we || !cur_exp.is_lsu)
              err($sformatf("misaligned 2nd half malformed: %s a=0x%08h (1st addr 0x%08h) b=0x%08h lsu_en=%0b we=%0b prev_is_lsu=%0b",
                            op.name(), a, last_result, b, vif.lsu_en, vif.rf_alu_we, cur_exp.is_lsu));
          end
          if (issued_prev && vif.data_misaligned_ex) err("data_misaligned_ex together with an issued instruction");
          if (!alu_op_in_scope(op))
            err($sformatf("operator %s not producible by the RV32IM decoder (pc 0x%08h instr 0x%08h)", op.name(), cur_pc, cur_instr));
          if (vif.mult_en) err("alu_en together with mult_en");
          if (is_div_operator(op) && vif.alu_ready)  err("divider ready in the first cycle of a DIV/REM");
          if (!is_div_operator(op) && !vif.alu_ready) err("alu_ready low for a single-cycle ALU operator");
          if (!cur_exp.in_scope)
            err($sformatf("tagged instruction 0x%08h @0x%08h is not in the RV32IM subset", cur_instr, cur_pc));
          else if (cur_exp.is_lsu != vif.lsu_en)
            err($sformatf("lsu_en=%0b but instruction 0x%08h @0x%08h is_lsu=%0b", vif.lsu_en, cur_instr, cur_pc, cur_exp.is_lsu));
          if (!cur_exp.in_scope) ;
          else if (!cur_exp.alu_en)
            err($sformatf("tagged instruction 0x%08h @0x%08h should not use the ALU (multiplier op) - tag out of sync?", cur_instr, cur_pc));
          else if (cur_exp.op != op)
            err($sformatf("decoder: instruction 0x%08h @0x%08h expects %s, EX executes %s", cur_instr, cur_pc, cur_exp.op.name(), op.name()));
        end else begin
          // no instruction was issued into EX: must be the bubble pattern
          if ((vif.alu_operator != ALU_SLTU) || vif.rf_alu_we || vif.branch_in_ex)
            err($sformatf("ALU activity without an issued instruction: %s we=%0b", vif.alu_operator.name(), vif.rf_alu_we));
          else
            n_bubbles++;
        end
      end else if (!in_flight && issued_prev && !vif.alu_en && !vif.mult_en) begin
        err($sformatf("issued instruction 0x%08h @0x%08h uses neither ALU nor multiplier", tag_instr, tag_pc));
      end

      // ---- 2. progress / finish -------------------------------------------------------
      if (in_flight) begin
        total++;
        if (vif.alu_ready && !vif.ex_ready) stall++;
        if (!vif.alu_en)                    err("alu_en dropped before the instruction left EX");
        if (vif.alu_operand_a != a || vif.alu_operand_b != b) err("ALU operands changed while in EX");
        if (vif.alu_operator != op)         err("alu_operator changed while in EX");
        if (!vif.alu_ready && vif.ex_ready) err("ex_ready while the divider is busy");
        if (!vif.alu_ready && vif.ex_valid) err("ex_valid while the divider is busy");

        if (vif.ex_ready) begin
          bit [31:0]   exp_res, res;
          bit          exp_cmp;
          int unsigned alu_cycles, exp_cycles;
          alu_op_class_e cls;
          res        = vif.alu_result;
          exp_res    = alu_ref(op, a, b);
          exp_cmp    = alu_cmp_ref(op, a, b);
          cls        = alu_op_class(op);
          alu_cycles = total - stall;
          exp_cycles = is_div_operator(op) ? div_latency_ref(op, a) : ALU_LATENCY;
          n_txn++; n_cls[cls]++;
          if (vif.lsu_en) n_lsu++;
          if (stall > 0) n_stalled++;
          if (stall > max_stall) max_stall = stall;

          // result (raw operands -> unit function)
          if (alu_op_in_scope(op) && (res !== exp_res))
            err($sformatf("%s result 0x%08h expected 0x%08h (a=0x%08h b=0x%08h) pc=0x%08h", op.name(), res, exp_res, a, b, cur_pc));
          if (is_branch_operator(op) && (vif.alu_cmp_result !== exp_cmp))
            err($sformatf("%s branch decision %0b expected %0b (a=0x%08h b=0x%08h)", op.name(), vif.alu_cmp_result, exp_cmp, a, b));

          // latency
          if (alu_cycles != exp_cycles)
            err($sformatf("%s latency %0d (total %0d stall %0d) expected %0d (a=0x%08h b=0x%08h)", op.name(), alu_cycles, total, stall, exp_cycles, a, b));
          if (is_div_operator(op)) begin
            n_div++;
            if (stall > 0) n_div_stalled++;
            if (alu_cycles < div_lat_min) div_lat_min = alu_cycles;
            if (alu_cycles > div_lat_max) div_lat_max = alu_cycles;
            if (alu_cycles <= 35) n_div_lat[alu_cycles]++;
          end

          // completion / write port
          if (is_branch_operator(op)) begin
            n_branch++;
            if (vif.alu_cmp_result) n_branch_taken++;
            if (!vif.ex_valid) n_branch_no_valid++;
            if (!vif.branch_in_ex) err("branch operator without branch_in_ex");
          end else begin
            if (!vif.ex_valid) err($sformatf("%s left EX (ex_ready) without ex_valid", op.name()));
            if (vif.branch_in_ex) err("branch_in_ex for a non-branch operator");
          end
          if (vif.ex_valid) begin
            if (cur_exp.in_scope && cur_exp.alu_en && (vif.rf_alu_we != cur_exp.we))
              err($sformatf("rf_alu_we=%0b expected %0b for instruction 0x%08h @0x%08h", vif.rf_alu_we, cur_exp.we, cur_instr, cur_pc));
            if (vif.rf_alu_we) begin
              if (vif.rf_alu_wdata != res) err("rf_alu_wdata != alu_result");
              if (vif.rf_alu_waddr[5])     err("rf_alu_waddr[5] set");
              if (cur_exp.in_scope && (vif.rf_alu_waddr[4:0] != cur_exp.rd))
                err($sformatf("write port rd x%0d != instruction rd x%0d", vif.rf_alu_waddr[4:0], cur_exp.rd));
            end
          end else if (vif.rf_alu_we) begin
            err("rf_alu_we asserted in a cycle that leaves EX without ex_valid");
          end

          // operand sourcing checks that do not need a register model
          if (cur_exp.in_scope) begin
            if (cur_exp.is_lui   && (res != instr_imm_u(cur_instr)))
              err($sformatf("LUI result 0x%08h != imm_u 0x%08h", res, instr_imm_u(cur_instr)));
            if (cur_exp.is_auipc && (res != cur_pc + instr_imm_u(cur_instr)))
              err($sformatf("AUIPC result 0x%08h != pc+imm_u 0x%08h", res, cur_pc + instr_imm_u(cur_instr)));
            if (cur_exp.is_jump  && ((a != cur_pc) || (b != 32'd4) || (res != cur_pc + 32'd4)))
              err($sformatf("JAL/JALR link: a=0x%08h b=0x%08h res=0x%08h pc=0x%08h", a, b, res, cur_pc));
          end

          if (verbose)
            $display("[%0t] ALU_CHECK %-9s pc=0x%08h a=0x%08h b=0x%08h -> 0x%08h we=%0b x%0d | tot=%0d stall=%0d net=%0d%s%s",
                     $time, op.name(), cur_pc, a, b, res, vif.rf_alu_we, vif.rf_alu_waddr[4:0], total, stall, alu_cycles,
                     vif.ex_valid ? "" : " (no ex_valid)", cur_misaligned_2nd ? " (misaligned 2nd half)" : "");
          last_result = res;
          in_flight = 0;
        end else if (total > 128) begin
          err("instruction stuck in EX");
          in_flight = 0;
        end
      end

      // ---- 3. issue pulse of this cycle (belongs to the NEXT EX instruction) -----------
      issued_prev = (vif.id_valid && vif.is_decoding);
      if (issued_prev) begin
        tag_pc    = vif.pc_id;
        tag_instr = vif.instr_id;
      end
    end
  end

endmodule : alu_smoke_checker
