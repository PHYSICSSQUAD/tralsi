// =============================================================================
// mini_plain_tb.sv  (top module of the PLAIN mini bench — tb/mini/)
// -----------------------------------------------------------------------------
// WHAT THIS FILE IS:
//   The NO-UVM twin of mini_tb.sv.  Same clock/wires/interface/mini_dut
//   wiring, but instead of the UVM agents + scoreboard it instantiates the
//   plain-SV checkers that the big smoke bench uses (mul_smoke_checker +
//   alu_smoke_checker — the RTL-validated twins of the UVM monitors):
//
//     mini_dut  ──drives──►  alu_mul_if  ──sensed by──►  both checkers
//
//   So the SAME checking logic runs twice in the project: class-based UVM
//   (mini_tb.sv) and procedural plain SV (this file) — one of each to watch
//   before integrating with the real cv32e40p core.
//
//   Plusargs (defaults set by run_mini_plain.sh):
//     +mini_prog=simple   only the 3 instructions in mini_dut (default here)
//     +mini_prog=full     the complete directed scenario
//     +verbose            per-instruction print from the MUL checker
//     +verbose_alu        per-instruction print from the ALU checker
//     +vcd                dump mini_plain.vcd (needs Verilator --trace)
//
// END-OF-TEST CONTRACT (mirrors tb_smoke / mini_tb):
//   MINI_PLAIN TEST PASSED requires
//     - mul checker saw >=1 transaction and 0 errors, and
//     - alu checker saw >=1 transaction and 0 errors.
// =============================================================================
`timescale 1ns/1ps

module mini_plain_tb;
  import cv32e40p_pkg::*;        // alu_opcode_e / mul_opcode_e for the wires

  // ---------------------------------------------------------------------------
  // 1. Clock — free-running, 10 ns period (same style as mini_tb).
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 2. Wires + shared interface + behavioural core — identical wiring to
  //    mini_tb.sv so both tops observe EXACTLY the same signals.
  // ---------------------------------------------------------------------------
  logic        rst_n;
  logic        ex_ready, ex_valid, lsu_ready_ex, wb_ready;
  logic        branch_in_ex, lsu_en, data_misaligned_ex;
  logic        alu_en, alu_cmp_result, alu_ready;
  alu_opcode_e alu_operator;
  logic [31:0] alu_operand_a, alu_operand_b, alu_operand_c, alu_result;
  logic        mult_en, mult_sel_subword, mult_ready, mult_multicycle, mulh_active;
  mul_opcode_e mult_operator;
  logic [ 1:0] mult_signed_mode;
  logic [31:0] mult_operand_a, mult_operand_b, mult_operand_c, mult_result;
  logic [ 4:0] mult_imm;
  logic        rf_alu_we;
  logic [ 5:0] rf_alu_waddr;
  logic [31:0] rf_alu_wdata;
  logic        id_valid, is_decoding;
  logic [31:0] pc_id, instr_id;
  logic        scenario_done;

  alu_mul_if vif (
    .clk                (clk),
    .rst_n              (rst_n),
    .ex_ready           (ex_ready),
    .ex_valid           (ex_valid),
    .lsu_ready_ex       (lsu_ready_ex),
    .wb_ready           (wb_ready),
    .branch_in_ex       (branch_in_ex),
    .lsu_en             (lsu_en),
    .data_misaligned_ex (data_misaligned_ex),
    .alu_en             (alu_en),
    .alu_operator       (alu_operator),
    .alu_operand_a      (alu_operand_a),
    .alu_operand_b      (alu_operand_b),
    .alu_operand_c      (alu_operand_c),
    .alu_result         (alu_result),
    .alu_cmp_result     (alu_cmp_result),
    .alu_ready          (alu_ready),
    .mult_en            (mult_en),
    .mult_operator      (mult_operator),
    .mult_signed_mode   (mult_signed_mode),
    .mult_operand_a     (mult_operand_a),
    .mult_operand_b     (mult_operand_b),
    .mult_operand_c     (mult_operand_c),
    .mult_sel_subword   (mult_sel_subword),
    .mult_imm           (mult_imm),
    .mult_result        (mult_result),
    .mult_ready         (mult_ready),
    .mult_multicycle    (mult_multicycle),
    .mulh_active        (mulh_active),
    .rf_alu_we          (rf_alu_we),
    .rf_alu_waddr       (rf_alu_waddr),
    .rf_alu_wdata       (rf_alu_wdata),
    .id_valid           (id_valid),
    .is_decoding        (is_decoding),
    .pc_id              (pc_id),
    .instr_id           (instr_id)
  );

  mini_dut dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .ex_ready           (ex_ready),
    .ex_valid           (ex_valid),
    .lsu_ready_ex       (lsu_ready_ex),
    .wb_ready           (wb_ready),
    .branch_in_ex       (branch_in_ex),
    .lsu_en             (lsu_en),
    .data_misaligned_ex (data_misaligned_ex),
    .alu_en             (alu_en),
    .alu_operator       (alu_operator),
    .alu_operand_a      (alu_operand_a),
    .alu_operand_b      (alu_operand_b),
    .alu_operand_c      (alu_operand_c),
    .alu_result         (alu_result),
    .alu_cmp_result     (alu_cmp_result),
    .alu_ready          (alu_ready),
    .mult_en            (mult_en),
    .mult_operator      (mult_operator),
    .mult_signed_mode   (mult_signed_mode),
    .mult_operand_a     (mult_operand_a),
    .mult_operand_b     (mult_operand_b),
    .mult_operand_c     (mult_operand_c),
    .mult_sel_subword   (mult_sel_subword),
    .mult_imm           (mult_imm),
    .mult_result        (mult_result),
    .mult_ready         (mult_ready),
    .mult_multicycle    (mult_multicycle),
    .mulh_active        (mulh_active),
    .rf_alu_we          (rf_alu_we),
    .rf_alu_waddr       (rf_alu_waddr),
    .rf_alu_wdata       (rf_alu_wdata),
    .id_valid           (id_valid),
    .is_decoding        (is_decoding),
    .pc_id              (pc_id),
    .instr_id           (instr_id),
    .scenario_done      (scenario_done)
  );

  // ---------------------------------------------------------------------------
  // 3. The SAME plain-SV checkers the big RTL smoke bench uses — this is the
  //    whole point of this top: identical checking logic, no UVM anywhere.
  // ---------------------------------------------------------------------------
  bit verbose, verbose_alu;
  mul_smoke_checker chk  (.vif(vif), .verbose(verbose));
  alu_smoke_checker achk (.vif(vif), .verbose(verbose_alu));

  initial begin
    verbose     = $test$plusargs("verbose");
    verbose_alu = $test$plusargs("verbose_alu");
    if ($test$plusargs("vcd")) begin
      $dumpfile("mini_plain.vcd");
      $dumpvars(0, mini_plain_tb);
    end
  end

  // ---------------------------------------------------------------------------
  // 4. Scenario finished -> wait a few cycles for the last publications, then
  //    print the summary and the verdict (contract same as mini_tb/smoke).
  // ---------------------------------------------------------------------------
  int unsigned n_errors;

  initial begin
    wait (scenario_done === 1'b1);
    repeat (5) @(posedge clk);

    n_errors = chk.n_err + achk.n_err;
    $display("MINI_PLAIN: MUL checker: %0d transactions (MUL %0d, MULH* %0d), %0d errors",
             chk.n_txn, chk.n_mul, chk.n_mulh, chk.n_err);
    $display("MINI_PLAIN: ALU checker: %0d transactions (%0d bubbles), %0d errors",
             achk.n_txn, achk.n_bubbles, achk.n_err);
    if (n_errors == 0 && chk.n_txn > 0 && achk.n_txn > 0)
      $display("MINI_PLAIN TEST PASSED");
    else
      $display("MINI_PLAIN TEST FAILED (%0d errors, mul_txn=%0d alu_txn=%0d)",
               n_errors, chk.n_txn, achk.n_txn);
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Watchdog — the full scenario is a few hundred cycles; 5000 is a margin.
  // ---------------------------------------------------------------------------
  initial begin
    repeat (5000) @(posedge clk);
    $display("MINI_PLAIN_WATCHDOG: scenario_done=%b", scenario_done);
    $fatal(1, "mini plain bench watchdog expired");
  end

endmodule : mini_plain_tb
