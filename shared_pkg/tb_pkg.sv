//----------------------------------------------------------------------
// File       : tb_pkg.sv
// Description: Shared team package defining RISC-V types, decoding unions,
//              and helper functions for RV32I/M verification.
//----------------------------------------------------------------------

package tb_pkg;

    typedef enum logic [6:0] {
        OP_OP   = 7'b0110011,
        OP_IMM  = 7'b0010011,
        OP_LUI  = 7'b0110111
    } opcode_e;

    typedef enum {
        ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
        ADDI, LUI,
        MUL, MULH, MULHSU, MULHU
    } instr_e;

    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } r_type_t;

    typedef union packed {
        r_type_t    r_type;
        logic [31:0] raw;
    } instr_t;

    function automatic logic [6:0] get_opcode(instr_e op);
        case (op)
            LUI:     return OP_LUI;
            ADDI:    return OP_IMM;
            default: return OP_OP;
        endcase
    endfunction

    function automatic logic [2:0] get_funct3(instr_e op);
        case (op)
            MUL:     return 3'b000;
            MULH:    return 3'b001;
            MULHSU:  return 3'b010;
            MULHU:   return 3'b011;
            ADDI:    return 3'b000;
            default: return 3'b000;
        endcase
    endfunction

    function automatic logic [6:0] get_funct7(instr_e op);
        case (op)
            MUL, MULH, MULHSU, MULHU: return 7'b0000001;
            default:                  return 7'b0000000;
        endcase
    endfunction

endpackage
