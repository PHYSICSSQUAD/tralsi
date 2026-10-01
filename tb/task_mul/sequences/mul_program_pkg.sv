// =============================================================================
// mul_program_pkg.sv
// -----------------------------------------------------------------------------
// MUL-directed program generator (plain SystemVerilog, no UVM dependency so
// that it can be used by the UVM V_Sequence layer AND by the Verilator smoke
// test). It produces a list of RV32IM instruction words that exercises the
// multiplier scenarios of the MUL verification plan (notes/mul_plan.md §2.7):
//
//   single       : one M op with class-weighted operands (corner values first)
//   sign_matrix  : MULH / MULHSU / MULHU x {pos,neg} x {pos,neg}
//   special_regs : rd = x0, rs1 == rs2, rd == rs1, rd == rs2, all equal
//   back_to_back : 2..5 independent M ops with no gap (MULH x MULH, MULH->MUL, ...)
//   dependency   : RAW distance 1 / 2, MULH->MUL, MUL->store data, MUL->address,
//                  DIV->MUL, MUL->branch condition, accumulate chains
//   after_load   : LW then an independent MULH/MUL (with data wait states the
//                  MULH FSM ends in FINISH while WB waits -> external stall),
//                  then a load-use MUL
//   before_branch: M op followed by a taken branch, M op in the branch shadow
//                  (must never reach EX), M op after a not-taken branch
//   div_mix      : DIV / REM interleaved with M ops (ALU multi-cycle + MUL)
//   alu_mix      : RV32I ALU operators, LUI/AUIPC, AUIPC+JALR pattern (ALU agent)
//   div_corners  : divisor classes sweeping the divider latency 3..35, divide by
//                  zero, INT_MIN / -1 (ALU agent, risc_m_02 / risc_m_03)
//   lsu_mix      : lb/lh/lw/lbu/lhu + sb/sh/sw, aligned and misaligned, with M
//                  ops around (ALU address path, misaligned 2nd pass in EX)
//
// Register convention: x0 zero, x1 temp, x2 data-window pointer, x3 end-of-test
// temp; M-op operands / destinations are x4..x31 (x0 as rd with pct_rd_x0).
// Memory: all loads/stores go to data_base + [0, 0x3FC]; the end-of-test block
// stores x0 to end_store_addr and then spins (jal x0, 0) - the same convention
// as tb/sim/smoke. The team's Instructions agent can replace the end block
// (set emit_end_block = 0 and append its own).
//
// Expected observations for the checkers:
//   n_mul_if_expected = number of MUL/MULH/MULHSU/MULHU that reach EX
//                       (shadow victims excluded) -> must equal the number of
//                       transactions reported by the MUL monitor.
// =============================================================================
package mul_program_pkg;
  import rv32m_ref_pkg::*;

  // ---------------------------------------------------------------------------
  // RV32IM instruction ENCODERS: build 32-bit words field by field.
  // Every RISC-V instruction = fields packed at fixed positions:
  //   [6:0] opcode, [11:7] rd, [14:12] funct3, [19:15] rs1, [24:20] rs2, [31:25] funct7
  // ---------------------------------------------------------------------------
  localparam logic [6:0] OPC_LUI    = 7'h37;   // LUI
  localparam logic [6:0] OPC_AUIPC  = 7'h17;   // AUIPC
  localparam logic [6:0] OPC_JAL    = 7'h6F;   // JAL
  localparam logic [6:0] OPC_JALR   = 7'h67;   // JALR
  localparam logic [6:0] OPC_BRANCH = 7'h63;   // branches (BEQ, BNE, ...)
  localparam logic [6:0] OPC_LOAD   = 7'h03;   // loads (LB, LH, LW, ...)
  localparam logic [6:0] OPC_STORE  = 7'h23;   // stores (SB, SH, SW)
  localparam logic [6:0] OPC_OPIMM  = 7'h13;   // immediate ALU ops (ADDI, ...)
  localparam logic [6:0] OPC_OP     = 7'h33;   // register ALU ops (ADD, MUL, ...)

  // R-type: {funct7, rs2, rs1, funct3, rd, opcode} - register-register ops
  function automatic logic [31:0] enc_r(input logic [6:0] f7, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] opc);
    return {f7, rs2, rs1, f3, rd, opc};
  endfunction

  // I-type: {imm[11:0], rs1, funct3, rd, opcode} - immediate ops + loads + jalr
  function automatic logic [31:0] enc_i(input logic [11:0] imm, input logic [4:0] rs1, input logic [2:0] f3,
                                        input logic [4:0] rd, input logic [6:0] opc);
    return {imm, rs1, f3, rd, opc};
  endfunction

  // S-type: immediate SPLIT in two parts - {imm[11:5], rs2, rs1, f3, imm[4:0], op}
  function automatic logic [31:0] enc_s(input logic [11:0] imm, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3, input logic [6:0] opc);
    return {imm[11:5], rs2, rs1, f3, imm[4:0], opc};
  endfunction

  // B-type: branch offset SPLIT and SCRAMBLED (bit0 is not stored, always 0):
  // {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}
  function automatic logic [31:0] enc_b(input logic [12:0] off, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3);
    return {off[12], off[10:5], rs2, rs1, f3, off[4:1], off[11], OPC_BRANCH};
  endfunction

  // U-type: {imm[31:12], rd, opcode} - the upper 20 bits (LUI / AUIPC)
  function automatic logic [31:0] enc_u(input logic [19:0] imm20, input logic [4:0] rd, input logic [6:0] opc);
    return {imm20, rd, opc};
  endfunction

  // J-type: jump offset SPLIT and SCRAMBLED like B-type:
  // {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode}
  function automatic logic [31:0] enc_j(input logic [20:0] off, input logic [4:0] rd);
    return {off[20], off[10:1], off[11], off[19:12], rd, OPC_JAL};
  endfunction

  // MNEMONICS: one function per assembly instruction, so the scenario blocks
  // read like assembly: i_addi(rd, rs1, imm) == "addi rd, rs1, imm".
  // Each just calls the right encoder with the right opcode/funct values.
  function automatic logic [31:0] i_lui (input logic [4:0] rd, input logic [19:0] imm20); return enc_u(imm20, rd, OPC_LUI); endfunction
  function automatic logic [31:0] i_addi(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b000, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_xori(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b100, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_ori (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b110, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_andi(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b111, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slli(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0000000, sh}, rs1, 3'b001, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_srli(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0000000, sh}, rs1, 3'b101, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_srai(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0100000, sh}, rs1, 3'b101, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slti (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b010, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_sltiu(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b011, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slt (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b010, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sltu(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b011, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sll (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b001, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_srl (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b101, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sra (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h20, rs2, rs1, 3'b101, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_auipc(input logic [4:0] rd, input logic [19:0] imm20); return enc_u(imm20, rd, OPC_AUIPC); endfunction
  function automatic logic [31:0] i_jalr(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b000, rd, OPC_JALR); endfunction
  function automatic logic [31:0] i_add (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b000, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sub (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h20, rs2, rs1, 3'b000, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_xor (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b100, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_or  (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b110, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_and (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b111, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_lw  (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b010, rd, OPC_LOAD); endfunction
  function automatic logic [31:0] i_sw  (input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm); return enc_s(imm, rs2, rs1, 3'b010, OPC_STORE); endfunction
  // generic load/store: f3 = 000 lb / 001 lh / 010 lw / 100 lbu / 101 lhu ; 000 sb / 001 sh / 010 sw
  function automatic logic [31:0] i_load (input logic [2:0] f3, input logic [4:0] rd,  input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, f3, rd, OPC_LOAD); endfunction
  function automatic logic [31:0] i_store(input logic [2:0] f3, input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm); return enc_s(imm, rs2, rs1, f3, OPC_STORE); endfunction
  function automatic logic [31:0] i_beq (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b000); endfunction
  function automatic logic [31:0] i_bne (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b001); endfunction
  function automatic logic [31:0] i_blt (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b100); endfunction
  function automatic logic [31:0] i_bge (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b101); endfunction
  function automatic logic [31:0] i_jal (input logic [4:0] rd, input logic [20:0] off); return enc_j(off, rd); endfunction
  function automatic logic [31:0] i_nop (); return i_addi(5'd0, 5'd0, 12'd0); endfunction
  // M extension: funct7 = 0000001, funct3 = rv32m_op_e
  function automatic logic [31:0] i_m(input rv32m_op_e op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2);
    return enc_r(7'h01, rs2, rs1, op[2:0], rd, OPC_OP);
  endfunction

  function automatic string op_name(input rv32m_op_e op);
    case (op)
      MUL: return "mul"; MULH: return "mulh"; MULHSU: return "mulhsu"; MULHU: return "mulhu";
      DIV: return "div"; DIVU: return "divu"; REM: return "rem"; default: return "remu";
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Program word with annotation
  // ---------------------------------------------------------------------------
  // One generated instruction = the binary word + its assembly text + which
  // scenario block produced it (used in listings and debug logs).
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [31:0] word;     // the 32-bit instruction
    string       text;     // assembly text, e.g. "mulh x5, x6, x7"
    string       tag;      // scenario tag, e.g. "back_to_back"
  } prog_word_t;

  // The 11 kinds of scenario blocks the generator can emit (weights below).
  typedef enum int {BLK_SINGLE, BLK_SIGN_MATRIX, BLK_SPECIAL_REGS, BLK_BACK_TO_BACK,
                    BLK_DEPENDENCY, BLK_AFTER_LOAD, BLK_BEFORE_BRANCH, BLK_DIV_MIX,
                    BLK_ALU_MIX, BLK_DIV_CORNERS, BLK_LSU_MIX} blk_kind_e;
  localparam int N_BLK_KINDS = 11;

  // ---------------------------------------------------------------------------
  // Generator
  // ---------------------------------------------------------------------------
  class mul_program_gen;
    // -------- INPUT knobs (set by the sequence / smoke driver) ----------------
    int unsigned n_blocks        = 40;   // how many scenario blocks to emit
    // -- block MIX weights: relative chance each block type is picked --
    int unsigned w_single        = 30;   // one M op, corner-weighted operands
    int unsigned w_sign_matrix   = 6;    // MULH* x sign combinations
    int unsigned w_special_regs  = 8;    // rd=x0, rs1==rs2, rd==rs1, ...
    int unsigned w_back_to_back  = 15;   // 2..5 M ops with no gap
    int unsigned w_dependency    = 15;   // RAW distance 1/2, chains, forwarding
    int unsigned w_after_load    = 12;   // LW then MULH/MUL (stall + load-use)
    int unsigned w_before_branch = 8;    // M op + taken/not-taken branch
    int unsigned w_div_mix       = 6;    // DIV/REM interleaved with M ops
    int unsigned w_alu_mix       = 10;   // RV32I ALU ops (ALU agent checks)
    int unsigned w_div_corners   = 8;    // divisor classes -> latency 3..35, /0, ovf
    int unsigned w_lsu_mix       = 6;    // loads/stores incl. misaligned (ALU addr)
    int unsigned pct_misaligned  = 40;   // % of lsu_mix that are misaligned (2 passes)
    int unsigned pct_rd_x0       = 3;    // % of M ops writing x0
    int unsigned pct_mulh        = 60;   // % of MUL picks that are MULH*
    // operand CLASS weights, indexed by operand_class_e (corners get more)
    int unsigned w_opclass[12]   = '{5, 5, 5, 5, 5, 3, 3, 6, 15, 18, 15, 15};
    logic [31:0] data_base       = 32'h0001_0000;  // data window base
    logic [31:0] end_store_addr  = 32'h0001_0FFC;  // end-of-test store address
    bit          emit_end_block  = 1'b1;   // append the final store+spin block
    bit          init_all_regs   = 1'b1;   // start with reg initialization

    // -------- OUTPUTS (filled by build()) ------------------------------------
    prog_word_t  prog[$];                  // the generated instruction stream
    int unsigned n_m_ops[8];               // M ops by funct3 (incl. shadow ones)
    int unsigned n_mul_if_expected;        // MUL-family ops that will REACH EX
    int unsigned n_shadow_ops;             // MUL-family ops in a branch shadow
    int unsigned n_blocks_by_kind[N_BLK_KINDS];  // per-block-type histogram

    function new();                        // nothing to do in the constructor
    endfunction

    // -------- low-level helpers ----------------------------------------------
    // Append one instruction to the program (word + text + tag stay together).
    function void emit(input logic [31:0] w, input string text, input string tag);
      prog_word_t p;
      p.word = w; p.text = text; p.tag = tag;
      prog.push_back(p);               // queue push_back
    endfunction

    function int unsigned size();
      return prog.size();              // how many words generated so far
    endfunction

    // Load an arbitrary 32-bit constant into a register ("li rd, value").
    // Small values (fit in 12 signed bits) = one ADDI from x0;
    // big values = LUI + ADDI (the +0x800 compensates ADDI's sign extension).
    function void set_reg(input logic [4:0] rd, input logic [31:0] value, input string tag);
      logic [31:0] hi;
      logic [11:0] lo;
      if (rd == 5'd0) return;          // x0 is hardwired to 0 - nothing to do
      if ((value[31:11] == 21'h0) || (value[31:11] == 21'h1F_FFFF)) begin
        // value fits in signed 12 bits -> single ADDI from x0
        emit(i_addi(rd, 5'd0, value[11:0]), $sformatf("addi x%0d, x0, %0d", rd, $signed(value[11:0])), tag);
      end else begin
        lo = value[11:0];              // low 12 bits (will be sign-extended)
        hi = value + 32'h0000_0800;    // add 0x800 so LUI's + sign-extended lo == value
        emit(i_lui(rd, hi[31:12]), $sformatf("lui x%0d, 0x%05h", rd, hi[31:12]), tag);
        if (lo != 12'h0)               // skip ADDI when the low part is zero
          emit(i_addi(rd, rd, lo), $sformatf("addi x%0d, x%0d, %0d", rd, rd, $signed(lo)), tag);
      end
    endfunction

    // -------- random helpers --------------------------------------------------
    // pick_reg: a random register in x4..x31 (x0-x3 are reserved by convention)
    function logic [4:0] pick_reg();
      return 5'($urandom_range(31, 4));
    endfunction

    function logic [4:0] pick_reg_ne(input logic [4:0] a);
      logic [4:0] r;
      do r = pick_reg(); while (r == a);
      return r;
    endfunction

    function logic [4:0] pick_reg_ne2(input logic [4:0] a, input logic [4:0] b);
      logic [4:0] r;
      do r = pick_reg(); while ((r == a) || (r == b));
      return r;
    endfunction

    // pick_rd: destination register, occasionally x0 (pct_rd_x0 % of the time)
    function logic [4:0] pick_rd();
      if ($urandom_range(99) < pct_rd_x0) return 5'd0;
      return pick_reg();
    endfunction

    // pick_class: choose an operand CLASS by WEIGHT (w_opclass[]).
    // Trick: sum all weights, draw a random point in [0,total), walk the
    // cumulative sum until the point falls inside one class' slice.
    function operand_class_e pick_class();
      int unsigned total = 0, r, acc = 0;
      for (int i = 0; i < 12; i++) total += w_opclass[i];   // sum all weights
      r = $urandom_range(total - 1);                        // random point
      for (int i = 0; i < 12; i++) begin
        acc += w_opclass[i];                                // running total
        if (r < acc) return operand_class_e'(i);            // found our slice
      end
      return OPC_POS_LARGE;                                 // fallback (never hit)
    endfunction

    function logic [31:0] value_of_class(input operand_class_e c);
      case (c)
        OPC_ZERO:      return 32'h0000_0000;
        OPC_ONE:       return 32'h0000_0001;
        OPC_MINUS_ONE: return 32'hFFFF_FFFF;
        OPC_INT_MAX:   return 32'h7FFF_FFFF;
        OPC_INT_MIN:   return 32'h8000_0000;
        OPC_ALT_AA:    return 32'hAAAA_AAAA;
        OPC_ALT_55:    return 32'h5555_5555;
        OPC_POW2:      return 32'h1 << $urandom_range(30, 1);
        OPC_POS_SMALL: return 32'($urandom_range(32'h0000_FFFF, 32'h2));
        OPC_POS_LARGE: return 32'($urandom_range(32'h7FFF_FFFE, 32'h0001_0000));
        OPC_NEG_SMALL: return 32'($urandom_range(32'hFFFF_FFFE, 32'hFFFF_0000));
        default:       return 32'($urandom_range(32'hFFFE_FFFF, 32'h8000_0001));
      endcase
    endfunction

    // pick_value: a concrete number from the class chosen by pick_class()
    function logic [31:0] pick_value();
      return value_of_class(pick_class());
    endfunction

    // pick_signed_value: keep drawing until the sign bit matches (neg=1 -> negative)
    function logic [31:0] pick_signed_value(input bit negative);
      logic [31:0] v;
      do v = pick_value(); while (v[31] != negative);
      return v;
    endfunction

    // -- op pickers (each returns a random member of its family) --
    function rv32m_op_e pick_mul_op();     // MUL, or MULH* with pct_mulh %
      if ($urandom_range(99) < pct_mulh) return rv32m_op_e'($urandom_range(3, 1));  // 1..3 = MULH/MULHSU/MULHU
      return MUL;
    endfunction

    function rv32m_op_e pick_mulh_op();    // always MULH/MULHSU/MULHU (1..3)
      return rv32m_op_e'($urandom_range(3, 1));
    endfunction

    function rv32m_op_e pick_div_op();     // always DIV/DIVU/REM/REMU (4..7)
      return rv32m_op_e'($urandom_range(7, 4));
    endfunction

    // Emit one M-family op AND update the bookkeeping counters:
    //   n_m_ops[op]        - how many of each funct3 were generated
    //   n_mul_if_expected  - MUL ops that will actually reach EX
    //   n_shadow_ops       - MUL ops in a taken-branch shadow (never reach EX)
    function void m_op(input rv32m_op_e op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2,
                       input string tag, input bit in_shadow = 1'b0);
      emit(i_m(op, rd, rs1, rs2), $sformatf("%s x%0d, x%0d, x%0d", op_name(op), rd, rs1, rs2), tag);
      n_m_ops[op]++;
      if (is_mul_op(op)) begin
        if (in_shadow) n_shadow_ops++;    // victim of a taken branch -> no EX
        else           n_mul_if_expected++;  // will show on the MUL interface
      end
    endfunction

    // Random word-aligned offset inside the data window [0, 0x3FC]
    function logic [11:0] pick_data_offset();
      return 12'($urandom_range(12'h3FC >> 2) << 2);
    endfunction

    // -------- scenario blocks --------
    // One M op with class-weighted operands (corner values first).
    function void blk_single();
      logic [4:0] a, b, d;
      a = pick_reg(); b = pick_reg(); d = pick_rd();
      set_reg(a, pick_value(), "single");
      if (b != a) set_reg(b, pick_value(), "single");
      m_op(pick_mul_op(), d, a, b, "single");
    endfunction

    // MULH/MULHSU/MULHU x {pos,neg} x {pos,neg} = 12 cells.
    function void blk_sign_matrix();
      logic [4:0] a, b;
      rv32m_op_e ops[3] = '{MULH, MULHSU, MULHU};
      a = pick_reg(); b = pick_reg_ne(a);
      foreach (ops[i]) begin
        for (int s = 0; s < 4; s++) begin
          set_reg(a, pick_signed_value(s[0]), "sign_matrix");
          set_reg(b, pick_signed_value(s[1]), "sign_matrix");
          m_op(ops[i], pick_rd(), a, b, "sign_matrix");
        end
      end
    endfunction

    // rd=x0, rs1==rs2, rd==rs1, rd==rs2, all equal.
    function void blk_special_regs();
      logic [4:0] a, b;
      a = pick_reg(); b = pick_reg_ne(a);
      set_reg(a, pick_value(), "special_regs");
      set_reg(b, pick_value(), "special_regs");
      m_op(pick_mul_op(), 5'd0, a, b, "special_regs:rd_x0");
      m_op(pick_mul_op(), pick_reg_ne2(a, b), a, a, "special_regs:rs1_eq_rs2");
      m_op(pick_mul_op(), a, a, b, "special_regs:rd_eq_rs1");
      m_op(pick_mul_op(), b, a, b, "special_regs:rd_eq_rs2");
      m_op(pick_mul_op(), a, a, a, "special_regs:all_equal");
    endfunction

    // 2..5 independent M ops with NO gap (pure back-to-back).
    function void blk_back_to_back();
      int unsigned n;
      logic [4:0] a, b, d;
      n = $urandom_range(5, 2);
      a = pick_reg(); b = pick_reg_ne(a);
      set_reg(a, pick_value(), "back_to_back");
      set_reg(b, pick_value(), "back_to_back");
      // destinations distinct from the sources -> no RAW between the M ops
      for (int i = 0; i < n; i++) begin
        d = pick_reg_ne2(a, b);
        m_op(pick_mul_op(), d, a, b, "back_to_back");
      end
    endfunction

    // RAW hazards: distance 1/2, MULH->MUL, store, address, DIV->MUL, branch, chain.
    function void blk_dependency();
      logic [4:0] a, b, d, e;
      logic [11:0] off;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, d);
      off = pick_data_offset();
      set_reg(a, pick_value(), "dependency");
      set_reg(b, pick_value(), "dependency");
      case ($urandom_range(8))
        0: begin  // MUL -> ALU consumer, distance 1 (EX->ID forwarding of the MUL result)
          m_op(MUL, d, a, b, "dep:mul_alu_d1");
          emit(i_add(e, d, d), $sformatf("add x%0d, x%0d, x%0d", e, d, d), "dep:mul_alu_d1");
        end
        1: begin  // MUL -> ALU consumer, distance 2
          m_op(MUL, d, a, b, "dep:mul_alu_d2");
          emit(i_nop(), "nop", "dep:mul_alu_d2");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "dep:mul_alu_d2");
        end
        2: begin  // MULH -> dependent MUL (distance 1)
          m_op(pick_mulh_op(), d, a, b, "dep:mulh_mul");
          m_op(MUL, e, d, b, "dep:mulh_mul");
        end
        3: begin  // MULH -> dependent MULH
          m_op(pick_mulh_op(), d, a, b, "dep:mulh_mulh");
          m_op(pick_mulh_op(), e, a, d, "dep:mulh_mulh");
        end
        4: begin  // MUL -> store data -> load back
          m_op(pick_mul_op(), d, a, b, "dep:mul_store");
          emit(i_sw(d, 5'd2, off), $sformatf("sw x%0d, %0d(x2)", d, off), "dep:mul_store");
          emit(i_lw(e, 5'd2, off), $sformatf("lw x%0d, %0d(x2)", e, off), "dep:mul_store");
        end
        5: begin  // MUL result used as address (offset * 4 + data pointer)
          set_reg(a, 32'(off >> 2), "dep:mul_addr");
          set_reg(b, 32'd4, "dep:mul_addr");
          m_op(MUL, d, a, b, "dep:mul_addr");
          emit(i_add(d, d, 5'd2), $sformatf("add x%0d, x%0d, x2", d, d), "dep:mul_addr");
          emit(i_sw(a, d, 12'd0), $sformatf("sw x%0d, 0(x%0d)", a, d), "dep:mul_addr");
          emit(i_lw(e, d, 12'd0), $sformatf("lw x%0d, 0(x%0d)", e, d), "dep:mul_addr");
        end
        6: begin  // DIV (multi-cycle ALU) -> dependent MUL
          m_op(pick_div_op(), d, a, b, "dep:div_mul");
          m_op(MUL, e, d, a, "dep:div_mul");
        end
        7: begin  // MUL result decides a branch (always taken: rd == rd) with a NOP in the shadow
          m_op(MUL, d, a, b, "dep:mul_branch");
          emit(i_beq(d, d, 13'd8), $sformatf("beq x%0d, x%0d, +8", d, d), "dep:mul_branch");
          emit(i_nop(), "nop (shadow)", "dep:mul_branch");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "dep:mul_branch");
        end
        default: begin  // accumulate chain rd == rs1
          m_op(MUL, d, a, b, "dep:chain");
          m_op(MUL, d, d, b, "dep:chain");
          m_op(pick_mulh_op(), d, d, a, "dep:chain");
        end
      endcase
    endfunction

    // LW then MULH/MUL (FSM overlaps the load wait) then a load-use MUL.
    function void blk_after_load();
      logic [4:0] a, l, e, f, d, g;
      logic [11:0] off;
      a = pick_reg(); l = pick_reg_ne(a);
      e = pick_reg_ne2(a, l); f = pick_reg_ne2(a, l);
      d = pick_reg_ne2(l, e); g = pick_reg_ne2(l, d);
      off = pick_data_offset();
      set_reg(a, pick_value(), "after_load");
      emit(i_sw(a, 5'd2, off), $sformatf("sw x%0d, %0d(x2)", a, off), "after_load");
      set_reg(e, pick_value(), "after_load");
      set_reg(f, pick_value(), "after_load");
      emit(i_lw(l, 5'd2, off), $sformatf("lw x%0d, %0d(x2)", l, off), "after_load");
      case ($urandom_range(2))
        0: m_op(pick_mulh_op(), d, e, f, "after_load:mulh_indep");   // FSM runs while the load waits
        1: m_op(MUL, d, e, f, "after_load:mul_indep");
        default: begin
          emit(i_nop(), "nop", "after_load");
          m_op(pick_mulh_op(), d, e, f, "after_load:mulh_indep_d2");
        end
      endcase
      m_op(pick_mul_op(), g, l, e, "after_load:load_use");   // needs the load result
    endfunction

    // M op + taken branch, M op in the shadow (never reaches EX), M op after not-taken.
    function void blk_before_branch();
      logic [4:0] a, b, d, e;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, b);
      set_reg(a, pick_value(), "before_branch");
      set_reg(b, pick_value(), "before_branch");
      case ($urandom_range(2))
        0: begin  // MULH then taken branch, MUL in the shadow (never reaches EX)
          m_op(pick_mulh_op(), d, a, b, "before_branch:mulh_taken");
          emit(i_beq(5'd0, 5'd0, 13'd12), "beq x0, x0, +12", "before_branch:mulh_taken");
          m_op(MUL, e, a, b, "before_branch:shadow", 1'b1);
          emit(i_nop(), "nop (shadow)", "before_branch:shadow");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "before_branch:target");
        end
        1: begin  // MUL then taken branch, MULH in the shadow
          m_op(MUL, d, a, b, "before_branch:mul_taken");
          emit(i_beq(5'd0, 5'd0, 13'd12), "beq x0, x0, +12", "before_branch:mul_taken");
          m_op(pick_mulh_op(), e, a, b, "before_branch:shadow", 1'b1);
          emit(i_nop(), "nop (shadow)", "before_branch:shadow");
          emit(i_add(e, d, b), $sformatf("add x%0d, x%0d, x%0d", e, d, b), "before_branch:target");
        end
        default: begin  // not-taken branch then M op (executes normally)
          emit(i_bne(5'd0, 5'd0, 13'd8), "bne x0, x0, +8 (not taken)", "before_branch:not_taken");
          m_op(pick_mul_op(), d, a, b, "before_branch:after_not_taken");
        end
      endcase
    endfunction

    // DIV/REM interleaved with M ops (multi-cycle ALU + multiplier together).
    function void blk_div_mix();
      logic [4:0] a, b, d, e, f, g;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, b); f = pick_reg_ne2(a, b); g = pick_reg_ne2(a, b);
      set_reg(a, pick_value(), "div_mix");
      set_reg(b, pick_value(), "div_mix");
      m_op(pick_div_op(), d, a, b, "div_mix");
      m_op(pick_mul_op(), e, a, b, "div_mix");
      m_op(pick_div_op(), f, b, a, "div_mix");
      m_op(pick_mul_op(), g, e, f, "div_mix");
    endfunction

    // RV32I ALU operators on random registers (+ AUIPC/JALR pattern) - ALU agent coverage
    // RV32I ALU ops, LUI/AUIPC, AUIPC+JALR pattern (ALU agent coverage).
    function void blk_alu_mix();
      int unsigned n;
      logic [4:0]  d, r1, r2;
      logic [11:0] imm;
      logic [4:0]  sh;
      n = $urandom_range(8, 4);
      for (int i = 0; i < n; i++) begin
        d = pick_rd(); r1 = pick_reg(); r2 = pick_reg();
        imm = 12'($urandom()); sh = 5'($urandom());
        case ($urandom_range(21))
          0:  emit(i_add (d, r1, r2), $sformatf("add x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          1:  emit(i_sub (d, r1, r2), $sformatf("sub x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          2:  emit(i_sll (d, r1, r2), $sformatf("sll x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          3:  emit(i_slt (d, r1, r2), $sformatf("slt x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          4:  emit(i_sltu(d, r1, r2), $sformatf("sltu x%0d, x%0d, x%0d", d, r1, r2), "alu_mix");
          5:  emit(i_xor (d, r1, r2), $sformatf("xor x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          6:  emit(i_srl (d, r1, r2), $sformatf("srl x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          7:  emit(i_sra (d, r1, r2), $sformatf("sra x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          8:  emit(i_or  (d, r1, r2), $sformatf("or x%0d, x%0d, x%0d",   d, r1, r2), "alu_mix");
          9:  emit(i_and (d, r1, r2), $sformatf("and x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          10: emit(i_addi (d, r1, imm), $sformatf("addi x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          11: emit(i_slti (d, r1, imm), $sformatf("slti x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          12: emit(i_sltiu(d, r1, imm), $sformatf("sltiu x%0d, x%0d, %0d", d, r1, $signed(imm)), "alu_mix");
          13: emit(i_xori (d, r1, imm), $sformatf("xori x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          14: emit(i_ori  (d, r1, imm), $sformatf("ori x%0d, x%0d, %0d",   d, r1, $signed(imm)), "alu_mix");
          15: emit(i_andi (d, r1, imm), $sformatf("andi x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          16: emit(i_slli (d, r1, sh),  $sformatf("slli x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          17: emit(i_srli (d, r1, sh),  $sformatf("srli x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          18: emit(i_srai (d, r1, sh),  $sformatf("srai x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          19: emit(i_lui  (d, 20'($urandom())), $sformatf("lui x%0d, <rand>", d), "alu_mix");
          20: emit(i_auipc(d, 20'($urandom())), $sformatf("auipc x%0d, <rand>", d), "alu_mix");
          default: begin  // auipc + jalr over one shadow word (jr_stall bubble, JALR link value)
            logic [4:0] t = pick_reg();
            emit(i_auipc(t, 20'd0), $sformatf("auipc x%0d, 0", t), "alu_mix:jalr");
            emit(i_jalr(d, t, 12'd12), $sformatf("jalr x%0d, x%0d, 12", d, t), "alu_mix:jalr");
            emit(i_nop(), "nop (jalr shadow)", "alu_mix:jalr");
          end
        endcase
      end
    endfunction

    // divisor classes: sweeps the divider latency (3..35), divide by zero, signed overflow
    // Divisor classes sweeping latency 3..35, /0, INT_MIN/-1 (risc_m_02).
    function void blk_div_corners();
      int unsigned n;
      logic [4:0]  a, b, d;
      logic [31:0] dividend, divisor;
      n = $urandom_range(6, 3);
      a = pick_reg(); b = pick_reg_ne(a);
      for (int i = 0; i < n; i++) begin
        case ($urandom_range(11))
          0:  divisor = 32'h0000_0000;
          1:  divisor = 32'h0000_0001;
          2:  divisor = 32'hFFFF_FFFF;
          3:  divisor = 32'h8000_0000;
          4:  divisor = 32'h7FFF_FFFF;
          5:  divisor = 32'h1 << $urandom_range(31, 1);          // one bit: every leading-zero count
          6:  divisor = ~(32'h1 << $urandom_range(31, 1));       // negative with every leading-one count
          7:  divisor = 32'($urandom_range(32'hFFFF, 2));
          8:  divisor = 32'($urandom_range(32'hFFFF_FFFE, 32'hFFFF_0000));
          9:  divisor = 32'hFFFF_FFFE;
          10: divisor = 32'h4000_0000;
          default: divisor = $urandom();
        endcase
        case ($urandom_range(5))
          0: dividend = 32'h8000_0000;   // INT_MIN / -1 overflow, INT_MIN / x
          1: dividend = 32'h0000_0000;
          2: dividend = 32'hFFFF_FFFF;
          3: dividend = 32'h7FFF_FFFF;
          4: dividend = 32'h0000_0001;
          default: dividend = $urandom();
        endcase
        d = pick_rd();
        set_reg(a, dividend, "div_corners");
        set_reg(b, divisor,  "div_corners");
        m_op(pick_div_op(), d, a, b, "div_corners");     // rs1 = dividend, rs2 = divisor
      end
    endfunction

    // byte/half/word loads+stores, aligned and misaligned, with M ops around.
    function void blk_lsu_mix();
      int unsigned n;
      logic [4:0]  v, l, d, e;
      logic [11:0] off;
      logic [2:0]  f3;
      n = $urandom_range(4, 2);
      for (int i = 0; i < n; i++) begin
        v = pick_reg(); l = pick_reg_ne(v); d = pick_rd(); e = pick_reg_ne(v);
        off = 12'($urandom_range(12'h3F8));                     // keep addr + 3 inside the data window
        if ($urandom_range(99) >= pct_misaligned) off[1:0] = 2'b00;
        set_reg(v, pick_value(), "lsu_mix");
        f3 = 3'($urandom_range(2));                              // sb / sh / sw
        emit(i_store(f3, v, 5'd2, off), $sformatf("s%s x%0d, %0d(x2)", f3 == 0 ? "b" : f3 == 1 ? "h" : "w", v, off), "lsu_mix");
        case ($urandom_range(2))
          0: m_op(pick_mul_op(), d, v, e, "lsu_mix");
          1: emit(i_add(d, v, e), $sformatf("add x%0d, x%0d, x%0d", d, v, e), "lsu_mix");
          default: ;
        endcase
        case ($urandom_range(4))                                 // lb / lh / lw / lbu / lhu
          0: f3 = 3'b000; 1: f3 = 3'b001; 2: f3 = 3'b010; 3: f3 = 3'b100; default: f3 = 3'b101;
        endcase
        emit(i_load(f3, l, 5'd2, off), $sformatf("l%s x%0d, %0d(x2)", f3 == 0 ? "b" : f3 == 1 ? "h" : f3 == 2 ? "w" : f3 == 4 ? "bu" : "hu", l, off), "lsu_mix");
        if ($urandom_range(1)) m_op(pick_mul_op(), d, l, e, "lsu_mix:load_use");   // load-use stall + M op
      end
    endfunction

    // -------- top level -------------------------------------------------------
    // pick_block: choose ONE block kind by its weight (same cumulative-sum
    // trick as pick_class: sum weights, draw a point, walk until found).
    function blk_kind_e pick_block();
      int unsigned w[N_BLK_KINDS];
      int unsigned total = 0, r, acc = 0;
      w = '{w_single, w_sign_matrix, w_special_regs, w_back_to_back,
            w_dependency, w_after_load, w_before_branch, w_div_mix, w_alu_mix, w_div_corners, w_lsu_mix};
      for (int i = 0; i < N_BLK_KINDS; i++) total += w[i];   // sum all weights
      r = $urandom_range(total - 1);                          // random point
      for (int i = 0; i < N_BLK_KINDS; i++) begin
        acc += w[i];
        if (r < acc) return blk_kind_e'(i);                   // our slice
      end
      return BLK_SINGLE;                                      // fallback
    endfunction

    // build(): assemble the whole program. Steps:
    //   1. reset output queues and counters
    //   2. header: x2 = data pointer, optionally initialize x4..x31
    //   3. emit n_blocks random scenario blocks (weighted pick)
    //   4. end block: store x0 to end_store_addr, then spin (jal x0, 0)
    function void build();
      prog.delete();                        // start with an empty program
      n_mul_if_expected = 0;                // reset all bookkeeping counters
      n_shadow_ops = 0;
      foreach (n_m_ops[i]) n_m_ops[i] = 0;
      foreach (n_blocks_by_kind[i]) n_blocks_by_kind[i] = 0;
      // header: data pointer in x2, optional register initialization
      set_reg(5'd2, data_base, "header");   // x2 = data window base
      if (init_all_regs)
        for (int r = 4; r < 32; r++) set_reg(5'(r), pick_value(), "header");
      for (int i = 0; i < n_blocks; i++) begin   // the main block loop
        blk_kind_e k;
        k = pick_block();                  // weighted random block kind
        n_blocks_by_kind[k]++;             // histogram for the summary
        case (k)                           // run exactly one block generator
          BLK_SINGLE:        blk_single();
          BLK_SIGN_MATRIX:   blk_sign_matrix();
          BLK_SPECIAL_REGS:  blk_special_regs();
          BLK_BACK_TO_BACK:  blk_back_to_back();
          BLK_DEPENDENCY:    blk_dependency();
          BLK_AFTER_LOAD:    blk_after_load();
          BLK_BEFORE_BRANCH: blk_before_branch();
          BLK_DIV_MIX:       blk_div_mix();
          BLK_ALU_MIX:       blk_alu_mix();
          BLK_DIV_CORNERS:   blk_div_corners();
          default:           blk_lsu_mix();
        endcase
      end
      if (emit_end_block) begin            // closing marker the TB watches for
        set_reg(5'd3, end_store_addr, "end");           // x3 = marker address
        emit(i_sw(5'd0, 5'd3, 12'd0), "sw x0, 0(x3)   ; end-of-test marker", "end");
        emit(i_jal(5'd0, 21'd0), "jal x0, 0      ; spin", "end");  // infinite loop
      end
    endfunction

    // -------- export -----------------------------------------------------------
    // get_words: copy just the binary words into a plain queue (for callers
    // that do not need text/tags).
    function void get_words(ref logic [31:0] q[$]);
      q.delete();
      foreach (prog[i]) q.push_back(prog[i].word);
    endfunction

    // write_mem: save the program as a $readmemh image (with @word-address
    // header) so the Verilator smoke test / simulator can load it directly.
    function void write_mem(input string path, input logic [31:0] base_addr);
      int fd;
      fd = $fopen(path, "w");
      if (fd == 0) begin
        $display("mul_program_gen: cannot write %s", path);
        return;
      end
      $fdisplay(fd, "@%08h", base_addr >> 2);   // @-header: BYTE addr >> 2
      foreach (prog[i]) $fdisplay(fd, "%08h", prog[i].word);  // one word/line
      $fclose(fd);
    endfunction

    function void write_listing(input string path, input logic [31:0] base_addr);
      int fd;
      fd = $fopen(path, "w");
      if (fd == 0) return;
      $fdisplay(fd, "# %0d words, %0d MUL-family ops expected on the MUL interface, %0d shadow victims",
                prog.size(), n_mul_if_expected, n_shadow_ops);
      foreach (prog[i])
        $fdisplay(fd, "%08h: %08h  %-32s ; %s", base_addr + 4 * i, prog[i].word, prog[i].text, prog[i].tag);
      $fclose(fd);
    endfunction

    // summary(): one-line statistics string (words, blocks per kind, M ops per
    // funct3, and how many MUL transactions the interface should show).
    function string summary();
      return $sformatf("%0d words | blocks single=%0d sign=%0d special=%0d b2b=%0d dep=%0d load=%0d branch=%0d div=%0d alu=%0d divc=%0d lsu=%0d | MUL=%0d MULH=%0d MULHSU=%0d MULHU=%0d DIV*=%0d | expected on MUL if=%0d (shadow %0d)",
                       prog.size(), n_blocks_by_kind[0], n_blocks_by_kind[1], n_blocks_by_kind[2], n_blocks_by_kind[3],
                       n_blocks_by_kind[4], n_blocks_by_kind[5], n_blocks_by_kind[6], n_blocks_by_kind[7], n_blocks_by_kind[8], n_blocks_by_kind[9], n_blocks_by_kind[10],
                       n_m_ops[0], n_m_ops[1], n_m_ops[2], n_m_ops[3], n_m_ops[4] + n_m_ops[5] + n_m_ops[6] + n_m_ops[7],
                       n_mul_if_expected, n_shadow_ops);
    endfunction
  endclass : mul_program_gen
endpackage : mul_program_pkg
