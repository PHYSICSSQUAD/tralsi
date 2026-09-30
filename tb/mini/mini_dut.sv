// =============================================================================
// mini_dut.sv  (part of the MINI UVM environment — tb/mini/)
// -----------------------------------------------------------------------------
// WHAT THIS FILE IS:
//   A small BEHAVIOURAL stand-in for the parts of cv32e40p_core that the
//   ALU_MUL interface (tb/interfaces/alu_mul_if.sv) observes: the ID issue
//   side, the EX stage handshake, the ALU/divider, the multiplier and the
//   register-file write port.  It lets the REAL UVM stack (mul_agent,
//   alu_agent, alu_mul_scoreboard, mul_cov, alu_cov — everything in
//   tb/agents, tb/env, tb/fcov) run and prove itself WITHOUT the big RTL
//   design, so the environment can be validated quickly on any free
//   UVM-capable simulator before it is integrated with the real core.
//
// RELATIONSHIP TO THE REAL RTL (read this before changing anything):
//   * Results:  computed with INDEPENDENT native SV operators (`*`, `/`,
//     `$signed(...)`, ...), NOT with tb/common/*_ref_pkg — so when the
//     scoreboard compares "DUT result vs golden model" the two sides are
//     genuinely independent computations.
//   * Latency:  DIV/REM lengths come from alu_ref_pkg::div_latency_ref()
//     on purpose: that function IS the documented RTL latency model
//     (rtl/cv32e40p_alu.sv + cv32e40p_alu_div.sv), and the scoreboard's
//     latency check must agree with it.  MUL = 1 cycle, MULH* = 5 cycles
//     with mult_multicycle = 1 in the first 3 — per rtl/cv32e40p_mult.sv.
//   * Protocol: every waveform below satisfies the exact checks in
//     tb/agents/alu_agent/alu_monitor.sv and mul_monitor.sv (see notes in
//     each task).  If a monitor check changes, update this file to match.
//
// TIMING RULES IMPLEMENTED (mirrors notes/mul_plan.md section 0.2):
//   * The driver changes signals on the NEGLIGE (negedge clk).  The
//     monitors sample on posedge clk with `input #1step`, i.e. they see
//     the values driven at the previous negedge — race-free.
//   * issue cycle N (id_valid && is_decoding, pc_id, instr_id)  =>
//     EX activity of that instruction in cycle N+1 (ALWAYS — the ALU
//     monitor errors if an issue pulse is not followed by EX work).
//   * ALU non-div: 1 EX cycle (alu_ready=1, ex_ready=1).  External stall:
//     alu_ready=1 but ex_ready=0 for k cycles (monitor counts stall).
//   * DIV/REM: first L-1 cycles alu_ready=0 (busy), last cycle
//     alu_ready=1 + ex_ready=1 + ex_valid=1.  L = div_latency_ref(op, a)
//     where a = divisor (the decoder swapped the operands, see alu_ref_pkg).
//   * MUL: 1 cycle, mult_ready=1, ex_valid=1.
//   * MULH*: 4 busy cycles (mult_ready=0, ex_ready=0, ex_valid=0,
//     mult_multicycle=1 in the first 3) + final cycle mult_ready=1,
//     ex_valid=1.  Net = 5 cycles, 0 stalls, multicycle window = 3.
//   * Branch: branch_in_ex=1, we=0; may leave EX with ex_valid=0.
//   * Misaligned ld/st: pass 1 = ADD(rs1, imm) tagged by an issue pulse;
//     pass 2 = NEXT cycle, NO issue pulse, data_misaligned_ex=1,
//     ADD(first address, 4), lsu_en=1, we=0 (monitor's misaligned rules).
//   * Bubbles: alu_en=1, ALU_SLTU, we=0, branch_in_ex=0 and no issue pulse
//     behind them — exactly the idle pattern of rtl/cv32e40p_id_stage.
// =============================================================================
module mini_dut
  import cv32e40p_pkg::*;   // alu_opcode_e / mul_opcode_e for the port types
(
  input  logic        clk,           // free-running clock from mini_tb
  output logic        rst_n,         // driven by the scenario (incl. reset-kill)

  // --- EX handshake ---------------------------------------------------------
  output logic        ex_ready,      // EX free / op leaves EX this cycle
  output logic        ex_valid,      // result valid this cycle
  output logic        lsu_ready_ex,  // always 1 here (no real LSU)
  output logic        wb_ready,      // 0 during injected external stalls
  output logic        branch_in_ex,  // 1 while a branch op is in EX
  output logic        lsu_en,        // 1 while an address op is in EX
  output logic        data_misaligned_ex,  // 1 only in the 2nd pass

  // --- ALU / divider group --------------------------------------------------
  output logic        alu_en,
  output alu_opcode_e alu_operator,
  output logic [31:0] alu_operand_a,   // divisor for DIV/REM
  output logic [31:0] alu_operand_b,   // dividend for DIV/REM
  output logic [31:0] alu_operand_c,   // RV32IM: 0
  output logic [31:0] alu_result,
  output logic        alu_cmp_result,  // branch decision
  output logic        alu_ready,       // 0 while the divider is busy

  // --- multiplier group -----------------------------------------------------
  output logic        mult_en,
  output mul_opcode_e mult_operator,   // MUL_MAC32 = MUL, MUL_H = MULH*
  output logic [ 1:0] mult_signed_mode,
  output logic [31:0] mult_operand_a,
  output logic [31:0] mult_operand_b,
  output logic [31:0] mult_operand_c,  // must be 0 at start (REGC_ZERO)
  output logic        mult_sel_subword,// RV32IM: 0 (PULP feature)
  output logic [ 4:0] mult_imm,        // RV32IM: 0 (PULP feature)
  output logic [31:0] mult_result,
  output logic        mult_ready,      // 0 in busy MULH cycles
  output logic        mult_multicycle, // 1 in the first 3 MULH cycles
  output logic        mulh_active,     // informational (MULH FSM busy)

  // --- register-file write port (port b of the RF) --------------------------
  output logic        rf_alu_we,
  output logic [ 5:0] rf_alu_waddr,    // {1'b0, rd} — bit5 = FP regfile = 0
  output logic [31:0] rf_alu_wdata,

  // --- ID side: issue pulses that tag the transactions ----------------------
  output logic        id_valid,
  output logic        is_decoding,
  output logic [31:0] pc_id,
  output logic [31:0] instr_id,

  // --- to mini_tb: high when the whole scenario has been played -------------
  output logic        scenario_done
);

  // Package imports used by the scenario code below:
  import rv32m_ref_pkg::*;     // rv32m_op_e + MUL..REMU literals
  import alu_ref_pkg::*;       // div_latency_ref, is_div_operator
  import mul_program_pkg::*;   // instruction encoders (i_m, i_add, i_lw, ...)

  // Running PC of the next issue pulse (tags and AUIPC/JAL operands use it).
  logic [31:0] cur_pc = 32'h0000_0080;

  // ---------------------------------------------------------------------------
  // Native golden helpers — deliberately INDEPENDENT of tb/common/*_ref_pkg.
  // The scoreboard will compare these against alu_ref/rv32m_ref, so a mistake
  // in either implementation shows up as a UVM_ERROR.
  // ---------------------------------------------------------------------------

  // RISC-V M-extension multiply results (high/low 32 bits of the product).
  function automatic logic [31:0] mul_native(input rv32m_op_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    logic signed [63:0] ps;     // signed 64-bit product
    logic        [63:0] pu;     // unsigned 64-bit product
    logic signed [64:0] a65, b65, p65;  // for MULHSU (mixed sign)
    ps  = $signed(a) * $signed(b);      // operands widen to the 64-bit context
    pu  = {32'b0, a} * {32'b0, b};      // zero-extended unsigned multiply
    a65 = {{33{a[31]}}, a};             // sign-extend a to 65 bits
    b65 = {33'b0, b};                   // zero-extend b to 65 bits
    p65 = a65 * b65;                    // signed x unsigned == signed x (b >= 0)
    case (op)
      MUL:    return ps[31:0];
      MULH:   return ps[63:32];
      MULHU:  return pu[63:32];
      MULHSU: return p65[63:32];
      default: return 32'hxxxx_xxxx;
    endcase
  endfunction

  // Branch/compare decision (same semantics as alu_ref_pkg::alu_cmp_ref).
  function automatic bit cmp_native(input alu_opcode_e op,
                                    input logic [31:0] a,
                                    input logic [31:0] b);
    case (op)
      ALU_EQ:            return (a == b);
      ALU_NE:            return (a != b);
      ALU_LTS, ALU_SLTS: return ($signed(a) < $signed(b));
      ALU_GES:           return ($signed(a) >= $signed(b));
      ALU_LTU, ALU_SLTU: return (a < b);
      ALU_GEU:           return (a >= b);
      default:           return 1'b0;
    endcase
  endfunction

  // Divider/remainder per the RISC-V spec (a = divisor, b = dividend).
  function automatic logic [31:0] div_native(input alu_opcode_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    bit div_s = (op == ALU_DIV) || (op == ALU_REM);   // signed op?
    if (a == 32'd0) begin                            // divide by zero
      case (op)
        ALU_DIV,  ALU_DIVU: return 32'hFFFF_FFFF;     //   q = -1
        default:            return b;                 //   r = dividend
      endcase
    end
    if (div_s && (b == 32'h8000_0000) && (a == 32'hFFFF_FFFF)) begin
      case (op)                                       // signed overflow
        ALU_DIV: return 32'h8000_0000;                //   q = INT_MIN
        default: return 32'd0;                        //   r = 0
      endcase
    end
    case (op)
      ALU_DIV:  return $unsigned($signed(b) / $signed(a));
      ALU_DIVU: return b / a;
      ALU_REM:  return $unsigned($signed(b) % $signed(a));
      default:  return b % a;                         // ALU_REMU
    endcase
  endfunction

  // Everything the ALU can compute, straight from the operand conventions
  // documented in tb/common/alu_ref_pkg.sv (R/I: a=rs1 b=rs2/imm; branch:
  // replicate the cmp bit; DIV: swapped — handled by div_native).
  function automatic logic [31:0] alu_native(input alu_opcode_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    case (op)
      ALU_ADD:  return a + b;
      ALU_SUB:  return a - b;
      ALU_AND:  return a & b;
      ALU_OR:   return a | b;
      ALU_XOR:  return a ^ b;
      ALU_SLL:  return a << b[4:0];
      ALU_SRL:  return a >> b[4:0];
      ALU_SRA:  return $unsigned($signed(a) >>> b[4:0]);
      ALU_SLTS: return {31'b0, cmp_native(ALU_SLTS, a, b)};
      ALU_SLTU: return {31'b0, cmp_native(ALU_SLTU, a, b)};
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:
                return {32{cmp_native(op, a, b)}};    // VEC_MODE32 replicate
      ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU:
                return div_native(op, a, b);
      default:  return a + b;   // LUI/AUIPC/JAL/ld/st all ride on ALU_ADD
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Low-level cycle drivers — every task moves to the NEXT negedge first, so
  // the values it sets are what the monitors sample at the following posedge.
  // ---------------------------------------------------------------------------

  // One clock half-period of waiting.
  task automatic step();
    @(negedge clk);
  endtask

  // All units quiet, no issue pulse, handshakes inactive.
  // (Also the recovery state after a reset: monitors only sample on posedge
  //  when rst_n=1, so whatever we do during reset is never protocol-checked.)
  task automatic set_idle();
    rst_n                = rst_n;         // scenario owns reset; keep value
    ex_ready             = 1'b0;
    ex_valid             = 1'b0;
    lsu_ready_ex         = 1'b1;
    wb_ready             = 1'b1;
    branch_in_ex         = 1'b0;
    lsu_en               = 1'b0;
    data_misaligned_ex   = 1'b0;
    alu_en               = 1'b0;
    alu_operator         = ALU_SLTU;      // harmless default
    alu_operand_a        = 32'd0;
    alu_operand_b        = 32'd0;
    alu_operand_c        = 32'd0;
    alu_result           = 32'd0;
    alu_cmp_result       = 1'b0;
    alu_ready            = 1'b1;
    mult_en              = 1'b0;
    mult_operator        = MUL_MAC32;
    mult_signed_mode     = 2'b11;
    mult_operand_a       = 32'd0;
    mult_operand_b       = 32'd0;
    mult_operand_c       = 32'd0;
    mult_sel_subword     = 1'b0;
    mult_imm             = 5'd0;
    mult_result          = 32'd0;
    mult_ready           = 1'b1;
    mult_multicycle      = 1'b0;
    mulh_active          = 1'b0;
    rf_alu_we            = 1'b0;
    rf_alu_waddr         = 6'd0;
    rf_alu_wdata         = 32'd0;
    id_valid             = 1'b0;
    is_decoding          = 1'b0;
  endtask

  // One-cycle issue pulse: the instruction "arrives" in ID this cycle and
  // MUST show up in EX on the very next cycle (alu_monitor enforces this).
  task automatic issue(input logic [31:0] instr);
    step();
    set_idle();
    id_valid    = 1'b1;
    is_decoding = 1'b1;
    pc_id       = cur_pc;
    instr_id    = instr;
  endtask

  // ---------------------------------------------------------------------------
  // Instruction executors — each one plays the full life of one instruction:
  // issue cycle -> EX cycle(s).  They assume rst_n is already 1.
  // ---------------------------------------------------------------------------

  // One ALU/branch/ld-st/DIV instruction.
  //   stall_i = external hold cycles (alu_ready=1, ex_ready=0) before exit.
  task automatic do_alu(input logic [31:0]      instr,
                        input alu_opcode_e      op,
                        input logic [31:0]      a,
                        input logic [31:0]      b,
                        input bit               lsu_i  = 1'b0,
                        input bit               br_i   = 1'b0,
                        input bit               we_i   = 1'b1,
                        input logic [4:0]       rd_i   = 5'd3,
                        input bit               exv_i  = 1'b1,
                        input int unsigned      stall_i = 0);
    bit          is_div = is_div_operator(op);
    int unsigned lat    = is_div ? div_latency_ref(op, a) : 1;  // a = divisor
    logic [31:0] res    = alu_native(op, a, b);
    bit          cmp    = cmp_native(op, a, b);

    issue(instr);                       // cycle N: tag for EX at N+1
    step();
    set_idle();                         // cycle N+1: EX begins
    alu_en         = 1'b1;
    alu_operator   = op;
    alu_operand_a  = a;
    alu_operand_b  = b;
    alu_operand_c  = 32'd0;
    alu_result     = res;               // available from the first cycle
    alu_cmp_result = cmp;
    branch_in_ex   = br_i;
    lsu_en         = lsu_i;
    rf_alu_we      = we_i;
    rf_alu_waddr   = {1'b0, rd_i};
    rf_alu_wdata   = res;

    if (is_div) begin
      // ---- divider: L-1 busy cycles (alu_ready=0), then the finish cycle
      alu_ready = 1'b0;
      ex_ready  = 1'b0;
      ex_valid  = 1'b0;
      repeat (lat - 2) step();          // remaining busy cycles (min L=3)
      step();                           // finish cycle begins...
      alu_ready = 1'b1;                 // ...divider done
      if (stall_i == 0) begin
        ex_ready = 1'b1;                // no hold: leaves EX right now
        ex_valid = 1'b1;
      end else begin
        // External stall: unit done but WB holds EX (wb_ready=0 in RTL).
        ex_ready = 1'b0;
        ex_valid = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_ready = 1'b1;
        ex_valid = 1'b1;
      end
    end else begin
      // ---- single-cycle op: the first EX cycle may already be the exit
      alu_ready = 1'b1;
      if (stall_i == 0) begin
        ex_ready = 1'b1;
        ex_valid = exv_i;               // branch may legitimately exit with 0
      end else begin
        ex_ready = 1'b0;
        ex_valid = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_ready = 1'b1;
        ex_valid = exv_i;
      end
    end
    cur_pc += 4;                        // this instruction has been "retired"
  endtask

  // Misaligned load/store: pass 1 = the address, pass 2 = address+4 with
  // data_misaligned_ex=1 and NO issue pulse in between (replay rule).
  task automatic do_misaligned(input logic [31:0] instr,
                               input logic [31:0] a,      // rs1 value
                               input logic [31:0] imm,    // immediate
                               input logic [4:0]  rd_i);
    logic [31:0] addr = a + imm;
    issue(instr);                       // issue cycle
    // --- pass 1: tagged, normal ADD(rs1, imm), completes immediately
    step();
    set_idle();
    alu_en         = 1'b1;
    alu_operator   = ALU_ADD;
    alu_operand_a  = a;
    alu_operand_b  = imm;
    alu_result     = addr;
    alu_ready      = 1'b1;
    ex_ready       = 1'b1;
    ex_valid       = 1'b1;
    lsu_en         = 1'b1;
    rf_alu_we      = 1'b0;              // RF write comes from the LSU, not ALU
    rf_alu_waddr   = {1'b0, rd_i};
    // --- pass 2: next cycle, inherits pass 1's tag, shape = ADD(addr, 4)
    step();
    set_idle();
    alu_en         = 1'b1;
    alu_operator   = ALU_ADD;
    alu_operand_a  = addr;              // == monitor's last_result
    alu_operand_b  = 32'd4;
    alu_result     = addr + 32'd4;
    alu_ready      = 1'b1;
    ex_ready       = 1'b1;
    ex_valid       = 1'b1;
    lsu_en         = 1'b1;
    data_misaligned_ex = 1'b1;
    rf_alu_we      = 1'b0;
    rf_alu_waddr   = {1'b0, rd_i};
    cur_pc += 4;
  endtask

  // One multiplier instruction (MUL: 1 cycle, MULH*: 5 cycles).
  //   stall_i = external hold cycles before ex_valid (mult_ready=1, ex_valid=0).
  task automatic do_mul(input logic [31:0]  instr,
                        input rv32m_op_e    op,
                        input logic [31:0]  a,
                        input logic [31:0]  b,
                        input logic [4:0]   rd_i,
                        input int unsigned  stall_i = 0);
    bit          is_h  = (op != MUL);
    mul_opcode_e m_op  = is_h ? MUL_H : MUL_MAC32;
    logic [1:0]  sm;                                // signedness per funct3
    logic [31:0] res   = mul_native(op, a, b);
    case (op)
      MULHU:   sm = 2'b00;                          // both unsigned
      MULHSU:  sm = 2'b01;                          // a signed, b unsigned
      default: sm = 2'b11;                          // MUL / MULH: both signed
    endcase

    issue(instr);                       // issue cycle
    step();
    set_idle();                         // first EX cycle
    mult_en          = 1'b1;
    mult_operator    = m_op;
    mult_signed_mode = sm;
    mult_operand_a   = a;
    mult_operand_b   = b;
    mult_operand_c   = 32'd0;           // REGC_ZERO
    mult_sel_subword = 1'b0;            // PULP features off
    mult_imm         = 5'd0;
    mult_result      = res;
    rf_alu_we        = 1'b1;            // MUL unit writes the RF
    rf_alu_waddr     = {1'b0, rd_i};
    rf_alu_wdata     = res;

    if (is_h) begin
      // ---- MULH*: busy cycles with mult_ready=0 (so no stall is counted)
      mult_ready      = 1'b0;
      ex_ready        = 1'b0;
      ex_valid        = 1'b0;
      mult_multicycle = 1'b1;           // STEP0..STEP2 = first 3 cycles
      mulh_active     = 1'b1;
      step();                           // busy cycle 2 (values hold)
      step();                           // busy cycle 3 (values hold)
      step();                           // 3rd multicycle cycle done -> off
      mult_multicycle = 1'b0;
      step();                           // busy cycle 4 (mc=0 now)
      if (stall_i > 0) begin            // external hold, mult_ready=1
        mult_ready = 1'b1;
        wb_ready   = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready   = 1'b1;
      end
      mult_ready = 1'b1;
      ex_valid   = 1'b1;                // FINISH cycle
      ex_ready   = 1'b1;
      mulh_active = 1'b0;
    end else begin
      // ---- plain MUL: single cycle (optionally held externally first)
      mult_ready = 1'b1;
      if (stall_i == 0) begin
        ex_valid = 1'b1;
        ex_ready = 1'b1;
      end else begin
        ex_valid = 1'b0;                // external stall: WB holds the result
        ex_ready = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_valid = 1'b1;
        ex_ready = 1'b1;
      end
    end
    cur_pc += 4;
  endtask

  // Reset-kill: start an MULH, then yank rst_n mid-flight.  The monitors
  // must publish it as killed_by_reset (scoreboard skips it, coverage
  // counts it in its reset group).
  task automatic do_mul_kill();
    issue(i_m(MULH, 5'd11, 5'd1, 5'd2));
    step();
    set_idle();
    mult_en          = 1'b1;
    mult_operator    = MUL_H;
    mult_signed_mode = 2'b11;
    mult_operand_a   = 32'h1234_5678;
    mult_operand_b   = 32'h9ABC_DEF0;
    mult_multicycle  = 1'b1;
    mult_ready       = 1'b0;
    rf_alu_we        = 1'b1;
    rf_alu_waddr     = 6'd11;
    step();                           // still busy...
    // ---- reset strikes: first posedge with rst_n=0 closes the transaction
    step();
    rst_n    = 1'b0;
    set_idle();                       // units off while reset is active
    step();                           // second reset cycle
    rst_n    = 1'b1;
    step();                           // healthy again (monitors were reset)
    // no cur_pc++ — this instruction never completed
  endtask

  // Reset-kill during a long DIVU (divisor 0 -> would take 35 cycles).
  task automatic do_div_kill();
    issue(i_m(DIVU, 5'd13, 5'd1, 5'd2));
    step();
    set_idle();
    alu_en        = 1'b1;
    alu_operator  = ALU_DIVU;
    alu_operand_a = 32'd0;            // divisor 0 = slowest divider op
    alu_operand_b = 32'h1234_5678;
    alu_ready     = 1'b0;
    ex_ready      = 1'b0;
    ex_valid      = 1'b0;
    rf_alu_we     = 1'b1;
    rf_alu_waddr  = 6'd13;
    step();                           // busy...
    step();                           // busy...
    step();
    rst_n    = 1'b0;
    set_idle();
    step();
    rst_n    = 1'b1;
    step();
  endtask

  // Idle bubbles: the ID stage's exact pattern while it has nothing to send.
  task automatic do_bubble(input int n = 1);
    repeat (n) begin
      step();
      set_idle();
      alu_en       = 1'b1;            // ALU loaded with the idle instruction
      alu_operator = ALU_SLTU;
      ex_ready     = 1'b1;            // passes straight through
      // we=0 and branch_in_ex=0 from set_idle() — the looks_like_bubble shape
    end
  endtask

  // Fully quiet cycles (no unit active at all).
  task automatic do_idle(input int n = 1);
    repeat (n) begin
      step();
      set_idle();
    end
  endtask

  // ---------------------------------------------------------------------------
  // +mini_prog=simple -> only the 3-instruction program above; default = full
  bit                               prog_simple = 1'b0;

  // The scenario: a directed program that lights up every check in the
  // scoreboard / monitors / coverage.  Structure:
  //   1. reset, 2. MUL side, 3. ALU side, 4. DIV latency corners,
  //   5. misaligned + reset-kills, 6. trailing bubbles/idle.
  // ---------------------------------------------------------------------------
  initial begin : scenario
    scenario_done = 1'b0;
    rst_n         = 1'b0;             // hold reset for a few cycles
    set_idle();
    repeat (4) step();
    rst_n = 1'b1;
    step();

    // Program select: +mini_prog=simple runs ONLY the 3 instructions below
    // (easy to watch in the console / waveform); default = the full scenario.
    begin
      string pname;
      if ($value$plusargs("mini_prog=%s", pname) && pname == "simple")
        prog_simple = 1;
    end
    $display("[MINI] program = %s", prog_simple ? "SIMPLE (3 instructions)" : "FULL");

    if (prog_simple) begin
      // ================= SIMPLE: 3 instructions — edit here ==============
      // 1. MUL x5 = x1*x2 = 7*6, 1 cycle
      do_mul(i_m(MUL, 5'd5, 5'd1, 5'd2), MUL, 32'h0000_0007, 32'h0000_0006, 5'd5);
      // 2. MULH signed: high32(-1 * 3), 5 cycles (shows the multicycle shape)
      do_mul(i_m(MULH, 5'd6, 5'd1, 5'd2), MULH, 32'hFFFF_FFFF, 32'h0000_0003, 5'd6);
      // 3. plain ALU add: 0x12345678 + 0x11112222
      do_alu(i_add(5'd12, 5'd1, 5'd2), ALU_ADD, 32'h1234_5678, 32'h1111_2222, .rd_i(5'd12));
      do_bubble(1);
      // ===============================================================
    end else begin
    // ================= MUL side (sb: result, latency, wb, tag) ==============
    // MUL, 1 cycle: 7*6 = 42
    do_mul(i_m(MUL, 5'd5, 5'd1, 5'd2), MUL, 32'h0000_0007, 32'h0000_0006, 5'd5);
    // MULH signed: high32(-1 * 3)
    do_mul(i_m(MULH, 5'd6, 5'd1, 5'd2), MULH, 32'hFFFF_FFFF, 32'h0000_0003, 5'd6);
    // MULHU unsigned high32 of the same bits
    do_mul(i_m(MULHU, 5'd7, 5'd1, 5'd2), MULHU, 32'hFFFF_FFFF, 32'h0000_0003, 5'd7);
    // MULHSU: a signed, b unsigned
    do_mul(i_m(MULHSU, 5'd8, 5'd1, 5'd2), MULHSU, 32'hFFFF_FFFF, 32'h0000_0003, 5'd8);
    do_bubble(2);                     // RTL-style idle between instructions
    // MUL with 1 external stall cycle (net must still be 1 multiplier cycle)
    do_mul(i_m(MUL, 5'd9, 5'd1, 5'd2), MUL, 32'hDEAD_BEEF, 32'hCAFE_BABE, 5'd9, 1);
    // MULH with 2 external stall cycles (net 5, total 7, stall 2)
    do_mul(i_m(MULH, 5'd10, 5'd1, 5'd2), MULH, 32'h0123_4567, 32'h89AB_CDEF, 5'd10, 2);
    // reset kills a running MULH -> killed_by_reset path
    do_mul_kill();
    do_idle(2);
    // corner operands: all-ones * all-ones
    do_mul(i_m(MUL, 5'd11, 5'd1, 5'd2), MUL, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 5'd11);

    // ================= ALU side =============================================
    do_alu(i_add (5'd12, 5'd1, 5'd2), ALU_ADD, 32'h1234_5678, 32'h1111_2222, .rd_i(5'd12));
    do_alu(i_sub (5'd13, 5'd1, 5'd2), ALU_SUB, 32'h0000_0005, 32'h0000_0008, .rd_i(5'd13));
    do_alu(i_xor (5'd14, 5'd1, 5'd2), ALU_XOR, 32'hF0F0_F0F0, 32'h0FF0_0FF0, .rd_i(5'd14));
    do_alu(i_sll (5'd15, 5'd1, 5'd2), ALU_SLL, 32'h0000_0001, 32'h0000_0011, .rd_i(5'd15)); // sh=17
    do_alu(i_sra (5'd16, 5'd1, 5'd2), ALU_SRA, 32'h8000_0000, 32'h0000_0004, .rd_i(5'd16));
    do_alu(i_slt (5'd17, 5'd1, 5'd2), ALU_SLTS, 32'hFFFF_FFFF, 32'h0000_0001, .rd_i(5'd17)); // -1 < 1
    do_alu(i_sltu(5'd18, 5'd1, 5'd2), ALU_SLTU, 32'hFFFF_FFFF, 32'h0000_0001, .rd_i(5'd18)); // 2^32-1 !< 1
    do_alu(i_addi(5'd19, 5'd1, 12'h025), ALU_ADD, 32'h0000_1000, 32'h0000_0025, .rd_i(5'd19));
    do_alu(i_andi(5'd20, 5'd1, 12'h0F0), ALU_AND, 32'hABCD_EF12, 32'h0000_00F0, .rd_i(5'd20));
    do_alu(i_ori (5'd21, 5'd1, 12'h301), ALU_OR,  32'hABCD_0000, 32'h0000_0301, .rd_i(5'd21));
    do_alu(i_srai(5'd22, 5'd1, 5'd8),    ALU_SRA, 32'hF000_0000, 32'h0000_0008, .rd_i(5'd22));
    do_bubble(1);
    // LUI: a=0, b=imm_u, result = imm_u (decoder cross-check)
    do_alu(i_lui(5'd23, 20'h12345), ALU_ADD, 32'h0, 32'h1234_5000, .rd_i(5'd23));
    // AUIPC: a=pc, b=imm_u, result = pc + imm_u
    do_alu(i_auipc(5'd24, 20'h000AB), ALU_ADD, cur_pc, 32'h000A_B000, .rd_i(5'd24));
    // JAL / JALR link value: a=pc, b=4, result = pc+4
    do_alu(i_jal(5'd25, 21'h00010), ALU_ADD, cur_pc, 32'd4, .rd_i(5'd25));
    do_alu(i_jalr(5'd26, 5'd1, 12'h000), ALU_ADD, cur_pc, 32'd4, .rd_i(5'd26));
    // branch taken: a == b -> cmp=1, branch_in_ex=1, we=0
    do_alu(i_beq(5'd1, 5'd2, 13'h008), ALU_EQ, 32'h0000_0042, 32'h0000_0042,
           .br_i(1'b1), .we_i(1'b0), .rd_i(5'd0));
    // branch NOT taken AND leaving with ex_valid=0 (branch shortcut path)
    do_alu(i_bne(5'd1, 5'd2, 13'h008), ALU_NE, 32'h0000_0042, 32'h0000_0042,
           .br_i(1'b1), .we_i(1'b0), .exv_i(1'b0), .rd_i(5'd0));
    // aligned load + store: address through the ALU, no port-b write
    do_alu(i_lw(5'd27, 5'd1, 12'h010), ALU_ADD, 32'h2000_0000, 32'h0000_0010,
           .lsu_i(1'b1), .we_i(1'b0), .rd_i(5'd27));
    do_alu(i_sw(5'd2, 5'd1, 12'h014), ALU_ADD, 32'h2000_0000, 32'h0000_0014,
           .lsu_i(1'b1), .we_i(1'b0), .rd_i(5'd0));
    do_bubble(1);

    // ================= DIV/REM latency corners (sb: div latency + result) ===
    // DIVU, divisor >= 0x80000000 -> 6-bit clb wrap -> FASTEST (3 cycles)
    do_alu(i_m(DIVU, 5'd28, 5'd1, 5'd2), ALU_DIVU, 32'h8000_0000, 32'hFFFF_FFFF, .rd_i(5'd28));
    // DIVU by zero -> SLOWEST (35 cycles)
    do_alu(i_m(DIVU, 5'd29, 5'd1, 5'd2), ALU_DIVU, 32'h0000_0000, 32'h1234_5678, .rd_i(5'd29));
    // DIV signed, divisor=1 -> 34 cycles
    do_alu(i_m(DIV, 5'd30, 5'd1, 5'd2), ALU_DIV, 32'h0000_0001, 32'h0000_0005, .rd_i(5'd30));
    // REM signed, negative divisor -> 34 cycles
    do_alu(i_m(REM, 5'd31, 5'd1, 5'd2), ALU_REM, 32'hFFFF_FFFF, 32'h0000_0064, .rd_i(5'd31));
    // REMU, divisor=4 -> 32 cycles
    do_alu(i_m(REMU, 5'd12, 5'd1, 5'd2), ALU_REMU, 32'h0000_0004, 32'h0000_0064, .rd_i(5'd12));
    // DIV signed by -1 of INT_MIN -> signed overflow corner result
    do_alu(i_m(DIV, 5'd13, 5'd1, 5'd2), ALU_DIV, 32'hFFFF_FFFF, 32'h8000_0000, .rd_i(5'd13));
    // DIV with an external stall folded in (net must still equal the model)
    do_alu(i_m(DIV, 5'd14, 5'd1, 5'd2), ALU_DIV, 32'h0000_0010, 32'h0000_00FF,
           .rd_i(5'd14), .stall_i(2));

    // ================= misaligned split accesses (2-pass rules) =============
    // LH at an odd address -> two ADD passes, second one tagged "misaligned"
    do_misaligned(i_load(3'b001, 5'd15, 5'd1, 12'h003), 32'h2000_0000, 32'h0000_0003, 5'd15);
    // SW at an odd address -> same shape, store flavour
    do_misaligned(i_store(3'b010, 5'd2, 5'd1, 12'h001), 32'h2000_0000, 32'h0000_0001, 5'd0);
    do_bubble(1);

    // ================= reset-kill during a long DIVU ========================
    do_div_kill();
    do_idle(2);

    // ================= closing traffic ======================================
    do_alu(i_add(5'd16, 5'd3, 5'd4), ALU_ADD, 32'h0BAD_CAFE, 32'h600D_0001, .rd_i(5'd16));
    do_mul(i_m(MUL, 5'd17, 5'd3, 5'd4), MUL, 32'h0000_1234, 32'h0000_5678, 5'd17);
    do_bubble(2);
    end // else: full program

    do_idle(4);                       // let every monitor publish its last txn

    scenario_done = 1'b1;
  end

endmodule : mini_dut
