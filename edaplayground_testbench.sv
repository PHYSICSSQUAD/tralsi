// ====================================================================
// TESTBENCH.SV (All TB & UVM Verification Environment concatenated)
// ====================================================================

// -------------------- shared_pkg/tb_pkg.sv --------------------
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


// -------------------- mul_env/alu_mul_if.sv --------------------
//----------------------------------------------------------------------
// File       : alu_mul_if.sv
// Description: "ALU_MUL interface" from the team architecture diagram.
//              The passive window that the MUL agent (and later the
//              ALU agent) uses to observe the EX stage of CV32E40P.
//
// Why does it observe INTERNAL signals?
// - cv32e40p_top has no multiplier ports. The multiplier lives in the
//   EX stage and its result is written to the register file from EX
//   (databook, "Pipeline Details"). The guidelines ask for scoreboards
//   inside the datapath, so we must observe pipeline signals.
//
// How is it connected? -> by "bind", see alu_mul_bind.sv
// - All observed signals are INPUT PORTS of this interface. The bind
//   statement creates this interface INSIDE cv32e40p_core and connects
//   the ports to the core's local signals. No RTL file is modified and
//   tb_top contains no hierarchical paths into the DUT.
// - Every port is an input: the testbench only observes, it never
//   drives anything back into the core.
//
// How does the UVM side get the handle?
// - The interface lives inside the DUT, so tb_top cannot easily pass
//   it to uvm_config_db. Instead the small wrapper module in
//   alu_mul_bind.sv (which holds this interface) registers it under
//   the name "alu_mul_vif".
//
// Sharing with the ALU agent:
// - Only MUL-related signals are declared here. ex_valid and the EX
//   write-back port are common to MUL and ALU; the ALU owner adds the
//   ALU-only ports in the marked section (and in alu_mul_bind.sv).
//----------------------------------------------------------------------

`timescale 1ns/1ps

interface alu_mul_if (
    // gated core clock / active-low reset
    input logic        clk,
    input logic        rst_n,

    // ---------------- ID -> EX hand-off -----------------------------
    // The EX stage keeps only decoded control signals, not the
    // instruction word. The monitor records the word when it moves
    // from ID to EX so it can identify MUL/MULH/MULHSU/MULHU from the
    // real encoding, independently of the DUT's own decoder.
    input logic        id_valid,          // 1 = ID instruction enters EX at this edge
    input logic [31:0] id_instr,          // instruction word currently in ID

    // ---------------- EX stage multiplier ---------------------------
    input logic        ex_mult_en,        // ID/EX reg: multiplier instruction in EX
                                          // (1 cycle for MUL, 5 for MULH*)
    input logic [31:0] ex_mult_operand_a, // ID/EX reg: rs1 value (stable while MULH* iterates)
    input logic [31:0] ex_mult_operand_b, // ID/EX reg: rs2 value
    input logic        ex_valid,          // EX instruction finishes THIS cycle. The only
                                          // cycle in which a MULH* result is final.

    // ---------------- EX write-back port (ALU/MUL/DIV -> RF) --------
    // This is how a MUL result becomes architecturally visible.
    input logic        ex_wb_we,          // write enable
    input logic [5:0]  ex_wb_waddr,       // rd (bit 5 = FP regs, always 0 for RV32IM)
    input logic [31:0] ex_wb_wdata        // value written to rd (= multiplier result)

    // ---------------- ALU-only ports: reserved for the ALU owner ----
);

    // =================================================================
    // Monitor clocking block
    // =================================================================
    // "input #1step" samples every signal just BEFORE the rising edge,
    // i.e. exactly the values the DUT flops capture on that edge. This
    // removes any race between the DUT updating and the monitor reading.
    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst_n;
        input id_valid, id_instr;
        input ex_mult_en, ex_mult_operand_a, ex_mult_operand_b, ex_valid;
        input ex_wb_we, ex_wb_waddr, ex_wb_wdata;
    endclocking

    // Passive agents only need the monitor view: no driver modport.
    modport MON (clocking mon_cb, input clk, input rst_n);

endinterface


// -------------------- mul_pkg (inlined) --------------------
package mul_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import tb_pkg::*;

    // Inlined mul_env/mul_config.sv
//----------------------------------------------------------------------
// File       : mul_config.sv
// Description: Configuration object of the MUL agent.
//
// Why a config object?
// - It bundles everything the MUL agent needs (virtual interface and
//   knobs) in ONE object. The test/env puts it in uvm_config_db once;
//   the agent and monitor read it back. Same style as alu_config in
//   the team template.
// - It is a uvm_object (not a uvm_component) because it has no phases
//   and no place in the component tree - it is just data.
//----------------------------------------------------------------------

class mul_config extends uvm_object;

    `uvm_object_utils(mul_config)

    // Handle to the "ALU_MUL interface". "virtual" means: a reference to
    // the real interface instance that lives in tb_top (classes cannot
    // contain interfaces, only handles to them).
    virtual alu_mul_if vif;

    // The MUL agent is always passive in our architecture (the core is
    // driven by the Instruction/Data agents, not by us). It is kept as a
    // field only so the agent code reads like the other team agents.
    uvm_active_passive_enum is_active = UVM_PASSIVE;

    // 1 = create the MUL coverage collector. A regression can set it to
    // 0 to save simulation time without touching code.
    bit has_coverage = 1;

    function new(string name = "mul_config");
        super.new(name);
    endfunction

endclass


    // Inlined mul_env/mul_seq_item.sv
//----------------------------------------------------------------------
// File       : mul_seq_item.sv
// Description: One observed multiplier instruction (MUL, MULH, MULHSU,
//              MULHU) as it completed in the EX stage.
//
// Why "seq_item" if there is no sequence?
// - The team names every transaction class *_seq_item. Here it is only
//   used as an ANALYSIS transaction: the monitor creates it, and the
//   scoreboard and coverage receive copies of it. Nothing randomizes
//   it, so no field is "rand".
//
// Why does ONE item hold operands AND result?
// - The monitor sees both in the same clock cycle (completion cycle of
//   the instruction in EX). Packing them together means the scoreboard
//   needs no FIFOs and no matching logic: each item is self-contained.
//
// Transaction flow:
//   mul_monitor --(creates item)--> ap.write(item)
//        |--> mul_scoreboard.write(item)  : predict + compare
//        |--> mul_coverage.write(item)    : sample covergroup
//----------------------------------------------------------------------

class mul_seq_item extends uvm_sequence_item;

    `uvm_object_utils(mul_seq_item)

    // ---------------- What instruction was executed ------------------
    instr_t      instr;      // raw 32-bit encoding (tb_pkg union type)
    instr_e      op;         // decoded name: MUL / MULH / MULHSU / MULHU
    logic [4:0]  rd;         // destination register from the encoding

    // ---------------- Inputs seen by the multiplier ------------------
    logic [31:0] rs1_val;    // operand a (value of rs1)
    logic [31:0] rs2_val;    // operand b (value of rs2)

    // ---------------- Outputs produced by the DUT --------------------
    logic [31:0] result;     // value written to rd (EX write-back data)
    logic        wb_we;      // EX write-back enable at completion
    logic [5:0]  wb_waddr;   // EX write-back address at completion

    function new(string name = "mul_seq_item");
        super.new(name);
    endfunction

    // One-line text used by every `uvm_info / `uvm_error of the env.
    function string convert2string();
        return $sformatf("%-6s rd=x%0d rs1_val=0x%08h rs2_val=0x%08h result=0x%08h (instr=0x%08h we=%0b waddr=%0d)",
                         op.name(), rd, rs1_val, rs2_val, result,
                         instr.raw, wb_we, wb_waddr);
    endfunction

    // Field-by-field copy (used by clone()).
    function void do_copy(uvm_object rhs);
        mul_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal(get_type_name(), "do_copy: rhs is not a mul_seq_item")
        end
        super.do_copy(rhs);
        instr    = rhs_.instr;
        op       = rhs_.op;
        rd       = rhs_.rd;
        rs1_val  = rhs_.rs1_val;
        rs2_val  = rhs_.rs2_val;
        result   = rhs_.result;
        wb_we    = rhs_.wb_we;
        wb_waddr = rhs_.wb_waddr;
    endfunction

    // Field-by-field compare (used by compare()). "===" so that X/Z
    // values coming from the DUT are never treated as a match.
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        mul_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer)  &&
               (instr.raw === rhs_.instr.raw)   &&
               (rs1_val   === rhs_.rs1_val)     &&
               (rs2_val   === rhs_.rs2_val)     &&
               (result    === rhs_.result)      &&
               (wb_we     === rhs_.wb_we)       &&
               (wb_waddr  === rhs_.wb_waddr);
    endfunction

endclass


    // Inlined mul_env/mul_monitor.sv
//----------------------------------------------------------------------
// File       : mul_monitor.sv
// Description: Passive monitor of the MUL agent. Watches the ALU_MUL
//              interface and publishes ONE mul_seq_item for every
//              MUL / MULH / MULHSU / MULHU that completes in EX.
//
// Why a monitor (and no driver)?
// - The core fetches its own instructions (driven by the Instruction
//   agent). The MUL agent must never drive anything; it only observes.
//
// Pipeline facts this monitor relies on (RTL + databook):
// - ID -> EX: the ID/EX registers (incl. mult_en_ex and the operands)
//   are loaded ONLY on a clock edge where id_valid=1, with the
//   instruction that is in ID (cv32e40p_id_stage). So the instruction
//   in EX is always the one that was in ID at the last id_valid edge.
// - MUL takes 1 cycle in EX, MULH/MULHSU/MULHU take 5 cycles
//   (cv32e40p_mult MUL_H FSM: IDLE->STEP0->STEP1->STEP2->FINISH).
// - ex_valid=1 only in the cycle the EX instruction finishes. During
//   the MULH* iterations ex_valid=0, and the write-back data shows
//   intermediate values that must NOT be checked.
// - Instructions in EX are never flushed (branches resolve in EX and
//   only flush IF/ID), so every multiplier that enters EX completes.
//
// Algorithm, at every rising clock edge (sampled through mon_cb):
//   (1) COMPLETE: if ex_mult_en && ex_valid, the multiplier in EX
//       finishes now -> build item from the instruction word recorded
//       at step (2) earlier + operands + write-back data -> ap.write().
//   (2) ENTER   : if id_valid, the instruction in ID moves into EX now
//       -> remember its word. We record EVERY instruction (not only
//       multiplies): if it is not a multiply, ex_mult_en stays 0 and
//       step (1) simply never uses it. This needs no decoder signal.
//   Order matters: a new MUL may enter EX on the same edge the old one
//   leaves, so first finish the old one, then record the new one.
//
// Transaction flow:
//   DUT signals --> alu_mul_if.mon_cb --> mul_monitor --ap--> scoreboard
//                                                        \--> coverage
//----------------------------------------------------------------------

class mul_monitor extends uvm_monitor;

    `uvm_component_utils(mul_monitor)

    // Analysis port: a "broadcast" output. write(item) calls write() of
    // every connected subscriber (scoreboard, coverage) immediately.
    // The monitor does not need to know who is listening.
    uvm_analysis_port #(mul_seq_item) ap;

    mul_config         cfg;
    virtual alu_mul_if vif;

    // State between step (2) and step (1): the instruction now in EX.
    logic [31:0] ex_instr;         // instruction word that entered EX
    bit          ex_instr_valid;   // 1 = ex_instr belongs to the instruction now in EX

    // Simple statistic printed in report_phase.
    int unsigned num_items;

    function new(string name = "mul_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // build_phase: create ports and fetch the configuration.
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(mul_config)::get(this, "", "mul_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "mul_config 'mul_cfg' not found in uvm_config_db")
        end
        vif = cfg.vif;
        if (vif == null) begin
            `uvm_fatal(get_type_name(), "mul_config.vif is null - is alu_mul_bind.sv compiled and alu_mul_bind instantiated in tb_top?")
        end
    endfunction

    // run_phase: endless sampling loop (a monitor never ends the test).
    task run_phase(uvm_phase phase);
        ex_instr_valid = 0;
        num_items      = 0;
        forever begin
            @(vif.mon_cb);

            // Reset clears the pipeline, so anything we were tracking is
            // gone. Forget it and wait for the next valid instruction.
            if (vif.mon_cb.rst_n !== 1'b1) begin
                ex_instr_valid = 0;
                continue;
            end

            // ---- (1) COMPLETE: multiplier leaves EX on this edge ----
            if (vif.mon_cb.ex_mult_en === 1'b1 && vif.mon_cb.ex_valid === 1'b1) begin
                if (!ex_instr_valid) begin
                    `uvm_error(get_type_name(),
                        "EX multiplier completed but no multiplier instruction was seen entering EX")
                end
                else begin
                    publish_item();
                end
                ex_instr_valid = 0;
            end

            // ---- (2) ENTER: ID instruction moves into EX on this edge ----
            if (vif.mon_cb.id_valid === 1'b1) begin
                ex_instr       = vif.mon_cb.id_instr;
                ex_instr_valid = 1;
            end
        end
    endtask

    // Build one transaction from the current mon_cb sample and send it.
    function void publish_item();
        mul_seq_item item;
        instr_e      op;

        // Decode the recorded instruction. Anything that is not one of
        // the 4 multiply instructions is out of MUL scope (e.g. a PULP
        // dot-product). It is reported, never silently dropped.
        if (!decode_mul(ex_instr, op)) begin
            `uvm_error(get_type_name(),
                $sformatf("Multiplier used by a non RV32M-MUL instruction 0x%08h - not checked", ex_instr))
            return;
        end

        // "create" (factory) instead of "new" so a test could override
        // the item type without changing this code.
        item          = mul_seq_item::type_id::create("item");
        item.instr    = ex_instr;
        item.op       = op;
        item.rd       = item.instr.r_type.rd;
        item.rs1_val  = vif.mon_cb.ex_mult_operand_a;
        item.rs2_val  = vif.mon_cb.ex_mult_operand_b;
        item.result   = vif.mon_cb.ex_wb_wdata;
        item.wb_we    = vif.mon_cb.ex_wb_we;
        item.wb_waddr = vif.mon_cb.ex_wb_waddr;

        num_items++;
        `uvm_info(get_type_name(), {"Observed: ", item.convert2string()}, UVM_HIGH)
        ap.write(item);
    endfunction

    // Returns 1 and the instruction name if 'raw' is MUL/MULH/MULHSU/MULHU.
    // Uses the encoding helpers of the shared tb_pkg so every team decodes
    // instructions the same way.
    function bit decode_mul(logic [31:0] raw, output instr_e op);
        instr_t      i;
        instr_e      cand[4] = '{MUL, MULH, MULHSU, MULHU};
        i = raw;
        foreach (cand[k]) begin
            if (i.r_type.opcode === get_opcode(cand[k]) &&
                i.r_type.funct3 === get_funct3(cand[k]) &&
                i.r_type.funct7 === get_funct7(cand[k])) begin
                op = cand[k];
                return 1;
            end
        end
        op = MUL;
        return 0;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("MUL monitor published %0d multiplier transactions", num_items), UVM_LOW)
    endfunction

endclass


    // Inlined mul_env/mul_agent.sv
//----------------------------------------------------------------------
// File       : mul_agent.sv
// Description: Passive MUL agent = mul_config + virtual interface +
//              mul_monitor (exactly the box drawn in the architecture).
//
// Why an agent if it holds only a monitor?
// - It keeps the same structure as every other team agent, so the team
//   env treats all agents the same way. If later someone needs more
//   (e.g. a second monitor), only this file changes.
// - No sequencer and no driver are created: the agent is passive
//   because the multiplier's inputs come from the program the core
//   executes, not from us.
//
// Transaction flow:
//   mul_monitor.ap ---> (re-exported as) mul_agent.ap ---> env
//----------------------------------------------------------------------

class mul_agent extends uvm_agent;

    `uvm_component_utils(mul_agent)

    mul_monitor mon;
    mul_config  cfg;

    // Agent-level port: the env connects to agent.ap and does not need
    // to know the monitor exists inside.
    uvm_analysis_port #(mul_seq_item) ap;

    function new(string name = "mul_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(mul_config)::get(this, "", "mul_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "mul_config 'mul_cfg' not found in uvm_config_db")
        end
        // Always passive: see header.
        is_active = UVM_PASSIVE;
        mon = mul_monitor::type_id::create("mon", this);
    endfunction

    // connect_phase: hand out the monitor's port as the agent's port.
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
    endfunction

endclass


    // Inlined mul_env/mul_ref_model.sv
//----------------------------------------------------------------------
// File       : mul_ref_model.sv
// Description: Golden (expected-value) model of the four RV32M
//              multiply instructions, written from the RISC-V
//              Unprivileged ISA spec, chapter 7.1:
//
//   MUL    : low  32 bits of rs1 x rs2
//   MULH   : high 32 bits of   signed(rs1) x   signed(rs2)
//   MULHSU : high 32 bits of   signed(rs1) x unsigned(rs2)
//   MULHU  : high 32 bits of unsigned(rs1) x unsigned(rs2)
//
// Why is it so simple?
// - It must be INDEPENDENT of the RTL. The RTL computes MULH* with a
//   5-cycle FSM of 16-bit partial products; copying that would copy its
//   bugs. Here we just extend both operands to 64 bits and let the
//   simulator multiply: different algorithm, same mathematical answer.
// - Why 64 bits? A 32x32 product needs up to 64 bits. Doing it in 32
//   bits would lose the high half that MULH* return.
// - Sign/zero extension is what makes the four instructions different:
//     signed   operand: copy bit 31 into bits 63..32 ($signed + longint)
//     unsigned operand: fill bits 63..32 with zeros
//   For MUL the low 32 bits are the same whatever extension is used.
//
// Why a uvm_object (not a component)?
// - It has no ports, no phases and no state: it is a pure function. The
//   scoreboard owns one and calls predict(). (In the team env the
//   Predictor can call the same function.)
//
// Example (also in MUL_VERIFICATION_DESIGN.md):
//   MULH 0x80000000 x 0x80000000 = (-2^31) x (-2^31) = 2^62
//        = 0x4000_0000_0000_0000 -> expected rd = 0x40000000
//----------------------------------------------------------------------

class mul_ref_model extends uvm_object;

    `uvm_object_utils(mul_ref_model)

    function new(string name = "mul_ref_model");
        super.new(name);
    endfunction

    // Returns the value that must be written to rd.
    function logic [31:0] predict(instr_e op, logic [31:0] rs1_val, logic [31:0] rs2_val);
        longint signed   a_s, b_s;   // sign-extended operands
        longint unsigned a_u, b_u;   // zero-extended operands
        logic   [63:0]   product;

        a_s = longint'($signed(rs1_val));   // e.g. 0xFFFFFFFF -> -1
        b_s = longint'($signed(rs2_val));
        a_u = {32'b0, rs1_val};             // e.g. 0xFFFFFFFF -> 4294967295
        b_u = {32'b0, rs2_val};

        case (op)
            MUL   : begin product = a_s * b_s; return product[31:0];  end
            MULH  : begin product = a_s * b_s; return product[63:32]; end
            // signed x unsigned: b_u fits in 63 bits, so a signed 64-bit
            // multiply with a zero-extended b gives the exact result.
            MULHSU: begin product = a_s * longint'(b_u); return product[63:32]; end
            MULHU : begin product = a_u * b_u; return product[63:32]; end
            default: begin
                `uvm_error(get_type_name(), $sformatf("predict() called with non-MUL op %s", op.name()))
                return 'x;
            end
        endcase
    endfunction

endclass


    // Inlined mul_env/mul_scoreboard.sv
//----------------------------------------------------------------------
// File       : mul_scoreboard.sv
// Description: MUL part of the "ALU_MUL Scoreboard" of the team
//              architecture. Checks every observed MUL / MULH / MULHSU /
//              MULHU against mul_ref_model.
//
// Checks per instruction:
//   1. result   == mul_ref_model.predict(op, rs1_val, rs2_val)
//   2. wb_we    == 1           (the result is really written)
//   3. wb_waddr == {1'b0, rd}  (to the register named in the encoding)
//
// Why no FIFOs (the template ALU scoreboard has two)?
// - The template gets expected and actual items from different places
//   at different times. Here the monitor delivers operands AND result
//   in the SAME item, so we can predict and compare immediately inside
//   write(). Less code, nothing can get out of order.
//
// Why uvm_analysis_imp?
// - "imp" = the end point that IMPLEMENTS write(). When the monitor
//   calls ap.write(item), UVM calls this class's write(item) directly.
//
// Transaction flow:
//   mul_monitor.ap --> analysis_export.write(item) --> write()
//        --> ref_model.predict() --> compare --> PASS / MISMATCH
//
// What is NOT checked here (owned by other components):
// - Whether rs1_val/rs2_val are the correct architectural register
//   values (forwarding, hazards) -> Predictor / reg_file scoreboard.
// - The register file content (incl. rd = x0 staying 0) -> reg_file
//   scoreboard.
//----------------------------------------------------------------------

class mul_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(mul_scoreboard)

    uvm_analysis_imp #(mul_seq_item, mul_scoreboard) analysis_export;

    mul_ref_model ref_model;

    int unsigned pass_count;
    int unsigned fail_count;
    // Per-instruction counters for the summary, indexed by the
    // instruction name (associative array keyed by instr_e).
    int unsigned op_count[instr_e];

    function new(string name = "mul_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        ref_model       = mul_ref_model::type_id::create("ref_model");
        pass_count      = 0;
        fail_count      = 0;
    endfunction

    // Called by the monitor (through the analysis port) once per
    // completed multiplier instruction.
    function void write(mul_seq_item item);
        logic [31:0] expected;
        bit          ok;

        expected = ref_model.predict(item.op, item.rs1_val, item.rs2_val);

        // "===" also compares X/Z: an X result is a FAIL, never a match.
        ok = (item.result   === expected)          &&
             (item.wb_we    === 1'b1)              &&
             (item.wb_waddr === {1'b0, item.rd});

        if (op_count.exists(item.op)) op_count[item.op]++;
        else                          op_count[item.op] = 1;

        if (ok) begin
            pass_count++;
            `uvm_info(get_type_name(),
                $sformatf("PASS     %-6s rs1=0x%08h rs2=0x%08h expected=0x%08h actual=0x%08h rd=x%0d",
                          item.op.name(), item.rs1_val, item.rs2_val, expected, item.result, item.rd),
                UVM_MEDIUM)
        end
        else begin
            fail_count++;
            `uvm_error(get_type_name(),
                $sformatf("MISMATCH %-6s instr=0x%08h rs1=0x%08h rs2=0x%08h expected=0x%08h actual=0x%08h | rd=x%0d wb_we=%0b (exp 1) wb_waddr=%0d (exp %0d)",
                          item.op.name(), item.instr.raw, item.rs1_val, item.rs2_val, expected, item.result,
                          item.rd, item.wb_we, item.wb_waddr, item.rd))
        end
    endfunction

    // check_phase: a test that "passes" with zero checks proves nothing.
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (pass_count + fail_count == 0) begin
            `uvm_warning(get_type_name(), "No MUL/MULH/MULHSU/MULHU instruction was checked in this test")
        end
    endfunction

    function void report_phase(uvm_phase phase);
        string s;
        super.report_phase(phase);
        s = $sformatf("\n---------------- MUL SCOREBOARD SUMMARY ----------------\n");
        s = {s, $sformatf("  Checked : %0d   PASS : %0d   FAIL : %0d\n",
                          pass_count + fail_count, pass_count, fail_count)};
        foreach (op_count[op]) begin
            s = {s, $sformatf("  %-6s : %0d\n", op.name(), op_count[op])};
        end
        s = {s, "---------------------------------------------------------"};
        `uvm_info(get_type_name(), s, UVM_NONE)
    endfunction

endclass


    // Inlined mul_env/mul_coverage.sv
//----------------------------------------------------------------------
// File       : mul_coverage.sv
// Description: Functional coverage of MUL / MULH / MULHSU / MULHU.
//              Part of the team "coverage_collector" (all monitors feed
//              it in the architecture). Answers the question:
//              "Did the tests exercise the interesting multiply cases?"
//
// Why uvm_subscriber?
// - A subscriber is a component with ONE built-in analysis_export and
//   a write() function to fill in. Perfect for "receive item, sample".
//
// What is measured and WHY:
// - cp_op                : every instruction executed at least once.
// - cp_rs1/rs2_class     : corner values where multipliers usually
//                          break: 0, 1, -1, max positive, min negative.
// - cp_rs1/rs2_sign      : sign of each operand; MULH, MULHSU and MULHU
//                          differ ONLY in how they treat the sign bit.
// - cx_op_sign           : every op with every sign combination.
// - cx_op_rs1/rs2_class  : every corner value with every op.
// - cx_op_extremes       : the hardest pairs (min_neg, max_pos, -1)
//                          with every op, e.g. MULH min_neg x min_neg.
// - cx_op_result         : zero and all-ones results for every op.
//
// Transaction flow:
//   mul_monitor.ap --> analysis_export --> write(item) --> cg.sample()
//----------------------------------------------------------------------

class mul_coverage extends uvm_subscriber #(mul_seq_item);

    `uvm_component_utils(mul_coverage)

    // Copy of the item being sampled. The covergroup reads these fields.
    mul_seq_item item;

    // MUL_NO_COVERGROUP: only for simulators without a covergroup
    // licence (e.g. free ModelSim-Intel, which refuses to elaborate any
    // covergroup). Normal runs (Questa/VCS/Xcelium) leave it undefined.
`ifndef MUL_NO_COVERGROUP
    covergroup mul_cg;
        option.per_instance = 1;

        cp_op: coverpoint item.op {
            bins mul    = {MUL};
            bins mulh   = {MULH};
            bins mulhsu = {MULHSU};
            bins mulhu  = {MULHU};
        }

        // Operand value classes: single corner values + the two ranges
        // between them, so every 32-bit value falls in exactly one bin.
        cp_rs1_class: coverpoint item.rs1_val {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins pos_other = {[32'h0000_0002 : 32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins neg_other = {[32'h8000_0001 : 32'hFFFF_FFFE]};
            bins minus_one = {32'hFFFF_FFFF};
        }
        cp_rs2_class: coverpoint item.rs2_val {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins pos_other = {[32'h0000_0002 : 32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins neg_other = {[32'h8000_0001 : 32'hFFFF_FFFE]};
            bins minus_one = {32'hFFFF_FFFF};
        }

        // Sign view of the operands (MSB = sign bit for signed ops,
        // = large magnitude for unsigned ops).
        cp_rs1_sign: coverpoint item.rs1_val {
            bins zero      = {32'h0000_0000};
            bins msb_clear = {[32'h0000_0001 : 32'h7FFF_FFFF]};
            bins msb_set   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }
        cp_rs2_sign: coverpoint item.rs2_val {
            bins zero      = {32'h0000_0000};
            bins msb_clear = {[32'h0000_0001 : 32'h7FFF_FFFF]};
            bins msb_set   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }

        // Only the extreme values; used in cx_op_extremes.
        cp_rs1_extreme: coverpoint item.rs1_val {
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins minus_one = {32'hFFFF_FFFF};
        }
        cp_rs2_extreme: coverpoint item.rs2_val {
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins minus_one = {32'hFFFF_FFFF};
        }

        cp_result: coverpoint item.result {
            bins zero     = {32'h0000_0000};
            bins all_ones = {32'hFFFF_FFFF};
            bins other    = {[32'h0000_0001 : 32'hFFFF_FFFE]};
        }

        cx_op_sign      : cross cp_op, cp_rs1_sign, cp_rs2_sign;
        cx_op_rs1_class : cross cp_op, cp_rs1_class;
        cx_op_rs2_class : cross cp_op, cp_rs2_class;
        cx_op_extremes  : cross cp_op, cp_rs1_extreme, cp_rs2_extreme;

        cx_op_result    : cross cp_op, cp_result {
            // MULHU can never return 0xFFFFFFFF: the largest unsigned
            // product is (2^32-1)^2 whose high half is 0xFFFFFFFE.
            ignore_bins mulhu_all_ones = binsof(cp_op.mulhu) && binsof(cp_result.all_ones);
        }
    endgroup
`endif

    // Number of sampled items (always counted, also useful without
    // a covergroup licence).
    int unsigned num_sampled;

    function new(string name = "mul_coverage", uvm_component parent = null);
        super.new(name, parent);
`ifndef MUL_NO_COVERGROUP
        // Embedded covergroups must be constructed in new().
        mul_cg = new();
`endif
    endfunction

    // Called once per completed multiplier instruction.
    function void write(mul_seq_item t);
        item = t;
        num_sampled++;
`ifndef MUL_NO_COVERGROUP
        mul_cg.sample();
`endif
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
`ifndef MUL_NO_COVERGROUP
        `uvm_info(get_type_name(),
            $sformatf("MUL functional coverage = %0.2f%% (%0d items sampled)",
                      mul_cg.get_inst_coverage(), num_sampled), UVM_NONE)
`else
        `uvm_info(get_type_name(),
            $sformatf("MUL_NO_COVERGROUP defined: covergroup disabled, %0d items received", num_sampled), UVM_NONE)
`endif
    endfunction

endclass


    // Inlined mul_env/mul_env.sv
//----------------------------------------------------------------------
// File       : mul_env.sv
// Description: Small container that wires the MUL pieces together:
//
//      +------------------------- mul_env ---------------------------+
//      |  mul_agent (passive)                                        |
//      |   +-------------+                                           |
//      |   | mul_monitor |--ap--+--> mul_scoreboard (ref model)      |
//      |   +-------------+      |                                    |
//      |                        +--> mul_coverage (if has_coverage)  |
//      +-------------------------------------------------------------+
//
// Why a separate env?
// - It lets the MUL part be compiled, elaborated and tested on its own.
// - The team env can either instantiate mul_env as one block, OR create
//   mul_agent / mul_scoreboard / mul_coverage itself and copy the two
//   connect lines below (mapping them to the architecture's MUL agent,
//   ALU_MUL Scoreboard and coverage_collector).
//
// Configuration: someone above (test or team env) must do
//   uvm_config_db#(mul_config)::set(this, "<path to mul_env>*", "mul_cfg", cfg);
// If nobody did, this env builds a default config from the
// "alu_mul_vif" handle that the bind wrapper (alu_mul_bind.sv) publishes.
//----------------------------------------------------------------------

class mul_env extends uvm_env;

    `uvm_component_utils(mul_env)

    mul_config     cfg;
    mul_agent      agent;
    mul_scoreboard sb;
    mul_coverage   cov;

    function new(string name = "mul_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // build_phase (top-down): create children. Children's build_phase
    // runs after this one, so the config must be set before that.
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(mul_config)::get(this, "", "mul_cfg", cfg)) begin
            cfg = mul_config::type_id::create("cfg");
            if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", cfg.vif)) begin
                `uvm_fatal(get_type_name(), "Neither 'mul_cfg' nor 'alu_mul_vif' found in uvm_config_db (is alu_mul_bind.sv compiled and alu_mul_bind instantiated in tb_top?)")
            end
        end
        // Make the same config visible to everything below this env.
        uvm_config_db#(mul_config)::set(this, "*", "mul_cfg", cfg);

        agent = mul_agent::type_id::create("agent", this);
        sb    = mul_scoreboard::type_id::create("sb", this);
        if (cfg.has_coverage) begin
            cov = mul_coverage::type_id::create("cov", this);
        end
    endfunction

    // connect_phase: one monitor port fans out to two subscribers.
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.analysis_export);
        if (cfg.has_coverage) begin
            agent.ap.connect(cov.analysis_export);
        end
    endfunction

endclass


endpackage

// -------------------- mul_env/alu_mul_bind.sv --------------------
//----------------------------------------------------------------------
// File       : alu_mul_bind.sv
// Description: Attaches the "ALU_MUL interface" to the CV32E40P core
//              with a SystemVerilog "bind" statement.
//
// Why bind?
// - Our testbench may only talk to the DUT through cv32e40p_top. But
//   the guidelines also ask for scoreboards "in the datapath" to make
//   debugging easy, and the multiplier result never appears on a
//   cv32e40p_top port.
// - "bind <module> <unit> <instance> (...)" asks the simulator to add
//   <unit> INSIDE every instance of <module>, as if it had been written
//   in the RTL - without editing any RTL file. The port connections
//   are evaluated inside cv32e40p_core, so they use the core's own
//   local signal names and need no hierarchical paths.
// - We bind a tiny wrapper MODULE (alu_mul_bind_wrap) instead of the
//   interface itself: the wrapper instantiates alu_mul_if and puts its
//   handle into uvm_config_db as "alu_mul_vif". (An interface cannot
//   pass a handle to itself, but its parent module can.)
// - tb_top therefore has no "dut.core_i...." references and does not
//   connect any interface signal itself.
//
// How to use: compile this file with the RTL (it is listed in mul.f)
// and add ONE line to tb_top:
//       alu_mul_bind mul_bind ();
// The bind statement is placed inside module "alu_mul_bind" because
// simulators (e.g. ModelSim) only apply a bind that belongs to an
// elaborated module; a bind left alone in a file may be ignored.
// (Alternative: load alu_mul_bind as a second top: vsim tb_top alu_mul_bind)
//
// Signal sources (all declared in cv32e40p_core.sv):
//   clk                  : gated core clock - the clock of all ID/EX
//                          pipeline registers (it stops when the core
//                          sleeps, so the monitor sees no fake edges).
//   id_valid             : ID stage hands its instruction to EX
//   instr_rdata_id       : instruction word currently in ID
//   mult_en_ex           : ID/EX register - multiplier instruction in EX
//   mult_operand_a/b_ex  : ID/EX registers - rs1/rs2 values
//   ex_valid             : EX instruction finishes this cycle
//   regfile_alu_*_fw     : EX write-back port to the register file
//----------------------------------------------------------------------

`timescale 1ns/1ps

module alu_mul_bind_wrap (
    input logic        clk,
    input logic        rst_n,
    input logic        id_valid,
    input logic [31:0] id_instr,
    input logic        ex_mult_en,
    input logic [31:0] ex_mult_operand_a,
    input logic [31:0] ex_mult_operand_b,
    input logic        ex_valid,
    input logic        ex_wb_we,
    input logic [5:0]  ex_wb_waddr,
    input logic [31:0] ex_wb_wdata
);
    import uvm_pkg::*;

    alu_mul_if mul_if (.*);

    // Runs at time 0 with no delay, i.e. before UVM's build_phase
    // (run_test only starts phasing after some #0 delays).
    initial uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", mul_if);
endmodule

module alu_mul_bind;
bind cv32e40p_core alu_mul_bind_wrap alu_mul_bind_i (
    .clk               (clk),
    .rst_n             (rst_ni),
    .id_valid          (id_valid),
    .id_instr          (instr_rdata_id),
    .ex_mult_en        (mult_en_ex),
    .ex_mult_operand_a (mult_operand_a_ex),
    .ex_mult_operand_b (mult_operand_b_ex),
    .ex_valid          (ex_valid),
    .ex_wb_we          (regfile_alu_we_fw),
    .ex_wb_waddr       (regfile_alu_waddr_fw),
    .ex_wb_wdata       (regfile_alu_wdata_fw)
);
endmodule


// -------------------- mul_private_tb/mul_int_test_pkg.sv --------------------
//----------------------------------------------------------------------
// File       : mul_int_test_pkg.sv
// Description: PRIVATE integration tests for the MUL environment.
//              NOT part of the team environment - only used to prove
//              that mul_env works with the real CV32E40P RTL.
//
// Contents:
//   mul_int_program        : tiny hand-written programs + the expected
//                            result of every multiply, computed by hand
//   mul_int_expect_checker : compares each observed multiply with the
//                            hand-computed value (cross-checks that the
//                            monitor sees the right instructions in the
//                            right order, independent of mul_ref_model)
//   mul_int_base_test      : creates mul_env + checker, waits for the
//                            program to finish
//   mul_basic_test         : 1 MUL + 1 MULH (the "first simple test")
//   mul_all_ops_test       : all 4 ops, corner values, back-to-back and
//                            dependent multiplies
//
// No sequences: the core fetches the program from the memory in
// mul_int_tb_top, exactly like real software.
//----------------------------------------------------------------------

package mul_int_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import tb_pkg::*;
    import mul_pkg::*;

    // =================================================================
    // Program builder
    // =================================================================
    class mul_int_program;

        logic [31:0] code[$];        // machine code, loaded at address 0
        instr_e      exp_op[$];      // expected multiply sequence
        logic [31:0] exp_result[$];  // hand-computed expected rd values
        string       name;

        // R-type multiply. 'exp' is computed BY HAND in the comments.
        function void mul_op(instr_e op, int rd, int rs1, int rs2, logic [31:0] exp);
            code.push_back({get_funct7(op), 5'(rs2), 5'(rs1), get_funct3(op), 5'(rd), get_opcode(op)});
            exp_op.push_back(op);
            exp_result.push_back(exp);
        endfunction

        function void addi(int rd, int rs1, int imm);
            code.push_back({12'(imm), 5'(rs1), get_funct3(ADDI), 5'(rd), get_opcode(ADDI)});
        endfunction

        function void lui(int rd, logic [19:0] imm20);
            code.push_back({imm20, 5'(rd), get_opcode(LUI)});
        endfunction

        // Builds the program that belongs to a test name.
        static function mul_int_program get(string test_name);
            mul_int_program p = new();
            p.name = test_name;
            case (test_name)
                "mul_basic_test": begin
                    p.addi(1, 0, 3);                              // x1 = 3
                    p.addi(2, 0, -2);                             // x2 = 0xFFFFFFFE (-2)
                    p.mul_op(MUL,  5, 1, 2, 32'hFFFF_FFFA);      // 3 * -2 = -6
                    p.lui (3, 20'h80000);                         // x3 = 0x80000000 (-2^31)
                    p.mul_op(MULH, 6, 3, 3, 32'h4000_0000);      // 2^62 -> high = 0x40000000
                end
                "mul_all_ops_test": begin
                    p.addi(1, 0, 3);                              // x1  = 3
                    p.addi(2, 0, -2);                             // x2  = 0xFFFFFFFE
                    p.lui (3, 20'h80000);                         // x3  = 0x80000000 (min neg)
                    p.lui (4, 20'h80000);
                    p.addi(4, 4, -1);                             // x4  = 0x7FFFFFFF (max pos)
                    p.addi(15, 0, -1);                            // x15 = 0xFFFFFFFF
                    // one of each op
                    p.mul_op(MUL,     5,  1,  2, 32'hFFFF_FFFA);  // 3 * -2 = -6
                    p.mul_op(MULH,    6,  3,  3, 32'h4000_0000);  // (-2^31)^2 = 2^62
                    p.mul_op(MULHSU,  7,  2,  2, 32'hFFFF_FFFE);  // -2 * 0xFFFFFFFE = 0xFFFFFFFE_00000004
                    p.mul_op(MULHU,   8,  2,  2, 32'hFFFF_FFFC);  // 0xFFFFFFFE^2 = 0xFFFFFFFC_00000004
                    // corner values
                    p.mul_op(MULH,    9,  4,  3, 32'hC000_0000);  // max_pos*min_neg = 0xC0000000_80000000
                    p.mul_op(MULHU,  10, 15, 15, 32'hFFFF_FFFE);  // (2^32-1)^2 = 0xFFFFFFFE_00000001
                    p.mul_op(MULHSU, 11, 15, 15, 32'hFFFF_FFFF);  // -1 * (2^32-1) = 0xFFFFFFFF_00000001
                    p.mul_op(MUL,    12, 15, 15, 32'h0000_0001);  // -1 * -1 = 1
                    p.mul_op(MUL,    13,  0,  2, 32'h0000_0000);  // x0 * -2 = 0
                    // back-to-back, each one uses the previous result
                    // (checks the monitor across MULH->MUL hand-over and
                    //  operand forwarding from the EX write-back port)
                    p.mul_op(MULH,   14,  3,  4, 32'hC000_0000);  // min_neg*max_pos
                    p.mul_op(MUL,    16, 14,  1, 32'h4000_0000);  // 0xC0000000*3 = 0x2_40000000
                    p.mul_op(MULHU,  17, 16, 16, 32'h1000_0000);  // (2^30)^2 = 2^60
                    p.mul_op(MUL,    18, 17, 17, 32'h0000_0000);  // (2^28)^2 = 2^56 -> low = 0
                end
                default: `uvm_fatal("MUL_INT_PROG", {"No program for test ", test_name})
            endcase
            // Remaining memory is filled with "jal x0, 0" by tb_top, so the
            // core parks in a self-loop after the last instruction.
            return p;
        endfunction

    endclass

    // =================================================================
    // Hand-computed expectation checker (private TB only)
    // =================================================================
    class mul_int_expect_checker extends uvm_subscriber #(mul_seq_item);
        `uvm_component_utils(mul_int_expect_checker)

        mul_int_program prog;
        int unsigned    num_seen;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void write(mul_seq_item t);
            if (num_seen >= prog.exp_op.size()) begin
                `uvm_error("MUL_INT_CHK", {"Unexpected extra multiply: ", t.convert2string()})
            end
            else if (t.op !== prog.exp_op[num_seen] || t.result !== prog.exp_result[num_seen]) begin
                `uvm_error("MUL_INT_CHK", $sformatf("#%0d expected %s result=0x%08h, observed %s",
                    num_seen, prog.exp_op[num_seen].name(), prog.exp_result[num_seen], t.convert2string()))
            end
            else begin
                `uvm_info("MUL_INT_CHK", $sformatf("#%0d matches hand-computed value: %s",
                    num_seen, t.convert2string()), UVM_LOW)
            end
            num_seen++;
        endfunction

        function void check_phase(uvm_phase phase);
            if (num_seen != prog.exp_op.size())
                `uvm_error("MUL_INT_CHK", $sformatf("Observed %0d multiplies, program contains %0d",
                    num_seen, prog.exp_op.size()))
        endfunction
    endclass

    // =================================================================
    // Base test
    // =================================================================
    class mul_int_base_test extends uvm_test;
        `uvm_component_utils(mul_int_base_test)

        mul_env                env;
        mul_int_expect_checker chk;
        mul_int_program        prog;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // build_phase: the env finds the interface handle that the bound
        // alu_mul_if registered itself - the test does not touch it.
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            prog     = mul_int_program::get(get_type_name());
            env      = mul_env::type_id::create("env", this);
            chk      = mul_int_expect_checker::type_id::create("chk", this);
            chk.prog = prog;
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            env.agent.ap.connect(chk.analysis_export);
        endfunction

        // run_phase: keep the test alive until every multiply of the
        // program was observed (or a timeout hits).
        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            fork
                wait (chk.num_seen == prog.exp_op.size());
                begin
                    #100us;
                    `uvm_error(get_type_name(), "Timeout waiting for the program's multiplies")
                end
            join_any
            disable fork;
            #200ns;   // let a possible extra (wrong) multiply show up
            phase.drop_objection(this);
        endtask

        function void report_phase(uvm_phase phase);
            uvm_report_server rs = uvm_report_server::get_server();
            if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
                `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
            else
                `uvm_info(get_type_name(), "*** TEST FAILED ***", UVM_NONE)
        endfunction
    endclass

    class mul_basic_test extends mul_int_base_test;
        `uvm_component_utils(mul_basic_test)
        function new(string name, uvm_component parent); super.new(name, parent); endfunction
    endclass

    class mul_all_ops_test extends mul_int_base_test;
        `uvm_component_utils(mul_all_ops_test)
        function new(string name, uvm_component parent); super.new(name, parent); endfunction
    endclass

endpackage


// -------------------- mul_private_tb/mul_int_tb_top.sv --------------------
//----------------------------------------------------------------------
// File       : mul_int_tb_top.sv
// Description: PRIVATE integration top for the MUL environment.
//
// - Instantiates the real cv32e40p_top and talks to it ONLY through
//   its top-level ports (no hierarchical references into the DUT).
// - The ALU_MUL interface is attached inside the core by the bind in
//   mul_env/alu_mul_bind.sv (one line below: "alu_mul_bind mul_bind();")
//   and registers itself in uvm_config_db, so this file never
//   connects any interface signal.
// - A minimal single-port memory answers both OBI buses (instruction
//   fetch and data) with grant in the same cycle and rvalid one cycle
//   later. It replaces the team's Instruction/Data agents, which are
//   not needed to validate the MUL environment.
//----------------------------------------------------------------------

`timescale 1ns/1ps

module mul_int_tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import mul_int_test_pkg::*;

    localparam int          MEM_WORDS = 1024;               // 4 KB at address 0
    localparam logic [31:0] JAL_SELF  = 32'h0000_006F;      // jal x0, 0

    logic clk   = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [31:0] mem [MEM_WORDS];

    // ---------------- OBI signals ----------------
    logic        instr_req, instr_gnt, instr_rvalid;
    logic [31:0] instr_addr, instr_rdata;
    logic        data_req, data_gnt, data_rvalid, data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr, data_wdata, data_rdata;

    cv32e40p_top dut (
        .clk_i               (clk),
        .rst_ni              (rst_n),
        .pulp_clock_en_i     (1'b0),
        .scan_cg_en_i        (1'b0),
        .boot_addr_i         (32'h0000_0000),
        .mtvec_addr_i        (32'h0000_0000),
        .dm_halt_addr_i      (32'h0000_0000),
        .hart_id_i           (32'h0000_0000),
        .dm_exception_addr_i (32'h0000_0000),
        .instr_req_o         (instr_req),
        .instr_gnt_i         (instr_gnt),
        .instr_rvalid_i      (instr_rvalid),
        .instr_addr_o        (instr_addr),
        .instr_rdata_i       (instr_rdata),
        .data_req_o          (data_req),
        .data_gnt_i          (data_gnt),
        .data_rvalid_i       (data_rvalid),
        .data_we_o           (data_we),
        .data_be_o           (data_be),
        .data_addr_o         (data_addr),
        .data_wdata_o        (data_wdata),
        .data_rdata_i        (data_rdata),
        .irq_i               (32'h0),
        .irq_ack_o           (),
        .irq_id_o            (),
        .debug_req_i         (1'b0),
        .debug_havereset_o   (),
        .debug_running_o     (),
        .debug_halted_o      (),
        .fetch_enable_i      (1'b1),
        .core_sleep_o        ()
    );

    // ---------------- Attach the ALU_MUL interface (bind) ----------------
    // The only MUL-related line in tb_top. It contains a "bind" that
    // puts alu_mul_if inside cv32e40p_core - see mul_env/alu_mul_bind.sv.
    alu_mul_bind mul_bind ();

    // ---------------- Simple OBI memory ----------------
    assign instr_gnt = instr_req;
    assign data_gnt  = data_req;

    // plain "always" (not always_ff): mem is also preloaded by the
    // initial block below
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_rvalid <= 1'b0;
            data_rvalid  <= 1'b0;
        end
        else begin
            instr_rvalid <= instr_req;
            if (instr_req) instr_rdata <= mem[instr_addr[11:2]];

            data_rvalid <= data_req;
            if (data_req) begin
                if (data_we) begin
                    for (int b = 0; b < 4; b++)
                        if (data_be[b]) mem[data_addr[11:2]][8*b +: 8] <= data_wdata[8*b +: 8];
                end
                else begin
                    data_rdata <= mem[data_addr[11:2]];
                end
            end
        end
    end

    // ---------------- Program load, reset, UVM start ----------------
    initial begin
        string          test_name;
        mul_int_program prog;

        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) test_name = "mul_basic_test";
        prog = mul_int_program::get(test_name);
        foreach (mem[i]) mem[i] = JAL_SELF;
        foreach (prog.code[i]) mem[i] = prog.code[i];
        $display("[mul_int_tb_top] loaded %0d instructions for %s", prog.code.size(), test_name);

        fork
            begin
                repeat (5) @(posedge clk);
                rst_n <= 1'b1;
            end
        join_none

        run_test(test_name);
    end

endmodule


