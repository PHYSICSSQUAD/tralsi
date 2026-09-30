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

  // ---- what the instruction is and which raw numbers the ALU got ----------------
  rand alu_opcode_e op;   // the ALU operation (ADD, SLT, DIV, ... enum, randomizable)
  rand bit [31:0]   a;    // RAW ALU input A (after ID muxes; for DIV = divisor)
  rand bit [31:0]   b;    // RAW ALU input B (after ID muxes; for DIV = dividend)
  bit [31:0]        c;    // RAW ALU input C (unused by RV32IM, recorded anyway)

  // ---- what happened when the instruction finished (filled by monitor) ----------
  bit [31:0]        result;        // alu_result in the completing cycle
  bit               cmp;           // alu_cmp_result = branch decision 0/1
  bit [31:0]        wdata;         // value written to the register file
  bit [5:0]         waddr;         // destination register number
  bit               we;            // write enable in the completing cycle
  bit               ex_valid;      // ex_valid at completion (0 possible: branch)
  bit               branch_in_ex;  // 1 = op was a branch/jump
  bit               lsu_en;        // 1 = result is a load/store ADDRESS
  bit               misaligned_2nd;// 1 = this is the 2nd pass of a misaligned ld/st

  // ---- timing (all filled by the monitor) ---------------------------------------
  int unsigned      total_cycles;  // cycles spent in EX (start .. completion)
  int unsigned      stall_cycles;  // of which waiting for LSU/WB (external stall)
  int unsigned      alu_cycles;    // total - stall = "real" ALU/divider cycles
  int unsigned      cycle_start;   // monitor cycle counter at start
  int unsigned      cycle_end;     // monitor cycle counter at completion
  time              t_start;       // simulation time at start
  time              t_end;         // simulation time at completion

  // ---- tag: which instruction caused this (from ID issue pulse) ----------------
  bit               tag_valid;     // 1 = pc/instr below are meaningful
  bit [31:0]        pc;            // PC of the instruction
  bit [31:0]        instr;         // the 32-bit instruction word

  // ---- abnormal termination ------------------------------------------------------
  bit               killed_by_reset; // 1 = reset hit while the op was in EX

  // Randomize only operations that belong to our verification scope
  // (everything except ECALL/EBREAK/FENCE/CSR/custom - see alu_ref_pkg).
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
  // Classification helpers: quick answers the scoreboard/coverage ask.
  // (all are thin wrappers over functions in tb/common/alu_ref_pkg.sv)
  // ---------------------------------------------------------------------------
  function alu_op_class_e op_class(); return alu_op_class(op);      endfunction  // ARITH/LOGIC/SHIFT/...
  function bit is_div();              return is_div_operator(op);    endfunction  // DIV/DIVU/REM/REMU?
  function bit is_branch();           return is_branch_operator(op); endfunction  // branch/compare op?

  // ---------------------------------------------------------------------------
  // EXPECTATIONS = what the DUT SHOULD have done (golden model calls).
  // The scoreboard compares the DUT outputs against these.
  //   exp_result     -> alu_ref: value of arith/logic/shift/div result
  //   exp_cmp        -> alu_cmp_ref: branch decision 0/1
  //   exp_alu_cycles -> 1 for normal ops; for DIV the exact RTL latency
  //                     model div_latency_ref(op, a) = 3..35 cycles
  // ---------------------------------------------------------------------------
  function bit [31:0] exp_result();       return alu_ref(op, a, b);     endfunction
  function bit        exp_cmp();          return alu_cmp_ref(op, a, b); endfunction
  function int unsigned exp_alu_cycles(); return is_div() ? div_latency_ref(op, a) : ALU_LATENCY; endfunction

  // Decoder-level expectations from the tagged instruction word: what did the
  // PROGRAM ask for (op class, we, rd, LUI/AUIPC/jump flags, lsu)?
  // Only meaningful when tag_valid==1.
  function alu_expect_t expect_of_tag();  return alu_expect_of_instr(instr); endfunction

  // ---------------------------------------------------------------------------
  // Register fields - two sources that must agree:
  //   rd()        = destination the DUT actually wrote (write port)
  //   instr_rd()  = destination the instruction encoding asks for
  // RISC-V instruction encoding: rd=[11:7], rs1=[19:15], rs2=[24:20].
  // ---------------------------------------------------------------------------
  function bit [4:0] rd();        return waddr[4:0];   endfunction  // from the write port
  function bit [4:0] instr_rd();  return instr[11:7];  endfunction  // from the tagged word
  function bit [4:0] instr_rs1(); return instr[19:15]; endfunction
  function bit [4:0] instr_rs2(); return instr[24:20]; endfunction

  // ---------------------------------------------------------------------------
  // convert2string: build one readable line for log messages.
  // %-9s = name padded to 9 chars, %08h = 8-digit hex, %0b/%0d = binary/decimal.
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    string s;                       // the line we are building
    s = $sformatf("%-9s a=0x%08h b=0x%08h -> res=0x%08h exp=0x%08h cmp=%0b we=%0b rd=x%0d ex_valid=%0b | cyc tot=%0d stall=%0d alu=%0d (exp %0d)",
                  op.name(), a, b, result, exp_result(), cmp, we, rd(), ex_valid,
                  total_cycles, stall_cycles, alu_cycles, exp_alu_cycles());
    if (tag_valid)       s = {s, $sformatf(" | pc=0x%08h instr=0x%08h", pc, instr)};  // add tag
    if (lsu_en)          s = {s, misaligned_2nd ? " | LSU addr (misaligned 2nd pass)" : " | LSU addr"}; // mark address ops
    if (killed_by_reset) s = {s, " | KILLED_BY_RESET"};                                // mark reset kills
    return s;                       // hand the finished line back
  endfunction

endclass : alu_txn
