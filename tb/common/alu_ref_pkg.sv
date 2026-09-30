// =============================================================================
// alu_ref_pkg.sv
// -----------------------------------------------------------------------------
// Reference behaviour of the CV32E40P ALU (rtl/cv32e40p_alu.sv +
// cv32e40p_alu_div.sv) for the RV32IM configuration, seen from the EX-stage
// operands of alu_mul_if. Shared by the ALU agent, the ALU_MUL Scoreboard,
// the ALU coverage, alu_sva and the Verilator smoke checker.
//
//   alu_op_in_scope(op)      operator producible by the RV32IM decoder
//   alu_ref(op, a, b)        alu_result for the operators in scope
//   alu_cmp_ref(op, a, b)    comparison_result_o (= branch decision)
//   div_latency_ref(op, a)   cycles a DIV/DIVU/REM/REMU spends in EX net of
//                            external stalls (exact model of the RTL counter,
//                            3..35, validated on the RTL)
//   alu_expect_of_instr(w)   what the decoder must produce for instruction w
//
// Operand convention (rtl/cv32e40p_decoder.sv):
//   R/I-type ALU ops : a = rs1, b = rs2 / imm
//   LUI              : a = 0,  b = imm_u          (ALU_ADD)
//   AUIPC            : a = pc, b = imm_u          (ALU_ADD)
//   JAL / JALR       : a = pc, b = 4              (ALU_ADD, link value)
//   branches         : a = rs1, b = rs2           (ALU_EQ/NE/LTS/GES/LTU/GEU)
//   loads / stores   : a = rs1, b = imm_i / imm_s (ALU_ADD, address, no RF write)
//   DIV/DIVU/REM/REMU: a = rs2 (DIVISOR), b = rs1 (DIVIDEND) - swapped by the decoder
// =============================================================================
package alu_ref_pkg;
  import cv32e40p_pkg::alu_opcode_e;
  import cv32e40p_pkg::ALU_ADD;  import cv32e40p_pkg::ALU_SUB;
  import cv32e40p_pkg::ALU_XOR;  import cv32e40p_pkg::ALU_OR;   import cv32e40p_pkg::ALU_AND;
  import cv32e40p_pkg::ALU_SRA;  import cv32e40p_pkg::ALU_SRL;  import cv32e40p_pkg::ALU_SLL;
  import cv32e40p_pkg::ALU_LTS;  import cv32e40p_pkg::ALU_LTU;  import cv32e40p_pkg::ALU_GES;
  import cv32e40p_pkg::ALU_GEU;  import cv32e40p_pkg::ALU_EQ;   import cv32e40p_pkg::ALU_NE;
  import cv32e40p_pkg::ALU_SLTS; import cv32e40p_pkg::ALU_SLTU;
  import cv32e40p_pkg::ALU_DIVU; import cv32e40p_pkg::ALU_DIV;
  import cv32e40p_pkg::ALU_REMU; import cv32e40p_pkg::ALU_REM;
  import rv32m_ref_pkg::*;

  // ---------------------------------------------------------------------------
  // Operator classification
  // ---------------------------------------------------------------------------
  typedef enum int {
    ALU_CLS_ARITH,      // ADD, SUB
    ALU_CLS_LOGIC,      // AND, OR, XOR
    ALU_CLS_SHIFT,      // SLL, SRL, SRA
    ALU_CLS_SLT,        // SLTS, SLTU (result 0/1)
    ALU_CLS_BRANCH,     // EQ, NE, LTS, GES, LTU, GEU (result = {32{cmp}})
    ALU_CLS_DIV,        // DIV, DIVU, REM, REMU (multi-cycle)
    ALU_CLS_OTHER       // anything else: PULP / FPU only -> not producible in RV32IM
  } alu_op_class_e;

  function automatic alu_op_class_e alu_op_class(input alu_opcode_e op);
    case (op)
      ALU_ADD, ALU_SUB:                                    return ALU_CLS_ARITH;
      ALU_AND, ALU_OR, ALU_XOR:                            return ALU_CLS_LOGIC;
      ALU_SLL, ALU_SRL, ALU_SRA:                           return ALU_CLS_SHIFT;
      ALU_SLTS, ALU_SLTU:                                  return ALU_CLS_SLT;
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:  return ALU_CLS_BRANCH;
      ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU:                return ALU_CLS_DIV;
      default:                                             return ALU_CLS_OTHER;
    endcase
  endfunction

  function automatic bit alu_op_in_scope(input alu_opcode_e op);
    return alu_op_class(op) != ALU_CLS_OTHER;
  endfunction

  function automatic bit is_div_operator(input alu_opcode_e op);
    return alu_op_class(op) == ALU_CLS_DIV;
  endfunction

  function automatic bit is_branch_operator(input alu_opcode_e op);
    return alu_op_class(op) == ALU_CLS_BRANCH;
  endfunction

  // ALU_DIVU=..00, ALU_DIV=..01, ALU_REMU=..10, ALU_REM=..11 (bit0 signed, bit1 rem)
  function automatic rv32m_op_e div_op_of(input alu_opcode_e op);
    case (op)
      ALU_DIV:  return DIV;
      ALU_DIVU: return DIVU;
      ALU_REM:  return REM;
      default:  return REMU;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------------
  // comparison_result_o of the ALU (VEC_MODE32): used as branch decision
  function automatic bit alu_cmp_ref(input alu_opcode_e op, input logic [31:0] a, input logic [31:0] b);
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

  // alu_result for every operator in scope; 'x for out-of-scope operators
  function automatic logic [31:0] alu_ref(input alu_opcode_e op, input logic [31:0] a, input logic [31:0] b);
    case (op)
      ALU_ADD:  return a + b;
      ALU_SUB:  return a - b;
      ALU_AND:  return a & b;
      ALU_OR:   return a | b;
      ALU_XOR:  return a ^ b;
      ALU_SLL:  return a << b[4:0];
      ALU_SRL:  return a >> b[4:0];
      ALU_SRA:  return $unsigned($signed(a) >>> b[4:0]);
      ALU_SLTS, ALU_SLTU:
                return {31'b0, alu_cmp_ref(op, a, b)};
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:
                return {32{alu_cmp_ref(op, a, b)}};       // one byte lane per cmp_result bit, all equal in VEC_MODE32
      // divider: operand_a = divisor, operand_b = dividend
      ALU_DIV:  return div_ref (b, a);
      ALU_DIVU: return divu_ref(b, a);
      ALU_REM:  return rem_ref (b, a);
      ALU_REMU: return remu_ref(b, a);
      default:  return 'x;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Divider latency (cycles in EX net of external stalls)
  // ---------------------------------------------------------------------------
  // rtl/cv32e40p_alu.sv (widths matter: clb_result and div_shift are 6 bits)
  //   div_signed      = operator[0]                       (ALU_DIV, ALU_REM)
  //   div_op_a_signed = operand_a[31] & div_signed        (negative divisor of a signed op)
  //   ff_input        = reverse(operand_a)                 otherwise
  //                   = reverse(~operand_a)                if div_op_a_signed
  //   ff1[4:0]        = index of the first 1 of ff_input   = leading zeros (or leading ones) of the divisor
  //   clb[5:0]        = ff1 - 1                            (63 when ff1 == 0)
  //   div_shift_int   = no_one ? 31 : clb
  //   div_shift[5:0]  = div_shift_int + (div_op_a_signed ? 0 : 1)   (64 wraps to 0)
  // rtl/cv32e40p_alu_div.sv
  //   IDLE (load, Cnt <= div_shift) -> DIVIDE for Cnt+1 cycles -> FINISH (1 cycle when ex_ready)
  //   => latency = div_shift + 3
  // Resulting table (n = leading zeros of the divisor, or leading ones for a negative signed divisor):
  //   divisor 0                          : 35        (no one found)
  //   unsigned op / positive divisor      : n == 0 -> 3 (clb wraps), else n + 3   (4 .. 34)
  //   signed op, negative divisor         : -1 -> 34 (no one in ~divisor), else n + 2 (3 .. 33)
  // Validated against the RTL with tb/scripts/run_smoke.sh (all bins 3..35).
  function automatic int unsigned leading_zeros32(input logic [31:0] v);
    for (int i = 31; i >= 0; i--) if (v[i]) return 31 - i;
    return 32;
  endfunction

  function automatic int unsigned div_shift_ref(input alu_opcode_e op, input logic [31:0] divisor);
    logic [6:0]  op_bits;
    bit          div_signed;
    bit          op_a_signed;
    int unsigned n;          // leading zeros of the (possibly inverted) divisor
    logic [5:0]  clb, shift_int, shift;
    op_bits     = op;
    div_signed  = op_bits[0];
    op_a_signed = divisor[31] & div_signed;
    n = op_a_signed ? leading_zeros32(~divisor) : leading_zeros32(divisor);
    clb       = 6'(n) - 6'd1;                      // n == 0 -> 63 (RTL: 6-bit clb_result)
    shift_int = (n == 32) ? 6'd31 : clb;
    shift     = shift_int + (op_a_signed ? 6'd0 : 6'd1);   // 63 + 1 wraps to 0
    return shift;
  endfunction

  function automatic int unsigned div_latency_ref(input alu_opcode_e op, input logic [31:0] divisor);
    return div_shift_ref(op, divisor) + 3;
  endfunction

  localparam int unsigned DIV_LATENCY_MIN = 3;
  localparam int unsigned DIV_LATENCY_MAX = 35;
  localparam int unsigned ALU_LATENCY     = 1;

  // ---------------------------------------------------------------------------
  // Decoder expectations per instruction word (RV32IM subset used by the TB)
  // ---------------------------------------------------------------------------
  typedef struct {
    bit          in_scope;   // instruction the TB generates (RV32I base w/o FENCE/ECALL/EBREAK/CSR + RV32M)
    bit          alu_en;     // executes in the ALU (everything in scope except MUL/MULH/MULHSU/MULHU)
    alu_opcode_e op;         // expected alu_operator
    bit          we;         // expected regfile_alu_we (RF port b write from EX)
    bit          is_branch;
    bit          is_jump;    // JAL / JALR (link value pc+4 through the ALU)
    bit          is_lsu;     // load / store (address through the ALU, no port-b write)
    bit          is_lui;
    bit          is_auipc;
    bit          is_div;
    logic [4:0]  rd;
  } alu_expect_t;

  function automatic logic [31:0] instr_imm_u(input logic [31:0] w);
    return {w[31:12], 12'b0};
  endfunction

  function automatic alu_expect_t alu_expect_of_instr(input logic [31:0] w);
    alu_expect_t e;
    logic [6:0] opc = w[6:0];
    logic [2:0] f3  = w[14:12];
    logic [6:0] f7  = w[31:25];
    e.in_scope = 0; e.alu_en = 0; e.op = ALU_ADD; e.we = 0;
    e.is_branch = 0; e.is_jump = 0; e.is_lsu = 0; e.is_lui = 0; e.is_auipc = 0; e.is_div = 0;
    e.rd = w[11:7];
    case (opc)
      7'h37: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_lui = 1;   end
      7'h17: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_auipc = 1; end
      7'h6F: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_jump = 1;  end
      7'h67: if (f3 == 3'b000) begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_jump = 1; end
      7'h63: begin
        e.is_branch = 1; e.alu_en = 1; e.in_scope = 1;
        case (f3)
          3'b000: e.op = ALU_EQ;
          3'b001: e.op = ALU_NE;
          3'b100: e.op = ALU_LTS;
          3'b101: e.op = ALU_GES;
          3'b110: e.op = ALU_LTU;
          3'b111: e.op = ALU_GEU;
          default: e.in_scope = 0;
        endcase
      end
      7'h03: if (f3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101}) begin
        e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.is_lsu = 1;   // RF write comes from the LSU port
      end
      7'h23: if (f3 inside {3'b000, 3'b001, 3'b010}) begin
        e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.is_lsu = 1;
      end
      7'h13: begin
        e.in_scope = 1; e.alu_en = 1; e.we = 1;
        case (f3)
          3'b000: e.op = ALU_ADD;
          3'b010: e.op = ALU_SLTS;
          3'b011: e.op = ALU_SLTU;
          3'b100: e.op = ALU_XOR;
          3'b110: e.op = ALU_OR;
          3'b111: e.op = ALU_AND;
          3'b001: begin e.op = ALU_SLL; if (f7 != 7'h00) e.in_scope = 0; end
          3'b101: begin
            if (f7 == 7'h00)      e.op = ALU_SRL;
            else if (f7 == 7'h20) e.op = ALU_SRA;
            else                  e.in_scope = 0;
          end
          default: e.in_scope = 0;
        endcase
      end
      7'h33: begin
        if (f7 == 7'h01) begin                     // RV32M
          e.in_scope = 1;
          if (f3[2]) begin                         // DIV/DIVU/REM/REMU -> ALU
            e.alu_en = 1; e.we = 1; e.is_div = 1;
            case (f3[1:0])
              2'b00: e.op = ALU_DIV;
              2'b01: e.op = ALU_DIVU;
              2'b10: e.op = ALU_REM;
              default: e.op = ALU_REMU;
            endcase
          end                                      // else MUL family: alu_en = 0 (multiplier)
        end else if (f7 == 7'h00 || f7 == 7'h20) begin
          e.in_scope = 1; e.alu_en = 1; e.we = 1;
          case ({f7[5], f3})
            4'b0_000: e.op = ALU_ADD;
            4'b1_000: e.op = ALU_SUB;
            4'b0_001: e.op = ALU_SLL;
            4'b0_010: e.op = ALU_SLTS;
            4'b0_011: e.op = ALU_SLTU;
            4'b0_100: e.op = ALU_XOR;
            4'b0_101: e.op = ALU_SRL;
            4'b1_101: e.op = ALU_SRA;
            4'b0_110: e.op = ALU_OR;
            4'b0_111: e.op = ALU_AND;
            default:  e.in_scope = 0;
          endcase
        end
      end
      default: ;
    endcase
    return e;
  endfunction

  function automatic string alu_op_name(input alu_opcode_e op);
    return op.name();
  endfunction
endpackage : alu_ref_pkg
