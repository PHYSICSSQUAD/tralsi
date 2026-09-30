// =============================================================================
// mul_txn.sv  (included inside mul_agent_pkg)
// =============================================================================
// WHAT THIS FILE IS:
//   The transaction = the DATA OBJECT that represents ONE multiplier-unit
//   instruction seen in the EX stage (MUL / MULH / MULHSU / MULHU).
//   The monitor CREATES it, the ALU_MUL Scoreboard and the MUL covergroups
//   CONSUME it. In UVM words: it is a uvm_sequence_item (here used only as a
//   plain data bag, because the agent is passive - no sequences drive it).
//
// Field sources (RTL names in alu_mul_if.sv / alu_mul_bind.sv):
//   op               decoded from mult_operator + mult_signed_mode
//   rs1_val/rs2_val  mult_operand_a / mult_operand_b in the FIRST EX cycle
//   result           mult_result in the ex_valid cycle
//   wdata/waddr/we   register-file write port in the ex_valid cycle
//   total_cycles     how many cycles the op stayed in EX (first .. ex_valid)
//   stall_cycles     cycles where mult_ready && !ex_valid (held by LSU/WB)
//   mult_cycles      total - stall => expected 1 (MUL) / 5 (MULH*)
//   multicycle_len   cycles with mult_multicycle==1 => expected 0 / 3
//   pc, instr        tag from the ID issue pulse one cycle before EX
//   killed_by_reset  reset hit while the op was in EX (never completed)
// =============================================================================
class mul_txn extends uvm_sequence_item;

  // ---- decoded operation (the "what" of this instruction) -------------------
  rand rv32m_op_e   op;        // rand = randomizable; constraint below limits it
                               // to MUL/MULH/MULHSU/MULHU only

  // ---- operands (the two 32-bit numbers the instruction multiplies) --------
  rand bit [31:0]   rs1_val;   // first operand  (architectural rs1 value)
  rand bit [31:0]   rs2_val;   // second operand (architectural rs2 value)

  // ---- RAW control fields exactly as seen on the interface -----------------
  // (kept for protocol/debug checks, NOT randomized - the DUT drives them)
  mul_opcode_e      mult_operator;     // MUL_MAC32 or MUL_H
  bit [1:0]         mult_signed_mode;  // signedness of a/b (11/01/00)
  bit               mult_sel_subword;  // PULP feature -> must be 0 in RV32IM
  bit [4:0]         mult_imm;          // PULP feature -> must be 0 in RV32IM
  bit [31:0]        op_c_start;        // mult_operand_c in first cycle (=0 here)

  // ---- completion data (filled by the monitor at ex_valid) -----------------
  bit [31:0]        result;   // value the DUT produced (mult_result)
  bit [31:0]        wdata;    // value actually written to the register file
  bit [5:0]         waddr;    // destination register number (+ FP bit, =0)
  bit               we;       // write enable seen in the completing cycle

  // ---- timing statistics (all filled by the monitor) -----------------------
  int unsigned      total_cycles;     // cycles spent in EX (start..complete)
  int unsigned      stall_cycles;     // of which waiting for LSU/WB
  int unsigned      mult_cycles;      // total - stall = "real" multiplier cycles
  int unsigned      multicycle_len;   // cycles with mult_multicycle==1
  int unsigned      cycle_start;      // monitor cycle counter when op entered EX
  int unsigned      cycle_end;        // monitor cycle counter when ex_valid seen
  time              t_start;          // simulation TIME when op entered EX
  time              t_end;            // simulation TIME when it completed

  // ---- tag (which instruction caused this - for debug prints) --------------
  bit               tag_valid;        // 1 = pc/instr below are meaningful
  bit [31:0]        pc;               // PC of the instruction (from ID stage)
  bit [31:0]        instr;            // the 32-bit instruction word (from ID)

  // ---- abnormal termination ------------------------------------------------
  bit               killed_by_reset;  // 1 = reset came, transaction closed early

  // ---- constraint: this transaction type only holds MUL-unit ops ----------
  constraint c_mul_unit_ops { op inside {MUL, MULH, MULHSU, MULHU}; }

  // ---- UVM field automation macros ----------------------------------------
  // Register every field for uvm print/copy/compare.
  // UVM_ALL_ON    = participate in all operations.
  // UVM_NOCOMPARE = do NOT compare this field (it is informational, e.g. the
  //                 raw control fields and timing - two valid transactions may
  //                 legitimately differ in them).
  // UVM_HEX/UVM_DEC/UVM_TIME = how to print the value.
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

  // Standard UVM constructor: call parent with the instance name.
  function new(string name = "mul_txn");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // decode_ctrl: turn the 2 raw control fields into a clean ISA opcode.
  //   operator = MUL_MAC32              -> op = MUL
  //   operator = MUL_H + mode 2'b11      -> op = MULH    (a signed, b signed)
  //   operator = MUL_H + mode 2'b01      -> op = MULHSU  (a signed, b unsigned)
  //   operator = MUL_H + mode 2'b00      -> op = MULHU   (both unsigned)
  // Returns 1 = decoded OK, 0 = combination the RV32IM decoder never produces
  // (any other operator value, or MUL_H with the illegal mode 2'b10).
  // "static" = callable without an object instance.
  // ---------------------------------------------------------------------------
  static function bit decode_ctrl(input  mul_opcode_e operator,
                                  input  bit [1:0]    signed_mode,
                                  output rv32m_op_e   op);
    op = MUL;                        // default (overwritten below)
    case (operator)
      MUL_MAC32: begin op = MUL; return 1; end   // plain multiply -> MUL
      MUL_H: begin
        case (signed_mode)
          2'b11:   begin op = MULH;   return 1; end  // both signed
          2'b01:   begin op = MULHSU; return 1; end  // a signed, b unsigned
          2'b00:   begin op = MULHU;  return 1; end  // both unsigned
          default: return 0;                          // 2'b10 never happens
        endcase
      end
      default: return 0;                              // not a MUL opcode at all
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Expectation helpers: the scoreboard calls these to know what the DUT
  // SHOULD have done, without recomputing anything itself.
  // ---------------------------------------------------------------------------
  function bit [31:0] exp_result();        // expected result = ISA reference
    return rv32m_ref(op, rs1_val, rs2_val);  // golden model from rv32m_ref_pkg
  endfunction

  function int unsigned exp_mult_cycles(); // expected "real" cycles in EX
    return (op == MUL) ? MUL_LATENCY : MULH_LATENCY;  // 1 for MUL, 5 for MULH*
  endfunction

  function int unsigned exp_multicycle_len(); // expected mult_multicycle length
    return (op == MUL) ? 0 : MULH_MULTICYCLE_LEN;     // 0 for MUL, 3 for MULH*
  endfunction

  function bit is_mulh();                  // TRUE for MULH/MULHSU/MULHU
    return (op != MUL);
  endfunction

  // ---------------------------------------------------------------------------
  // Register-field accessors: two sources for the destination register -
  // the write port (what the DUT did) and the instruction word (what the
  // program asked for). The scoreboard compares them to catch tag bugs.
  // Instruction fields follow the RISC-V encoding:
  //   rd  = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20]
  // ---------------------------------------------------------------------------
  function bit [4:0] rd();        return waddr[4:0];      endfunction  // from DUT write port
  function bit [4:0] instr_rd();  return instr[11:7];     endfunction  // from instruction word
  function bit [4:0] instr_rs1(); return instr[19:15];    endfunction
  function bit [4:0] instr_rs2(); return instr[24:20];    endfunction

  // ---------------------------------------------------------------------------
  // convert2string: one human-readable line, used by the scoreboard prints.
  // %-6s = name padded to 6 chars, %08h = 8-digit hex, %0d = decimal.
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    string s;   // local string we build up
    s = $sformatf("%-6s rs1=0x%08h rs2=0x%08h -> rd=x%0d res=0x%08h exp=0x%08h | cyc tot=%0d stall=%0d mult=%0d mc=%0d",
                  op.name(), rs1_val, rs2_val, rd(), result, exp_result(),
                  total_cycles, stall_cycles, mult_cycles, multicycle_len);
    if (tag_valid)       s = {s, $sformatf(" | pc=0x%08h instr=0x%08h", pc, instr)};  // append tag
    if (killed_by_reset) s = {s, " | KILLED_BY_RESET"};                                // append flag
    return s;   // hand the finished line back to the caller
  endfunction

endclass : mul_txn
