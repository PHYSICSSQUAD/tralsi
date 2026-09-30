// =============================================================================
// alu_txn.sv  (part of alu_agent_pkg)
// -----------------------------------------------------------------------------
// One ALU instruction observed in the EX stage of cv32e40p_core: every
// RV32I instruction except the multiplier ops uses the ALU (arithmetic/logic/
// shift/compare, LUI/AUIPC, JAL/JALR link, branch decision, load/store address)
// plus the RV32M DIV/DIVU/REM/REMU that live in rtl/cv32e40p_alu_div.sv.
//
// Produced by alu_monitor, consumed by the ALU_MUL Scoreboard (`_alu` port)
// and by the ALU covergroups in coverage_collector.
//
// Field sources (alu_mul_if.sv for the RTL mapping):
//   op             alu_operator in the first EX cycle (cv32e40p_pkg::alu_opcode_e)
//   a, b, c        alu_operand_a/b/c in the first EX cycle - the RAW UNIT
//                  operands after the ID muxes (forwarding, immediates, PC,
//                  DIV operand swap: a = divisor = rs2, b = dividend = rs1)
//   result         alu_result in the completion cycle
//   cmp            alu_cmp_result in the completion cycle (branch decision)
//   wdata/waddr/we register-file ALU write port in the completion cycle
//   ex_valid       ex_valid in the completion cycle (0 possible for a branch)
//   branch_in_ex   branch_in_ex in the completion cycle
//   lsu_en         data_req_ex: the result is a load/store address (no RF write
//                  through the ALU port)
//   misaligned_2nd second EX pass of a misaligned load/store: ID re-loads the
//                  ALU with a = first address, b = 4 without an issue pulse;
//                  the item inherits pc/instr of the first pass (tag_valid kept)
//   total_cycles   cycles in EX (first alu_en .. ex_ready)
//   stall_cycles   cycles with alu_ready && !ex_ready (EX held by LSU / WB)
//   alu_cycles     total - stall: 1 for every operator except DIV/REM which
//                  take div_latency_ref(op, a) = 3..35 (alu_ref_pkg)
//   cycle_start/end, t_start/end   monitor counters (distance between ops)
//   pc, instr      tag from the ID issue pulse one cycle earlier; the decoder
//                  expectations (alu_expect_of_instr) are derived from it
//   killed_by_reset reset asserted while the instruction was in EX
// =============================================================================
class alu_txn extends uvm_sequence_item;

  // ---- operation and raw unit operands -----------------------------------------
  rand alu_opcode_e op;
  rand bit [31:0]   a;
  rand bit [31:0]   b;
  bit [31:0]        c;

  // ---- completion ----------------------------------------------------------------
  bit [31:0]        result;
  bit               cmp;
  bit [31:0]        wdata;
  bit [5:0]         waddr;
  bit               we;
  bit               ex_valid;
  bit               branch_in_ex;
  bit               lsu_en;
  bit               misaligned_2nd;

  // ---- timing --------------------------------------------------------------------
  int unsigned      total_cycles;
  int unsigned      stall_cycles;
  int unsigned      alu_cycles;
  int unsigned      cycle_start;
  int unsigned      cycle_end;
  time              t_start;
  time              t_end;

  // ---- tag -----------------------------------------------------------------------
  bit               tag_valid;
  bit [31:0]        pc;
  bit [31:0]        instr;

  // ---- abnormal termination -----------------------------------------------------------
  bit               killed_by_reset;

  constraint c_in_scope { alu_op_in_scope(op); }

  `uvm_object_utils_begin(alu_txn)
    `uvm_field_enum(alu_opcode_e, op,          UVM_ALL_ON)
    `uvm_field_int (a,                          UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (b,                          UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (c,                          UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (result,                     UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (cmp,                        UVM_ALL_ON)
    `uvm_field_int (wdata,                      UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (waddr,                      UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (we,                         UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (ex_valid,                   UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (branch_in_ex,               UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (lsu_en,                     UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (misaligned_2nd,             UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (total_cycles,               UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (stall_cycles,               UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (alu_cycles,                 UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (cycle_start,                UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (cycle_end,                  UVM_ALL_ON | UVM_NOCOMPARE | UVM_DEC)
    `uvm_field_int (t_start,                    UVM_ALL_ON | UVM_NOCOMPARE | UVM_TIME)
    `uvm_field_int (t_end,                      UVM_ALL_ON | UVM_NOCOMPARE | UVM_TIME)
    `uvm_field_int (tag_valid,                  UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (pc,                         UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (instr,                      UVM_ALL_ON | UVM_NOCOMPARE | UVM_HEX)
    `uvm_field_int (killed_by_reset,            UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "alu_txn");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Classification helpers
  // ---------------------------------------------------------------------------
  function alu_op_class_e op_class(); return alu_op_class(op);      endfunction
  function bit is_div();              return is_div_operator(op);    endfunction
  function bit is_branch();           return is_branch_operator(op); endfunction

  // ---------------------------------------------------------------------------
  // Expectations (unit level - raw operands in, unit outputs out)
  // ---------------------------------------------------------------------------
  function bit [31:0] exp_result();       return alu_ref(op, a, b);     endfunction
  function bit        exp_cmp();          return alu_cmp_ref(op, a, b); endfunction
  function int unsigned exp_alu_cycles(); return is_div() ? div_latency_ref(op, a) : ALU_LATENCY; endfunction

  // Decoder-level expectations from the tagged instruction word (valid when tag_valid)
  function alu_expect_t expect_of_tag();  return alu_expect_of_instr(instr); endfunction

  // ---------------------------------------------------------------------------
  // Register fields
  // ---------------------------------------------------------------------------
  function bit [4:0] rd();        return waddr[4:0];   endfunction  // from the write port
  function bit [4:0] instr_rd();  return instr[11:7];  endfunction  // from the tagged word
  function bit [4:0] instr_rs1(); return instr[19:15]; endfunction
  function bit [4:0] instr_rs2(); return instr[24:20]; endfunction

  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    string s;
    s = $sformatf("%-9s a=0x%08h b=0x%08h -> res=0x%08h exp=0x%08h cmp=%0b we=%0b rd=x%0d ex_valid=%0b | cyc tot=%0d stall=%0d alu=%0d (exp %0d)",
                  op.name(), a, b, result, exp_result(), cmp, we, rd(), ex_valid,
                  total_cycles, stall_cycles, alu_cycles, exp_alu_cycles());
    if (tag_valid)       s = {s, $sformatf(" | pc=0x%08h instr=0x%08h", pc, instr)};
    if (lsu_en)          s = {s, misaligned_2nd ? " | LSU addr (misaligned 2nd pass)" : " | LSU addr"};
    if (killed_by_reset) s = {s, " | KILLED_BY_RESET"};
    return s;
  endfunction

endclass : alu_txn
