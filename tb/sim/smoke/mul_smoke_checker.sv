// =============================================================================
// mul_smoke_checker.sv
// -----------------------------------------------------------------------------
// Plain-SystemVerilog twin of mul_monitor + the MUL side of alu_mul_scoreboard,
// used by the non-UVM smoke test (tb_smoke.sv) to validate the transaction
// reconstruction algorithm, the reference functions and the latency model
// against the real RTL with Verilator.
//
// Keep the algorithm identical to tb/agents/mul_agent/mul_monitor.sv:
//   start    : mult_en && !in_flight
//   progress : total++, stall++ if (mult_ready && !ex_valid), mc++ if mult_multicycle
//   finish   : ex_valid -> check result / write port / latency / tag
// Sampling: always @(posedge clk) reads the values the DUT held during the
// cycle that ends at this edge (same as the #1step clocking block).
// =============================================================================
module mul_smoke_checker
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
(
  alu_mul_if vif,
  input bit  verbose
);

  localparam int unsigned MUL_LATENCY         = 1;
  localparam int unsigned MULH_LATENCY        = 5;
  localparam int unsigned MULH_MULTICYCLE_LEN = 3;

  // statistics visible to the top
  int unsigned n_txn, n_err, n_mul, n_mulh, n_stalled, max_stall, n_killed;
  int unsigned n_op [8];

  // state
  bit          in_flight;
  rv32m_op_e   op;
  bit [31:0]   a, b, op_c0;
  int unsigned total, stall, mc, cyc_start;
  bit          tag_valid, cur_tag_valid;
  bit [31:0]   tag_pc, tag_instr, cur_pc, cur_instr;
  int unsigned cycle_cnt;

  function automatic bit decode_ctrl(input mul_opcode_e operator, input logic [1:0] sm, output rv32m_op_e o);
    o = MUL;
    case (operator)
      MUL_MAC32: begin o = MUL; return 1; end
      MUL_H: case (sm)
        2'b11: begin o = MULH;   return 1; end
        2'b01: begin o = MULHSU; return 1; end
        2'b00: begin o = MULHU;  return 1; end
        default: return 0;
      endcase
      default: return 0;
    endcase
  endfunction

  task automatic err(input string msg);
    n_err++;
    $display("[%0t] MUL_CHECK ERROR: %s", $time, msg);
  endtask

  always @(posedge vif.clk) begin
    cycle_cnt++;
    if (!vif.rst_n) begin
      if (in_flight) begin
        n_killed++;
        $display("[%0t] MUL_CHECK: %s killed by reset after %0d cycles", $time, op.name(), total);
      end
      in_flight = 0;
      tag_valid = 0;
    end else begin
      // ---- 1. start ---------------------------------------------------------------
      if (!in_flight && vif.mult_en) begin
        rv32m_op_e o;
        if (!decode_ctrl(vif.mult_operator, vif.mult_signed_mode, o))
          err($sformatf("illegal operator/sign mode %s/%0b", vif.mult_operator.name(), vif.mult_signed_mode));
        op            = o;
        a             = vif.mult_operand_a;
        b             = vif.mult_operand_b;
        op_c0         = vif.mult_operand_c;
        total         = 0; stall = 0; mc = 0;
        cyc_start     = cycle_cnt;
        cur_tag_valid = tag_valid;
        cur_pc        = tag_pc;
        cur_instr     = tag_instr;
        in_flight     = 1;
        if (vif.alu_en)                 err("alu_en together with mult_en");
        if (vif.mult_sel_subword || vif.mult_imm != 0) err("PULP multiplier controls active");
        if (op_c0 != 0)                 err($sformatf("mult_operand_c != 0 at start (0x%08h)", op_c0));
        if (cur_tag_valid && !is_rv32m_instr(cur_instr))
          err($sformatf("tag out of sync: instr 0x%08h @0x%08h is not RV32M", cur_instr, cur_pc));
      end

      // ---- 2. progress / finish -------------------------------------------------------
      if (in_flight) begin
        total++;
        if (vif.mult_ready && !vif.ex_valid) stall++;
        if (vif.mult_multicycle)             mc++;
        if (!vif.mult_en)                    err("mult_en dropped before ex_valid");
        if (vif.mult_operand_a != a || vif.mult_operand_b != b) err("operands changed while in EX");
        if (!vif.mult_ready && vif.ex_ready) err("ex_ready while mult_ready=0");

        if (vif.ex_valid) begin
          bit [31:0]   exp_res, res;
          int unsigned mult_cycles, exp_cycles, exp_mc;
          res         = vif.mult_result;
          exp_res     = rv32m_ref(op, a, b);
          mult_cycles = total - stall;
          exp_cycles  = (op == MUL) ? MUL_LATENCY : MULH_LATENCY;
          exp_mc      = (op == MUL) ? 0 : MULH_MULTICYCLE_LEN;
          n_txn++; n_op[op]++;
          if (op == MUL) n_mul++; else n_mulh++;
          if (stall > 0) n_stalled++;
          if (stall > max_stall) max_stall = stall;

          if (res != exp_res)
            err($sformatf("%s result 0x%08h expected 0x%08h (a=0x%08h b=0x%08h)", op.name(), res, exp_res, a, b));
          if (!vif.rf_alu_we)              err("rf_alu_we=0 in the ex_valid cycle");
          if (vif.rf_alu_wdata != res)     err("rf_alu_wdata != mult_result");
          if (vif.rf_alu_waddr[5])         err("rf_alu_waddr[5] set");
          if (mult_cycles != exp_cycles)
            err($sformatf("%s latency %0d (total %0d stall %0d) expected %0d", op.name(), mult_cycles, total, stall, exp_cycles));
          if (mc != exp_mc)
            err($sformatf("%s mult_multicycle for %0d cycles expected %0d", op.name(), mc, exp_mc));
          if (cur_tag_valid && is_rv32m_instr(cur_instr)) begin
            if (rv32m_op_of(cur_instr) != op)
              err($sformatf("tag funct3 %s != executed %s", rv32m_op_of(cur_instr).name(), op.name()));
            if (cur_instr[11:7] != vif.rf_alu_waddr[4:0])
              err($sformatf("tag rd x%0d != write port x%0d", cur_instr[11:7], vif.rf_alu_waddr[4:0]));
          end
          if (verbose)
            $display("[%0t] MUL_CHECK %-6s pc=0x%08h a=0x%08h b=0x%08h -> x%0d = 0x%08h | tot=%0d stall=%0d mult=%0d mc=%0d",
                     $time, op.name(), cur_pc, a, b, vif.rf_alu_waddr[4:0], res, total, stall, total - stall, mc);
          in_flight = 0;
        end else if (total > 64) begin
          err("instruction stuck in EX");
          in_flight = 0;
        end
      end

      // ---- 3. issue pulse of this cycle (belongs to the NEXT EX instruction) -----------
      if (vif.id_valid && vif.is_decoding) begin
        tag_valid = 1;
        tag_pc    = vif.pc_id;
        tag_instr = vif.instr_id;
      end
    end
  end

endmodule : mul_smoke_checker
