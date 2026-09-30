// Probe: does Verilator support clocking blocks with `input #1step` and
// `@(clocking_event)` — the exact access style used by our UVM monitors?
`timescale 1ns/1ps
interface probe_if (input logic clk, input logic sig);
  logic cb_saw;
  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input sig;
  endclocking
  modport MON (clocking mon_cb, input clk);
  always @(posedge clk) cb_saw <= mon_cb.sig;  // plain sampling reference
endinterface

module cb_probe;
  logic clk = 0;
  logic sig = 0;
  int   event_hits = 0;
  always #5 clk = ~clk;

  probe_if vif (.clk(clk), .sig(sig));

  // class-side @(vif.mon_cb) — mirrors the UVM monitor loop
  class watcher;
    virtual probe_if vif;
    function new(virtual probe_if v); vif = v; endfunction
    task run();
      forever begin
        @(vif.mon_cb);
        event_hits++;
        if (vif.mon_cb.sig === 1'b1) $display("T=%0t mon_cb saw sig=1", $time);
      end
    endtask
  endclass

  initial begin
    watcher w = new(vif);
    fork w.run(); join_none
    @(posedge clk); #1 sig = 1;      // sig high across 3 posedges
    repeat (3) @(posedge clk);
    #1 sig = 0;
    repeat (3) @(posedge clk);
    if (event_hits >= 5 && vif.cb_saw === 1'b0)
      $display("CLOCKING_OK hits=%0d", event_hits);
    else if (event_hits >= 5)
      $display("CLOCKING_PARTIAL hits=%0d cb_saw=%0b", event_hits, vif.cb_saw);
    else
      $display("CLOCKING_BAD hits=%0d", event_hits);
    $finish;
  end
endmodule
