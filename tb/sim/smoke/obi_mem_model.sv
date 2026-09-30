// =============================================================================
// obi_mem_model.sv
// -----------------------------------------------------------------------------
// Simple OBI slave memory for the (non-UVM) smoke test. Behaviour follows the
// CV32E40P databook "Instruction Fetch" / "Load-Store-Unit" chapters:
//   * req may wait 0..max_gnt_wait cycles for gnt (address phase held by the
//     master while req && !gnt);
//   * gnt is combinational from req (allowed by OBI);
//   * one rvalid pulse per accepted request, in order, earliest in the cycle
//     right after the grant cycle, plus 0..max_rvalid_wait extra cycles;
//   * word addressed (addr[31:2]), byte enables applied on writes, so the
//     misaligned two-beat accesses of the LSU work without special handling;
//   * reads outside the window return RD_DEFAULT (an RV32 "j ." for the
//     instruction memory so a runaway core parks itself).
// =============================================================================
module obi_mem_model #(
    parameter int unsigned MEM_WORDS  = 1024,
    parameter logic [31:0] BASE       = 32'h0000_0000,
    parameter bit          READ_ONLY  = 1'b0,
    parameter logic [31:0] RD_DEFAULT = 32'h0000_006F   // jal x0, 0
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        req,
    output logic        gnt,
    input  logic [31:0] addr,
    input  logic        we,
    input  logic [ 3:0] be,
    input  logic [31:0] wdata,
    output logic        rvalid,
    output logic [31:0] rdata
);

  logic [31:0] mem [MEM_WORDS];

  // wait-state knobs (set by the testbench, e.g. from plusargs)
  int unsigned max_gnt_wait    = 0;
  int unsigned max_rvalid_wait = 0;

  typedef struct {
    logic [31:0] addr;
    logic        we;
    logic [3:0]  be;
    logic [31:0] wdata;
    int unsigned delay;   // extra cycles before rvalid (0 = right after the grant cycle)
  } req_t;

  req_t        pending [$];
  int unsigned gnt_wait;

  // statistics
  int unsigned n_req, n_rd, n_wr;

  function automatic bit in_window(input logic [31:0] a);
    return (a >= BASE) && ((a - BASE) < (MEM_WORDS * 4));
  endfunction

  function automatic int unsigned widx(input logic [31:0] a);
    return (a - BASE) >> 2;
  endfunction

  // grant: combinational from req, gated by the wait counter
  assign gnt = req && (gnt_wait == 0);

  always @(posedge clk or negedge rst_n) begin  // not always_ff: tb_smoke preloads mem
    if (!rst_n) begin
      gnt_wait <= 0;
      pending.delete();
      rvalid   <= 1'b0;
      rdata    <= '0;
      n_req    <= 0;
      n_rd     <= 0;
      n_wr     <= 0;
    end else begin
      // ---- address phase ---------------------------------------------------------
      if (req && gnt) begin
        req_t r;
        r.addr  = addr;
        r.we    = we;
        r.be    = be;
        r.wdata = wdata;
        r.delay = (max_rvalid_wait == 0) ? 0 : $urandom_range(max_rvalid_wait);
        pending.push_back(r);
        gnt_wait <= (max_gnt_wait == 0) ? 0 : $urandom_range(max_gnt_wait);
        n_req <= n_req + 1;
      end else if (req && !gnt) begin
        gnt_wait <= gnt_wait - 1;
      end

      // ---- response phase (in order, one per cycle) -------------------------------
      rvalid <= 1'b0;
      if (pending.size() > 0) begin
        if (pending[0].delay == 0) begin
          req_t r;
          r = pending.pop_front();
          rvalid <= 1'b1;
          if (r.we && !READ_ONLY) begin
            if (in_window(r.addr)) begin
              for (int i = 0; i < 4; i++)
                if (r.be[i]) mem[widx(r.addr)][8*i +: 8] <= r.wdata[8*i +: 8];
            end
            n_wr  <= n_wr + 1;
            rdata <= '0;
          end else begin
            rdata <= in_window(r.addr) ? mem[widx(r.addr)] : RD_DEFAULT;
            n_rd  <= n_rd + 1;
          end
        end else begin
          pending[0].delay--;
        end
      end
    end
  end

endmodule : obi_mem_model
