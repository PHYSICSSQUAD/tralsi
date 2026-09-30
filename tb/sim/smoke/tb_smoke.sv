// =============================================================================
// tb_smoke.sv
// -----------------------------------------------------------------------------
// Non-UVM smoke test of the multiplier verification pieces on the real RTL:
//   * cv32e40p_top in the RV32IM configuration with the tie-offs from the
//     guidelines (irq_i=0, debug_req_i=0, pulp_clock_en_i=0, scan_cg_en_i=0)
//   * OBI instruction / data memory models with programmable wait states
//   * alu_mul_if bound into the core (alu_mul_bind.sv) + mul_sva bound
//   * mul_smoke_checker (plain-SV twin of the MUL monitor + scoreboard)
//   * end-of-test = store to MAGIC_ADDR, then architectural register compare
//     against the expected state produced by tb/scripts/rv32_asm.py
//
// Plusargs:
//   +prog=<file.mem>  +exp=<exp_regs.txt>
//   +gen=<n_blocks>    generate the program with mul_program_gen instead of +prog
//                      (writes gen.mem / gen.lst into +gen_dir, default ".")
//   +rf_dump=<file>    dump the final register file ("N hexval" lines)
//   +igw=<n> +irw=<n>  instruction bus max gnt / extra rvalid wait states
//   +dgw=<n> +drw=<n>  data bus max gnt / extra rvalid wait states
//   +reset_at=<cycle>  assert reset again for 3 cycles at that cycle (0 = never)
//   +timeout=<cycles>  +verbose
// =============================================================================
`timescale 1ns/1ps
module tb_smoke;
  import rv32m_ref_pkg::*;
  import mul_program_pkg::*;
`ifdef SMOKE_UVM
  import uvm_pkg::*;
  import mul_smoke_uvm_pkg::*;
`endif

  localparam logic [31:0] BOOT_ADDR  = 32'h0000_0080;
  localparam logic [31:0] MTVEC_ADDR = 32'h0000_0F00;
  localparam logic [31:0] DATA_BASE  = 32'h0001_0000;
  localparam logic [31:0] MAGIC_ADDR = 32'h0001_0FFC;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic fetch_enable = 1'b0;

  // OBI instruction bus
  logic        instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;
  // OBI data bus
  logic        data_req, data_gnt, data_rvalid, data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;
  logic        core_sleep;
  logic        irq_ack;
  logic [4:0]  irq_id;
  logic        dbg_havereset, dbg_running, dbg_halted;

  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  cv32e40p_top #(
      .COREV_PULP      (0),
      .COREV_CLUSTER   (0),
      .FPU             (0),
      .FPU_ADDMUL_LAT  (0),
      .FPU_OTHERS_LAT  (0),
      .ZFINX           (0),
      .NUM_MHPMCOUNTERS(1)
  ) dut (
      .clk_i               (clk),
      .rst_ni              (rst_n),
      .pulp_clock_en_i     (1'b0),
      .scan_cg_en_i        (1'b0),
      .boot_addr_i         (BOOT_ADDR),
      .mtvec_addr_i        (MTVEC_ADDR),
      .dm_halt_addr_i      (32'h1A11_0800),
      .hart_id_i           (32'h0),
      .dm_exception_addr_i (32'h1A11_1000),
      .instr_req_o         (instr_req),
      .instr_gnt_i         (instr_gnt),
      .instr_rvalid_i      (instr_rvalid),
      .instr_addr_o        (instr_addr),
      .instr_rdata_i       (instr_rdata),
      .data_req_o          (data_req),
      .data_gnt_i          (data_gnt),
      .data_rvalid_i       (data_rvalid),
      .data_we_o           (data_we),
      .data_be_o           (data_be),
      .data_addr_o         (data_addr),
      .data_wdata_o        (data_wdata),
      .data_rdata_i        (data_rdata),
      .irq_i               (32'h0),
      .irq_ack_o           (irq_ack),
      .irq_id_o            (irq_id),
      .debug_req_i         (1'b0),
      .debug_havereset_o   (dbg_havereset),
      .debug_running_o     (dbg_running),
      .debug_halted_o      (dbg_halted),
      .fetch_enable_i      (fetch_enable),
      .core_sleep_o        (core_sleep)
  );

  // ---------------------------------------------------------------------------
  // Memories
  // ---------------------------------------------------------------------------
  obi_mem_model #(.MEM_WORDS(4096), .BASE(32'h0), .READ_ONLY(1'b1), .RD_DEFAULT(32'h0000_006F)) imem (
      .clk(clk), .rst_n(rst_n),
      .req(instr_req), .gnt(instr_gnt), .addr(instr_addr), .we(1'b0), .be(4'hF), .wdata(32'h0),
      .rvalid(instr_rvalid), .rdata(instr_rdata));

  obi_mem_model #(.MEM_WORDS(1024), .BASE(DATA_BASE), .READ_ONLY(1'b0), .RD_DEFAULT(32'h0)) dmem (
      .clk(clk), .rst_n(rst_n),
      .req(data_req), .gnt(data_gnt), .addr(data_addr), .we(data_we), .be(data_be), .wdata(data_wdata),
      .rvalid(data_rvalid), .rdata(data_rdata));

  // ---------------------------------------------------------------------------
  // Checker on the bound interface
  // ---------------------------------------------------------------------------
  bit verbose, verbose_alu;
  mul_smoke_checker chk  (.vif(dut.core_i.alu_mul_if_i), .verbose(verbose));
  alu_smoke_checker achk (.vif(dut.core_i.alu_mul_if_i), .verbose(verbose_alu));

  // ---------------------------------------------------------------------------
  // Test control
  // ---------------------------------------------------------------------------
  int unsigned cycle;
  bit          done;
  int unsigned done_cycle;
  int unsigned timeout_cycles = 20000;
  int unsigned reset_at = 0;
  int unsigned igw = 0, irw = 0, dgw = 0, drw = 0;
  string       prog_file = "prog.mem";
  string       exp_file  = "exp_regs.txt";
  string       gen_dir   = ".";
  string       rf_dump   = "";
  int unsigned gen_blocks = 0;
  int unsigned n_mul_if_expected = 0;
  bit          have_expected_count = 0;
  int unsigned n_errors;

  always @(posedge clk) begin
    cycle <= cycle + 1;
    if (rst_n && data_req && data_gnt && data_we && (data_addr == MAGIC_ADDR) && !done) begin
      done       <= 1'b1;
      done_cycle <= cycle;
      $display("[%0t] end-of-test store seen at cycle %0d", $time, cycle);
    end
  end

  task automatic apply_reset(input int unsigned hold_cycles);
    rst_n = 1'b0;
    repeat (hold_cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic dump_regs();
    int fd;
    if (rf_dump == "") return;
    fd = $fopen(rf_dump, "w");
    if (fd == 0) begin
      $display("WARNING: cannot write %s", rf_dump);
      return;
    end
    for (int i = 0; i < 32; i++)
      $fdisplay(fd, "%0d %08h", i, (i == 0) ? 32'h0 : dut.core_i.id_stage_i.register_file_i.mem[i]);
    $fclose(fd);
    $display("final register file written to %s", rf_dump);
  endtask

  task automatic compare_regs();
    int          fd, r, idx;
    logic [31:0] exp_v, got_v;
    int unsigned n_cmp, n_bad;
    if (exp_file == "") return;
    fd = $fopen(exp_file, "r");
    if (fd == 0) begin
      $display("WARNING: cannot open %s - skipping register compare", exp_file);
      return;
    end
    while (!$feof(fd)) begin
      r = $fscanf(fd, "%d %h\n", idx, exp_v);
      if (r != 2) break;
      if (idx == 0) continue;
      got_v = dut.core_i.id_stage_i.register_file_i.mem[idx];
      n_cmp++;
      if (got_v !== exp_v) begin
        n_bad++;
        $display("REG MISMATCH x%0d: got 0x%08h expected 0x%08h", idx, got_v, exp_v);
      end
    end
    $fclose(fd);
    $display("register compare: %0d registers, %0d mismatches", n_cmp, n_bad);
    n_errors += n_bad;
  endtask

  initial begin
    void'($value$plusargs("prog=%s", prog_file));
    void'($value$plusargs("exp=%s", exp_file));
    void'($value$plusargs("igw=%d", igw));
    void'($value$plusargs("irw=%d", irw));
    void'($value$plusargs("dgw=%d", dgw));
    void'($value$plusargs("drw=%d", drw));
    void'($value$plusargs("reset_at=%d", reset_at));
    void'($value$plusargs("timeout=%d", timeout_cycles));
    void'($value$plusargs("gen=%d", gen_blocks));
    void'($value$plusargs("gen_dir=%s", gen_dir));
    void'($value$plusargs("rf_dump=%s", rf_dump));
    verbose     = $test$plusargs("verbose");
    verbose_alu = $test$plusargs("verbose_alu");
`ifdef SMOKE_UVM
    // the UVM stack (real mul_agent / scoreboard / coverage) runs alongside the plain checker
    fork
      run_test("mul_smoke_test");
    join_none
`endif

    for (int i = 0; i < 4096; i++) imem.mem[i] = 32'h0000_006F;   // unused code space spins in place
    for (int i = 0; i < 1024; i++) dmem.mem[i] = 32'h0;
    if (gen_blocks != 0) begin
      // MUL-directed random program from the generator used by the V_Sequence layer
      mul_program_gen gen;
      logic [31:0] words[$];
      gen = new();
      gen.n_blocks       = gen_blocks;
      gen.data_base      = DATA_BASE;
      gen.end_store_addr = MAGIC_ADDR;
      gen.build();
      gen.get_words(words);
      foreach (words[i]) imem.mem[(BOOT_ADDR >> 2) + i] = words[i];
      gen.write_mem({gen_dir, "/gen.mem"}, BOOT_ADDR);
      gen.write_listing({gen_dir, "/gen.lst"}, BOOT_ADDR);
      n_mul_if_expected   = gen.n_mul_if_expected;
      have_expected_count = 1'b1;
      $display("generated program: %s", gen.summary());
      if ((BOOT_ADDR >> 2) + words.size() > 4096) begin
        $display("ERROR: generated program does not fit in the instruction memory");
        n_errors++;
      end
    end else begin
      $readmemh(prog_file, imem.mem);
    end
    imem.max_gnt_wait    = igw;
    imem.max_rvalid_wait = irw;
    dmem.max_gnt_wait    = dgw;
    dmem.max_rvalid_wait = drw;
    $display("smoke: prog=%s igw=%0d irw=%0d dgw=%0d drw=%0d reset_at=%0d", prog_file, igw, irw, dgw, drw, reset_at);

    apply_reset(5);
    repeat (3) @(posedge clk);
    fetch_enable = 1'b1;

    fork
      begin : timeout_watch
        while (!done && (cycle < timeout_cycles)) @(posedge clk);
        if (!done) begin
          $display("ERROR: timeout after %0d cycles (pc_id=0x%08h)", cycle, dut.core_i.pc_id);
          n_errors++;
        end
      end
      begin : mid_reset
        if (reset_at != 0) begin
          while ((cycle < reset_at) && !done) @(posedge clk);
          if (!done) begin
            $display("[%0t] re-asserting reset at cycle %0d", $time, cycle);
            apply_reset(3);
            repeat (2) @(posedge clk);
            fetch_enable = 1'b1;
          end
        end
        while (!done && (cycle < timeout_cycles)) @(posedge clk);
      end
    join

    repeat (30) @(posedge clk);
    n_errors += chk.n_err;
    n_errors += achk.n_err;
    compare_regs();
    dump_regs();
    if (have_expected_count && (reset_at == 0)) begin
      if (chk.n_txn != n_mul_if_expected) begin
        $display("ERROR: MUL interface saw %0d transactions, program expects %0d", chk.n_txn, n_mul_if_expected);
        n_errors++;
      end else begin
        $display("MUL transaction count matches the program: %0d", n_mul_if_expected);
      end
    end

    $display("--------------------------------------------------------------");
    $display("MUL checker: %0d transactions (MUL %0d, MULH* %0d), %0d with external stall (max %0d cycles), %0d killed by reset, %0d errors",
             chk.n_txn, chk.n_mul, chk.n_mulh, chk.n_stalled, chk.max_stall, chk.n_killed, chk.n_err);
    $display("per op: MUL=%0d MULH=%0d MULHSU=%0d MULHU=%0d", chk.n_op[0], chk.n_op[1], chk.n_op[2], chk.n_op[3]);
    $display("ALU checker: %0d transactions (arith %0d, logic %0d, shift %0d, slt %0d, branch %0d [taken %0d, w/o ex_valid %0d], div %0d; lsu addr %0d incl. %0d misaligned 2nd halves), %0d bubbles, %0d stalled (max %0d), %0d killed by reset, %0d errors",
             achk.n_txn, achk.n_cls[0], achk.n_cls[1], achk.n_cls[2], achk.n_cls[3], achk.n_cls[4], achk.n_branch_taken, achk.n_branch_no_valid,
             achk.n_cls[5], achk.n_lsu, achk.n_misaligned_2nd, achk.n_bubbles, achk.n_stalled, achk.max_stall, achk.n_killed, achk.n_err);
    if (achk.n_div != 0) begin
      string h = "";
      for (int i = 3; i <= 35; i++) if (achk.n_div_lat[i] != 0) h = {h, $sformatf(" %0d:%0d", i, achk.n_div_lat[i])};
      $display("DIV/REM: %0d ops, net latency min %0d max %0d, %0d held by external stalls; histogram(latency:count)%s",
               achk.n_div, achk.div_lat_min, achk.div_lat_max, achk.n_div_stalled, h);
    end
    $display("imem: %0d requests, dmem: %0d requests (%0d reads, %0d writes)", imem.n_req, dmem.n_req, dmem.n_rd, dmem.n_wr);
    $display("cycles: %0d (end-of-test at %0d)", cycle, done_cycle);
    if (n_errors == 0) $display("SMOKE TEST PASSED");
    else               $display("SMOKE TEST FAILED (%0d errors)", n_errors);
    $display("--------------------------------------------------------------");
`ifdef SMOKE_UVM
    // hand over to UVM: the test drops its objection, UVM prints its report and finishes
    begin
      uvm_event #(uvm_object) done_ev = uvm_event_pool::get_global("smoke_done");
      done_ev.trigger();
    end
`else
    $finish;
`endif
  end

endmodule : tb_smoke
