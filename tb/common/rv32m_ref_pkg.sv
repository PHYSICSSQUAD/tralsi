// =============================================================================
// rv32m_ref_pkg.sv
// -----------------------------------------------------------------------------
// Golden (reference) functions for the RISC-V "M" standard extension, RV32.
//
// Used by:
//   * ALU_MUL Scoreboard   (MUL side: mul/mulh/mulhsu/mulhu, ALU side: div/rem)
//   * Predictor            (ISA-level model, executes the program image)
//   * coverage_collector   (operand / result classification helpers)
//
// Source of truth: RISC-V Unprivileged ISA, version 20191213, chapter 7
// (a_random_refrence/riscv-spec-20191213.pdf):
//   MUL     rd = (rs1 * rs2)[31:0]                       (same for signed/unsigned)
//   MULH    rd = (sext(rs1) * sext(rs2))[63:32]
//   MULHSU  rd = (sext(rs1) * zext(rs2))[63:32]
//   MULHU   rd = (zext(rs1) * zext(rs2))[63:32]
//   DIV     signed quotient, rounds toward zero
//   DIVU    unsigned quotient
//   REM     signed remainder, sign of the dividend (rs1)
//   REMU    unsigned remainder
//   Table 7.1 - division by zero:   DIV/DIVU -> all ones, REM/REMU -> dividend
//               signed overflow (-2^31 / -1): DIV -> -2^31, REM -> 0
//
// All functions take the ARCHITECTURAL operands (rs1 value, rs2 value).
// DUT note (rtl/cv32e40p_decoder.sv, "div/divu/rem/remu"): the core feeds the
// divider with swapped operands (alu_operand_a = rs2 = divisor,
// alu_operand_b = rs1 = dividend, OP_A_REGB_OR_FWD / OP_B_REGA_OR_FWD). The ALU
// monitor must un-swap them before calling div_ref()/rem_ref(). The multiplier
// is NOT swapped (mult_operand_a = rs1, mult_operand_b = rs2).
//
// Scope (guidelines): vanilla RV32I + RV32M only; nothing else is modelled here.
// =============================================================================
package rv32m_ref_pkg;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  localparam logic [31:0] INT32_MIN = 32'h8000_0000;
  localparam logic [31:0] INT32_MAX = 32'h7FFF_FFFF;
  localparam logic [31:0] ALL_ONES  = 32'hFFFF_FFFF;

  // RV32M opcodes. The enum value equals the funct3 field of the instruction
  // (opcode OP = 0110011, funct7 = 0000001), so decoding is a plain cast.
  typedef enum logic [2:0] {
    MUL    = 3'b000,
    MULH   = 3'b001,
    MULHSU = 3'b010,
    MULHU  = 3'b011,
    DIV    = 3'b100,
    DIVU   = 3'b101,
    REM    = 3'b110,
    REMU   = 3'b111
  } rv32m_op_e;

  // ---------------------------------------------------------------------------
  // Multiplier reference functions
  // ---------------------------------------------------------------------------
  // MUL: low 32 bits of the 64-bit product (identical for signed and unsigned).
  function automatic logic [31:0] mul_ref(input logic [31:0] a, input logic [31:0] b);
    logic [63:0] p;
    p = {32'b0, a} * {32'b0, b};
    return p[31:0];
  endfunction

  // MULH: high 32 bits of signed(rs1) * signed(rs2).
  function automatic logic [31:0] mulh_ref(input logic [31:0] a, input logic [31:0] b);
    logic signed [63:0] p;
    p = $signed({{32{a[31]}}, a}) * $signed({{32{b[31]}}, b});
    return p[63:32];
  endfunction

  // MULHSU: high 32 bits of signed(rs1) * unsigned(rs2).
  // zext(rs2) is a non-negative 64-bit signed number, so a 64-bit signed product
  // is exact (|a| <= 2^31, b < 2^32  ->  |p| < 2^63).
  function automatic logic [31:0] mulhsu_ref(input logic [31:0] a, input logic [31:0] b);
    logic signed [63:0] p;
    p = $signed({{32{a[31]}}, a}) * $signed({32'b0, b});
    return p[63:32];
  endfunction

  // MULHU: high 32 bits of unsigned(rs1) * unsigned(rs2).
  function automatic logic [31:0] mulhu_ref(input logic [31:0] a, input logic [31:0] b);
    logic [63:0] p;
    p = {32'b0, a} * {32'b0, b};
    return p[63:32];
  endfunction

  // ---------------------------------------------------------------------------
  // Divider reference functions (spec table 7.1 special cases handled first,
  // so we never rely on simulator behaviour for x/0 or INT32_MIN/-1)
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] div_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0)                              return ALL_ONES;   // quotient = -1
    if ((a == INT32_MIN) && (b == ALL_ONES))     return INT32_MIN;  // signed overflow
    return $signed(a) / $signed(b);                                 // truncates toward zero
  endfunction

  function automatic logic [31:0] divu_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0) return ALL_ONES;                                // quotient = 2^32 - 1
    return a / b;
  endfunction

  function automatic logic [31:0] rem_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0)                              return a;          // remainder = dividend
    if ((a == INT32_MIN) && (b == ALL_ONES))     return 32'h0;      // signed overflow
    return $signed(a) % $signed(b);                                 // sign of the dividend
  endfunction

  function automatic logic [31:0] remu_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0) return a;                                       // remainder = dividend
    return a % b;
  endfunction

  // ---------------------------------------------------------------------------
  // Dispatcher: expected rd value for any RV32M instruction
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] rv32m_ref(input rv32m_op_e  op,
                                            input logic [31:0] rs1_val,
                                            input logic [31:0] rs2_val);
    case (op)
      MUL:     return mul_ref   (rs1_val, rs2_val);
      MULH:    return mulh_ref  (rs1_val, rs2_val);
      MULHSU:  return mulhsu_ref(rs1_val, rs2_val);
      MULHU:   return mulhu_ref (rs1_val, rs2_val);
      DIV:     return div_ref   (rs1_val, rs2_val);
      DIVU:    return divu_ref  (rs1_val, rs2_val);
      REM:     return rem_ref   (rs1_val, rs2_val);
      REMU:    return remu_ref  (rs1_val, rs2_val);
      default: return 32'hx;
    endcase
  endfunction

  function automatic bit is_mul_op(input rv32m_op_e op);
    return (op inside {MUL, MULH, MULHSU, MULHU});
  endfunction

  function automatic bit is_div_op(input rv32m_op_e op);
    return (op inside {DIV, DIVU, REM, REMU});
  endfunction

  // ---------------------------------------------------------------------------
  // Instruction-word helpers (R-type: funct7 | rs2 | rs1 | funct3 | rd | opcode)
  // ---------------------------------------------------------------------------
  localparam logic [6:0] OPCODE_OP   = 7'b0110011;
  localparam logic [6:0] FUNCT7_MULDIV = 7'b0000001;

  function automatic bit is_rv32m_instr(input logic [31:0] instr);
    return (instr[6:0] == OPCODE_OP) && (instr[31:25] == FUNCT7_MULDIV);
  endfunction

  function automatic rv32m_op_e rv32m_op_of(input logic [31:0] instr);
    return rv32m_op_e'(instr[14:12]);
  endfunction

  function automatic logic [4:0] instr_rd (input logic [31:0] instr); return instr[11:7];  endfunction
  function automatic logic [4:0] instr_rs1(input logic [31:0] instr); return instr[19:15]; endfunction
  function automatic logic [4:0] instr_rs2(input logic [31:0] instr); return instr[24:20]; endfunction

  // ---------------------------------------------------------------------------
  // Coverage helpers
  // ---------------------------------------------------------------------------
  // Operand classes used by the MUL / ALU covergroups (vplan: m_operands_cg,
  // mulh_corners_cg, div_corners_cg). Exact corner values first, then ranges.
  typedef enum int {
    OPC_ZERO,        // 0x00000000
    OPC_ONE,         // 0x00000001
    OPC_MINUS_ONE,   // 0xFFFFFFFF
    OPC_INT_MAX,     // 0x7FFFFFFF
    OPC_INT_MIN,     // 0x80000000
    OPC_ALT_AA,      // 0xAAAAAAAA
    OPC_ALT_55,      // 0x55555555
    OPC_POW2,        // exactly one bit set (2 .. 2^30)
    OPC_POS_SMALL,   // 0x00000002 .. 0x0000FFFF (positive, 16-bit)
    OPC_POS_LARGE,   // 0x00010000 .. 0x7FFFFFFE
    OPC_NEG_SMALL,   // 0xFFFF0000 .. 0xFFFFFFFE (-65536 .. -2)
    OPC_NEG_LARGE    // 0x80000001 .. 0xFFFEFFFF
  } operand_class_e;

  function automatic bit is_pow2(input logic [31:0] v);
    return (v != 32'h0) && ((v & (v - 32'h1)) == 32'h0);
  endfunction

  function automatic operand_class_e classify_operand(input logic [31:0] v);
    if (v == 32'h0000_0000) return OPC_ZERO;
    if (v == 32'h0000_0001) return OPC_ONE;
    if (v == ALL_ONES)      return OPC_MINUS_ONE;
    if (v == INT32_MAX)     return OPC_INT_MAX;
    if (v == INT32_MIN)     return OPC_INT_MIN;
    if (v == 32'hAAAA_AAAA) return OPC_ALT_AA;
    if (v == 32'h5555_5555) return OPC_ALT_55;
    if (is_pow2(v))         return OPC_POW2;
    if (v[31] == 1'b0)      return (v <= 32'h0000_FFFF) ? OPC_POS_SMALL : OPC_POS_LARGE;
    return (v >= 32'hFFFF_0000) ? OPC_NEG_SMALL : OPC_NEG_LARGE;
  endfunction

  // 1 when the exact signed product does not fit in 32 bits, i.e. MUL's result
  // differs from the mathematical signed product (the high word is not the
  // sign extension of the low word). Interesting bin for MUL coverage.
  function automatic bit mul_signed_overflow(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] lo, hi;
    lo = mul_ref(a, b);
    hi = mulh_ref(a, b);
    return (hi != {32{lo[31]}});
  endfunction

  // 1 when the unsigned product does not fit in 32 bits.
  function automatic bit mul_unsigned_overflow(input logic [31:0] a, input logic [31:0] b);
    return (mulhu_ref(a, b) != 32'h0);
  endfunction

endpackage : rv32m_ref_pkg
