//----------------------------------------------------------------------
// File       : mul_standalone_tb.sv
// Description: Pure SystemVerilog Testbench (NON-UVM) for CV32E40P MUL.
//              Contains the EXACT SAME verification logic, reference model,
//              scoreboard, hand-computed golden checker, and stimulus programs
//              as the UVM environment, but runs in standard ModelSim without UVM.
//----------------------------------------------------------------------

`timescale 1ns/1ps

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

module mul_standalone_tb;

    import tb_pkg::*;

    localparam int          MEM_WORDS = 1024;
    localparam logic [31:0] JAL_SELF  = 32'h0000_006F; // jal x0, 0

    // Clock and reset
    logic clk   = 0;
    logic rst_n = 0;
    always #5 clk = ~clk;

    logic [31:0] mem [MEM_WORDS];

    // OBI bus signals
    logic        instr_req, instr_gnt, instr_rvalid;
    logic [31:0] instr_addr, instr_rdata;
    logic        data_req, data_gnt, data_rvalid, data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr, data_wdata, data_rdata;

    // ---------------- DUT Instantiation ----------------
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

    // ---------------- Simple OBI Memory ----------------
    assign instr_gnt = instr_req;
    assign data_gnt  = data_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_rvalid <= 1'b0;
            data_rvalid  <= 1'b0;
        end else begin
            instr_rvalid <= instr_req;
            if (instr_req) instr_rdata <= mem[instr_addr[11:2]];

            data_rvalid <= data_req;
            if (data_req) begin
                if (data_we) begin
                    for (int b = 0; b < 4; b++)
                        if (data_be[b]) mem[data_addr[11:2]][8*b +: 8] <= data_wdata[8*b +: 8];
                end else begin
                    data_rdata <= mem[data_addr[11:2]];
                end
            end
        end
    end

    // ---------------- Reference Model ----------------
    function automatic logic [31:0] ref_model_predict(instr_e op, logic [31:0] rs1_val, logic [31:0] rs2_val);
        longint signed   s_rs1, s_rs2, s_prod;
        longint unsigned u_rs1, u_rs2, u_prod;

        s_rs1 = longint'(signed'(rs1_val));
        s_rs2 = longint'(signed'(rs2_val));
        u_rs1 = {32'b0, rs1_val};
        u_rs2 = {32'b0, rs2_val};

        case (op)
            MUL: begin
                s_prod = s_rs1 * s_rs2;
                return s_prod[31:0];
            end
            MULH: begin
                s_prod = s_rs1 * s_rs2;
                return s_prod[63:32];
            end
            MULHSU: begin
                s_prod = s_rs1 * $signed({1'b0, u_rs2});
                return s_prod[63:32];
            end
            MULHU: begin
                u_prod = u_rs1 * u_rs2;
                return u_prod[63:32];
            end
            default: return 32'h0;
        endcase
    endfunction

    // ---------------- Program Generator ----------------
    logic [31:0] test_code[$];
    instr_e      exp_op[$];
    logic [31:0] exp_result[$];

    function automatic void add_mul(instr_e op, int rd, int rs1, int rs2, logic [31:0] exp);
        test_code.push_back({get_funct7(op), 5'(rs2), 5'(rs1), get_funct3(op), 5'(rd), get_opcode(op)});
        exp_op.push_back(op);
        exp_result.push_back(exp);
    endfunction

    function automatic void add_addi(int rd, int rs1, int imm);
        test_code.push_back({12'(imm), 5'(rs1), get_funct3(ADDI), 5'(rd), get_opcode(ADDI)});
    endfunction

    function automatic void add_lui(int rd, logic [19:0] imm20);
        test_code.push_back({imm20, 5'(rd), get_opcode(LUI)});
    endfunction

    function automatic void load_program(string name);
        test_code.delete();
        exp_op.delete();
        exp_result.delete();

        if (name == "mul_basic_test") begin
            add_addi(1, 0, 3);                              // x1 = 3
            add_addi(2, 0, -2);                             // x2 = 0xFFFFFFFE (-2)
            add_mul (MUL,  5, 1, 2, 32'hFFFF_FFFA);         // 3 * -2 = -6
            add_lui (3, 20'h80000);                         // x3 = 0x80000000 (-2^31)
            add_mul (MULH, 6, 3, 3, 32'h4000_0000);         // 2^62 -> high = 0x40000000
        end
        else begin // "mul_all_ops_test" (default)
            add_addi(1, 0, 3);                              // x1  = 3
            add_addi(2, 0, -2);                             // x2  = 0xFFFFFFFE
            add_lui (3, 20'h80000);                         // x3  = 0x80000000 (min neg)
            add_lui (4, 20'h80000);
            add_addi(4, 4, -1);                             // x4  = 0x7FFFFFFF (max pos)
            add_addi(15, 0, -1);                            // x15 = 0xFFFFFFFF
            // one of each op
            add_mul(MUL,     5,  1,  2, 32'hFFFF_FFFA);     // 3 * -2 = -6
            add_mul(MULH,    6,  3,  3, 32'h4000_0000);     // (-2^31)^2 = 2^62
            add_mul(MULHSU,  7,  2,  2, 32'hFFFF_FFFE);     // -2 * 0xFFFFFFFE = 0xFFFFFFFE_00000004
            add_mul(MULHU,   8,  2,  2, 32'hFFFF_FFFC);     // 0xFFFFFFFE^2 = 0xFFFFFFFC_00000004
            // corner values
            add_mul(MULH,    9,  4,  3, 32'hC000_0000);     // max_pos*min_neg = 0xC0000000_80000000
            add_mul(MULHU,  10, 15, 15, 32'hFFFF_FFFE);     // (2^32-1)^2 = 0xFFFFFFFE_00000001
            add_mul(MULHSU, 11, 15, 15, 32'hFFFF_FFFF);     // -1 * (2^32-1) = 0xFFFFFFFF_00000001
            add_mul(MUL,    12, 15, 15, 32'h0000_0001);     // -1 * -1 = 1
            add_mul(MUL,    13,  0,  2, 32'h0000_0000);     // x0 * -2 = 0
            // back-to-back, each one uses the previous result
            add_mul(MULH,   14,  3,  4, 32'hC000_0000);     // min_neg*max_pos
            add_mul(MUL,    16, 14,  1, 32'h4000_0000);     // 0xC0000000*3 = 0x2_40000000
            add_mul(MULHU,  17, 16, 16, 32'h1000_0000);     // (2^30)^2 = 2^60
            add_mul(MUL,    18, 17, 17, 32'h0000_0000);     // (2^28)^2 = 2^56 -> low = 0
        end
    endfunction

    // ---------------- Monitor & Scoreboard Logic ----------------
    function automatic bit decode_mul(logic [31:0] raw, output instr_e op);
        instr_t i;
        instr_e cand[4] = '{MUL, MULH, MULHSU, MULHU};
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

    logic [31:0] ex_instr;
    bit          ex_instr_valid;
    int unsigned num_items = 0;
    int unsigned pass_count = 0;
    int unsigned fail_count = 0;
    int unsigned chk_matches = 0;
    int unsigned op_count[instr_e];

    // Pipeline monitoring at clk edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_instr_valid <= 0;
            num_items      <= 0;
        end
        else begin
            // 1. COMPLETE: multiplier finishes in EX
            if (dut.core_i.mult_en_ex === 1'b1 && dut.core_i.ex_valid === 1'b1) begin
                if (!ex_instr_valid) begin
                    $display("[TB_ERROR] @%0t: EX multiplier completed without valid instruction!", $time);
                    fail_count++;
                end
                else begin
                    instr_e      op;
                    logic [31:0] rs1_val, rs2_val, actual_res, exp_ref, hand_exp;
                    logic [4:0]  rd;
                    logic        wb_we;
                    logic [5:0]  wb_waddr;
                    bit          ok;

                    if (!decode_mul(ex_instr, op)) begin
                        $display("[TB_ERROR] @%0t: Unknown multiplier instruction 0x%08h", $time, ex_instr);
                        fail_count++;
                    end
                    else begin
                        rs1_val    = dut.core_i.mult_operand_a_ex;
                        rs2_val    = dut.core_i.mult_operand_b_ex;
                        actual_res = dut.core_i.regfile_alu_wdata_fw;
                        wb_we      = dut.core_i.regfile_alu_we_fw;
                        wb_waddr   = dut.core_i.regfile_alu_waddr_fw;
                        rd         = ex_instr[11:7];

                        // Reference Model prediction
                        exp_ref = ref_model_predict(op, rs1_val, rs2_val);

                        // Scoreboard check
                        ok = (actual_res === exp_ref) && (wb_we === 1'b1) && (wb_waddr === {1'b0, rd});

                        if (op_count.exists(op)) op_count[op]++;
                        else                     op_count[op] = 1;

                        if (ok) begin
                            pass_count++;
                            $display("[MUL_SB PASS] %-6s rs1=0x%08h rs2=0x%08h -> result=0x%08h (exp: 0x%08h) rd=x%0d",
                                     op.name(), rs1_val, rs2_val, actual_res, exp_ref, rd);
                        end
                        else begin
                            fail_count++;
                            $display("[MUL_SB MISMATCH] %-6s instr=0x%08h rs1=0x%08h rs2=0x%08h exp=0x%08h act=0x%08h | rd=x%0d we=%0b waddr=%0d",
                                     op.name(), ex_instr, rs1_val, rs2_val, exp_ref, actual_res, rd, wb_we, wb_waddr);
                        end

                        // Hand-computed checker cross-check
                        if (num_items < exp_op.size()) begin
                            hand_exp = exp_result[num_items];
                            if (op === exp_op[num_items] && actual_res === hand_exp) begin
                                chk_matches++;
                                $display("  [HAND_CHK PASS] #%0d matched expected golden value: 0x%08h", num_items, hand_exp);
                            end else begin
                                $display("  [HAND_CHK FAIL] #%0d expected %s=0x%08h, got %s=0x%08h",
                                         num_items, exp_op[num_items].name(), hand_exp, op.name(), actual_res);
                                fail_count++;
                            end
                        end

                        num_items++;
                    end
                end
                ex_instr_valid <= 0;
            end

            // 2. ENTER: instruction moves ID -> EX
            if (dut.core_i.id_valid === 1'b1) begin
                ex_instr       <= dut.core_i.instr_rdata_id;
                ex_instr_valid <= 1;
            end
        end
    end

    // ---------------- Main Test Control ----------------
    initial begin
        string test_name = "mul_all_ops_test";
        void'($value$plusargs("TESTNAME=%s", test_name));

        load_program(test_name);

        // Preload memory
        foreach (mem[i]) mem[i] = JAL_SELF;
        foreach (test_code[i]) mem[i] = test_code[i];

        $display("==========================================================");
        $display(" Starting Standalone Simulation: %s", test_name);
        $display(" Loaded %0d instructions into instruction memory", test_code.size());
        $display("==========================================================");

        // Reset sequence
        #10;
        repeat (5) @(posedge clk);
        rst_n <= 1'b1;

        // Wait for all expected multiplies or timeout
        fork
            begin
                wait (num_items == exp_op.size());
                #200; // allow pipeline to settle
            end
            begin
                #100000; // 100 us timeout
                $display("\n[TIMEOUT] Test timed out waiting for multiplier operations!");
                fail_count++;
            end
        join_any
        disable fork;

        // ---------------- Final Report ----------------
        $display("\n==========================================================");
        $display("                 MUL SIMULATION SUMMARY                   ");
        $display("==========================================================");
        $display(" Total Multiply Ops Checked : %0d", num_items);
        $display(" Scoreboard Passes          : %0d", pass_count);
        $display(" Scoreboard Fails           : %0d", fail_count);
        $display(" Hand-computed Match Passes : %0d / %0d", chk_matches, exp_op.size());
        $display("----------------------------------------------------------");
        foreach (op_count[op]) begin
            $display("  Op: %-6s executed %0d times", op.name(), op_count[op]);
        end
        $display("----------------------------------------------------------");
        if (fail_count == 0 && pass_count == exp_op.size()) begin
            $display("       *** ALL TESTS PASSED SUCCESSFULLY! ***             ");
        end else begin
            $display("       *** TEST FAILED - CHECK MISMATCHES! ***            ");
        end
        $display("==========================================================\n");

        $finish;
    end

endmodule
