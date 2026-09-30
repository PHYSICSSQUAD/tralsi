// =============================================================================
// mul_txn.sv  (part of mul_agent_pkg)
// -----------------------------------------------------------------------------
// One multiplier-unit instruction observed in the EX stage of cv32e40p_core:
// MUL / MULH / MULHSU / MULHU (RV32M, the only instructions that use
// rtl/cv32e40p_mult.sv in the RV32IM configuration).
//
// Produced by mul_monitor, consumed by the ALU_MUL Scoreboard and by the MUL
// covergroups in coverage_collector.
//
// Field sources (see alu_mul_if.sv for the RTL mapping):
//   op                 decoded from mult_operator + mult_signed_mode
//                        MUL_MAC32        -> MUL
//                        MUL_H, mode 2'b11 -> MULH   (rs1 signed,   rs2 signed)
//                        MUL_H, mode 2'b01 -> MULHSU (rs1 signed,   rs2 unsigned)
//                        MUL_H, mode 2'b00 -> MULHU  (rs1 unsigned, rs2 unsigned)
//                      (rtl/cv32e40p_decoder.sv "supported RV32M instructions")
//   rs1_val, rs2_val   mult_operand_a / mult_operand_b in the first EX cycle
//                      (already forwarded values = architectural rs1 / rs2)
//   result             mult_result in the ex_valid cycle
//   wdata/waddr/we     register-file ALU write port in the ex_valid cycle
//   total_cycles       cycles the instruction spent in EX (first mult_en .. ex_valid)
//   stall_cycles       cycles with mult_ready && !ex_valid (EX held by LSU/WB)
//   mult_cycles        total_cycles - stall_cycles: expected 1 (MUL) / 5 (MULH*)
//                      (databook pipeline chapter: "mulh* 5 cycles";
//                       rtl/cv32e40p_mult.sv FSM IDLE->STEP0->STEP1->STEP2->FINISH)
//   multicycle_len     cycles with mult_multicycle==1: expected 0 (MUL) / 3 (MULH*)
//   cycle_start/end    monitor clock-cycle counter at start / completion (lets the
//                      coverage measure the distance between two MUL-unit ops)
//   pc, instr          tag taken from the ID issue pulse one cycle earlier
//   killed_by_reset    reset asserted while the instruction was in EX (no completion)
// =============================================================================
class mul_txn extends uvm_sequence_item;

  // ---- decoded operation ----------------------------------------------------
  rand rv32m_op_e   op;

  // ---- operands (architectural rs1 / rs2 values) ----------------------------
  rand bit [31:0]   rs1_val;
  rand bit [31:0]   rs2_val;

  // ---- raw control fields as seen on the interface (debug / protocol checks)
  mul_opcode_e      mult_operator;
  bit [1:0]         mult_signed_mode;
  bit               mult_sel_subword;   // PULP only -> must be 0
  bit [4:0]         mult_imm;           // PULP only -> must be 0
  bit [31:0]        op_c_start;         // mult_operand_c in the first cycle (REGC_ZERO -> 0)

  // ---- completion --------------------------------------------------------------
  bit [31:0]        result;
  bit [31:0]        wdata;
  bit [5:0]         waddr;
  bit               we;

  // ---- timing ----------------------------------------------------------------
  int unsigned      total_cycles;
  int unsigned      stall_cycles;
  int unsigned      mult_cycles;
  int unsigned      multicycle_len;
  int unsigned      cycle_start;        // monitor cycle counter value of the first EX cycle
  int unsigned      cycle_end;          // ... of the ex_valid cycle (cycle_end - cycle_start + 1 == total_cycles)
  time              t_start;
  time              t_end;

  // ---- tag -------------------------------------------------------------------
  bit               tag_valid;
  bit [31:0]        pc;
  bit [31:0]        instr;

  // ---- abnormal termination -----------------------------------------------------
  bit               killed_by_reset;

  constraint c_mul_unit_ops { op inside {MUL, MULH, MULHSU, MULHU}; }

  `uvm_object_utils_begin(mul_txn)
    `uvm_field_enum(rv32m_op_e,  op,               UVM_ALL_ON)
    `uvm_field_int (rs1_val,                        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (rs2_val,                        UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(mul_opcode_e, mult_operator,    UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (mult_signed_mode,               UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (mult_sel_subword,               UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (mult_imm,                       UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (op_c_start,                     UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (result,                         UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (wdata,                          UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (waddr,                          UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (we,                             UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (total_cycles,                   UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (stall_cycles,                   UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (mult_cycles,                    UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (multicycle_len,                 UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (cycle_start,                    UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (cycle_end,                      UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (t_start,                        UVM_ALL_ON | UVM_NOCOMPARE | UVM_TIME)
    `uvm_field_int (t_end,                          UVM_ALL_ON | UVM_NOCOMPARE | UVM_TIME)
    `uvm_field_int (tag_valid,                      UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (pc,                             UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (instr,                          UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (killed_by_reset,                UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "mul_txn");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Decode of the DUT control fields. Returns 0 for a combination that the
  // RV32IM decoder never produces (any other mul_opcode_e, or MUL_H with
  // signed_mode 2'b10).
  // ---------------------------------------------------------------------------
  static function bit decode_ctrl(input  mul_opcode_e operator,
                                  input  bit [1:0]    signed_mode,
                                  output rv32m_op_e   op);
    op = MUL;
    case (operator)
      MUL_MAC32: begin op = MUL; return 1; end
      MUL_H: begin
        case (signed_mode)
          2'b11:   begin op = MULH;   return 1; end
          2'b01:   begin op = MULHSU; return 1; end
          2'b00:   begin op = MULHU;  return 1; end
          default: return 0;
        endcase
      end
      default: return 0;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Expectations
  // ---------------------------------------------------------------------------
  function bit [31:0] exp_result();
    return rv32m_ref(op, rs1_val, rs2_val);
  endfunction

  function int unsigned exp_mult_cycles();
    return (op == MUL) ? MUL_LATENCY : MULH_LATENCY;
  endfunction

  function int unsigned exp_multicycle_len();
    return (op == MUL) ? 0 : MULH_MULTICYCLE_LEN;
  endfunction

  function bit is_mulh();
    return (op != MUL);
  endfunction

  // ---------------------------------------------------------------------------
  // Register fields
  // ---------------------------------------------------------------------------
  function bit [4:0] rd();        return waddr[4:0];      endfunction  // from the write port
  function bit [4:0] instr_rd();  return instr[11:7];     endfunction  // from the tagged word
  function bit [4:0] instr_rs1(); return instr[19:15];    endfunction
  function bit [4:0] instr_rs2(); return instr[24:20];    endfunction

  // ---------------------------------------------------------------------------
  // Human-readable one-liner (used in scoreboard messages)
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    string s;
    s = $sformatf("%-6s rs1=0x%08h rs2=0x%08h -> rd=x%0d res=0x%08h exp=0x%08h | cyc tot=%0d stall=%0d mult=%0d mc=%0d",
                  op.name(), rs1_val, rs2_val, rd(), result, exp_result(),
                  total_cycles, stall_cycles, mult_cycles, multicycle_len);
    if (tag_valid)       s = {s, $sformatf(" | pc=0x%08h instr=0x%08h", pc, instr)};
    if (killed_by_reset) s = {s, " | KILLED_BY_RESET"};
    return s;
  endfunction

endclass : mul_txn
