// =============================================================================
// rv32m_ref_selftest.sv
// -----------------------------------------------------------------------------
// Self-test for rv32m_ref_pkg. Not part of the UVM environment.
//
// The vectors were computed independently (Python big-integer arithmetic from
// the spec definitions) and cover the RISC-V spec table 7.1 special cases plus
// sign corners for every op.
//
// Two mechanisms, same vectors:
//   1. Elaboration-time check (generate-if + $error): runs in ANY tool that
//      elaborates the design, including a pure linter/elaborator - no
//      simulation needed. The functions are constant functions, so the tool
//      evaluates them while elaborating.
//   2. Run-time check (initial block): prints PASS/FAIL in a simulator.
//
//   slang   : python3 tb/scripts/slang_check.py tb/common/rv32m_ref_pkg.sv \
//               tb/common/rv32m_ref_selftest.sv --top rv32m_ref_selftest
//   Questa  : vlog tb/common/rv32m_ref_pkg.sv tb/common/rv32m_ref_selftest.sv ;
//             vsim -c rv32m_ref_selftest -do "run -all; quit"
// =============================================================================
module rv32m_ref_selftest;
  import rv32m_ref_pkg::*;

  typedef struct packed {
    rv32m_op_e   op;
    logic [31:0] a;    // rs1 value
    logic [31:0] b;    // rs2 value
    logic [31:0] exp;  // expected rd value
  } vec_t;

  localparam int unsigned N_VEC = 60;

  localparam vec_t VEC [N_VEC] = '{
    // op      rs1            rs2            expected
    '{MUL   , 32'h00000000, 32'h00000000, 32'h00000000},
    '{MUL   , 32'h00000001, 32'h7FFFFFFF, 32'h7FFFFFFF},
    '{MUL   , 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000001},  // (-1)*(-1)
    '{MUL   , 32'h80000000, 32'h00000002, 32'h00000000},  // low word overflow to 0
    '{MUL   , 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h00000001},
    '{MUL   , 32'h12345678, 32'h9ABCDEF0, 32'h242D2080},
    '{MUL   , 32'hFFFFFFFF, 32'h00000001, 32'hFFFFFFFF},
    '{MUL   , 32'hAAAAAAAA, 32'h55555555, 32'h71C71C72},
    '{MULH  , 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000},  // (-1)*(-1) = 1 -> high 0
    '{MULH  , 32'h80000000, 32'hFFFFFFFF, 32'h00000000},  // INT_MIN*(-1) = 2^31 -> high 0
    '{MULH  , 32'h80000000, 32'h80000000, 32'h40000000},  // 2^62
    '{MULH  , 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h3FFFFFFF},
    '{MULH  , 32'hFFFFFFFF, 32'h00000001, 32'hFFFFFFFF},  // -1 -> high all ones
    '{MULH  , 32'h80000000, 32'h00000001, 32'hFFFFFFFF},
    '{MULH  , 32'h12345678, 32'h9ABCDEF0, 32'hF8CC93D6},
    '{MULH  , 32'h00000000, 32'h80000000, 32'h00000000},
    '{MULHSU, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF},  // -1 * (2^32-1)
    '{MULHSU, 32'h80000000, 32'hFFFFFFFF, 32'h80000000},  // -2^31 * (2^32-1)
    '{MULHSU, 32'h00000001, 32'hFFFFFFFF, 32'h00000000},
    '{MULHSU, 32'h7FFFFFFF, 32'hFFFFFFFF, 32'h7FFFFFFE},
    '{MULHSU, 32'hFFFFFFFF, 32'h00000001, 32'hFFFFFFFF},
    '{MULHSU, 32'h12345678, 32'h9ABCDEF0, 32'h0B00EA4E},
    '{MULHSU, 32'h80000000, 32'h00000001, 32'hFFFFFFFF},
    '{MULHU , 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE},
    '{MULHU , 32'h80000000, 32'h00000002, 32'h00000001},
    '{MULHU , 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h3FFFFFFF},
    '{MULHU , 32'h00000001, 32'hFFFFFFFF, 32'h00000000},
    '{MULHU , 32'h12345678, 32'h9ABCDEF0, 32'h0B00EA4E},
    '{MULHU , 32'h80000000, 32'h80000000, 32'h40000000},
    '{DIV   , 32'h00000007, 32'h00000002, 32'h00000003},
    '{DIV   , 32'hFFFFFFF9, 32'h00000002, 32'hFFFFFFFD},  // -7/2 = -3 (toward zero)
    '{DIV   , 32'h00000007, 32'hFFFFFFFE, 32'hFFFFFFFD},  //  7/-2 = -3
    '{DIV   , 32'hFFFFFFF9, 32'hFFFFFFFE, 32'h00000003},  // -7/-2 = 3
    '{DIV   , 32'h80000000, 32'hFFFFFFFF, 32'h80000000},  // overflow -> INT_MIN
    '{DIV   , 32'h00000005, 32'h00000000, 32'hFFFFFFFF},  // /0 -> -1
    '{DIV   , 32'h00000000, 32'h00000005, 32'h00000000},
    '{DIV   , 32'h80000000, 32'h00000001, 32'h80000000},
    '{DIV   , 32'h7FFFFFFF, 32'hFFFFFFFF, 32'h80000001},
    '{DIV   , 32'h80000000, 32'h00000002, 32'hC0000000},
    '{DIVU  , 32'hFFFFFFFF, 32'h00000002, 32'h7FFFFFFF},
    '{DIVU  , 32'h00000005, 32'h00000000, 32'hFFFFFFFF},  // /0 -> 2^32-1
    '{DIVU  , 32'h80000000, 32'hFFFFFFFF, 32'h00000000},
    '{DIVU  , 32'h00000007, 32'h00000007, 32'h00000001},
    '{DIVU  , 32'h00000003, 32'h00000007, 32'h00000000},
    '{DIVU  , 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000001},
    '{REM   , 32'h00000007, 32'h00000002, 32'h00000001},
    '{REM   , 32'hFFFFFFF9, 32'h00000002, 32'hFFFFFFFF},  // -7%2 = -1 (sign of dividend)
    '{REM   , 32'h00000007, 32'hFFFFFFFE, 32'h00000001},  //  7%-2 = 1
    '{REM   , 32'hFFFFFFF9, 32'hFFFFFFFE, 32'hFFFFFFFF},  // -7%-2 = -1
    '{REM   , 32'h80000000, 32'hFFFFFFFF, 32'h00000000},  // overflow -> 0
    '{REM   , 32'h00000005, 32'h00000000, 32'h00000005},  // %0 -> dividend
    '{REM   , 32'hFFFFFFFB, 32'h00000000, 32'hFFFFFFFB},
    '{REM   , 32'h80000000, 32'h00000002, 32'h00000000},
    '{REM   , 32'h80000000, 32'h00000003, 32'hFFFFFFFE},  // -2^31 % 3 = -2
    '{REMU  , 32'hFFFFFFFF, 32'h00000002, 32'h00000001},
    '{REMU  , 32'h00000005, 32'h00000000, 32'h00000005},  // %0 -> dividend
    '{REMU  , 32'h80000000, 32'hFFFFFFFF, 32'h80000000},
    '{REMU  , 32'h00000007, 32'hFFFFFFFF, 32'h00000007},
    '{REMU  , 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000},
    '{REMU  , 32'h12345678, 32'h00001000, 32'h00000678}
  };

  // ---------------------------------------------------------------------------
  // 1. Elaboration-time checks
  // ---------------------------------------------------------------------------
  for (genvar i = 0; i < N_VEC; i++) begin : g_elab_check
    if (rv32m_ref(VEC[i].op, VEC[i].a, VEC[i].b) !== VEC[i].exp) begin : g_fail
      $error("rv32m_ref self-test: vector %0d (%s a=%h b=%h) exp=%h got=%h",
             i, VEC[i].op.name(), VEC[i].a, VEC[i].b, VEC[i].exp,
             rv32m_ref(VEC[i].op, VEC[i].a, VEC[i].b));
    end
  end

  // Coverage-helper sanity (also at elaboration)
  if (classify_operand(32'h0)          != OPC_ZERO)      $error("classify_operand: zero");
  if (classify_operand(32'h1)          != OPC_ONE)       $error("classify_operand: one");
  if (classify_operand(32'hFFFF_FFFF)  != OPC_MINUS_ONE) $error("classify_operand: -1");
  if (classify_operand(32'h7FFF_FFFF)  != OPC_INT_MAX)   $error("classify_operand: int_max");
  if (classify_operand(32'h8000_0000)  != OPC_INT_MIN)   $error("classify_operand: int_min");
  if (classify_operand(32'h0000_4000)  != OPC_POW2)      $error("classify_operand: pow2");
  if (classify_operand(32'h0000_1234)  != OPC_POS_SMALL) $error("classify_operand: pos_small");
  if (classify_operand(32'h1234_5678)  != OPC_POS_LARGE) $error("classify_operand: pos_large");
  if (classify_operand(32'hFFFF_FFF9)  != OPC_NEG_SMALL) $error("classify_operand: neg_small");
  if (classify_operand(32'h9ABC_DEF0)  != OPC_NEG_LARGE) $error("classify_operand: neg_large");
  if (mul_signed_overflow(32'h0001_0000, 32'h0000_8000) != 1'b1) $error("mul_signed_overflow: 2^16*2^15 must overflow");
  if (mul_signed_overflow(32'h0001_0000, 32'h0000_4000) != 1'b0) $error("mul_signed_overflow: 2^16*2^14 must not overflow");
  if (mul_signed_overflow(32'hFFFF_FFFF, 32'h8000_0000) != 1'b1) $error("mul_signed_overflow: -1*INT_MIN must overflow");
  if (mul_unsigned_overflow(32'h0001_0000, 32'h0001_0000) != 1'b1) $error("mul_unsigned_overflow: 2^16*2^16");
  if (!is_rv32m_instr(32'h02C5_8533)) $error("is_rv32m_instr: mul a0,a1,a2");     // 0000001 01100 01011 000 01010 0110011
  if (rv32m_op_of(32'h02C5_9533) != MULH)   $error("rv32m_op_of: mulh");
  if (rv32m_op_of(32'h02C5_C533) != DIV)    $error("rv32m_op_of: div");
  if (rv32m_op_of(32'h02C5_F533) != REMU)   $error("rv32m_op_of: remu");
  if (is_rv32m_instr(32'h00C5_8533))  $error("is_rv32m_instr: add must not match");

  // ---------------------------------------------------------------------------
  // 2. Run-time checks (simulator)
  // ---------------------------------------------------------------------------
  initial begin : p_runtime_check
    automatic int fails = 0;
    for (int i = 0; i < N_VEC; i++) begin
      automatic logic [31:0] got;
      got = rv32m_ref(VEC[i].op, VEC[i].a, VEC[i].b);
      if (got !== VEC[i].exp) begin
        fails++;
        $display("FAIL vec %0d: %-6s a=%h b=%h exp=%h got=%h",
                 i, VEC[i].op.name(), VEC[i].a, VEC[i].b, VEC[i].exp, got);
      end
    end
    if (fails == 0) $display("rv32m_ref_selftest: PASS (%0d vectors)", N_VEC);
    else            $display("rv32m_ref_selftest: FAIL (%0d of %0d vectors)", fails, N_VEC);
    $finish;
  end
endmodule : rv32m_ref_selftest
