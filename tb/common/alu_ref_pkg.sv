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
  // Import the ALU operation enum type and ONLY the enum literals we use
  // (SystemVerilog: importing the type alone does NOT bring the literals).
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

  // Put one operator into its class (used by coverage bins + statistics).
  function automatic alu_op_class_e alu_op_class(input alu_opcode_e op);
    case (op)
      ALU_ADD, ALU_SUB:                                    return ALU_CLS_ARITH;   // add/sub
      ALU_AND, ALU_OR, ALU_XOR:                            return ALU_CLS_LOGIC;   // bitwise
      ALU_SLL, ALU_SRL, ALU_SRA:                           return ALU_CLS_SHIFT;   // shifts
      ALU_SLTS, ALU_SLTU:                                  return ALU_CLS_SLT;     // set-less-than
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:  return ALU_CLS_BRANCH;  // compares
      ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU:                return ALU_CLS_DIV;     // divider
      default:                                             return ALU_CLS_OTHER;   // PULP/FPU only
    endcase
  endfunction

  // Is this operator producible by the RV32IM decoder? (= verification scope)
  function automatic bit alu_op_in_scope(input alu_opcode_e op);
    return alu_op_class(op) != ALU_CLS_OTHER;
  endfunction

  // Quick predicates built on the classification above.
  function automatic bit is_div_operator(input alu_opcode_e op);
    return alu_op_class(op) == ALU_CLS_DIV;
  endfunction

  function automatic bit is_branch_operator(input alu_opcode_e op);
    return alu_op_class(op) == ALU_CLS_BRANCH;
  endfunction

  // Map an ALU divider operator to the ISA-level enum of rv32m_ref_pkg:
  // ALU_DIVU=..00, ALU_DIV=..01, ALU_REMU=..10, ALU_REM=..11
  // (bit0 = signed op, bit1 = remainder instead of quotient)
  function automatic rv32m_op_e div_op_of(input alu_opcode_e op);
    case (op)
      ALU_DIV:  return DIV;      // signed quotient
      ALU_DIVU: return DIVU;     // unsigned quotient
      ALU_REM:  return REM;      // signed remainder
      default:  return REMU;     // ALU_REMU -> unsigned remainder
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------------
  // comparison_result_o of the ALU (VEC_MODE32): used as branch decision
  // The ALU comparator: used as the branch decision (taken / not taken) and
  // as the result source for SLTS/SLTU (0 or 1).
  function automatic bit alu_cmp_ref(input alu_opcode_e op, input logic [31:0] a, input logic [31:0] b);
    case (op)
      ALU_EQ:            return (a == b);                  // equal?
      ALU_NE:            return (a != b);                  // not equal?
      ALU_LTS, ALU_SLTS: return ($signed(a) < $signed(b)); // signed less-than
      ALU_GES:           return ($signed(a) >= $signed(b));// signed >=
      ALU_LTU, ALU_SLTU: return (a < b);                   // unsigned less-than
      ALU_GEU:           return (a >= b);                  // unsigned >=
      default:           return 1'b0;                      // not a compare op
    endcase
  endfunction

  // alu_result for every operator in scope; 'x for out-of-scope operators
  // Expected alu_result for every operator in scope; 'x for out-of-scope.
  // a = alu_operand_a, b = alu_operand_b exactly as the DUT sees them.
  function automatic logic [31:0] alu_ref(input alu_opcode_e op, input logic [31:0] a, input logic [31:0] b);
    case (op)
      ALU_ADD:  return a + b;                       // add (also LUI/AUIPC/ld-st/jal: see header)
      ALU_SUB:  return a - b;
      ALU_AND:  return a & b;                       // bitwise ops
      ALU_OR:   return a | b;
      ALU_XOR:  return a ^ b;
      ALU_SLL:  return a << b[4:0];                 // shifts use only b[4:0]
      ALU_SRL:  return a >> b[4:0];                 // logical shift right
      ALU_SRA:  return $unsigned($signed(a) >>> b[4:0]);  // arithmetic shift right
      ALU_SLTS, ALU_SLTU:
                return {31'b0, alu_cmp_ref(op, a, b)};    // result = 0 or 1
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:
                return {32{alu_cmp_ref(op, a, b)}}; // replicate cmp to all 32 bits (VEC_MODE32)
      // divider: DUT SWAPPED the operands - a = divisor, b = dividend
      ALU_DIV:  return div_ref (b, a);              // so call the model as (dividend, divisor)
      ALU_DIVU: return divu_ref(b, a);
      ALU_REM:  return rem_ref (b, a);
      ALU_REMU: return remu_ref(b, a);
      default:  return 'x;                          // out of scope - no expectation
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

  // Compute the RTL's "div_shift" counter preload - the heart of the latency
  // model. Mirrors rtl/cv32e40p_alu.sv line by line, INCLUDING the 6-bit widths
  // (the wrap at 6 bits is what makes DIVU of a divisor >= 0x80000000 take
  // only 3 cycles instead of 35!).
  function automatic int unsigned div_shift_ref(input alu_opcode_e op, input logic [31:0] divisor);
    logic [6:0]  op_bits;      // operator as bits (to read bit0 = "signed op")
    bit          div_signed;   // 1 for ALU_DIV / ALU_REM
    bit          op_a_signed;  // signed op AND negative divisor
    int unsigned n;            // leading zeros of divisor (or of ~divisor)
    logic [5:0]  clb, shift_int, shift;   // all 6 bits wide - W matters!
    op_bits     = op;                     // enum -> bit vector
    div_signed  = op_bits[0];             // ALU_DIVU=..00, DIV=..01, REMU=..10, REM=..11
    op_a_signed = divisor[31] & div_signed;   // negative divisor of a signed op
    n = op_a_signed ? leading_zeros32(~divisor) : leading_zeros32(divisor);
    clb       = 6'(n) - 6'd1;             // "count leading bits": n==0 -> 63 (wrap!)
    shift_int = (n == 32) ? 6'd31 : clb;  // divisor == 0 special case -> 31
    shift     = shift_int + (op_a_signed ? 6'd0 : 6'd1);  // 63 + 1 wraps to 0
    return shift;                         // value loaded into the divider counter
  endfunction

  // Net EX cycles of a DIV/REM = div_shift + 3 (IDLE + DIVIDE x(shift+1) + FINISH
  // - see the derivation in the big comment block above this function).
  function automatic int unsigned div_latency_ref(input alu_opcode_e op, input logic [31:0] divisor);
    return div_shift_ref(op, divisor) + 3;
  endfunction

  localparam int unsigned DIV_LATENCY_MIN = 3;    // fastest divider op (3 cycles)
  localparam int unsigned DIV_LATENCY_MAX = 35;   // slowest: divide by zero
  localparam int unsigned ALU_LATENCY     = 1;    // every non-divider op: 1 cycle

  // ---------------------------------------------------------------------------
  // Decoder expectations per instruction word (RV32IM subset used by the TB)
  // ---------------------------------------------------------------------------
  // Everything the DECODER must produce for one instruction word.
  // The scoreboard recomputes this from the tagged word and compares it with
  // what the EX stage actually did (cross-check decoder vs datapath).
  typedef struct {
    bit          in_scope;   // the TB generates this instr (RV32I w/o FENCE/ECALL/CSR + RV32M)
    bit          alu_en;     // executes in the ALU (all in scope except MUL/MULH*)
    alu_opcode_e op;         // expected alu_operator
    bit          we;         // expected regfile_alu_we (RF port-b write)
    bit          is_branch;  // branch instruction (we=0, cmp result only)
    bit          is_jump;    // JAL / JALR (link value pc+4 through the ALU)
    bit          is_lsu;     // load / store (address through ALU, no port-b write)
    bit          is_lui;     // LUI  (result = imm_u)
    bit          is_auipc;   // AUIPC (result = pc + imm_u)
    bit          is_div;     // DIV/DIVU/REM/REMU (multi-cycle)
    logic [4:0]  rd;         // destination register field of the instruction
  } alu_expect_t;

  // U-type immediate: bits [31:12] of the instruction, shifted left by 12.
  function automatic logic [31:0] instr_imm_u(input logic [31:0] w);
    return {w[31:12], 12'b0};
  endfunction

  // Decode ONE 32-bit instruction word into the expectations struct above.
  // opc = opcode [6:0], f3 = funct3 [14:12], f7 = funct7 [31:25] (RISC-V layout).
  // Unknown/unsupported encodings keep in_scope = 0 (no expectation).
  function automatic alu_expect_t alu_expect_of_instr(input logic [31:0] w);
    alu_expect_t e;
    logic [6:0] opc = w[6:0];   // main opcode
    logic [2:0] f3  = w[14:12]; // funct3
    logic [6:0] f7  = w[31:25]; // funct7 (top of R-type)
    e.in_scope = 0; e.alu_en = 0; e.op = ALU_ADD; e.we = 0;   // defaults...
    e.is_branch = 0; e.is_jump = 0; e.is_lsu = 0; e.is_lui = 0; e.is_auipc = 0; e.is_div = 0;
    e.rd = w[11:7];             // rd field exists in every format we use
    case (opc)                  // dispatch on the main opcode
      // --- U/J formats: all run as ALU_ADD with we=1 -------------------------
      7'h37: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_lui = 1;   end  // LUI
      7'h17: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_auipc = 1; end  // AUIPC
      7'h6F: begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_jump = 1;  end  // JAL
      7'h67: if (f3 == 3'b000) begin e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.we = 1; e.is_jump = 1; end  // JALR (f3=000 only)

      // --- branches (opcode 1100011): compare op from funct3, NO reg write ---
      7'h63: begin
        e.is_branch = 1; e.alu_en = 1; e.in_scope = 1;
        case (f3)
          3'b000: e.op = ALU_EQ;     // BEQ
          3'b001: e.op = ALU_NE;     // BNE
          3'b100: e.op = ALU_LTS;    // BLT
          3'b101: e.op = ALU_GES;    // BGE
          3'b110: e.op = ALU_LTU;    // BLTU
          3'b111: e.op = ALU_GEU;    // BGEU
          default: e.in_scope = 0;   // 010/011 don't exist for branches
        endcase
      end

      // --- loads (0000011): address = rs1 + imm; RF write comes from LSU -----
      7'h03: if (f3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101}) begin  // LB/LH/LW/LBU/LHU
        e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.is_lsu = 1;
      end
      // --- stores (0100011): address = rs1 + imm_s (SB/SH/SW) ---------------
      7'h23: if (f3 inside {3'b000, 3'b001, 3'b010}) begin
        e.in_scope = 1; e.alu_en = 1; e.op = ALU_ADD; e.is_lsu = 1;
      end

      // --- OP-IMM (0010011): immediate ALU ops, we=1 ------------------------
      7'h13: begin
        e.in_scope = 1; e.alu_en = 1; e.we = 1;
        case (f3)
          3'b000: e.op = ALU_ADD;    // ADDI
          3'b010: e.op = ALU_SLTS;   // SLTI
          3'b011: e.op = ALU_SLTU;   // SLTIU
          3'b100: e.op = ALU_XOR;    // XORI
          3'b110: e.op = ALU_OR;     // ORI
          3'b111: e.op = ALU_AND;    // ANDI
          3'b001: begin e.op = ALU_SLL; if (f7 != 7'h00) e.in_scope = 0; end   // SLLI: funct7 must be 0
          3'b101: begin                          // right shifts use funct7:
            if (f7 == 7'h00)      e.op = ALU_SRL; //   SRLI
            else if (f7 == 7'h20) e.op = ALU_SRA; //   SRAI
            else                  e.in_scope = 0; //   else illegal
          end
          default: e.in_scope = 0;
        endcase
      end

      // --- OP (0110011): register-register ALU ops (funct7 picks sub-op) ----
      7'h33: begin
        if (f7 == 7'h01) begin                     // funct7=0000001 -> RV32M
          e.in_scope = 1;
          if (f3[2]) begin                         // f3=1xx -> DIV/DIVU/REM/REMU -> ALU
            e.alu_en = 1; e.we = 1; e.is_div = 1;
            case (f3[1:0])
              2'b00: e.op = ALU_DIV;               // DIV
              2'b01: e.op = ALU_DIVU;              // DIVU
              2'b10: e.op = ALU_REM;               // REM
              default: e.op = ALU_REMU;            // REMU
            endcase
          end                                      // else MUL family: alu_en = 0 (multiplier)
        end else if (f7 == 7'h00 || f7 == 7'h20) begin  // base RV32I
          e.in_scope = 1; e.alu_en = 1; e.we = 1;
          case ({f7[5], f3})                       // f7[5]=1 -> "subtract variant"
            4'b0_000: e.op = ALU_ADD;              // ADD
            4'b1_000: e.op = ALU_SUB;              // SUB
            4'b0_001: e.op = ALU_SLL;              // SLL
            4'b0_010: e.op = ALU_SLTS;             // SLT
            4'b0_011: e.op = ALU_SLTU;             // SLTU
            4'b0_100: e.op = ALU_XOR;              // XOR
            4'b0_101: e.op = ALU_SRL;              // SRL
            4'b1_101: e.op = ALU_SRA;              // SRA
            4'b0_110: e.op = ALU_OR;               // OR
            4'b0_111: e.op = ALU_AND;              // AND
            default:  e.in_scope = 0;              // illegal funct7/funct3 mix
          endcase
        end
      end
      default: ;   // other opcodes (SYSTEM, FENCE, ...) -> not in scope
    endcase
    return e;
  endfunction

  // Tiny print helper: enum -> string (e.g. ALU_ADD -> "ALU_ADD").
  function automatic string alu_op_name(input alu_opcode_e op);
    return op.name();
  endfunction
endpackage : alu_ref_pkg
