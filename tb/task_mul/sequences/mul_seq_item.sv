`ifndef MUL_SEQ_ITEM
`define MUL_SEQ_ITEM

// ملاحظة: زميلك بيكتب import tb_pkg::* (باكيدج فريق التعليمات) — إحنا مش
// عندنا tb_pkg هنا، فبنجيب الـ enum من rv32m_ref_pkg وخلاص (self-contained).
import uvm_pkg::*;
`include "uvm_macros.svh"
import rv32m_ref_pkg::*;

class mul_seq_item extends uvm_sequence_item;
	`uvm_object_utils(mul_seq_item)

	typedef enum { MGRP_MUL, MGRP_MULDIV } mul_group_e;

	// Fields
	rand bit [31:0] addr;    // عنوان التعليمة (PC)
	rand bit [31:0] instr;   // كلمة التعليمتين الخام — بتتبني من الـ constraints تحت
	rand int        delay;   // دورات راحة قبل الإصدار

	// Gen Knobs
	rand rv32m_op_e   op;    // MUL / MULH / MULHSU / MULHU / DIV / DIVU / REM / REMU
	rand mul_group_e  group;

	//------------------ Constraints -----------------\\
	constraint delay_c { delay inside {[0:5]}; }

	// instr نمط R-type: opcode فاضي + funct3 + funct7 — الـ helpers تحت
	constraint opcode_c { instr[6:0]   == get_opcode(op); }
	constraint funct3_c { instr[14:12] == get_funct3(op); }
	constraint funct7_c { instr[31:25] == get_funct7(op); }

	constraint group_c {
		(group == MGRP_MUL)    -> op inside {MUL, MULH, MULHSU, MULHU};
		(group == MGRP_MULDIV) -> op inside {MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU};
	}

	constraint solve_order_c {
		solve group before op;
		solve op before instr;
	}

	// helpers محلية بسيطة (كل موديول قائم بذاته)
	// rv32m_op_e قيمه = funct3 بتاع التعليمات نفسها (مذكور في rv32m_ref_pkg)
	local static function bit [6:0] get_opcode(rv32m_op_e o); return 7'b0110011; endfunction // OP
	local static function bit [2:0] get_funct3 (rv32m_op_e o); return 3'(o);      endfunction
	local static function bit [6:0] get_funct7 (rv32m_op_e o); return 7'b0000001; endfunction // M ext

	function new(string name = "mul_seq_item");
		super.new(name);
	endfunction : new

	extern virtual function string convert2string();
	extern virtual function void   do_copy(uvm_object rhs);
	extern virtual function bit    do_compare(uvm_object rhs, uvm_comparer comparer);
endclass : mul_seq_item


function string mul_seq_item::convert2string();
	string contents = super.convert2string();
	$sformat(contents, "%s, addr  = 0x%08h", contents, addr);
	$sformat(contents, "%s, instr = 0x%08h", contents, instr);
	$sformat(contents, "%s, delay = %0d", contents, delay);
	return contents;
endfunction

function void mul_seq_item::do_copy(uvm_object rhs);
	mul_seq_item item;

	super.do_copy(rhs);

	if (!$cast(item, rhs))
		`uvm_fatal(get_type_name(), "do_copy: Cast failed")

	addr  = item.addr;
	instr = item.instr;
	delay = item.delay;
endfunction

function bit mul_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
	mul_seq_item item;
	bit status = 1;

	if (!$cast(item, rhs)) begin
		`uvm_error("COMPARE", "Cast failed in do_compare")
		return 0;
	end

	status &= super.do_compare(rhs, comparer);

	status &= (this.addr  == item.addr);
	status &= (this.instr == item.instr);
	status &= (this.delay == item.delay);

	return status;
endfunction
`endif
