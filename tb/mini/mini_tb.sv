// =============================================================================
// mini_tb.sv  (top module of the MINI UVM environment — tb/mini/)
// -----------------------------------------------------------------------------
// WHAT THIS FILE IS:
//   The smallest possible top that can run the REAL UVM verification stack
//   (mul_smoke_test from tb/sim/smoke/mul_smoke_uvm_pkg.sv, which builds the
//   real mul_agent + alu_agent + alu_mul_scoreboard + mul_cov + alu_cov):
//
//     1. generates clock + wires,
//     2. instantiates the shared probe interface alu_mul_if on those wires,
//     3. instantiates mini_dut (a behavioural stand-in for the core) which
//        DRIVES the wires with a scripted instruction scenario,
//     4. publishes the interface in the UVM config_db under the SAME key the
//        real registrar in tb/interfaces/alu_mul_bind.sv uses
//        ("alu_mul_vif") — so the agents need zero changes,
//     5. starts run_test("mul_smoke_test"), and
//     6. when the scenario is over, triggers the global uvm_event
//        "smoke_done" that the test waits on (exactly like tb_smoke does).
//
//   Because nothing here is cv32e40p-specific beyond the interface itself,
//   this top runs on ANY simulator that can compile UVM — the point of the
//   mini environment: prove the TB code before integrating with the big RTL.
//
// END-OF-TEST CONTRACT (same as the big smoke bench):
//   mul_smoke_test::report_phase fails the test (UVM_ERROR) unless
//     - the scoreboard saw >=1 MUL transaction and >=1 ALU transaction, and
//     - the scoreboard reported 0 errors.
// =============================================================================
`timescale 1ns/1ps

module mini_tb;
  import uvm_pkg::*;             // run_test, config_db, uvm_event_pool
  import cv32e40p_pkg::*;        // alu_opcode_e / mul_opcode_e for the wires

  // ---------------------------------------------------------------------------
  // 1. Clock — free-running, 10 ns period (same style as tb_smoke).
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 2. Wires — every signal alu_mul_if observes.  mini_dut drives them,
  //    the interface only SENSES them (all its ports are inputs).
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

  // ---------------------------------------------------------------------------
  // 3. The shared interface (#6 ALU_MUL of tb_architecture/arch.jpg), here
  //    instantiated standalone instead of being bound into cv32e40p_core.
  //    Clocking block mon_cb samples on posedge with `input #1step` -> the
  //    mini_dut drives at negedge, values are stable when the monitors look.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 4. The behavioural core: plays a scripted scenario on the wires above.
  // ---------------------------------------------------------------------------
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
  // 5. Start the UVM stack.  The virtual interface goes into the config_db
  //    BEFORE run_test so the agents find it in their build_phase — the same
  //    set() call the registrar at the bottom of alu_mul_bind.sv makes.
  // ---------------------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", vif);
    fork
      run_test("mul_smoke_test");   // builds env+agents+sb+cov, waits on event
    join_none
  end

  // ---------------------------------------------------------------------------
  // 6. Scenario finished -> tell the test (it waits on this global event,
  //    then drops its objection and prints the UVM report — see tb_smoke).
  // ---------------------------------------------------------------------------
  initial begin
    wait (scenario_done === 1'b1);
    repeat (5) @(posedge clk);      // let the last transactions get published
    begin
      uvm_event #(uvm_object) done_ev;
      done_ev = uvm_event_pool::get_global("smoke_done");
      done_ev.trigger();
      $display("MINI_UVM: scenario complete, smoke_done triggered at %0t", $time);
    end
  end

  // ---------------------------------------------------------------------------
  // Watchdog — the scenario is a few hundred cycles; 5000 is a huge margin.
  // If UVM never finishes (objection stuck, build fatal, ...) this ends the
  // simulation with a non-zero exit code so run_mini_uvm.sh reports FAIL.
  // ---------------------------------------------------------------------------
  initial begin
    repeat (5000) @(posedge clk);
    $display("MINI_UVM_WATCHDOG: scenario_done=%b", scenario_done);
    $fatal(1, "mini UVM environment watchdog expired");
  end

endmodule : mini_tb
