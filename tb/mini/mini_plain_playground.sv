`timescale 1ns/1ps
// =============================================================
// GENERATED FILE - do not edit by hand.
// Single-file version of the PLAIN mini bench (no UVM, no SVA,
// no covergroups) for EDA Playground / ModelSim / any SV sim.
// Regenerate: see tb/scripts/make_plain_bundle.sh
// Top module: mini_plain_tb  (prints 3 instructions + mini_plain.vcd)
// =============================================================

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> rtl/package/cv32e40p_pkg.sv
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
//                                                                            //
// Design Name:    RISC-V processor core                                      //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Defines for various constants used by the processor core.  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

package cv32e40p_pkg;

  ////////////////////////////////////////////////
  //    ___         ____          _             //
  //   / _ \ _ __  / ___|___   __| | ___  ___   //
  //  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //
  //  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //
  //   \___/| .__/ \____\___/ \__,_|\___||___/  //
  //        |_|                                 //
  ////////////////////////////////////////////////

  parameter OPCODE_SYSTEM = 7'h73;
  parameter OPCODE_FENCE = 7'h0f;
  parameter OPCODE_OP = 7'h33;
  parameter OPCODE_OPIMM = 7'h13;
  parameter OPCODE_STORE = 7'h23;
  parameter OPCODE_LOAD = 7'h03;
  parameter OPCODE_BRANCH = 7'h63;
  parameter OPCODE_JALR = 7'h67;
  parameter OPCODE_JAL = 7'h6f;
  parameter OPCODE_AUIPC = 7'h17;
  parameter OPCODE_LUI = 7'h37;
  parameter OPCODE_OP_FP = 7'h53;
  parameter OPCODE_OP_FMADD = 7'h43;
  parameter OPCODE_OP_FNMADD = 7'h4f;
  parameter OPCODE_OP_FMSUB = 7'h47;
  parameter OPCODE_OP_FNMSUB = 7'h4b;
  parameter OPCODE_STORE_FP = 7'h27;
  parameter OPCODE_LOAD_FP = 7'h07;
  parameter OPCODE_AMO = 7'h2F;

  // Those custom opcodes are used for PULP custom instructions
  parameter OPCODE_CUSTOM_0 = 7'h0b;
  parameter OPCODE_CUSTOM_1 = 7'h2b;
  parameter OPCODE_CUSTOM_2 = 7'h5b;
  parameter OPCODE_CUSTOM_3 = 7'h7b;

  parameter REGC_S1 = 2'b10;
  parameter REGC_S4 = 2'b00;
  parameter REGC_RD = 2'b01;
  parameter REGC_ZERO = 2'b11;

  //////////////////////////////////////////////////////////////////////////////
  //      _    _    _   _    ___                       _   _                  //
  //     / \  | |  | | | |  / _ \ _ __   ___ _ __ __ _| |_(_) ___  _ __  ___  //
  //    / _ \ | |  | | | | | | | | '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \/ __| //
  //   / ___ \| |__| |_| | | |_| | |_) |  __/ | | (_| | |_| | (_) | | | \__ \ //
  //  /_/   \_\_____\___/   \___/| .__/ \___|_|  \__,_|\__|_|\___/|_| |_|___/ //
  //                             |_|                                          //
  //////////////////////////////////////////////////////////////////////////////

  parameter ALU_OP_WIDTH = 7;

  typedef enum logic [ALU_OP_WIDTH-1:0] {

    ALU_ADD   = 7'b0011000,
    ALU_SUB   = 7'b0011001,
    ALU_ADDU  = 7'b0011010,
    ALU_SUBU  = 7'b0011011,
    ALU_ADDR  = 7'b0011100,
    ALU_SUBR  = 7'b0011101,
    ALU_ADDUR = 7'b0011110,
    ALU_SUBUR = 7'b0011111,

    ALU_XOR = 7'b0101111,
    ALU_OR  = 7'b0101110,
    ALU_AND = 7'b0010101,

    // Shifts
    ALU_SRA = 7'b0100100,
    ALU_SRL = 7'b0100101,
    ALU_ROR = 7'b0100110,
    ALU_SLL = 7'b0100111,

    // bit manipulation
    ALU_BEXT  = 7'b0101000,
    ALU_BEXTU = 7'b0101001,
    ALU_BINS  = 7'b0101010,
    ALU_BCLR  = 7'b0101011,
    ALU_BSET  = 7'b0101100,
    ALU_BREV  = 7'b1001001,

    // Bit counting
    ALU_FF1 = 7'b0110110,
    ALU_FL1 = 7'b0110111,
    ALU_CNT = 7'b0110100,
    ALU_CLB = 7'b0110101,

    // Sign-/zero-extensions
    ALU_EXTS = 7'b0111110,
    ALU_EXT  = 7'b0111111,

    // Comparisons
    ALU_LTS = 7'b0000000,
    ALU_LTU = 7'b0000001,
    ALU_LES = 7'b0000100,
    ALU_LEU = 7'b0000101,
    ALU_GTS = 7'b0001000,
    ALU_GTU = 7'b0001001,
    ALU_GES = 7'b0001010,
    ALU_GEU = 7'b0001011,
    ALU_EQ  = 7'b0001100,
    ALU_NE  = 7'b0001101,

    // Set Lower Than operations
    ALU_SLTS  = 7'b0000010,
    ALU_SLTU  = 7'b0000011,
    ALU_SLETS = 7'b0000110,
    ALU_SLETU = 7'b0000111,

    // Absolute value
    ALU_ABS   = 7'b0010100,
    ALU_CLIP  = 7'b0010110,
    ALU_CLIPU = 7'b0010111,

    // Insert/extract
    ALU_INS = 7'b0101101,

    // min/max
    ALU_MIN  = 7'b0010000,
    ALU_MINU = 7'b0010001,
    ALU_MAX  = 7'b0010010,
    ALU_MAXU = 7'b0010011,

    // div/rem
    ALU_DIVU = 7'b0110000,  // bit 0 is used for signed mode, bit 1 is used for remdiv
    ALU_DIV  = 7'b0110001,  // bit 0 is used for signed mode, bit 1 is used for remdiv
    ALU_REMU = 7'b0110010,  // bit 0 is used for signed mode, bit 1 is used for remdiv
    ALU_REM  = 7'b0110011,  // bit 0 is used for signed mode, bit 1 is used for remdiv

    ALU_SHUF  = 7'b0111010,
    ALU_SHUF2 = 7'b0111011,
    ALU_PCKLO = 7'b0111000,
    ALU_PCKHI = 7'b0111001

  } alu_opcode_e;

  parameter MUL_OP_WIDTH = 3;

  typedef enum logic [MUL_OP_WIDTH-1:0] {

    MUL_MAC32 = 3'b000,
    MUL_MSU32 = 3'b001,
    MUL_I     = 3'b010,
    MUL_IR    = 3'b011,
    MUL_DOT8  = 3'b100,
    MUL_DOT16 = 3'b101,
    MUL_H     = 3'b110

  } mul_opcode_e;

  // vector modes
  parameter VEC_MODE32 = 2'b00;
  parameter VEC_MODE16 = 2'b10;
  parameter VEC_MODE8 = 2'b11;


  // FSM state encoding
  typedef enum logic [4:0] {
    RESET,
    BOOT_SET,
    SLEEP,
    WAIT_SLEEP,
    FIRST_FETCH,
    DECODE,
    IRQ_FLUSH_ELW,
    ELW_EXE,
    FLUSH_EX,
    FLUSH_WB,
    XRET_JUMP,
    DBG_TAKEN_ID,
    DBG_TAKEN_IF,
    DBG_FLUSH,
    DBG_WAIT_BRANCH,
    DECODE_HWLOOP
  } ctrl_state_e;

  // Debug FSM state encoding
  // State encoding done one-hot to ensure that debug_havereset_o, debug_running_o, debug_halted_o
  // will come directly from flip-flops. *_INDEX and debug_state_e encoding must match

  parameter HAVERESET_INDEX = 0;
  parameter RUNNING_INDEX = 1;
  parameter HALTED_INDEX = 2;

  typedef enum logic [2:0] {
    HAVERESET = 3'b001,
    RUNNING   = 3'b010,
    HALTED    = 3'b100
  } debug_state_e;

  typedef enum logic {
    IDLE,
    BRANCH_WAIT
  } prefetch_state_e;

  typedef enum logic [2:0] {
    IDLE_MULT,
    STEP0,
    STEP1,
    STEP2,
    FINISH
  } mult_state_e;

  /////////////////////////////////////////////////////////
  //    ____ ____    ____            _     _             //
  //   / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __  //
  //  | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__| //
  //  | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |    //
  //   \____|____/  |_| \_\___|\__, |_|___/\__\___|_|    //
  //                           |___/                     //
  /////////////////////////////////////////////////////////

  // CSRs mnemonics
  // imported form IBEX, some regs may be still not implemented
  typedef enum logic [11:0] {

    ///////////////////////////////////////////////////////
    // User CSRs
    ///////////////////////////////////////////////////////

    // User trap setup
    CSR_USTATUS = 12'h000,  // Not included (PULP_SECURE = 0)

    // Floating Point
    CSR_FFLAGS = 12'h001,  // Included if FPU = 1
    CSR_FRM    = 12'h002,  // Included if FPU = 1
    CSR_FCSR   = 12'h003,  // Included if FPU = 1

    // User trap setup
    CSR_UTVEC = 12'h005,  // Not included (PULP_SECURE = 0)

    // User trap handling
    CSR_UEPC   = 12'h041,  // Not included (PULP_SECURE = 0)
    CSR_UCAUSE = 12'h042,  // Not included (PULP_SECURE = 0)

    ///////////////////////////////////////////////////////
    // User Custom CSRs
    ///////////////////////////////////////////////////////

    // Hardware Loop
    CSR_LPSTART0 = 12'hCC0,  // Custom CSR. Included if PULP_HWLP = 1
    CSR_LPEND0   = 12'hCC1,  // Custom CSR. Included if PULP_HWLP = 1
    CSR_LPCOUNT0 = 12'hCC2,  // Custom CSR. Included if PULP_HWLP = 1
    CSR_LPSTART1 = 12'hCC4,  // Custom CSR. Included if PULP_HWLP = 1
    CSR_LPEND1   = 12'hCC5,  // Custom CSR. Included if PULP_HWLP = 1
    CSR_LPCOUNT1 = 12'hCC6,  // Custom CSR. Included if PULP_HWLP = 1

    // User Hart ID
    CSR_UHARTID = 12'hCD0,  // Custom CSR. User Hart ID

    // Privilege
    CSR_PRIVLV = 12'hCD1,  // Custom CSR. Privilege Level

    // ZFINX
    CSR_ZFINX = 12'hCD2,  // Custom CSR. ZFINX

    ///////////////////////////////////////////////////////
    // Machine CSRs
    ///////////////////////////////////////////////////////

    // Machine trap setup
    CSR_MSTATUS = 12'h300,
    CSR_MISA    = 12'h301,
    CSR_MIE     = 12'h304,
    CSR_MTVEC   = 12'h305,

    // Performance counters
    CSR_MCOUNTEREN    = 12'h306,
    CSR_MCOUNTINHIBIT = 12'h320,
    CSR_MHPMEVENT3    = 12'h323,
    CSR_MHPMEVENT4    = 12'h324,
    CSR_MHPMEVENT5    = 12'h325,
    CSR_MHPMEVENT6    = 12'h326,
    CSR_MHPMEVENT7    = 12'h327,
    CSR_MHPMEVENT8    = 12'h328,
    CSR_MHPMEVENT9    = 12'h329,
    CSR_MHPMEVENT10   = 12'h32A,
    CSR_MHPMEVENT11   = 12'h32B,
    CSR_MHPMEVENT12   = 12'h32C,
    CSR_MHPMEVENT13   = 12'h32D,
    CSR_MHPMEVENT14   = 12'h32E,
    CSR_MHPMEVENT15   = 12'h32F,
    CSR_MHPMEVENT16   = 12'h330,
    CSR_MHPMEVENT17   = 12'h331,
    CSR_MHPMEVENT18   = 12'h332,
    CSR_MHPMEVENT19   = 12'h333,
    CSR_MHPMEVENT20   = 12'h334,
    CSR_MHPMEVENT21   = 12'h335,
    CSR_MHPMEVENT22   = 12'h336,
    CSR_MHPMEVENT23   = 12'h337,
    CSR_MHPMEVENT24   = 12'h338,
    CSR_MHPMEVENT25   = 12'h339,
    CSR_MHPMEVENT26   = 12'h33A,
    CSR_MHPMEVENT27   = 12'h33B,
    CSR_MHPMEVENT28   = 12'h33C,
    CSR_MHPMEVENT29   = 12'h33D,
    CSR_MHPMEVENT30   = 12'h33E,
    CSR_MHPMEVENT31   = 12'h33F,

    // Machine trap handling
    CSR_MSCRATCH = 12'h340,
    CSR_MEPC     = 12'h341,
    CSR_MCAUSE   = 12'h342,
    CSR_MTVAL    = 12'h343,
    CSR_MIP      = 12'h344,

    // Physical memory protection (PMP)
    CSR_PMPCFG0   = 12'h3A0,  // Not included (USE_PMP = 0)
    CSR_PMPCFG1   = 12'h3A1,  // Not included (USE_PMP = 0)
    CSR_PMPCFG2   = 12'h3A2,  // Not included (USE_PMP = 0)
    CSR_PMPCFG3   = 12'h3A3,  // Not included (USE_PMP = 0)
    CSR_PMPADDR0  = 12'h3B0,  // Not included (USE_PMP = 0)
    CSR_PMPADDR1  = 12'h3B1,  // Not included (USE_PMP = 0)
    CSR_PMPADDR2  = 12'h3B2,  // Not included (USE_PMP = 0)
    CSR_PMPADDR3  = 12'h3B3,  // Not included (USE_PMP = 0)
    CSR_PMPADDR4  = 12'h3B4,  // Not included (USE_PMP = 0)
    CSR_PMPADDR5  = 12'h3B5,  // Not included (USE_PMP = 0)
    CSR_PMPADDR6  = 12'h3B6,  // Not included (USE_PMP = 0)
    CSR_PMPADDR7  = 12'h3B7,  // Not included (USE_PMP = 0)
    CSR_PMPADDR8  = 12'h3B8,  // Not included (USE_PMP = 0)
    CSR_PMPADDR9  = 12'h3B9,  // Not included (USE_PMP = 0)
    CSR_PMPADDR10 = 12'h3BA,  // Not included (USE_PMP = 0)
    CSR_PMPADDR11 = 12'h3BB,  // Not included (USE_PMP = 0)
    CSR_PMPADDR12 = 12'h3BC,  // Not included (USE_PMP = 0)
    CSR_PMPADDR13 = 12'h3BD,  // Not included (USE_PMP = 0)
    CSR_PMPADDR14 = 12'h3BE,  // Not included (USE_PMP = 0)
    CSR_PMPADDR15 = 12'h3BF,  // Not included (USE_PMP = 0)

    // Trigger
    CSR_TSELECT  = 12'h7A0,
    CSR_TDATA1   = 12'h7A1,
    CSR_TDATA2   = 12'h7A2,
    CSR_TDATA3   = 12'h7A3,
    CSR_TINFO    = 12'h7A4,
    CSR_MCONTEXT = 12'h7A8,
    CSR_SCONTEXT = 12'h7AA,

    // Debug/trace
    CSR_DCSR = 12'h7B0,
    CSR_DPC  = 12'h7B1,

    // Debug
    CSR_DSCRATCH0 = 12'h7B2,
    CSR_DSCRATCH1 = 12'h7B3,

    // Hardware Performance Monitor
    CSR_MCYCLE        = 12'hB00,
    CSR_MINSTRET      = 12'hB02,
    CSR_MHPMCOUNTER3  = 12'hB03,
    CSR_MHPMCOUNTER4  = 12'hB04,
    CSR_MHPMCOUNTER5  = 12'hB05,
    CSR_MHPMCOUNTER6  = 12'hB06,
    CSR_MHPMCOUNTER7  = 12'hB07,
    CSR_MHPMCOUNTER8  = 12'hB08,
    CSR_MHPMCOUNTER9  = 12'hB09,
    CSR_MHPMCOUNTER10 = 12'hB0A,
    CSR_MHPMCOUNTER11 = 12'hB0B,
    CSR_MHPMCOUNTER12 = 12'hB0C,
    CSR_MHPMCOUNTER13 = 12'hB0D,
    CSR_MHPMCOUNTER14 = 12'hB0E,
    CSR_MHPMCOUNTER15 = 12'hB0F,
    CSR_MHPMCOUNTER16 = 12'hB10,
    CSR_MHPMCOUNTER17 = 12'hB11,
    CSR_MHPMCOUNTER18 = 12'hB12,
    CSR_MHPMCOUNTER19 = 12'hB13,
    CSR_MHPMCOUNTER20 = 12'hB14,
    CSR_MHPMCOUNTER21 = 12'hB15,
    CSR_MHPMCOUNTER22 = 12'hB16,
    CSR_MHPMCOUNTER23 = 12'hB17,
    CSR_MHPMCOUNTER24 = 12'hB18,
    CSR_MHPMCOUNTER25 = 12'hB19,
    CSR_MHPMCOUNTER26 = 12'hB1A,
    CSR_MHPMCOUNTER27 = 12'hB1B,
    CSR_MHPMCOUNTER28 = 12'hB1C,
    CSR_MHPMCOUNTER29 = 12'hB1D,
    CSR_MHPMCOUNTER30 = 12'hB1E,
    CSR_MHPMCOUNTER31 = 12'hB1F,

    CSR_MCYCLEH        = 12'hB80,
    CSR_MINSTRETH      = 12'hB82,
    CSR_MHPMCOUNTER3H  = 12'hB83,
    CSR_MHPMCOUNTER4H  = 12'hB84,
    CSR_MHPMCOUNTER5H  = 12'hB85,
    CSR_MHPMCOUNTER6H  = 12'hB86,
    CSR_MHPMCOUNTER7H  = 12'hB87,
    CSR_MHPMCOUNTER8H  = 12'hB88,
    CSR_MHPMCOUNTER9H  = 12'hB89,
    CSR_MHPMCOUNTER10H = 12'hB8A,
    CSR_MHPMCOUNTER11H = 12'hB8B,
    CSR_MHPMCOUNTER12H = 12'hB8C,
    CSR_MHPMCOUNTER13H = 12'hB8D,
    CSR_MHPMCOUNTER14H = 12'hB8E,
    CSR_MHPMCOUNTER15H = 12'hB8F,
    CSR_MHPMCOUNTER16H = 12'hB90,
    CSR_MHPMCOUNTER17H = 12'hB91,
    CSR_MHPMCOUNTER18H = 12'hB92,
    CSR_MHPMCOUNTER19H = 12'hB93,
    CSR_MHPMCOUNTER20H = 12'hB94,
    CSR_MHPMCOUNTER21H = 12'hB95,
    CSR_MHPMCOUNTER22H = 12'hB96,
    CSR_MHPMCOUNTER23H = 12'hB97,
    CSR_MHPMCOUNTER24H = 12'hB98,
    CSR_MHPMCOUNTER25H = 12'hB99,
    CSR_MHPMCOUNTER26H = 12'hB9A,
    CSR_MHPMCOUNTER27H = 12'hB9B,
    CSR_MHPMCOUNTER28H = 12'hB9C,
    CSR_MHPMCOUNTER29H = 12'hB9D,
    CSR_MHPMCOUNTER30H = 12'hB9E,
    CSR_MHPMCOUNTER31H = 12'hB9F,

    CSR_CYCLE        = 12'hC00,
    CSR_INSTRET      = 12'hC02,
    CSR_HPMCOUNTER3  = 12'hC03,
    CSR_HPMCOUNTER4  = 12'hC04,
    CSR_HPMCOUNTER5  = 12'hC05,
    CSR_HPMCOUNTER6  = 12'hC06,
    CSR_HPMCOUNTER7  = 12'hC07,
    CSR_HPMCOUNTER8  = 12'hC08,
    CSR_HPMCOUNTER9  = 12'hC09,
    CSR_HPMCOUNTER10 = 12'hC0A,
    CSR_HPMCOUNTER11 = 12'hC0B,
    CSR_HPMCOUNTER12 = 12'hC0C,
    CSR_HPMCOUNTER13 = 12'hC0D,
    CSR_HPMCOUNTER14 = 12'hC0E,
    CSR_HPMCOUNTER15 = 12'hC0F,
    CSR_HPMCOUNTER16 = 12'hC10,
    CSR_HPMCOUNTER17 = 12'hC11,
    CSR_HPMCOUNTER18 = 12'hC12,
    CSR_HPMCOUNTER19 = 12'hC13,
    CSR_HPMCOUNTER20 = 12'hC14,
    CSR_HPMCOUNTER21 = 12'hC15,
    CSR_HPMCOUNTER22 = 12'hC16,
    CSR_HPMCOUNTER23 = 12'hC17,
    CSR_HPMCOUNTER24 = 12'hC18,
    CSR_HPMCOUNTER25 = 12'hC19,
    CSR_HPMCOUNTER26 = 12'hC1A,
    CSR_HPMCOUNTER27 = 12'hC1B,
    CSR_HPMCOUNTER28 = 12'hC1C,
    CSR_HPMCOUNTER29 = 12'hC1D,
    CSR_HPMCOUNTER30 = 12'hC1E,
    CSR_HPMCOUNTER31 = 12'hC1F,

    CSR_CYCLEH        = 12'hC80,
    CSR_INSTRETH      = 12'hC82,
    CSR_HPMCOUNTER3H  = 12'hC83,
    CSR_HPMCOUNTER4H  = 12'hC84,
    CSR_HPMCOUNTER5H  = 12'hC85,
    CSR_HPMCOUNTER6H  = 12'hC86,
    CSR_HPMCOUNTER7H  = 12'hC87,
    CSR_HPMCOUNTER8H  = 12'hC88,
    CSR_HPMCOUNTER9H  = 12'hC89,
    CSR_HPMCOUNTER10H = 12'hC8A,
    CSR_HPMCOUNTER11H = 12'hC8B,
    CSR_HPMCOUNTER12H = 12'hC8C,
    CSR_HPMCOUNTER13H = 12'hC8D,
    CSR_HPMCOUNTER14H = 12'hC8E,
    CSR_HPMCOUNTER15H = 12'hC8F,
    CSR_HPMCOUNTER16H = 12'hC90,
    CSR_HPMCOUNTER17H = 12'hC91,
    CSR_HPMCOUNTER18H = 12'hC92,
    CSR_HPMCOUNTER19H = 12'hC93,
    CSR_HPMCOUNTER20H = 12'hC94,
    CSR_HPMCOUNTER21H = 12'hC95,
    CSR_HPMCOUNTER22H = 12'hC96,
    CSR_HPMCOUNTER23H = 12'hC97,
    CSR_HPMCOUNTER24H = 12'hC98,
    CSR_HPMCOUNTER25H = 12'hC99,
    CSR_HPMCOUNTER26H = 12'hC9A,
    CSR_HPMCOUNTER27H = 12'hC9B,
    CSR_HPMCOUNTER28H = 12'hC9C,
    CSR_HPMCOUNTER29H = 12'hC9D,
    CSR_HPMCOUNTER30H = 12'hC9E,
    CSR_HPMCOUNTER31H = 12'hC9F,

    // Machine information
    CSR_MVENDORID = 12'hF11,
    CSR_MARCHID   = 12'hF12,
    CSR_MIMPID    = 12'hF13,
    CSR_MHARTID   = 12'hF14
  } csr_num_e;

  // CSR operations

  parameter CSR_OP_WIDTH = 2;

  typedef enum logic [CSR_OP_WIDTH-1:0] {
    CSR_OP_READ  = 2'b00,
    CSR_OP_WRITE = 2'b01,
    CSR_OP_SET   = 2'b10,
    CSR_OP_CLEAR = 2'b11
  } csr_opcode_e;

  // CSR interrupt pending/enable bits
  parameter int unsigned CSR_MSIX_BIT = 3;
  parameter int unsigned CSR_MTIX_BIT = 7;
  parameter int unsigned CSR_MEIX_BIT = 11;
  parameter int unsigned CSR_MFIX_BIT_LOW = 16;
  parameter int unsigned CSR_MFIX_BIT_HIGH = 31;

  // SPR for debugger, not accessible by CPU
  parameter SP_DVR0 = 16'h3000;
  parameter SP_DCR0 = 16'h3008;
  parameter SP_DMR1 = 16'h3010;
  parameter SP_DMR2 = 16'h3011;

  parameter SP_DVR_MSB = 8'h00;
  parameter SP_DCR_MSB = 8'h01;
  parameter SP_DMR_MSB = 8'h02;
  parameter SP_DSR_MSB = 8'h04;

  // Privileged mode
  typedef enum logic [1:0] {
    PRIV_LVL_M = 2'b11,
    PRIV_LVL_H = 2'b10,
    PRIV_LVL_S = 2'b01,
    PRIV_LVL_U = 2'b00
  } PrivLvl_t;

  typedef struct packed {
    logic uie;
    // logic sie;      - unimplemented, hardwired to '0
    // logic hie;      - unimplemented, hardwired to '0
    logic mie;
    logic upie;
    // logic spie;     - unimplemented, hardwired to '0
    // logic hpie;     - unimplemented, hardwired to '0
    logic mpie;
    // logic spp;      - unimplemented, hardwired to '0
    // logic[1:0] hpp; - unimplemented, hardwired to '0
    PrivLvl_t mpp;
    logic mprv;
  } Status_t;

  typedef struct packed {
    logic [31:28] xdebugver;
    logic [27:16] zero2;
    logic ebreakm;
    logic zero1;
    logic ebreaks;
    logic ebreaku;
    logic stepie;
    logic stopcount;
    logic stoptime;
    logic [8:6] cause;
    logic zero0;
    logic mprven;
    logic nmip;
    logic step;
    PrivLvl_t prv;
  } Dcsr_t;

  // Floating Point State
  typedef enum logic [1:0] {
    FS_OFF     = 2'b00,
    FS_INITIAL = 2'b01,
    FS_CLEAN   = 2'b10,
    FS_DIRTY   = 2'b11
  } FS_t;

  // Machine Vendor ID - OpenHW JEDEC ID is '2 decimal (bank 13)'
  parameter MVENDORID_OFFSET = 7'h2;  // Final byte without parity bit
  parameter MVENDORID_BANK = 25'hC;  // Number of continuation codes

  // Machine Architecture ID (https://github.com/riscv/riscv-isa-manual/blob/master/marchid.md)
  parameter MARCHID = 32'h4;

  parameter MHPMCOUNTER_WIDTH = 64;

  ///////////////////////////////////////////////
  //   ___ ____    ____  _                     //
  //  |_ _|  _ \  / ___|| |_ __ _  __ _  ___   //
  //   | || | | | \___ \| __/ _` |/ _` |/ _ \  //
  //   | || |_| |  ___) | || (_| | (_| |  __/  //
  //  |___|____/  |____/ \__\__,_|\__, |\___|  //
  //                              |___/        //
  ///////////////////////////////////////////////

  // forwarding operand mux
  parameter SEL_REGFILE = 2'b00;
  parameter SEL_FW_EX = 2'b01;
  parameter SEL_FW_WB = 2'b10;

  // operand a selection
  parameter OP_A_REGA_OR_FWD = 3'b000;
  parameter OP_A_CURRPC = 3'b001;
  parameter OP_A_IMM = 3'b010;
  parameter OP_A_REGB_OR_FWD = 3'b011;
  parameter OP_A_REGC_OR_FWD = 3'b100;

  // immediate a selection
  parameter IMMA_Z = 1'b0;
  parameter IMMA_ZERO = 1'b1;

  // operand b selection
  parameter OP_B_REGB_OR_FWD = 3'b000;
  parameter OP_B_REGC_OR_FWD = 3'b001;
  parameter OP_B_IMM = 3'b010;
  parameter OP_B_REGA_OR_FWD = 3'b011;
  parameter OP_B_BMASK = 3'b100;

  // immediate b selection
  parameter IMMB_I = 4'b0000;
  parameter IMMB_S = 4'b0001;
  parameter IMMB_U = 4'b0010;
  parameter IMMB_PCINCR = 4'b0011;
  parameter IMMB_S2 = 4'b0100;
  parameter IMMB_S3 = 4'b0101;
  parameter IMMB_VS = 4'b0110;
  parameter IMMB_VU = 4'b0111;
  parameter IMMB_SHUF = 4'b1000;
  parameter IMMB_CLIP = 4'b1001;
  parameter IMMB_BI = 4'b1011;

  // bit mask selection
  parameter BMASK_A_ZERO = 1'b0;
  parameter BMASK_A_S3 = 1'b1;

  parameter BMASK_B_S2 = 2'b00;
  parameter BMASK_B_S3 = 2'b01;
  parameter BMASK_B_ZERO = 2'b10;
  parameter BMASK_B_ONE = 2'b11;

  parameter BMASK_A_REG = 1'b0;
  parameter BMASK_A_IMM = 1'b1;
  parameter BMASK_B_REG = 1'b0;
  parameter BMASK_B_IMM = 1'b1;


  // multiplication immediates
  parameter MIMM_ZERO = 1'b0;
  parameter MIMM_S3 = 1'b1;

  // operand c selection
  parameter OP_C_REGC_OR_FWD = 2'b00;
  parameter OP_C_REGB_OR_FWD = 2'b01;
  parameter OP_C_JT = 2'b10;

  // branch types
  parameter BRANCH_NONE = 2'b00;
  parameter BRANCH_JAL = 2'b01;
  parameter BRANCH_JALR = 2'b10;
  parameter BRANCH_COND = 2'b11;  // conditional branches

  // jump target mux
  parameter JT_JAL = 2'b01;
  parameter JT_JALR = 2'b10;
  parameter JT_COND = 2'b11;

  // Atomic operations
  parameter AMO_LR = 5'b00010;
  parameter AMO_SC = 5'b00011;
  parameter AMO_SWAP = 5'b00001;
  parameter AMO_ADD = 5'b00000;
  parameter AMO_XOR = 5'b00100;
  parameter AMO_AND = 5'b01100;
  parameter AMO_OR = 5'b01000;
  parameter AMO_MIN = 5'b10000;
  parameter AMO_MAX = 5'b10100;
  parameter AMO_MINU = 5'b11000;
  parameter AMO_MAXU = 5'b11100;

  ///////////////////////////////////////////////
  //   ___ _____   ____  _                     //
  //  |_ _|  ___| / ___|| |_ __ _  __ _  ___   //
  //   | || |_    \___ \| __/ _` |/ _` |/ _ \  //
  //   | ||  _|    ___) | || (_| | (_| |  __/  //
  //  |___|_|     |____/ \__\__,_|\__, |\___|  //
  //                              |___/        //
  ///////////////////////////////////////////////

  // PC mux selector defines
  parameter PC_BOOT = 4'b0000;
  parameter PC_JUMP = 4'b0010;
  parameter PC_BRANCH = 4'b0011;
  parameter PC_EXCEPTION = 4'b0100;
  parameter PC_FENCEI = 4'b0001;
  parameter PC_MRET = 4'b0101;
  parameter PC_URET = 4'b0110;
  parameter PC_DRET = 4'b0111;
  parameter PC_HWLOOP = 4'b1000;

  // Exception PC mux selector defines
  parameter EXC_PC_EXCEPTION = 3'b000;
  parameter EXC_PC_IRQ = 3'b001;

  parameter EXC_PC_DBD = 3'b010;
  parameter EXC_PC_DBE = 3'b011;

  // Exception Cause
  parameter EXC_CAUSE_INSTR_FAULT = 5'h01;
  parameter EXC_CAUSE_ILLEGAL_INSN = 5'h02;
  parameter EXC_CAUSE_BREAKPOINT = 5'h03;
  parameter EXC_CAUSE_LOAD_FAULT = 5'h05;
  parameter EXC_CAUSE_STORE_FAULT = 5'h07;
  parameter EXC_CAUSE_ECALL_UMODE = 5'h08;
  parameter EXC_CAUSE_ECALL_MMODE = 5'h0B;

  // Interrupt mask
  parameter IRQ_MASK = 32'hFFFF0888;

  // Trap mux selector
  parameter TRAP_MACHINE = 2'b00;
  parameter TRAP_USER = 2'b01;

  // Debug Cause
  parameter DBG_CAUSE_NONE = 3'h0;
  parameter DBG_CAUSE_EBREAK = 3'h1;
  parameter DBG_CAUSE_TRIGGER = 3'h2;
  parameter DBG_CAUSE_HALTREQ = 3'h3;
  parameter DBG_CAUSE_STEP = 3'h4;
  parameter DBG_CAUSE_RSTHALTREQ = 3'h5;

  // Debug module
  parameter DBG_SETS_W = 6;

  parameter DBG_SETS_IRQ = 5;
  parameter DBG_SETS_ECALL = 4;
  parameter DBG_SETS_EILL = 3;
  parameter DBG_SETS_ELSU = 2;
  parameter DBG_SETS_EBRK = 1;
  parameter DBG_SETS_SSTE = 0;

  parameter DBG_CAUSE_HALT = 6'h1F;

  // Constants for the dcsr.xdebugver fields
  typedef enum logic [3:0] {
    XDEBUGVER_NO     = 4'd0,  // no external debug support
    XDEBUGVER_STD    = 4'd4,  // external debug according to RISC-V debug spec
    XDEBUGVER_NONSTD = 4'd15  // debug not conforming to RISC-V debug spec
  } x_debug_ver_e;

  // Trigger types
  typedef enum logic [3:0] {
    TTYPE_MCONTROL = 4'h2,
    TTYPE_ICOUNT   = 4'h3,
    TTYPE_ITRIGGER = 4'h4,
    TTYPE_ETRIGGER = 4'h5
  } trigger_type_e;

  // Floating-point extensions configuration
  parameter bit C_RVF = 1'b1;  // Is F extension enabled
  parameter bit C_RVD = 1'b0;  // Is D extension enabled - NOT SUPPORTED CURRENTLY

  // Transprecision floating-point extensions configuration
  parameter bit C_XF16 = 1'b0;  // Is half-precision float extension (Xf16) enabled
  parameter bit C_XF16ALT = 1'b0; // Is alternative half-precision float extension (Xf16alt) enabled
  parameter bit C_XF8 = 1'b0;  // Is quarter-precision float extension (Xf8) enabled
  parameter bit C_XFVEC = 1'b0;  // Is vectorial float extension (Xfvec) enabled

  // Latency of FP operations: 0 = no pipe registers, 1 = 1 pipe register etc.
  parameter int unsigned C_LAT_FP64 = 'd0;
  //parameter int unsigned C_LAT_FP32 = 'd0;
  parameter int unsigned C_LAT_FP16 = 'd0;
  parameter int unsigned C_LAT_FP16ALT = 'd0;
  parameter int unsigned C_LAT_FP8 = 'd0;
  parameter int unsigned C_LAT_DIVSQRT = 'd1;  // divsqrt post-processing pipe
  //parameter int unsigned C_LAT_CONV = 'd0;
  //parameter int unsigned C_LAT_NONCOMP = 'd0;

  // General FPU-specific defines

  // Length of widest floating-point format = width of fp regfile
  parameter C_FLEN = C_RVD ? 64 :  // D ext.
  C_RVF ? 32 :  // F ext.
  C_XF16 ? 16 :  // Xf16 ext.
  C_XF16ALT ? 16 :  // Xf16alt ext.
  C_XF8 ? 8 :  // Xf8 ext.
  0;  // Unused in case of no FP

  parameter C_FFLAG = 5;
  parameter C_RM = 3;

endpackage

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/common/rv32m_ref_pkg.sv
// =============================================================================
// rv32m_ref_pkg.sv
// -----------------------------------------------------------------------------
// Golden (reference) functions for the RISC-V "M" standard extension, RV32.
//
// Used by:
//   * ALU_MUL Scoreboard   (MUL side: mul/mulh/mulhsu/mulhu, ALU side: div/rem)
//   * Predictor            (ISA-level model, executes the program image)
//   * coverage_collector   (operand / result classification helpers)
//
// Source of truth: RISC-V Unprivileged ISA, version 20191213, chapter 7
// (a_random_refrence/riscv-spec-20191213.pdf):
//   MUL     rd = (rs1 * rs2)[31:0]                       (same for signed/unsigned)
//   MULH    rd = (sext(rs1) * sext(rs2))[63:32]
//   MULHSU  rd = (sext(rs1) * zext(rs2))[63:32]
//   MULHU   rd = (zext(rs1) * zext(rs2))[63:32]
//   DIV     signed quotient, rounds toward zero
//   DIVU    unsigned quotient
//   REM     signed remainder, sign of the dividend (rs1)
//   REMU    unsigned remainder
//   Table 7.1 - division by zero:   DIV/DIVU -> all ones, REM/REMU -> dividend
//               signed overflow (-2^31 / -1): DIV -> -2^31, REM -> 0
//
// All functions take the ARCHITECTURAL operands (rs1 value, rs2 value).
// DUT note (rtl/cv32e40p_decoder.sv, "div/divu/rem/remu"): the core feeds the
// divider with swapped operands (alu_operand_a = rs2 = divisor,
// alu_operand_b = rs1 = dividend, OP_A_REGB_OR_FWD / OP_B_REGA_OR_FWD). The ALU
// monitor must un-swap them before calling div_ref()/rem_ref(). The multiplier
// is NOT swapped (mult_operand_a = rs1, mult_operand_b = rs2).
//
// Scope (guidelines): vanilla RV32I + RV32M only; nothing else is modelled here.
// =============================================================================
package rv32m_ref_pkg;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  localparam logic [31:0] INT32_MIN = 32'h8000_0000;  // smallest signed int (-2^31)
  localparam logic [31:0] INT32_MAX = 32'h7FFF_FFFF;  // largest signed int (2^31-1)
  localparam logic [31:0] ALL_ONES  = 32'hFFFF_FFFF;  // 32 ones = -1 signed / max unsigned

  // RV32M opcodes. The enum value equals the funct3 field of the instruction
  // (opcode OP = 0110011, funct7 = 0000001), so decoding is a plain cast.
  typedef enum logic [2:0] {
    MUL    = 3'b000,   // rd = low 32 bits of rs1 * rs2
    MULH   = 3'b001,   // rd = high 32 bits of signed * signed
    MULHSU = 3'b010,   // rd = high 32 bits of signed * unsigned
    MULHU  = 3'b011,   // rd = high 32 bits of unsigned * unsigned
    DIV    = 3'b100,   // signed divide, round toward zero
    DIVU   = 3'b101,   // unsigned divide
    REM    = 3'b110,   // signed remainder (sign of dividend)
    REMU   = 3'b111    // unsigned remainder
  } rv32m_op_e;   // enum VALUE == funct3 field of the instruction

  // ---------------------------------------------------------------------------
  // Multiplier reference functions
  // ---------------------------------------------------------------------------
  // MUL: low 32 bits of the 64-bit product (identical for signed and unsigned).
  function automatic logic [31:0] mul_ref(input logic [31:0] a, input logic [31:0] b);
    logic [63:0] p;
    p = {32'b0, a} * {32'b0, b};   // 64-bit product (zero-extend both, multiply)
    return p[31:0];                // return LOW half (same for signed/unsigned)
  endfunction

  // MULH: high 32 bits of signed(rs1) * signed(rs2).
  function automatic logic [31:0] mulh_ref(input logic [31:0] a, input logic [31:0] b);
    logic signed [63:0] p;
    p = $signed({{32{a[31]}}, a}) * $signed({{32{b[31]}}, b});  // sign-extend both to 64, signed multiply
    return p[63:32];               // return HIGH half
  endfunction

  // MULHSU: high 32 bits of signed(rs1) * unsigned(rs2).
  // zext(rs2) is a non-negative 64-bit signed number, so a 64-bit signed product
  // is exact (|a| <= 2^31, b < 2^32  ->  |p| < 2^63).
  function automatic logic [31:0] mulhsu_ref(input logic [31:0] a, input logic [31:0] b);
    logic signed [63:0] p;
    p = $signed({{32{a[31]}}, a}) * $signed({32'b0, b});  // a sign-extended, b zero-extended
    return p[63:32];               // HIGH half; product always fits in 64 bits signed
  endfunction

  // MULHU: high 32 bits of unsigned(rs1) * unsigned(rs2).
  function automatic logic [31:0] mulhu_ref(input logic [31:0] a, input logic [31:0] b);
    logic [63:0] p;
    p = {32'b0, a} * {32'b0, b};   // zero-extend both, plain 64-bit multiply
    return p[63:32];               // HIGH half
  endfunction

  // ---------------------------------------------------------------------------
  // Divider reference functions (spec table 7.1 special cases handled first,
  // so we never rely on simulator behaviour for x/0 or INT32_MIN/-1)
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] div_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0)                              return ALL_ONES;   // x/0 -> -1 (spec Table 7.1)
    if ((a == INT32_MIN) && (b == ALL_ONES))     return INT32_MIN;  // (-2^31)/(-1) -> -2^31 (overflow)
    return $signed(a) / $signed(b);                                 // signed divide, truncates toward 0
  endfunction

  function automatic logic [31:0] divu_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0) return ALL_ONES;                                // x/0 -> 2^32-1 (spec)
    return a / b;                                                   // plain unsigned divide
  endfunction

  function automatic logic [31:0] rem_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0)                              return a;          // x%0 -> x (spec)
    if ((a == INT32_MIN) && (b == ALL_ONES))     return 32'h0;      // overflow: remainder is 0
    return $signed(a) % $signed(b);                                 // sign follows the dividend
  endfunction

  function automatic logic [31:0] remu_ref(input logic [31:0] a, input logic [31:0] b);
    if (b == 32'h0) return a;                                       // x%0 -> x (spec)
    return a % b;                                                   // plain unsigned remainder
  endfunction

  // ---------------------------------------------------------------------------
  // Dispatcher: expected rd value for any RV32M instruction
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] rv32m_ref(input rv32m_op_e  op,
                                            input logic [31:0] rs1_val,
                                            input logic [31:0] rs2_val);
    case (op)
      MUL:     return mul_ref   (rs1_val, rs2_val);   // dispatch to the right model
      MULH:    return mulh_ref  (rs1_val, rs2_val);
      MULHSU:  return mulhsu_ref(rs1_val, rs2_val);
      MULHU:   return mulhu_ref (rs1_val, rs2_val);
      DIV:     return div_ref   (rs1_val, rs2_val);
      DIVU:    return divu_ref  (rs1_val, rs2_val);
      REM:     return rem_ref   (rs1_val, rs2_val);
      REMU:    return remu_ref  (rs1_val, rs2_val);
      default: return 32'hx;                      // unreachable (enum is closed)
    endcase
  endfunction

  // quick classification helpers (used by coverage + scoreboard)
  function automatic bit is_mul_op(input rv32m_op_e op);
    return (op inside {MUL, MULH, MULHSU, MULHU});  // one of the 4 multiplies?
  endfunction

  function automatic bit is_div_op(input rv32m_op_e op);
    return (op inside {DIV, DIVU, REM, REMU});      // one of the 4 divides?
  endfunction

  // ---------------------------------------------------------------------------
  // Instruction-word helpers (R-type: funct7 | rs2 | rs1 | funct3 | rd | opcode)
  // ---------------------------------------------------------------------------
  localparam logic [6:0] OPCODE_OP   = 7'b0110011;
  localparam logic [6:0] FUNCT7_MULDIV = 7'b0000001;

  // Is this 32-bit word an RV32M instruction? (R-type + funct7 of M-ext)
  function automatic bit is_rv32m_instr(input logic [31:0] instr);
    return (instr[6:0] == OPCODE_OP) && (instr[31:25] == FUNCT7_MULDIV);
  endfunction

  // Which RV32M op? funct3 field [14:12] cast to our enum (values match).
  function automatic rv32m_op_e rv32m_op_of(input logic [31:0] instr);
    return rv32m_op_e'(instr[14:12]);
  endfunction

  // RISC-V field extractors: rd=[11:7], rs1=[19:15], rs2=[24:20]
  function automatic logic [4:0] instr_rd (input logic [31:0] instr); return instr[11:7];  endfunction
  function automatic logic [4:0] instr_rs1(input logic [31:0] instr); return instr[19:15]; endfunction
  function automatic logic [4:0] instr_rs2(input logic [31:0] instr); return instr[24:20]; endfunction

  // ---------------------------------------------------------------------------
  // Coverage helpers
  // ---------------------------------------------------------------------------
  // Operand classes used by the MUL / ALU covergroups (vplan: m_operands_cg,
  // mulh_corners_cg, div_corners_cg). Exact corner values first, then ranges.
  typedef enum int {
    OPC_ZERO,        // 0x00000000
    OPC_ONE,         // 0x00000001
    OPC_MINUS_ONE,   // 0xFFFFFFFF
    OPC_INT_MAX,     // 0x7FFFFFFF
    OPC_INT_MIN,     // 0x80000000
    OPC_ALT_AA,      // 0xAAAAAAAA
    OPC_ALT_55,      // 0x55555555
    OPC_POW2,        // exactly one bit set (2 .. 2^30)
    OPC_POS_SMALL,   // 0x00000002 .. 0x0000FFFF (positive, 16-bit)
    OPC_POS_LARGE,   // 0x00010000 .. 0x7FFFFFFE
    OPC_NEG_SMALL,   // 0xFFFF0000 .. 0xFFFFFFFE (-65536 .. -2)
    OPC_NEG_LARGE    // 0x80000001 .. 0xFFFEFFFF
  } operand_class_e;

  // classic power-of-2 test: exactly one bit set and v != 0
  function automatic bit is_pow2(input logic [31:0] v);
    return (v != 32'h0) && ((v & (v - 32'h1)) == 32'h0);
  endfunction

  function automatic operand_class_e classify_operand(input logic [31:0] v);
    if (v == 32'h0000_0000) return OPC_ZERO;       // exact corner values first...
    if (v == 32'h0000_0001) return OPC_ONE;
    if (v == ALL_ONES)      return OPC_MINUS_ONE;
    if (v == INT32_MAX)     return OPC_INT_MAX;
    if (v == INT32_MIN)     return OPC_INT_MIN;
    if (v == 32'hAAAA_AAAA) return OPC_ALT_AA;     // alternating 1010...
    if (v == 32'h5555_5555) return OPC_ALT_55;     // alternating 0101...
    if (is_pow2(v))         return OPC_POW2;       // then "one bit set"
    if (v[31] == 1'b0)      return (v <= 32'h0000_FFFF) ? OPC_POS_SMALL : OPC_POS_LARGE;
    return (v >= 32'hFFFF_0000) ? OPC_NEG_SMALL : OPC_NEG_LARGE;  // negative ranges
  endfunction

  // 1 when the exact signed product does not fit in 32 bits, i.e. MUL's result
  // differs from the mathematical signed product (the high word is not the
  // sign extension of the low word). Interesting bin for MUL coverage.
  function automatic bit mul_signed_overflow(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] lo, hi;
    lo = mul_ref(a, b);               // low word of the product
    hi = mulh_ref(a, b);              // high word of the SIGNED product
    return (hi != {32{lo[31]}});      // high word is NOT the sign extension -> overflow
  endfunction

  // 1 when the unsigned product does not fit in 32 bits.
  function automatic bit mul_unsigned_overflow(input logic [31:0] a, input logic [31:0] b);
    return (mulhu_ref(a, b) != 32'h0);   // high word of unsigned product != 0
  endfunction

endpackage : rv32m_ref_pkg

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/common/alu_ref_pkg.sv
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

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/sequences/mul_program_pkg.sv
// =============================================================================
// mul_program_pkg.sv
// -----------------------------------------------------------------------------
// MUL-directed program generator (plain SystemVerilog, no UVM dependency so
// that it can be used by the UVM V_Sequence layer AND by the Verilator smoke
// test). It produces a list of RV32IM instruction words that exercises the
// multiplier scenarios of the MUL verification plan (notes/mul_plan.md §2.7):
//
//   single       : one M op with class-weighted operands (corner values first)
//   sign_matrix  : MULH / MULHSU / MULHU x {pos,neg} x {pos,neg}
//   special_regs : rd = x0, rs1 == rs2, rd == rs1, rd == rs2, all equal
//   back_to_back : 2..5 independent M ops with no gap (MULH x MULH, MULH->MUL, ...)
//   dependency   : RAW distance 1 / 2, MULH->MUL, MUL->store data, MUL->address,
//                  DIV->MUL, MUL->branch condition, accumulate chains
//   after_load   : LW then an independent MULH/MUL (with data wait states the
//                  MULH FSM ends in FINISH while WB waits -> external stall),
//                  then a load-use MUL
//   before_branch: M op followed by a taken branch, M op in the branch shadow
//                  (must never reach EX), M op after a not-taken branch
//   div_mix      : DIV / REM interleaved with M ops (ALU multi-cycle + MUL)
//   alu_mix      : RV32I ALU operators, LUI/AUIPC, AUIPC+JALR pattern (ALU agent)
//   div_corners  : divisor classes sweeping the divider latency 3..35, divide by
//                  zero, INT_MIN / -1 (ALU agent, risc_m_02 / risc_m_03)
//   lsu_mix      : lb/lh/lw/lbu/lhu + sb/sh/sw, aligned and misaligned, with M
//                  ops around (ALU address path, misaligned 2nd pass in EX)
//
// Register convention: x0 zero, x1 temp, x2 data-window pointer, x3 end-of-test
// temp; M-op operands / destinations are x4..x31 (x0 as rd with pct_rd_x0).
// Memory: all loads/stores go to data_base + [0, 0x3FC]; the end-of-test block
// stores x0 to end_store_addr and then spins (jal x0, 0) - the same convention
// as tb/sim/smoke. The team's Instructions agent can replace the end block
// (set emit_end_block = 0 and append its own).
//
// Expected observations for the checkers:
//   n_mul_if_expected = number of MUL/MULH/MULHSU/MULHU that reach EX
//                       (shadow victims excluded) -> must equal the number of
//                       transactions reported by the MUL monitor.
// =============================================================================
package mul_program_pkg;
  import rv32m_ref_pkg::*;

  // ---------------------------------------------------------------------------
  // RV32IM instruction ENCODERS: build 32-bit words field by field.
  // Every RISC-V instruction = fields packed at fixed positions:
  //   [6:0] opcode, [11:7] rd, [14:12] funct3, [19:15] rs1, [24:20] rs2, [31:25] funct7
  // ---------------------------------------------------------------------------
  localparam logic [6:0] OPC_LUI    = 7'h37;   // LUI
  localparam logic [6:0] OPC_AUIPC  = 7'h17;   // AUIPC
  localparam logic [6:0] OPC_JAL    = 7'h6F;   // JAL
  localparam logic [6:0] OPC_JALR   = 7'h67;   // JALR
  localparam logic [6:0] OPC_BRANCH = 7'h63;   // branches (BEQ, BNE, ...)
  localparam logic [6:0] OPC_LOAD   = 7'h03;   // loads (LB, LH, LW, ...)
  localparam logic [6:0] OPC_STORE  = 7'h23;   // stores (SB, SH, SW)
  localparam logic [6:0] OPC_OPIMM  = 7'h13;   // immediate ALU ops (ADDI, ...)
  localparam logic [6:0] OPC_OP     = 7'h33;   // register ALU ops (ADD, MUL, ...)

  // R-type: {funct7, rs2, rs1, funct3, rd, opcode} - register-register ops
  function automatic logic [31:0] enc_r(input logic [6:0] f7, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] opc);
    return {f7, rs2, rs1, f3, rd, opc};
  endfunction

  // I-type: {imm[11:0], rs1, funct3, rd, opcode} - immediate ops + loads + jalr
  function automatic logic [31:0] enc_i(input logic [11:0] imm, input logic [4:0] rs1, input logic [2:0] f3,
                                        input logic [4:0] rd, input logic [6:0] opc);
    return {imm, rs1, f3, rd, opc};
  endfunction

  // S-type: immediate SPLIT in two parts - {imm[11:5], rs2, rs1, f3, imm[4:0], op}
  function automatic logic [31:0] enc_s(input logic [11:0] imm, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3, input logic [6:0] opc);
    return {imm[11:5], rs2, rs1, f3, imm[4:0], opc};
  endfunction

  // B-type: branch offset SPLIT and SCRAMBLED (bit0 is not stored, always 0):
  // {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}
  function automatic logic [31:0] enc_b(input logic [12:0] off, input logic [4:0] rs2, input logic [4:0] rs1,
                                        input logic [2:0] f3);
    return {off[12], off[10:5], rs2, rs1, f3, off[4:1], off[11], OPC_BRANCH};
  endfunction

  // U-type: {imm[31:12], rd, opcode} - the upper 20 bits (LUI / AUIPC)
  function automatic logic [31:0] enc_u(input logic [19:0] imm20, input logic [4:0] rd, input logic [6:0] opc);
    return {imm20, rd, opc};
  endfunction

  // J-type: jump offset SPLIT and SCRAMBLED like B-type:
  // {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode}
  function automatic logic [31:0] enc_j(input logic [20:0] off, input logic [4:0] rd);
    return {off[20], off[10:1], off[11], off[19:12], rd, OPC_JAL};
  endfunction

  // MNEMONICS: one function per assembly instruction, so the scenario blocks
  // read like assembly: i_addi(rd, rs1, imm) == "addi rd, rs1, imm".
  // Each just calls the right encoder with the right opcode/funct values.
  function automatic logic [31:0] i_lui (input logic [4:0] rd, input logic [19:0] imm20); return enc_u(imm20, rd, OPC_LUI); endfunction
  function automatic logic [31:0] i_addi(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b000, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_xori(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b100, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_ori (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b110, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_andi(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b111, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slli(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0000000, sh}, rs1, 3'b001, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_srli(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0000000, sh}, rs1, 3'b101, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_srai(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] sh);  return enc_i({7'b0100000, sh}, rs1, 3'b101, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slti (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b010, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_sltiu(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b011, rd, OPC_OPIMM); endfunction
  function automatic logic [31:0] i_slt (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b010, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sltu(input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b011, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sll (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b001, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_srl (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b101, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sra (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h20, rs2, rs1, 3'b101, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_auipc(input logic [4:0] rd, input logic [19:0] imm20); return enc_u(imm20, rd, OPC_AUIPC); endfunction
  function automatic logic [31:0] i_jalr(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b000, rd, OPC_JALR); endfunction
  function automatic logic [31:0] i_add (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b000, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_sub (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h20, rs2, rs1, 3'b000, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_xor (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b100, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_or  (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b110, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_and (input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2); return enc_r(7'h00, rs2, rs1, 3'b111, rd, OPC_OP); endfunction
  function automatic logic [31:0] i_lw  (input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, 3'b010, rd, OPC_LOAD); endfunction
  function automatic logic [31:0] i_sw  (input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm); return enc_s(imm, rs2, rs1, 3'b010, OPC_STORE); endfunction
  // generic load/store: f3 = 000 lb / 001 lh / 010 lw / 100 lbu / 101 lhu ; 000 sb / 001 sh / 010 sw
  function automatic logic [31:0] i_load (input logic [2:0] f3, input logic [4:0] rd,  input logic [4:0] rs1, input logic [11:0] imm); return enc_i(imm, rs1, f3, rd, OPC_LOAD); endfunction
  function automatic logic [31:0] i_store(input logic [2:0] f3, input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm); return enc_s(imm, rs2, rs1, f3, OPC_STORE); endfunction
  function automatic logic [31:0] i_beq (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b000); endfunction
  function automatic logic [31:0] i_bne (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b001); endfunction
  function automatic logic [31:0] i_blt (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b100); endfunction
  function automatic logic [31:0] i_bge (input logic [4:0] rs1, input logic [4:0] rs2, input logic [12:0] off); return enc_b(off, rs2, rs1, 3'b101); endfunction
  function automatic logic [31:0] i_jal (input logic [4:0] rd, input logic [20:0] off); return enc_j(off, rd); endfunction
  function automatic logic [31:0] i_nop (); return i_addi(5'd0, 5'd0, 12'd0); endfunction
  // M extension: funct7 = 0000001, funct3 = rv32m_op_e
  function automatic logic [31:0] i_m(input rv32m_op_e op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2);
    return enc_r(7'h01, rs2, rs1, op[2:0], rd, OPC_OP);
  endfunction

  function automatic string op_name(input rv32m_op_e op);
    case (op)
      MUL: return "mul"; MULH: return "mulh"; MULHSU: return "mulhsu"; MULHU: return "mulhu";
      DIV: return "div"; DIVU: return "divu"; REM: return "rem"; default: return "remu";
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Program word with annotation
  // ---------------------------------------------------------------------------
  // One generated instruction = the binary word + its assembly text + which
  // scenario block produced it (used in listings and debug logs).
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [31:0] word;     // the 32-bit instruction
    string       text;     // assembly text, e.g. "mulh x5, x6, x7"
    string       tag;      // scenario tag, e.g. "back_to_back"
  } prog_word_t;

  // The 11 kinds of scenario blocks the generator can emit (weights below).
  typedef enum int {BLK_SINGLE, BLK_SIGN_MATRIX, BLK_SPECIAL_REGS, BLK_BACK_TO_BACK,
                    BLK_DEPENDENCY, BLK_AFTER_LOAD, BLK_BEFORE_BRANCH, BLK_DIV_MIX,
                    BLK_ALU_MIX, BLK_DIV_CORNERS, BLK_LSU_MIX} blk_kind_e;
  localparam int N_BLK_KINDS = 11;

  // ---------------------------------------------------------------------------
  // Generator
  // ---------------------------------------------------------------------------
  class mul_program_gen;
    // -------- INPUT knobs (set by the sequence / smoke driver) ----------------
    int unsigned n_blocks        = 40;   // how many scenario blocks to emit
    // -- block MIX weights: relative chance each block type is picked --
    int unsigned w_single        = 30;   // one M op, corner-weighted operands
    int unsigned w_sign_matrix   = 6;    // MULH* x sign combinations
    int unsigned w_special_regs  = 8;    // rd=x0, rs1==rs2, rd==rs1, ...
    int unsigned w_back_to_back  = 15;   // 2..5 M ops with no gap
    int unsigned w_dependency    = 15;   // RAW distance 1/2, chains, forwarding
    int unsigned w_after_load    = 12;   // LW then MULH/MUL (stall + load-use)
    int unsigned w_before_branch = 8;    // M op + taken/not-taken branch
    int unsigned w_div_mix       = 6;    // DIV/REM interleaved with M ops
    int unsigned w_alu_mix       = 10;   // RV32I ALU ops (ALU agent checks)
    int unsigned w_div_corners   = 8;    // divisor classes -> latency 3..35, /0, ovf
    int unsigned w_lsu_mix       = 6;    // loads/stores incl. misaligned (ALU addr)
    int unsigned pct_misaligned  = 40;   // % of lsu_mix that are misaligned (2 passes)
    int unsigned pct_rd_x0       = 3;    // % of M ops writing x0
    int unsigned pct_mulh        = 60;   // % of MUL picks that are MULH*
    // operand CLASS weights, indexed by operand_class_e (corners get more)
    int unsigned w_opclass[12]   = '{5, 5, 5, 5, 5, 3, 3, 6, 15, 18, 15, 15};
    logic [31:0] data_base       = 32'h0001_0000;  // data window base
    logic [31:0] end_store_addr  = 32'h0001_0FFC;  // end-of-test store address
    bit          emit_end_block  = 1'b1;   // append the final store+spin block
    bit          init_all_regs   = 1'b1;   // start with reg initialization

    // -------- OUTPUTS (filled by build()) ------------------------------------
    prog_word_t  prog[$];                  // the generated instruction stream
    int unsigned n_m_ops[8];               // M ops by funct3 (incl. shadow ones)
    int unsigned n_mul_if_expected;        // MUL-family ops that will REACH EX
    int unsigned n_shadow_ops;             // MUL-family ops in a branch shadow
    int unsigned n_blocks_by_kind[N_BLK_KINDS];  // per-block-type histogram

    function new();                        // nothing to do in the constructor
    endfunction

    // -------- low-level helpers ----------------------------------------------
    // Append one instruction to the program (word + text + tag stay together).
    function void emit(input logic [31:0] w, input string text, input string tag);
      prog_word_t p;
      p.word = w; p.text = text; p.tag = tag;
      prog.push_back(p);               // queue push_back
    endfunction

    function int unsigned size();
      return prog.size();              // how many words generated so far
    endfunction

    // Load an arbitrary 32-bit constant into a register ("li rd, value").
    // Small values (fit in 12 signed bits) = one ADDI from x0;
    // big values = LUI + ADDI (the +0x800 compensates ADDI's sign extension).
    function void set_reg(input logic [4:0] rd, input logic [31:0] value, input string tag);
      logic [31:0] hi;
      logic [11:0] lo;
      if (rd == 5'd0) return;          // x0 is hardwired to 0 - nothing to do
      if ((value[31:11] == 21'h0) || (value[31:11] == 21'h1F_FFFF)) begin
        // value fits in signed 12 bits -> single ADDI from x0
        emit(i_addi(rd, 5'd0, value[11:0]), $sformatf("addi x%0d, x0, %0d", rd, $signed(value[11:0])), tag);
      end else begin
        lo = value[11:0];              // low 12 bits (will be sign-extended)
        hi = value + 32'h0000_0800;    // add 0x800 so LUI's + sign-extended lo == value
        emit(i_lui(rd, hi[31:12]), $sformatf("lui x%0d, 0x%05h", rd, hi[31:12]), tag);
        if (lo != 12'h0)               // skip ADDI when the low part is zero
          emit(i_addi(rd, rd, lo), $sformatf("addi x%0d, x%0d, %0d", rd, rd, $signed(lo)), tag);
      end
    endfunction

    // -------- random helpers --------------------------------------------------
    // pick_reg: a random register in x4..x31 (x0-x3 are reserved by convention)
    function logic [4:0] pick_reg();
      return 5'($urandom_range(31, 4));
    endfunction

    function logic [4:0] pick_reg_ne(input logic [4:0] a);
      logic [4:0] r;
      do r = pick_reg(); while (r == a);
      return r;
    endfunction

    function logic [4:0] pick_reg_ne2(input logic [4:0] a, input logic [4:0] b);
      logic [4:0] r;
      do r = pick_reg(); while ((r == a) || (r == b));
      return r;
    endfunction

    // pick_rd: destination register, occasionally x0 (pct_rd_x0 % of the time)
    function logic [4:0] pick_rd();
      if ($urandom_range(99) < pct_rd_x0) return 5'd0;
      return pick_reg();
    endfunction

    // pick_class: choose an operand CLASS by WEIGHT (w_opclass[]).
    // Trick: sum all weights, draw a random point in [0,total), walk the
    // cumulative sum until the point falls inside one class' slice.
    function operand_class_e pick_class();
      int unsigned total = 0, r, acc = 0;
      for (int i = 0; i < 12; i++) total += w_opclass[i];   // sum all weights
      r = $urandom_range(total - 1);                        // random point
      for (int i = 0; i < 12; i++) begin
        acc += w_opclass[i];                                // running total
        if (r < acc) return operand_class_e'(i);            // found our slice
      end
      return OPC_POS_LARGE;                                 // fallback (never hit)
    endfunction

    function logic [31:0] value_of_class(input operand_class_e c);
      case (c)
        OPC_ZERO:      return 32'h0000_0000;
        OPC_ONE:       return 32'h0000_0001;
        OPC_MINUS_ONE: return 32'hFFFF_FFFF;
        OPC_INT_MAX:   return 32'h7FFF_FFFF;
        OPC_INT_MIN:   return 32'h8000_0000;
        OPC_ALT_AA:    return 32'hAAAA_AAAA;
        OPC_ALT_55:    return 32'h5555_5555;
        OPC_POW2:      return 32'h1 << $urandom_range(30, 1);
        OPC_POS_SMALL: return 32'($urandom_range(32'h0000_FFFF, 32'h2));
        OPC_POS_LARGE: return 32'($urandom_range(32'h7FFF_FFFE, 32'h0001_0000));
        OPC_NEG_SMALL: return 32'($urandom_range(32'hFFFF_FFFE, 32'hFFFF_0000));
        default:       return 32'($urandom_range(32'hFFFE_FFFF, 32'h8000_0001));
      endcase
    endfunction

    // pick_value: a concrete number from the class chosen by pick_class()
    function logic [31:0] pick_value();
      return value_of_class(pick_class());
    endfunction

    // pick_signed_value: keep drawing until the sign bit matches (neg=1 -> negative)
    function logic [31:0] pick_signed_value(input bit negative);
      logic [31:0] v;
      do v = pick_value(); while (v[31] != negative);
      return v;
    endfunction

    // -- op pickers (each returns a random member of its family) --
    function rv32m_op_e pick_mul_op();     // MUL, or MULH* with pct_mulh %
      if ($urandom_range(99) < pct_mulh) return rv32m_op_e'($urandom_range(3, 1));  // 1..3 = MULH/MULHSU/MULHU
      return MUL;
    endfunction

    function rv32m_op_e pick_mulh_op();    // always MULH/MULHSU/MULHU (1..3)
      return rv32m_op_e'($urandom_range(3, 1));
    endfunction

    function rv32m_op_e pick_div_op();     // always DIV/DIVU/REM/REMU (4..7)
      return rv32m_op_e'($urandom_range(7, 4));
    endfunction

    // Emit one M-family op AND update the bookkeeping counters:
    //   n_m_ops[op]        - how many of each funct3 were generated
    //   n_mul_if_expected  - MUL ops that will actually reach EX
    //   n_shadow_ops       - MUL ops in a taken-branch shadow (never reach EX)
    function void m_op(input rv32m_op_e op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2,
                       input string tag, input bit in_shadow = 1'b0);
      emit(i_m(op, rd, rs1, rs2), $sformatf("%s x%0d, x%0d, x%0d", op_name(op), rd, rs1, rs2), tag);
      n_m_ops[op]++;
      if (is_mul_op(op)) begin
        if (in_shadow) n_shadow_ops++;    // victim of a taken branch -> no EX
        else           n_mul_if_expected++;  // will show on the MUL interface
      end
    endfunction

    // Random word-aligned offset inside the data window [0, 0x3FC]
    function logic [11:0] pick_data_offset();
      return 12'($urandom_range(12'h3FC >> 2) << 2);
    endfunction

    // -------- scenario blocks --------
    // One M op with class-weighted operands (corner values first).
    function void blk_single();
      logic [4:0] a, b, d;
      a = pick_reg(); b = pick_reg(); d = pick_rd();
      set_reg(a, pick_value(), "single");
      if (b != a) set_reg(b, pick_value(), "single");
      m_op(pick_mul_op(), d, a, b, "single");
    endfunction

    // MULH/MULHSU/MULHU x {pos,neg} x {pos,neg} = 12 cells.
    function void blk_sign_matrix();
      logic [4:0] a, b;
      rv32m_op_e ops[3] = '{MULH, MULHSU, MULHU};
      a = pick_reg(); b = pick_reg_ne(a);
      foreach (ops[i]) begin
        for (int s = 0; s < 4; s++) begin
          set_reg(a, pick_signed_value(s[0]), "sign_matrix");
          set_reg(b, pick_signed_value(s[1]), "sign_matrix");
          m_op(ops[i], pick_rd(), a, b, "sign_matrix");
        end
      end
    endfunction

    // rd=x0, rs1==rs2, rd==rs1, rd==rs2, all equal.
    function void blk_special_regs();
      logic [4:0] a, b;
      a = pick_reg(); b = pick_reg_ne(a);
      set_reg(a, pick_value(), "special_regs");
      set_reg(b, pick_value(), "special_regs");
      m_op(pick_mul_op(), 5'd0, a, b, "special_regs:rd_x0");
      m_op(pick_mul_op(), pick_reg_ne2(a, b), a, a, "special_regs:rs1_eq_rs2");
      m_op(pick_mul_op(), a, a, b, "special_regs:rd_eq_rs1");
      m_op(pick_mul_op(), b, a, b, "special_regs:rd_eq_rs2");
      m_op(pick_mul_op(), a, a, a, "special_regs:all_equal");
    endfunction

    // 2..5 independent M ops with NO gap (pure back-to-back).
    function void blk_back_to_back();
      int unsigned n;
      logic [4:0] a, b, d;
      n = $urandom_range(5, 2);
      a = pick_reg(); b = pick_reg_ne(a);
      set_reg(a, pick_value(), "back_to_back");
      set_reg(b, pick_value(), "back_to_back");
      // destinations distinct from the sources -> no RAW between the M ops
      for (int i = 0; i < n; i++) begin
        d = pick_reg_ne2(a, b);
        m_op(pick_mul_op(), d, a, b, "back_to_back");
      end
    endfunction

    // RAW hazards: distance 1/2, MULH->MUL, store, address, DIV->MUL, branch, chain.
    function void blk_dependency();
      logic [4:0] a, b, d, e;
      logic [11:0] off;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, d);
      off = pick_data_offset();
      set_reg(a, pick_value(), "dependency");
      set_reg(b, pick_value(), "dependency");
      case ($urandom_range(8))
        0: begin  // MUL -> ALU consumer, distance 1 (EX->ID forwarding of the MUL result)
          m_op(MUL, d, a, b, "dep:mul_alu_d1");
          emit(i_add(e, d, d), $sformatf("add x%0d, x%0d, x%0d", e, d, d), "dep:mul_alu_d1");
        end
        1: begin  // MUL -> ALU consumer, distance 2
          m_op(MUL, d, a, b, "dep:mul_alu_d2");
          emit(i_nop(), "nop", "dep:mul_alu_d2");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "dep:mul_alu_d2");
        end
        2: begin  // MULH -> dependent MUL (distance 1)
          m_op(pick_mulh_op(), d, a, b, "dep:mulh_mul");
          m_op(MUL, e, d, b, "dep:mulh_mul");
        end
        3: begin  // MULH -> dependent MULH
          m_op(pick_mulh_op(), d, a, b, "dep:mulh_mulh");
          m_op(pick_mulh_op(), e, a, d, "dep:mulh_mulh");
        end
        4: begin  // MUL -> store data -> load back
          m_op(pick_mul_op(), d, a, b, "dep:mul_store");
          emit(i_sw(d, 5'd2, off), $sformatf("sw x%0d, %0d(x2)", d, off), "dep:mul_store");
          emit(i_lw(e, 5'd2, off), $sformatf("lw x%0d, %0d(x2)", e, off), "dep:mul_store");
        end
        5: begin  // MUL result used as address (offset * 4 + data pointer)
          set_reg(a, 32'(off >> 2), "dep:mul_addr");
          set_reg(b, 32'd4, "dep:mul_addr");
          m_op(MUL, d, a, b, "dep:mul_addr");
          emit(i_add(d, d, 5'd2), $sformatf("add x%0d, x%0d, x2", d, d), "dep:mul_addr");
          emit(i_sw(a, d, 12'd0), $sformatf("sw x%0d, 0(x%0d)", a, d), "dep:mul_addr");
          emit(i_lw(e, d, 12'd0), $sformatf("lw x%0d, 0(x%0d)", e, d), "dep:mul_addr");
        end
        6: begin  // DIV (multi-cycle ALU) -> dependent MUL
          m_op(pick_div_op(), d, a, b, "dep:div_mul");
          m_op(MUL, e, d, a, "dep:div_mul");
        end
        7: begin  // MUL result decides a branch (always taken: rd == rd) with a NOP in the shadow
          m_op(MUL, d, a, b, "dep:mul_branch");
          emit(i_beq(d, d, 13'd8), $sformatf("beq x%0d, x%0d, +8", d, d), "dep:mul_branch");
          emit(i_nop(), "nop (shadow)", "dep:mul_branch");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "dep:mul_branch");
        end
        default: begin  // accumulate chain rd == rs1
          m_op(MUL, d, a, b, "dep:chain");
          m_op(MUL, d, d, b, "dep:chain");
          m_op(pick_mulh_op(), d, d, a, "dep:chain");
        end
      endcase
    endfunction

    // LW then MULH/MUL (FSM overlaps the load wait) then a load-use MUL.
    function void blk_after_load();
      logic [4:0] a, l, e, f, d, g;
      logic [11:0] off;
      a = pick_reg(); l = pick_reg_ne(a);
      e = pick_reg_ne2(a, l); f = pick_reg_ne2(a, l);
      d = pick_reg_ne2(l, e); g = pick_reg_ne2(l, d);
      off = pick_data_offset();
      set_reg(a, pick_value(), "after_load");
      emit(i_sw(a, 5'd2, off), $sformatf("sw x%0d, %0d(x2)", a, off), "after_load");
      set_reg(e, pick_value(), "after_load");
      set_reg(f, pick_value(), "after_load");
      emit(i_lw(l, 5'd2, off), $sformatf("lw x%0d, %0d(x2)", l, off), "after_load");
      case ($urandom_range(2))
        0: m_op(pick_mulh_op(), d, e, f, "after_load:mulh_indep");   // FSM runs while the load waits
        1: m_op(MUL, d, e, f, "after_load:mul_indep");
        default: begin
          emit(i_nop(), "nop", "after_load");
          m_op(pick_mulh_op(), d, e, f, "after_load:mulh_indep_d2");
        end
      endcase
      m_op(pick_mul_op(), g, l, e, "after_load:load_use");   // needs the load result
    endfunction

    // M op + taken branch, M op in the shadow (never reaches EX), M op after not-taken.
    function void blk_before_branch();
      logic [4:0] a, b, d, e;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, b);
      set_reg(a, pick_value(), "before_branch");
      set_reg(b, pick_value(), "before_branch");
      case ($urandom_range(2))
        0: begin  // MULH then taken branch, MUL in the shadow (never reaches EX)
          m_op(pick_mulh_op(), d, a, b, "before_branch:mulh_taken");
          emit(i_beq(5'd0, 5'd0, 13'd12), "beq x0, x0, +12", "before_branch:mulh_taken");
          m_op(MUL, e, a, b, "before_branch:shadow", 1'b1);
          emit(i_nop(), "nop (shadow)", "before_branch:shadow");
          emit(i_add(e, d, a), $sformatf("add x%0d, x%0d, x%0d", e, d, a), "before_branch:target");
        end
        1: begin  // MUL then taken branch, MULH in the shadow
          m_op(MUL, d, a, b, "before_branch:mul_taken");
          emit(i_beq(5'd0, 5'd0, 13'd12), "beq x0, x0, +12", "before_branch:mul_taken");
          m_op(pick_mulh_op(), e, a, b, "before_branch:shadow", 1'b1);
          emit(i_nop(), "nop (shadow)", "before_branch:shadow");
          emit(i_add(e, d, b), $sformatf("add x%0d, x%0d, x%0d", e, d, b), "before_branch:target");
        end
        default: begin  // not-taken branch then M op (executes normally)
          emit(i_bne(5'd0, 5'd0, 13'd8), "bne x0, x0, +8 (not taken)", "before_branch:not_taken");
          m_op(pick_mul_op(), d, a, b, "before_branch:after_not_taken");
        end
      endcase
    endfunction

    // DIV/REM interleaved with M ops (multi-cycle ALU + multiplier together).
    function void blk_div_mix();
      logic [4:0] a, b, d, e, f, g;
      a = pick_reg(); b = pick_reg_ne(a);
      d = pick_reg_ne2(a, b); e = pick_reg_ne2(a, b); f = pick_reg_ne2(a, b); g = pick_reg_ne2(a, b);
      set_reg(a, pick_value(), "div_mix");
      set_reg(b, pick_value(), "div_mix");
      m_op(pick_div_op(), d, a, b, "div_mix");
      m_op(pick_mul_op(), e, a, b, "div_mix");
      m_op(pick_div_op(), f, b, a, "div_mix");
      m_op(pick_mul_op(), g, e, f, "div_mix");
    endfunction

    // RV32I ALU operators on random registers (+ AUIPC/JALR pattern) - ALU agent coverage
    // RV32I ALU ops, LUI/AUIPC, AUIPC+JALR pattern (ALU agent coverage).
    function void blk_alu_mix();
      int unsigned n;
      logic [4:0]  d, r1, r2;
      logic [11:0] imm;
      logic [4:0]  sh;
      n = $urandom_range(8, 4);
      for (int i = 0; i < n; i++) begin
        d = pick_rd(); r1 = pick_reg(); r2 = pick_reg();
        imm = 12'($urandom()); sh = 5'($urandom());
        case ($urandom_range(21))
          0:  emit(i_add (d, r1, r2), $sformatf("add x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          1:  emit(i_sub (d, r1, r2), $sformatf("sub x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          2:  emit(i_sll (d, r1, r2), $sformatf("sll x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          3:  emit(i_slt (d, r1, r2), $sformatf("slt x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          4:  emit(i_sltu(d, r1, r2), $sformatf("sltu x%0d, x%0d, x%0d", d, r1, r2), "alu_mix");
          5:  emit(i_xor (d, r1, r2), $sformatf("xor x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          6:  emit(i_srl (d, r1, r2), $sformatf("srl x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          7:  emit(i_sra (d, r1, r2), $sformatf("sra x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          8:  emit(i_or  (d, r1, r2), $sformatf("or x%0d, x%0d, x%0d",   d, r1, r2), "alu_mix");
          9:  emit(i_and (d, r1, r2), $sformatf("and x%0d, x%0d, x%0d",  d, r1, r2), "alu_mix");
          10: emit(i_addi (d, r1, imm), $sformatf("addi x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          11: emit(i_slti (d, r1, imm), $sformatf("slti x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          12: emit(i_sltiu(d, r1, imm), $sformatf("sltiu x%0d, x%0d, %0d", d, r1, $signed(imm)), "alu_mix");
          13: emit(i_xori (d, r1, imm), $sformatf("xori x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          14: emit(i_ori  (d, r1, imm), $sformatf("ori x%0d, x%0d, %0d",   d, r1, $signed(imm)), "alu_mix");
          15: emit(i_andi (d, r1, imm), $sformatf("andi x%0d, x%0d, %0d",  d, r1, $signed(imm)), "alu_mix");
          16: emit(i_slli (d, r1, sh),  $sformatf("slli x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          17: emit(i_srli (d, r1, sh),  $sformatf("srli x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          18: emit(i_srai (d, r1, sh),  $sformatf("srai x%0d, x%0d, %0d",  d, r1, sh), "alu_mix");
          19: emit(i_lui  (d, 20'($urandom())), $sformatf("lui x%0d, <rand>", d), "alu_mix");
          20: emit(i_auipc(d, 20'($urandom())), $sformatf("auipc x%0d, <rand>", d), "alu_mix");
          default: begin  // auipc + jalr over one shadow word (jr_stall bubble, JALR link value)
            logic [4:0] t = pick_reg();
            emit(i_auipc(t, 20'd0), $sformatf("auipc x%0d, 0", t), "alu_mix:jalr");
            emit(i_jalr(d, t, 12'd12), $sformatf("jalr x%0d, x%0d, 12", d, t), "alu_mix:jalr");
            emit(i_nop(), "nop (jalr shadow)", "alu_mix:jalr");
          end
        endcase
      end
    endfunction

    // divisor classes: sweeps the divider latency (3..35), divide by zero, signed overflow
    // Divisor classes sweeping latency 3..35, /0, INT_MIN/-1 (risc_m_02).
    function void blk_div_corners();
      int unsigned n;
      logic [4:0]  a, b, d;
      logic [31:0] dividend, divisor;
      n = $urandom_range(6, 3);
      a = pick_reg(); b = pick_reg_ne(a);
      for (int i = 0; i < n; i++) begin
        case ($urandom_range(11))
          0:  divisor = 32'h0000_0000;
          1:  divisor = 32'h0000_0001;
          2:  divisor = 32'hFFFF_FFFF;
          3:  divisor = 32'h8000_0000;
          4:  divisor = 32'h7FFF_FFFF;
          5:  divisor = 32'h1 << $urandom_range(31, 1);          // one bit: every leading-zero count
          6:  divisor = ~(32'h1 << $urandom_range(31, 1));       // negative with every leading-one count
          7:  divisor = 32'($urandom_range(32'hFFFF, 2));
          8:  divisor = 32'($urandom_range(32'hFFFF_FFFE, 32'hFFFF_0000));
          9:  divisor = 32'hFFFF_FFFE;
          10: divisor = 32'h4000_0000;
          default: divisor = $urandom();
        endcase
        case ($urandom_range(5))
          0: dividend = 32'h8000_0000;   // INT_MIN / -1 overflow, INT_MIN / x
          1: dividend = 32'h0000_0000;
          2: dividend = 32'hFFFF_FFFF;
          3: dividend = 32'h7FFF_FFFF;
          4: dividend = 32'h0000_0001;
          default: dividend = $urandom();
        endcase
        d = pick_rd();
        set_reg(a, dividend, "div_corners");
        set_reg(b, divisor,  "div_corners");
        m_op(pick_div_op(), d, a, b, "div_corners");     // rs1 = dividend, rs2 = divisor
      end
    endfunction

    // byte/half/word loads+stores, aligned and misaligned, with M ops around.
    function void blk_lsu_mix();
      int unsigned n;
      logic [4:0]  v, l, d, e;
      logic [11:0] off;
      logic [2:0]  f3;
      n = $urandom_range(4, 2);
      for (int i = 0; i < n; i++) begin
        v = pick_reg(); l = pick_reg_ne(v); d = pick_rd(); e = pick_reg_ne(v);
        off = 12'($urandom_range(12'h3F8));                     // keep addr + 3 inside the data window
        if ($urandom_range(99) >= pct_misaligned) off[1:0] = 2'b00;
        set_reg(v, pick_value(), "lsu_mix");
        f3 = 3'($urandom_range(2));                              // sb / sh / sw
        emit(i_store(f3, v, 5'd2, off), $sformatf("s%s x%0d, %0d(x2)", f3 == 0 ? "b" : f3 == 1 ? "h" : "w", v, off), "lsu_mix");
        case ($urandom_range(2))
          0: m_op(pick_mul_op(), d, v, e, "lsu_mix");
          1: emit(i_add(d, v, e), $sformatf("add x%0d, x%0d, x%0d", d, v, e), "lsu_mix");
          default: ;
        endcase
        case ($urandom_range(4))                                 // lb / lh / lw / lbu / lhu
          0: f3 = 3'b000; 1: f3 = 3'b001; 2: f3 = 3'b010; 3: f3 = 3'b100; default: f3 = 3'b101;
        endcase
        emit(i_load(f3, l, 5'd2, off), $sformatf("l%s x%0d, %0d(x2)", f3 == 0 ? "b" : f3 == 1 ? "h" : f3 == 2 ? "w" : f3 == 4 ? "bu" : "hu", l, off), "lsu_mix");
        if ($urandom_range(1)) m_op(pick_mul_op(), d, l, e, "lsu_mix:load_use");   // load-use stall + M op
      end
    endfunction

    // -------- top level -------------------------------------------------------
    // pick_block: choose ONE block kind by its weight (same cumulative-sum
    // trick as pick_class: sum weights, draw a point, walk until found).
    function blk_kind_e pick_block();
      int unsigned w[N_BLK_KINDS];
      int unsigned total = 0, r, acc = 0;
      w = '{w_single, w_sign_matrix, w_special_regs, w_back_to_back,
            w_dependency, w_after_load, w_before_branch, w_div_mix, w_alu_mix, w_div_corners, w_lsu_mix};
      for (int i = 0; i < N_BLK_KINDS; i++) total += w[i];   // sum all weights
      r = $urandom_range(total - 1);                          // random point
      for (int i = 0; i < N_BLK_KINDS; i++) begin
        acc += w[i];
        if (r < acc) return blk_kind_e'(i);                   // our slice
      end
      return BLK_SINGLE;                                      // fallback
    endfunction

    // build(): assemble the whole program. Steps:
    //   1. reset output queues and counters
    //   2. header: x2 = data pointer, optionally initialize x4..x31
    //   3. emit n_blocks random scenario blocks (weighted pick)
    //   4. end block: store x0 to end_store_addr, then spin (jal x0, 0)
    function void build();
      prog.delete();                        // start with an empty program
      n_mul_if_expected = 0;                // reset all bookkeeping counters
      n_shadow_ops = 0;
      foreach (n_m_ops[i]) n_m_ops[i] = 0;
      foreach (n_blocks_by_kind[i]) n_blocks_by_kind[i] = 0;
      // header: data pointer in x2, optional register initialization
      set_reg(5'd2, data_base, "header");   // x2 = data window base
      if (init_all_regs)
        for (int r = 4; r < 32; r++) set_reg(5'(r), pick_value(), "header");
      for (int i = 0; i < n_blocks; i++) begin   // the main block loop
        blk_kind_e k;
        k = pick_block();                  // weighted random block kind
        n_blocks_by_kind[k]++;             // histogram for the summary
        case (k)                           // run exactly one block generator
          BLK_SINGLE:        blk_single();
          BLK_SIGN_MATRIX:   blk_sign_matrix();
          BLK_SPECIAL_REGS:  blk_special_regs();
          BLK_BACK_TO_BACK:  blk_back_to_back();
          BLK_DEPENDENCY:    blk_dependency();
          BLK_AFTER_LOAD:    blk_after_load();
          BLK_BEFORE_BRANCH: blk_before_branch();
          BLK_DIV_MIX:       blk_div_mix();
          BLK_ALU_MIX:       blk_alu_mix();
          BLK_DIV_CORNERS:   blk_div_corners();
          default:           blk_lsu_mix();
        endcase
      end
      if (emit_end_block) begin            // closing marker the TB watches for
        set_reg(5'd3, end_store_addr, "end");           // x3 = marker address
        emit(i_sw(5'd0, 5'd3, 12'd0), "sw x0, 0(x3)   ; end-of-test marker", "end");
        emit(i_jal(5'd0, 21'd0), "jal x0, 0      ; spin", "end");  // infinite loop
      end
    endfunction

    // -------- export -----------------------------------------------------------
    // get_words: copy just the binary words into a plain queue (for callers
    // that do not need text/tags).
    function void get_words(ref logic [31:0] q[$]);
      q.delete();
      foreach (prog[i]) q.push_back(prog[i].word);
    endfunction

    // write_mem: save the program as a $readmemh image (with @word-address
    // header) so the Verilator smoke test / simulator can load it directly.
    function void write_mem(input string path, input logic [31:0] base_addr);
      int fd;
      fd = $fopen(path, "w");
      if (fd == 0) begin
        $display("mul_program_gen: cannot write %s", path);
        return;
      end
      $fdisplay(fd, "@%08h", base_addr >> 2);   // @-header: BYTE addr >> 2
      foreach (prog[i]) $fdisplay(fd, "%08h", prog[i].word);  // one word/line
      $fclose(fd);
    endfunction

    function void write_listing(input string path, input logic [31:0] base_addr);
      int fd;
      fd = $fopen(path, "w");
      if (fd == 0) return;
      $fdisplay(fd, "# %0d words, %0d MUL-family ops expected on the MUL interface, %0d shadow victims",
                prog.size(), n_mul_if_expected, n_shadow_ops);
      foreach (prog[i])
        $fdisplay(fd, "%08h: %08h  %-32s ; %s", base_addr + 4 * i, prog[i].word, prog[i].text, prog[i].tag);
      $fclose(fd);
    endfunction

    // summary(): one-line statistics string (words, blocks per kind, M ops per
    // funct3, and how many MUL transactions the interface should show).
    function string summary();
      return $sformatf("%0d words | blocks single=%0d sign=%0d special=%0d b2b=%0d dep=%0d load=%0d branch=%0d div=%0d alu=%0d divc=%0d lsu=%0d | MUL=%0d MULH=%0d MULHSU=%0d MULHU=%0d DIV*=%0d | expected on MUL if=%0d (shadow %0d)",
                       prog.size(), n_blocks_by_kind[0], n_blocks_by_kind[1], n_blocks_by_kind[2], n_blocks_by_kind[3],
                       n_blocks_by_kind[4], n_blocks_by_kind[5], n_blocks_by_kind[6], n_blocks_by_kind[7], n_blocks_by_kind[8], n_blocks_by_kind[9], n_blocks_by_kind[10],
                       n_m_ops[0], n_m_ops[1], n_m_ops[2], n_m_ops[3], n_m_ops[4] + n_m_ops[5] + n_m_ops[6] + n_m_ops[7],
                       n_mul_if_expected, n_shadow_ops);
    endfunction
  endclass : mul_program_gen
endpackage : mul_program_pkg

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/interfaces/alu_mul_if.sv
// =============================================================================
// alu_mul_if.sv
// =============================================================================
// WHAT THIS FILE IS:
//   This file defines ONE SystemVerilog interface called "alu_mul_if".
//   In the architecture picture (tb_architecture/arch.jpg) the Env talks to
//   the DUT through 6 interfaces:
//
//     1. Instruction interface   -> Instructions agent (active)
//     2. Data interface          -> Data agent (reactive)
//     3. Interrupt_Debug interface -> Interrupt_Debug agent (active)
//     4. Reset interface         -> Reset agent (active)
//     5. Reg_file interface      -> reg_file agent (passive)
//     6. ALU_MUL interface       -> MUL agent + ALU agent (both passive)
//                                    *** THIS IS #6 - WE BUILD ONLY THIS ONE ***
//
//   So this interface is 1 out of 6. Everything else in the picture
//   (Instruction / Data / ... interfaces) belongs to other people's work.
//   BOTH the MUL agent and the ALU agent read from THIS same interface.
//
// HOW IT IS CONNECTED (white-box / passive):
//   Every port below is an INPUT. The signals are hooked to the DUT by the
//   bind statement in alu_mul_bind.sv. Nothing in this file can drive the
//   DUT, so this probe can never change DUT behaviour. Both agents are
//   UVM_PASSIVE: they only watch (monitor), they never drive pins.
//
// SIGNAL TABLE  (all sources are inside cv32e40p_top.core_i, RV32IM config:
//                FPU=0, ZFINX=0, COREV_PULP=0, COREV_CLUSTER=0)
//
//   group     | signal              | DUT source (file)          | what it does
//   ----------+---------------------+----------------------------+-------------
//   handshake | ex_ready            | ex_ready (cv32e40p_ex_stage)| EX stage can accept a NEW op this cycle
//   handshake | ex_valid            | ex_valid (cv32e40p_ex_stage)| result of current op is VALID this cycle
//   handshake | lsu_ready_ex        | lsu_ready_ex (core)         | 0 = LSU holds EX (load/store in flight)
//   handshake | wb_ready            | wb_ready_wb (core)          | 0 = write-back stage holds EX
//   handshake | branch_in_ex        | branch_in_ex (core)         | 1 = current EX op is a branch/jump
//   handshake | lsu_en              | data_req_ex (core)          | 1 = ALU computes a load/store ADDRESS
//   handshake | data_misaligned_ex  | data_misaligned_ex (core)   | 1 = 2nd half of misaligned ld/st (addr+4)
//   ALU       | alu_en              | alu_en_ex (ID/EX reg)       | 1 = ALU unit is doing some work
//   ALU       | alu_operator        | alu_operator_ex (ID/EX reg) | which ALU op (ADD, SLT, DIV, ... enum)
//   ALU       | alu_operand_a/b/c   | alu_operand_a/b/c_ex        | 32-bit inputs a, b, c to the ALU
//   ALU       | alu_result          | ex_stage_i.alu_result       | ALU output (arith/logic/shift/div result)
//   ALU       | alu_cmp_result      | ex_stage_i.alu_cmp_result   | comparator output = branch decision
//   ALU       | alu_ready           | ex_stage_i.alu_ready        | 0 while divider is running (blocks EX)
//   MUL       | mult_en             | mult_en_ex (ID/EX reg)      | 1 = multiplier unit is doing work
//   MUL       | mult_operator       | mult_operator_ex            | MUL_MAC32 (=MUL) or MUL_H (=MULH*)
//   MUL       | mult_signed_mode    | mult_signed_mode_ex         | 11 both signed, 01 a signed, 00 none
//   MUL       | mult_operand_a/b/c  | mult_operand_a/b/c_ex       | inputs; c = accumulator for MULH
//   MUL       | mult_sel_subword    | mult_sel_subword_ex         | PULP subword mul - must be 0 for us
//   MUL       | mult_imm            | mult_imm_ex                 | PULP immediate  - must be 0 for us
//   MUL       | mult_result         | ex_stage_i.mult_result      | multiplier output
//   MUL       | mult_ready          | ex_stage_i.mult_ready       | 0 during MULH FSM middle cycles
//   MUL       | mult_multicycle     | mult_multicycle             | 1 in MULH STEP0..2 (tells ID to hold c)
//   MUL       | mulh_active         | ex_stage_i.mulh_active      | 1 while MULH FSM is not IDLE
//   RF write  | rf_alu_we           | regfile_alu_we_fw (core)    | write enable of RF port b (per cycle!)
//   RF write  | rf_alu_waddr        | regfile_alu_waddr_fw        | destination register x0..x31 (bit5=FP)
//   RF write  | rf_alu_wdata        | regfile_alu_wdata_fw        | value written to the register file
//   tag       | id_valid            | id_valid (core)             | ID stage holds a valid instruction
//   tag       | is_decoding         | is_decoding (core)          | instruction not killed (ctrl FSM OK)
//   tag       | pc_id               | pc_id (core)                | PC of instruction in ID (for messages)
//   tag       | instr_id            | instr_rdata_id (core)       | 32-bit instruction word in ID
//
// TIMING REFERENCE (notes/mul_plan.md section 0.2):
//   MUL   : 1 cycle in EX (mult_ready=1, ex_valid in same cycle unless stalled)
//   MULH* : 5 cycles in EX (IDLE, STEP0, STEP1, STEP2, FINISH), ex_valid in FINISH only
// =============================================================================
interface alu_mul_if
  import cv32e40p_pkg::*;   // bring in alu_opcode_e, mul_opcode_e enum types
(
  // --- clock and reset (1 clock for the whole SoC) --------------------------
  input logic clk,          // free-running clock of the core
  input logic rst_n,        // active-LOW reset; 0 = core is being reset

  // --- EX stage handshake ---------------------------------------------------
  // "handshake" = the standard valid/ready pair that says when data moves.
  input logic ex_ready,          // EX stage is FREE: it can accept a new operation
  input logic ex_valid,          // EX stage has a FINISHED result in this cycle
  input logic lsu_ready_ex,      // 0 = load/store unit is holding EX busy
  input logic wb_ready,          // 0 = write-back stage is holding EX busy
  input logic branch_in_ex,      // 1 = the op now in EX is a branch/jump decision
  input logic lsu_en,            // = data_req_ex: 1 = ALU output is an address for ld/st
  input logic data_misaligned_ex,// 1 = 2nd pass of a misaligned ld/st (ALU gets addr+4)

  // --- ALU group (everything about the integer ALU + divider) ---------------
  input logic        alu_en,          // 1 = ALU unit is active this cycle
  input alu_opcode_e alu_operator,    // which ALU op the decoder chose (enum)
  input logic [31:0] alu_operand_a,   // ALU input A (for DIV: this is the divisor/rs2)
  input logic [31:0] alu_operand_b,   // ALU input B (for DIV: this is the dividend/rs1)
  input logic [31:0] alu_operand_c,   // ALU input C (used by some PULP ops; RV32IM: unused)
  input logic [31:0] alu_result,      // ALU output value (arith/logic/shift/div)
  input logic        alu_cmp_result,  // comparator output (0/1) = branch taken/not-taken
  input logic        alu_ready,       // 0 while divider is busy -> EX is blocked

  // --- MUL group (everything about the multiplier) --------------------------
  input logic        mult_en,          // 1 = multiplier unit is active this cycle
  input mul_opcode_e mult_operator,    // MUL_MAC32 => MUL, MUL_H => MULH/MULHSU/MULHU
  input logic [ 1:0] mult_signed_mode, // which operands are signed (see table above)
  input logic [31:0] mult_operand_a,   // multiplier input A (= architectural rs1)
  input logic [31:0] mult_operand_b,   // multiplier input B (= architectural rs2)
  input logic [31:0] mult_operand_c,   // accumulator input for MULH (0 in our config)
  input logic        mult_sel_subword, // PULP feature - must stay 0 for RV32IM
  input logic [ 4:0] mult_imm,         // PULP feature - must stay 0 for RV32IM
  input logic [31:0] mult_result,      // multiplier output value
  input logic        mult_ready,       // 0 in middle cycles of MULH FSM
  input logic        mult_multicycle,  // 1 in MULH STEP0..2 -> ID must keep op_c
  input logic        mulh_active,      // 1 while MULH FSM is busy (not IDLE)

  // --- register-file ALU write port (port b) + forwarding value ------------
  input logic        rf_alu_we,    // write enable: 1 in EVERY EX cycle (qualify w/ ex_valid!)
  input logic [ 5:0] rf_alu_waddr, // destination register address (bit5 = FP reg, = 0 here)
  input logic [31:0] rf_alu_wdata, // value written to register file (also EX->ID forward)

  // --- tag: instruction issue pulse from the decode stage ------------------
  input logic        id_valid,     // ID stage holds a valid instruction
  input logic        is_decoding,  // instruction is NOT killed by the controller FSM
  input logic [31:0] pc_id,        // PC of the instruction currently in ID
  input logic [31:0] instr_id      // the 32-bit instruction word currently in ID
);

  // -----------------------------------------------------------------------------
  // Clocking block: defines HOW and WHEN the monitor samples the signals.
  // "input #1step" = sample 1 time-step BEFORE the active clock edge, so the
  // monitor sees exactly the values the DUT held during the cycle that is
  // ENDING at this edge (the stable, race-free values).
  // -----------------------------------------------------------------------------
  clocking mon_cb @(posedge clk);
    default input #1step output #0;   // sample before edge, drive never (passive)
    input ex_ready, ex_valid, lsu_ready_ex, wb_ready, branch_in_ex, lsu_en, data_misaligned_ex;
    input alu_en, alu_operator, alu_operand_a, alu_operand_b, alu_operand_c,
          alu_result, alu_cmp_result, alu_ready;
    input mult_en, mult_operator, mult_signed_mode,
          mult_operand_a, mult_operand_b, mult_operand_c,
          mult_sel_subword, mult_imm,
          mult_result, mult_ready, mult_multicycle, mulh_active;
    input rf_alu_we, rf_alu_waddr, rf_alu_wdata;
    input id_valid, is_decoding, pc_id, instr_id;
  endclocking : mon_cb

  // modport = the "view" the monitor gets: it may read the clocking block,
  // the clock and the reset. No output direction -> monitor cannot drive.
  modport MON (clocking mon_cb, input clk, input rst_n);

  // -----------------------------------------------------------------------------
  // Helper function: "issue pulse".
  // TRUE when the instruction that sits in the decode stage RIGHT NOW will
  // really move to the EX stage at the next clock edge.
  // Condition = id_valid && is_decoding (both must be 1; a killed instruction
  // has id_valid=1 but is_decoding=0).
  // -----------------------------------------------------------------------------
  function automatic bit issue_pulse();
    return (mon_cb.id_valid === 1'b1) && (mon_cb.is_decoding === 1'b1);
  endfunction

  // -----------------------------------------------------------------------------
  // Helper function: "mul_in_ex".
  // TRUE when the multiplier unit is active in the CURRENT cycle.
  // The ID/EX pipeline register clears mult_en whenever EX is free and ID has
  // nothing, so after an ex_valid the next cycle with mult_en=1 always belongs
  // to a NEW instruction - this is how the monitor starts a new transaction.
  // -----------------------------------------------------------------------------
  function automatic bit mul_in_ex();
    return (mon_cb.mult_en === 1'b1);
  endfunction

endinterface : alu_mul_if

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/sim/smoke/mul_smoke_checker.sv
// =============================================================================
// mul_smoke_checker.sv
// -----------------------------------------------------------------------------
// Plain-SystemVerilog twin of mul_monitor + the MUL side of alu_mul_scoreboard,
// used by the non-UVM smoke test (tb_smoke.sv) to validate the transaction
// reconstruction algorithm, the reference functions and the latency model
// against the real RTL with Verilator.
//
// Keep the algorithm identical to tb/agents/mul_agent/mul_monitor.sv:
//   start    : mult_en && !in_flight
//   progress : total++, stall++ if (mult_ready && !ex_valid), mc++ if mult_multicycle
//   finish   : ex_valid -> check result / write port / latency / tag
// Sampling: always @(posedge clk) reads the values the DUT held during the
// cycle that ends at this edge (same as the #1step clocking block).
// =============================================================================
module mul_smoke_checker
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
(
  alu_mul_if vif,
  input bit  verbose
);

  localparam int unsigned MUL_LATENCY         = 1;
  localparam int unsigned MULH_LATENCY        = 5;
  localparam int unsigned MULH_MULTICYCLE_LEN = 3;

  // statistics visible to the top
  int unsigned n_txn, n_err, n_mul, n_mulh, n_stalled, max_stall, n_killed;
  int unsigned n_op [8];

  // state
  bit          in_flight;
  rv32m_op_e   op;
  bit [31:0]   a, b, op_c0;
  int unsigned total, stall, mc, cyc_start;
  bit          tag_valid, cur_tag_valid;
  bit [31:0]   tag_pc, tag_instr, cur_pc, cur_instr;
  int unsigned cycle_cnt;

  function automatic bit decode_ctrl(input mul_opcode_e operator, input logic [1:0] sm, output rv32m_op_e o);
    o = MUL;
    case (operator)
      MUL_MAC32: begin o = MUL; return 1; end
      MUL_H: case (sm)
        2'b11: begin o = MULH;   return 1; end
        2'b01: begin o = MULHSU; return 1; end
        2'b00: begin o = MULHU;  return 1; end
        default: return 0;
      endcase
      default: return 0;
    endcase
  endfunction

  task automatic err(input string msg);
    n_err++;
    $display("[%0t] MUL_CHECK ERROR: %s", $time, msg);
  endtask

  always @(posedge vif.clk) begin
    cycle_cnt++;
    if (!vif.rst_n) begin
      if (in_flight) begin
        n_killed++;
        $display("[%0t] MUL_CHECK: %s killed by reset after %0d cycles", $time, op.name(), total);
      end
      in_flight = 0;
      tag_valid = 0;
    end else begin
      // ---- 1. start ---------------------------------------------------------------
      if (!in_flight && vif.mult_en) begin
        rv32m_op_e o;
        if (!decode_ctrl(vif.mult_operator, vif.mult_signed_mode, o))
          err($sformatf("illegal operator/sign mode %s/%0b", vif.mult_operator.name(), vif.mult_signed_mode));
        op            = o;
        a             = vif.mult_operand_a;
        b             = vif.mult_operand_b;
        op_c0         = vif.mult_operand_c;
        total         = 0; stall = 0; mc = 0;
        cyc_start     = cycle_cnt;
        cur_tag_valid = tag_valid;
        cur_pc        = tag_pc;
        cur_instr     = tag_instr;
        in_flight     = 1;
        if (vif.alu_en)                 err("alu_en together with mult_en");
        if (vif.mult_sel_subword || vif.mult_imm != 0) err("PULP multiplier controls active");
        if (op_c0 != 0)                 err($sformatf("mult_operand_c != 0 at start (0x%08h)", op_c0));
        if (cur_tag_valid && !is_rv32m_instr(cur_instr))
          err($sformatf("tag out of sync: instr 0x%08h @0x%08h is not RV32M", cur_instr, cur_pc));
      end

      // ---- 2. progress / finish -------------------------------------------------------
      if (in_flight) begin
        total++;
        if (vif.mult_ready && !vif.ex_valid) stall++;
        if (vif.mult_multicycle)             mc++;
        if (!vif.mult_en)                    err("mult_en dropped before ex_valid");
        if (vif.mult_operand_a != a || vif.mult_operand_b != b) err("operands changed while in EX");
        if (!vif.mult_ready && vif.ex_ready) err("ex_ready while mult_ready=0");

        if (vif.ex_valid) begin
          bit [31:0]   exp_res, res;
          int unsigned mult_cycles, exp_cycles, exp_mc;
          res         = vif.mult_result;
          exp_res     = rv32m_ref(op, a, b);
          mult_cycles = total - stall;
          exp_cycles  = (op == MUL) ? MUL_LATENCY : MULH_LATENCY;
          exp_mc      = (op == MUL) ? 0 : MULH_MULTICYCLE_LEN;
          n_txn++; n_op[op]++;
          if (op == MUL) n_mul++; else n_mulh++;
          if (stall > 0) n_stalled++;
          if (stall > max_stall) max_stall = stall;

          if (res != exp_res)
            err($sformatf("%s result 0x%08h expected 0x%08h (a=0x%08h b=0x%08h)", op.name(), res, exp_res, a, b));
          if (!vif.rf_alu_we)              err("rf_alu_we=0 in the ex_valid cycle");
          if (vif.rf_alu_wdata != res)     err("rf_alu_wdata != mult_result");
          if (vif.rf_alu_waddr[5])         err("rf_alu_waddr[5] set");
          if (mult_cycles != exp_cycles)
            err($sformatf("%s latency %0d (total %0d stall %0d) expected %0d", op.name(), mult_cycles, total, stall, exp_cycles));
          if (mc != exp_mc)
            err($sformatf("%s mult_multicycle for %0d cycles expected %0d", op.name(), mc, exp_mc));
          if (cur_tag_valid && is_rv32m_instr(cur_instr)) begin
            if (rv32m_op_of(cur_instr) != op)
              err($sformatf("tag funct3 %s != executed %s", rv32m_op_of(cur_instr).name(), op.name()));
            if (cur_instr[11:7] != vif.rf_alu_waddr[4:0])
              err($sformatf("tag rd x%0d != write port x%0d", cur_instr[11:7], vif.rf_alu_waddr[4:0]));
          end
          if (verbose)
            $display("[%0t] MUL_CHECK %-6s pc=0x%08h a=0x%08h b=0x%08h -> x%0d = 0x%08h | tot=%0d stall=%0d mult=%0d mc=%0d",
                     $time, op.name(), cur_pc, a, b, vif.rf_alu_waddr[4:0], res, total, stall, total - stall, mc);
          in_flight = 0;
        end else if (total > 64) begin
          err("instruction stuck in EX");
          in_flight = 0;
        end
      end

      // ---- 3. issue pulse of this cycle (belongs to the NEXT EX instruction) -----------
      if (vif.id_valid && vif.is_decoding) begin
        tag_valid = 1;
        tag_pc    = vif.pc_id;
        tag_instr = vif.instr_id;
      end
    end
  end

endmodule : mul_smoke_checker

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/sim/smoke/alu_smoke_checker.sv
// =============================================================================
// alu_smoke_checker.sv
// -----------------------------------------------------------------------------
// Plain-SystemVerilog twin of alu_monitor + the ALU side of alu_mul_scoreboard
// (tb/agents/alu_agent, tb/env/alu_mul_scoreboard.sv), used by tb_smoke.sv to
// validate the reconstruction algorithm, alu_ref_pkg and the divider latency
// model against the real RTL with Verilator.
//
// Algorithm (keep identical to alu_monitor.sv):
//   issue   : id_valid && is_decoding in cycle N  => the ID instruction is in
//             EX in cycle N+1 (tag pc/instr). Valid for exactly one cycle.
//   start   : alu_en && !in_flight
//               with an issue in the previous cycle -> new instruction
//               without, data_misaligned_ex=1       -> 2nd half of a misaligned
//               load/store: ID re-loads the ALU with a = first address (EX
//               forward), b = 4, we = 0, no issue pulse (id_valid=0 during the
//               misaligned stall) -> a transaction flagged misaligned_2nd that
//               inherits the tag of the first half
//               without, otherwise                  -> must be a pipeline
//               bubble (rtl/cv32e40p_id_stage.sv loads alu_en=1,
//               alu_operator=ALU_SLTU, regfile_alu_we=0 when EX is ready and
//               ID has nothing) -> counted, not a transaction
//   progress: total++, stall++ when alu_ready && !ex_ready (EX held by LSU/WB)
//   finish  : ex_ready (the instruction leaves EX). ex_valid == ex_ready except
//             for branches (branch_in_ex forces ex_ready while ex_valid may be
//             0 when WB is not ready) -> check result / latency / write port /
//             decoder expectations from the tagged instruction word.
//   reset   : in-flight instruction dropped (killed_by_reset)
// =============================================================================
module alu_smoke_checker
  import cv32e40p_pkg::*;
  import rv32m_ref_pkg::*;
  import alu_ref_pkg::*;
(
  alu_mul_if vif,
  input bit  verbose
);

  // statistics visible to the top
  int unsigned n_txn, n_err, n_killed, n_bubbles;
  int unsigned n_cls [7];              // by alu_op_class_e
  int unsigned n_div, n_div_stalled, div_lat_min = 99, div_lat_max = 0;
  int unsigned n_div_lat [36];         // histogram of net divider latency
  int unsigned n_branch, n_branch_taken, n_branch_no_valid;
  int unsigned n_stalled, max_stall;
  int unsigned n_misaligned_2nd, n_lsu;

  // state
  bit           in_flight;
  alu_opcode_e  op;
  bit [31:0]    a, b;
  int unsigned  total, stall;
  bit           issued_prev;           // issue pulse seen in the previous cycle
  bit [31:0]    tag_pc, tag_instr;
  bit           cur_tag_valid;
  bit [31:0]    cur_pc, cur_instr;
  alu_expect_t  cur_exp;
  bit           cur_misaligned_2nd;
  bit [31:0]    last_result;          // result of the previous transaction (misaligned 1st half address)
  int unsigned  cycle_cnt;

  task automatic err(input string msg);
    n_err++;
    $display("[%0t] ALU_CHECK ERROR: %s", $time, msg);
  endtask

  bit trace;
  initial trace = $test$plusargs("trace_alu");

  always @(posedge vif.clk) begin
    cycle_cnt++;
    if (trace && vif.rst_n)
      $display("[%0t] TRACE alu_en=%0b %-9s a=%08h b=%08h res=%08h rdy=%0b | mult_en=%0b | ex_ready=%0b ex_valid=%0b lsu_rdy=%0b wb_rdy=%0b br=%0b lsu_en=%0b misal=%0b | we=%0b x%0d | issue=%0b%0b pc_id=%08h",
               $time, vif.alu_en, vif.alu_operator.name(), vif.alu_operand_a, vif.alu_operand_b, vif.alu_result, vif.alu_ready, vif.mult_en,
               vif.ex_ready, vif.ex_valid, vif.lsu_ready_ex, vif.wb_ready, vif.branch_in_ex, vif.lsu_en, vif.data_misaligned_ex,
               vif.rf_alu_we, vif.rf_alu_waddr[4:0], vif.id_valid, vif.is_decoding, vif.pc_id);
    if (!vif.rst_n) begin
      if (in_flight) begin
        n_killed++;
        $display("[%0t] ALU_CHECK: %s killed by reset after %0d cycles", $time, op.name(), total);
      end
      in_flight   = 0;
      issued_prev = 0;
    end else begin
      // ---- 1. start ---------------------------------------------------------------
      if (!in_flight && vif.alu_en) begin
        if (issued_prev || vif.data_misaligned_ex) begin
          op            = vif.alu_operator;
          a             = vif.alu_operand_a;
          b             = vif.alu_operand_b;
          total         = 0; stall = 0;
          cur_misaligned_2nd = !issued_prev;
          if (issued_prev) begin
            cur_tag_valid = 1;
            cur_pc        = tag_pc;
            cur_instr     = tag_instr;
            cur_exp       = alu_expect_of_instr(tag_instr);
          end
          // else: 2nd half keeps cur_tag_valid / cur_pc / cur_instr / cur_exp of the 1st half
          in_flight     = 1;
          if (cur_misaligned_2nd) begin
            n_misaligned_2nd++;
            if (op != ALU_ADD || b != 32'd4 || a != last_result || !vif.lsu_en || vif.rf_alu_we || !cur_exp.is_lsu)
              err($sformatf("misaligned 2nd half malformed: %s a=0x%08h (1st addr 0x%08h) b=0x%08h lsu_en=%0b we=%0b prev_is_lsu=%0b",
                            op.name(), a, last_result, b, vif.lsu_en, vif.rf_alu_we, cur_exp.is_lsu));
          end
          if (issued_prev && vif.data_misaligned_ex) err("data_misaligned_ex together with an issued instruction");
          if (!alu_op_in_scope(op))
            err($sformatf("operator %s not producible by the RV32IM decoder (pc 0x%08h instr 0x%08h)", op.name(), cur_pc, cur_instr));
          if (vif.mult_en) err("alu_en together with mult_en");
          if (is_div_operator(op) && vif.alu_ready)  err("divider ready in the first cycle of a DIV/REM");
          if (!is_div_operator(op) && !vif.alu_ready) err("alu_ready low for a single-cycle ALU operator");
          if (!cur_exp.in_scope)
            err($sformatf("tagged instruction 0x%08h @0x%08h is not in the RV32IM subset", cur_instr, cur_pc));
          else if (cur_exp.is_lsu != vif.lsu_en)
            err($sformatf("lsu_en=%0b but instruction 0x%08h @0x%08h is_lsu=%0b", vif.lsu_en, cur_instr, cur_pc, cur_exp.is_lsu));
          if (!cur_exp.in_scope) ;
          else if (!cur_exp.alu_en)
            err($sformatf("tagged instruction 0x%08h @0x%08h should not use the ALU (multiplier op) - tag out of sync?", cur_instr, cur_pc));
          else if (cur_exp.op != op)
            err($sformatf("decoder: instruction 0x%08h @0x%08h expects %s, EX executes %s", cur_instr, cur_pc, cur_exp.op.name(), op.name()));
        end else begin
          // no instruction was issued into EX: must be the bubble pattern
          if ((vif.alu_operator != ALU_SLTU) || vif.rf_alu_we || vif.branch_in_ex)
            err($sformatf("ALU activity without an issued instruction: %s we=%0b", vif.alu_operator.name(), vif.rf_alu_we));
          else
            n_bubbles++;
        end
      end else if (!in_flight && issued_prev && !vif.alu_en && !vif.mult_en) begin
        err($sformatf("issued instruction 0x%08h @0x%08h uses neither ALU nor multiplier", tag_instr, tag_pc));
      end

      // ---- 2. progress / finish -------------------------------------------------------
      if (in_flight) begin
        total++;
        if (vif.alu_ready && !vif.ex_ready) stall++;
        if (!vif.alu_en)                    err("alu_en dropped before the instruction left EX");
        if (vif.alu_operand_a != a || vif.alu_operand_b != b) err("ALU operands changed while in EX");
        if (vif.alu_operator != op)         err("alu_operator changed while in EX");
        if (!vif.alu_ready && vif.ex_ready) err("ex_ready while the divider is busy");
        if (!vif.alu_ready && vif.ex_valid) err("ex_valid while the divider is busy");

        if (vif.ex_ready) begin
          bit [31:0]   exp_res, res;
          bit          exp_cmp;
          int unsigned alu_cycles, exp_cycles;
          alu_op_class_e cls;
          res        = vif.alu_result;
          exp_res    = alu_ref(op, a, b);
          exp_cmp    = alu_cmp_ref(op, a, b);
          cls        = alu_op_class(op);
          alu_cycles = total - stall;
          exp_cycles = is_div_operator(op) ? div_latency_ref(op, a) : ALU_LATENCY;
          n_txn++; n_cls[cls]++;
          if (vif.lsu_en) n_lsu++;
          if (stall > 0) n_stalled++;
          if (stall > max_stall) max_stall = stall;

          // result (raw operands -> unit function)
          if (alu_op_in_scope(op) && (res !== exp_res))
            err($sformatf("%s result 0x%08h expected 0x%08h (a=0x%08h b=0x%08h) pc=0x%08h", op.name(), res, exp_res, a, b, cur_pc));
          if (is_branch_operator(op) && (vif.alu_cmp_result !== exp_cmp))
            err($sformatf("%s branch decision %0b expected %0b (a=0x%08h b=0x%08h)", op.name(), vif.alu_cmp_result, exp_cmp, a, b));

          // latency
          if (alu_cycles != exp_cycles)
            err($sformatf("%s latency %0d (total %0d stall %0d) expected %0d (a=0x%08h b=0x%08h)", op.name(), alu_cycles, total, stall, exp_cycles, a, b));
          if (is_div_operator(op)) begin
            n_div++;
            if (stall > 0) n_div_stalled++;
            if (alu_cycles < div_lat_min) div_lat_min = alu_cycles;
            if (alu_cycles > div_lat_max) div_lat_max = alu_cycles;
            if (alu_cycles <= 35) n_div_lat[alu_cycles]++;
          end

          // completion / write port
          if (is_branch_operator(op)) begin
            n_branch++;
            if (vif.alu_cmp_result) n_branch_taken++;
            if (!vif.ex_valid) n_branch_no_valid++;
            if (!vif.branch_in_ex) err("branch operator without branch_in_ex");
          end else begin
            if (!vif.ex_valid) err($sformatf("%s left EX (ex_ready) without ex_valid", op.name()));
            if (vif.branch_in_ex) err("branch_in_ex for a non-branch operator");
          end
          if (vif.ex_valid) begin
            if (cur_exp.in_scope && cur_exp.alu_en && (vif.rf_alu_we != cur_exp.we))
              err($sformatf("rf_alu_we=%0b expected %0b for instruction 0x%08h @0x%08h", vif.rf_alu_we, cur_exp.we, cur_instr, cur_pc));
            if (vif.rf_alu_we) begin
              if (vif.rf_alu_wdata != res) err("rf_alu_wdata != alu_result");
              if (vif.rf_alu_waddr[5])     err("rf_alu_waddr[5] set");
              if (cur_exp.in_scope && (vif.rf_alu_waddr[4:0] != cur_exp.rd))
                err($sformatf("write port rd x%0d != instruction rd x%0d", vif.rf_alu_waddr[4:0], cur_exp.rd));
            end
          end else if (vif.rf_alu_we) begin
            err("rf_alu_we asserted in a cycle that leaves EX without ex_valid");
          end

          // operand sourcing checks that do not need a register model
          if (cur_exp.in_scope) begin
            if (cur_exp.is_lui   && (res != instr_imm_u(cur_instr)))
              err($sformatf("LUI result 0x%08h != imm_u 0x%08h", res, instr_imm_u(cur_instr)));
            if (cur_exp.is_auipc && (res != cur_pc + instr_imm_u(cur_instr)))
              err($sformatf("AUIPC result 0x%08h != pc+imm_u 0x%08h", res, cur_pc + instr_imm_u(cur_instr)));
            if (cur_exp.is_jump  && ((a != cur_pc) || (b != 32'd4) || (res != cur_pc + 32'd4)))
              err($sformatf("JAL/JALR link: a=0x%08h b=0x%08h res=0x%08h pc=0x%08h", a, b, res, cur_pc));
          end

          if (verbose)
            $display("[%0t] ALU_CHECK %-9s pc=0x%08h a=0x%08h b=0x%08h -> 0x%08h we=%0b x%0d | tot=%0d stall=%0d net=%0d%s%s",
                     $time, op.name(), cur_pc, a, b, res, vif.rf_alu_we, vif.rf_alu_waddr[4:0], total, stall, alu_cycles,
                     vif.ex_valid ? "" : " (no ex_valid)", cur_misaligned_2nd ? " (misaligned 2nd half)" : "");
          last_result = res;
          in_flight = 0;
        end else if (total > 128) begin
          err("instruction stuck in EX");
          in_flight = 0;
        end
      end

      // ---- 3. issue pulse of this cycle (belongs to the NEXT EX instruction) -----------
      issued_prev = (vif.id_valid && vif.is_decoding);
      if (issued_prev) begin
        tag_pc    = vif.pc_id;
        tag_instr = vif.instr_id;
      end
    end
  end

endmodule : alu_smoke_checker

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/mini/mini_dut.sv
// =============================================================================
// mini_dut.sv  (part of the MINI UVM environment — tb/mini/)
// -----------------------------------------------------------------------------
// WHAT THIS FILE IS:
//   A small BEHAVIOURAL stand-in for the parts of cv32e40p_core that the
//   ALU_MUL interface (tb/interfaces/alu_mul_if.sv) observes: the ID issue
//   side, the EX stage handshake, the ALU/divider, the multiplier and the
//   register-file write port.  It lets the REAL UVM stack (mul_agent,
//   alu_agent, alu_mul_scoreboard, mul_cov, alu_cov — everything in
//   tb/agents, tb/env, tb/fcov) run and prove itself WITHOUT the big RTL
//   design, so the environment can be validated quickly on any free
//   UVM-capable simulator before it is integrated with the real core.
//
// RELATIONSHIP TO THE REAL RTL (read this before changing anything):
//   * Results:  computed with INDEPENDENT native SV operators (`*`, `/`,
//     `$signed(...)`, ...), NOT with tb/common/*_ref_pkg — so when the
//     scoreboard compares "DUT result vs golden model" the two sides are
//     genuinely independent computations.
//   * Latency:  DIV/REM lengths come from alu_ref_pkg::div_latency_ref()
//     on purpose: that function IS the documented RTL latency model
//     (rtl/cv32e40p_alu.sv + cv32e40p_alu_div.sv), and the scoreboard's
//     latency check must agree with it.  MUL = 1 cycle, MULH* = 5 cycles
//     with mult_multicycle = 1 in the first 3 — per rtl/cv32e40p_mult.sv.
//   * Protocol: every waveform below satisfies the exact checks in
//     tb/agents/alu_agent/alu_monitor.sv and mul_monitor.sv (see notes in
//     each task).  If a monitor check changes, update this file to match.
//
// TIMING RULES IMPLEMENTED (mirrors notes/mul_plan.md section 0.2):
//   * The driver changes signals on the NEGLIGE (negedge clk).  The
//     monitors sample on posedge clk with `input #1step`, i.e. they see
//     the values driven at the previous negedge — race-free.
//   * issue cycle N (id_valid && is_decoding, pc_id, instr_id)  =>
//     EX activity of that instruction in cycle N+1 (ALWAYS — the ALU
//     monitor errors if an issue pulse is not followed by EX work).
//   * ALU non-div: 1 EX cycle (alu_ready=1, ex_ready=1).  External stall:
//     alu_ready=1 but ex_ready=0 for k cycles (monitor counts stall).
//   * DIV/REM: first L-1 cycles alu_ready=0 (busy), last cycle
//     alu_ready=1 + ex_ready=1 + ex_valid=1.  L = div_latency_ref(op, a)
//     where a = divisor (the decoder swapped the operands, see alu_ref_pkg).
//   * MUL: 1 cycle, mult_ready=1, ex_valid=1.
//   * MULH*: 4 busy cycles (mult_ready=0, ex_ready=0, ex_valid=0,
//     mult_multicycle=1 in the first 3) + final cycle mult_ready=1,
//     ex_valid=1.  Net = 5 cycles, 0 stalls, multicycle window = 3.
//   * Branch: branch_in_ex=1, we=0; may leave EX with ex_valid=0.
//   * Misaligned ld/st: pass 1 = ADD(rs1, imm) tagged by an issue pulse;
//     pass 2 = NEXT cycle, NO issue pulse, data_misaligned_ex=1,
//     ADD(first address, 4), lsu_en=1, we=0 (monitor's misaligned rules).
//   * Bubbles: alu_en=1, ALU_SLTU, we=0, branch_in_ex=0 and no issue pulse
//     behind them — exactly the idle pattern of rtl/cv32e40p_id_stage.
// =============================================================================
module mini_dut
  import cv32e40p_pkg::*;   // alu_opcode_e / mul_opcode_e for the port types
(
  input  logic        clk,           // free-running clock from mini_tb
  output logic        rst_n,         // driven by the scenario (incl. reset-kill)

  // --- EX handshake ---------------------------------------------------------
  output logic        ex_ready,      // EX free / op leaves EX this cycle
  output logic        ex_valid,      // result valid this cycle
  output logic        lsu_ready_ex,  // always 1 here (no real LSU)
  output logic        wb_ready,      // 0 during injected external stalls
  output logic        branch_in_ex,  // 1 while a branch op is in EX
  output logic        lsu_en,        // 1 while an address op is in EX
  output logic        data_misaligned_ex,  // 1 only in the 2nd pass

  // --- ALU / divider group --------------------------------------------------
  output logic        alu_en,
  output alu_opcode_e alu_operator,
  output logic [31:0] alu_operand_a,   // divisor for DIV/REM
  output logic [31:0] alu_operand_b,   // dividend for DIV/REM
  output logic [31:0] alu_operand_c,   // RV32IM: 0
  output logic [31:0] alu_result,
  output logic        alu_cmp_result,  // branch decision
  output logic        alu_ready,       // 0 while the divider is busy

  // --- multiplier group -----------------------------------------------------
  output logic        mult_en,
  output mul_opcode_e mult_operator,   // MUL_MAC32 = MUL, MUL_H = MULH*
  output logic [ 1:0] mult_signed_mode,
  output logic [31:0] mult_operand_a,
  output logic [31:0] mult_operand_b,
  output logic [31:0] mult_operand_c,  // must be 0 at start (REGC_ZERO)
  output logic        mult_sel_subword,// RV32IM: 0 (PULP feature)
  output logic [ 4:0] mult_imm,        // RV32IM: 0 (PULP feature)
  output logic [31:0] mult_result,
  output logic        mult_ready,      // 0 in busy MULH cycles
  output logic        mult_multicycle, // 1 in the first 3 MULH cycles
  output logic        mulh_active,     // informational (MULH FSM busy)

  // --- register-file write port (port b of the RF) --------------------------
  output logic        rf_alu_we,
  output logic [ 5:0] rf_alu_waddr,    // {1'b0, rd} — bit5 = FP regfile = 0
  output logic [31:0] rf_alu_wdata,

  // --- ID side: issue pulses that tag the transactions ----------------------
  output logic        id_valid,
  output logic        is_decoding,
  output logic [31:0] pc_id,
  output logic [31:0] instr_id,

  // --- to mini_tb: high when the whole scenario has been played -------------
  output logic        scenario_done
);

  // Package imports used by the scenario code below:
  import rv32m_ref_pkg::*;     // rv32m_op_e + MUL..REMU literals
  import alu_ref_pkg::*;       // div_latency_ref, is_div_operator
  import mul_program_pkg::*;   // instruction encoders (i_m, i_add, i_lw, ...)

  // Running PC of the next issue pulse (tags and AUIPC/JAL operands use it).
  logic [31:0] cur_pc = 32'h0000_0080;

  // ---------------------------------------------------------------------------
  // Native golden helpers — deliberately INDEPENDENT of tb/common/*_ref_pkg.
  // The scoreboard will compare these against alu_ref/rv32m_ref, so a mistake
  // in either implementation shows up as a UVM_ERROR.
  // ---------------------------------------------------------------------------

  // RISC-V M-extension multiply results (high/low 32 bits of the product).
  function automatic logic [31:0] mul_native(input rv32m_op_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    logic signed [63:0] ps;     // signed 64-bit product
    logic        [63:0] pu;     // unsigned 64-bit product
    logic signed [64:0] a65, b65, p65;  // for MULHSU (mixed sign)
    ps  = $signed(a) * $signed(b);      // operands widen to the 64-bit context
    pu  = {32'b0, a} * {32'b0, b};      // zero-extended unsigned multiply
    a65 = {{33{a[31]}}, a};             // sign-extend a to 65 bits
    b65 = {33'b0, b};                   // zero-extend b to 65 bits
    p65 = a65 * b65;                    // signed x unsigned == signed x (b >= 0)
    case (op)
      MUL:    return ps[31:0];
      MULH:   return ps[63:32];
      MULHU:  return pu[63:32];
      MULHSU: return p65[63:32];
      default: return 32'hxxxx_xxxx;
    endcase
  endfunction

  // Branch/compare decision (same semantics as alu_ref_pkg::alu_cmp_ref).
  function automatic bit cmp_native(input alu_opcode_e op,
                                    input logic [31:0] a,
                                    input logic [31:0] b);
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

  // Divider/remainder per the RISC-V spec (a = divisor, b = dividend).
  function automatic logic [31:0] div_native(input alu_opcode_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    bit div_s = (op == ALU_DIV) || (op == ALU_REM);   // signed op?
    if (a == 32'd0) begin                            // divide by zero
      case (op)
        ALU_DIV,  ALU_DIVU: return 32'hFFFF_FFFF;     //   q = -1
        default:            return b;                 //   r = dividend
      endcase
    end
    if (div_s && (b == 32'h8000_0000) && (a == 32'hFFFF_FFFF)) begin
      case (op)                                       // signed overflow
        ALU_DIV: return 32'h8000_0000;                //   q = INT_MIN
        default: return 32'd0;                        //   r = 0
      endcase
    end
    case (op)
      ALU_DIV:  return $unsigned($signed(b) / $signed(a));
      ALU_DIVU: return b / a;
      ALU_REM:  return $unsigned($signed(b) % $signed(a));
      default:  return b % a;                         // ALU_REMU
    endcase
  endfunction

  // Everything the ALU can compute, straight from the operand conventions
  // documented in tb/common/alu_ref_pkg.sv (R/I: a=rs1 b=rs2/imm; branch:
  // replicate the cmp bit; DIV: swapped — handled by div_native).
  function automatic logic [31:0] alu_native(input alu_opcode_e op,
                                             input logic [31:0] a,
                                             input logic [31:0] b);
    case (op)
      ALU_ADD:  return a + b;
      ALU_SUB:  return a - b;
      ALU_AND:  return a & b;
      ALU_OR:   return a | b;
      ALU_XOR:  return a ^ b;
      ALU_SLL:  return a << b[4:0];
      ALU_SRL:  return a >> b[4:0];
      ALU_SRA:  return $unsigned($signed(a) >>> b[4:0]);
      ALU_SLTS: return {31'b0, cmp_native(ALU_SLTS, a, b)};
      ALU_SLTU: return {31'b0, cmp_native(ALU_SLTU, a, b)};
      ALU_EQ, ALU_NE, ALU_LTS, ALU_GES, ALU_LTU, ALU_GEU:
                return {32{cmp_native(op, a, b)}};    // VEC_MODE32 replicate
      ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU:
                return div_native(op, a, b);
      default:  return a + b;   // LUI/AUIPC/JAL/ld/st all ride on ALU_ADD
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Low-level cycle drivers — every task moves to the NEXT negedge first, so
  // the values it sets are what the monitors sample at the following posedge.
  // ---------------------------------------------------------------------------

  // One clock half-period of waiting.
  task automatic step();
    @(negedge clk);
  endtask

  // All units quiet, no issue pulse, handshakes inactive.
  // (Also the recovery state after a reset: monitors only sample on posedge
  //  when rst_n=1, so whatever we do during reset is never protocol-checked.)
  task automatic set_idle();
    rst_n                = rst_n;         // scenario owns reset; keep value
    ex_ready             = 1'b0;
    ex_valid             = 1'b0;
    lsu_ready_ex         = 1'b1;
    wb_ready             = 1'b1;
    branch_in_ex         = 1'b0;
    lsu_en               = 1'b0;
    data_misaligned_ex   = 1'b0;
    alu_en               = 1'b0;
    alu_operator         = ALU_SLTU;      // harmless default
    alu_operand_a        = 32'd0;
    alu_operand_b        = 32'd0;
    alu_operand_c        = 32'd0;
    alu_result           = 32'd0;
    alu_cmp_result       = 1'b0;
    alu_ready            = 1'b1;
    mult_en              = 1'b0;
    mult_operator        = MUL_MAC32;
    mult_signed_mode     = 2'b11;
    mult_operand_a       = 32'd0;
    mult_operand_b       = 32'd0;
    mult_operand_c       = 32'd0;
    mult_sel_subword     = 1'b0;
    mult_imm             = 5'd0;
    mult_result          = 32'd0;
    mult_ready           = 1'b1;
    mult_multicycle      = 1'b0;
    mulh_active          = 1'b0;
    rf_alu_we            = 1'b0;
    rf_alu_waddr         = 6'd0;
    rf_alu_wdata         = 32'd0;
    id_valid             = 1'b0;
    is_decoding          = 1'b0;
  endtask

  // One-cycle issue pulse: the instruction "arrives" in ID this cycle and
  // MUST show up in EX on the very next cycle (alu_monitor enforces this).
  task automatic issue(input logic [31:0] instr);
    step();
    set_idle();
    id_valid    = 1'b1;
    is_decoding = 1'b1;
    pc_id       = cur_pc;
    instr_id    = instr;
  endtask

  // ---------------------------------------------------------------------------
  // Instruction executors — each one plays the full life of one instruction:
  // issue cycle -> EX cycle(s).  They assume rst_n is already 1.
  // ---------------------------------------------------------------------------

  // One ALU/branch/ld-st/DIV instruction.
  //   stall_i = external hold cycles (alu_ready=1, ex_ready=0) before exit.
  task automatic do_alu(input logic [31:0]      instr,
                        input alu_opcode_e      op,
                        input logic [31:0]      a,
                        input logic [31:0]      b,
                        input bit               lsu_i  = 1'b0,
                        input bit               br_i   = 1'b0,
                        input bit               we_i   = 1'b1,
                        input logic [4:0]       rd_i   = 5'd3,
                        input bit               exv_i  = 1'b1,
                        input int unsigned      stall_i = 0);
    bit          is_div = is_div_operator(op);
    int unsigned lat    = is_div ? div_latency_ref(op, a) : 1;  // a = divisor
    logic [31:0] res    = alu_native(op, a, b);
    bit          cmp    = cmp_native(op, a, b);

    issue(instr);                       // cycle N: tag for EX at N+1
    step();
    set_idle();                         // cycle N+1: EX begins
    alu_en         = 1'b1;
    alu_operator   = op;
    alu_operand_a  = a;
    alu_operand_b  = b;
    alu_operand_c  = 32'd0;
    alu_result     = res;               // available from the first cycle
    alu_cmp_result = cmp;
    branch_in_ex   = br_i;
    lsu_en         = lsu_i;
    rf_alu_we      = we_i;
    rf_alu_waddr   = {1'b0, rd_i};
    rf_alu_wdata   = res;

    if (is_div) begin
      // ---- divider: L-1 busy cycles (alu_ready=0), then the finish cycle
      alu_ready = 1'b0;
      ex_ready  = 1'b0;
      ex_valid  = 1'b0;
      repeat (lat - 2) step();          // remaining busy cycles (min L=3)
      step();                           // finish cycle begins...
      alu_ready = 1'b1;                 // ...divider done
      if (stall_i == 0) begin
        ex_ready = 1'b1;                // no hold: leaves EX right now
        ex_valid = 1'b1;
      end else begin
        // External stall: unit done but WB holds EX (wb_ready=0 in RTL).
        ex_ready = 1'b0;
        ex_valid = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_ready = 1'b1;
        ex_valid = 1'b1;
      end
    end else begin
      // ---- single-cycle op: the first EX cycle may already be the exit
      alu_ready = 1'b1;
      if (stall_i == 0) begin
        ex_ready = 1'b1;
        ex_valid = exv_i;               // branch may legitimately exit with 0
      end else begin
        ex_ready = 1'b0;
        ex_valid = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_ready = 1'b1;
        ex_valid = exv_i;
      end
    end
    cur_pc += 4;                        // this instruction has been "retired"
  endtask

  // Misaligned load/store: pass 1 = the address, pass 2 = address+4 with
  // data_misaligned_ex=1 and NO issue pulse in between (replay rule).
  task automatic do_misaligned(input logic [31:0] instr,
                               input logic [31:0] a,      // rs1 value
                               input logic [31:0] imm,    // immediate
                               input logic [4:0]  rd_i);
    logic [31:0] addr = a + imm;
    issue(instr);                       // issue cycle
    // --- pass 1: tagged, normal ADD(rs1, imm), completes immediately
    step();
    set_idle();
    alu_en         = 1'b1;
    alu_operator   = ALU_ADD;
    alu_operand_a  = a;
    alu_operand_b  = imm;
    alu_result     = addr;
    alu_ready      = 1'b1;
    ex_ready       = 1'b1;
    ex_valid       = 1'b1;
    lsu_en         = 1'b1;
    rf_alu_we      = 1'b0;              // RF write comes from the LSU, not ALU
    rf_alu_waddr   = {1'b0, rd_i};
    // --- pass 2: next cycle, inherits pass 1's tag, shape = ADD(addr, 4)
    step();
    set_idle();
    alu_en         = 1'b1;
    alu_operator   = ALU_ADD;
    alu_operand_a  = addr;              // == monitor's last_result
    alu_operand_b  = 32'd4;
    alu_result     = addr + 32'd4;
    alu_ready      = 1'b1;
    ex_ready       = 1'b1;
    ex_valid       = 1'b1;
    lsu_en         = 1'b1;
    data_misaligned_ex = 1'b1;
    rf_alu_we      = 1'b0;
    rf_alu_waddr   = {1'b0, rd_i};
    cur_pc += 4;
  endtask

  // One multiplier instruction (MUL: 1 cycle, MULH*: 5 cycles).
  //   stall_i = external hold cycles before ex_valid (mult_ready=1, ex_valid=0).
  task automatic do_mul(input logic [31:0]  instr,
                        input rv32m_op_e    op,
                        input logic [31:0]  a,
                        input logic [31:0]  b,
                        input logic [4:0]   rd_i,
                        input int unsigned  stall_i = 0);
    bit          is_h  = (op != MUL);
    mul_opcode_e m_op  = is_h ? MUL_H : MUL_MAC32;
    logic [1:0]  sm;                                // signedness per funct3
    logic [31:0] res   = mul_native(op, a, b);
    case (op)
      MULHU:   sm = 2'b00;                          // both unsigned
      MULHSU:  sm = 2'b01;                          // a signed, b unsigned
      default: sm = 2'b11;                          // MUL / MULH: both signed
    endcase

    issue(instr);                       // issue cycle
    step();
    set_idle();                         // first EX cycle
    mult_en          = 1'b1;
    mult_operator    = m_op;
    mult_signed_mode = sm;
    mult_operand_a   = a;
    mult_operand_b   = b;
    mult_operand_c   = 32'd0;           // REGC_ZERO
    mult_sel_subword = 1'b0;            // PULP features off
    mult_imm         = 5'd0;
    mult_result      = res;
    rf_alu_we        = 1'b1;            // MUL unit writes the RF
    rf_alu_waddr     = {1'b0, rd_i};
    rf_alu_wdata     = res;

    if (is_h) begin
      // ---- MULH*: busy cycles with mult_ready=0 (so no stall is counted)
      mult_ready      = 1'b0;
      ex_ready        = 1'b0;
      ex_valid        = 1'b0;
      mult_multicycle = 1'b1;           // STEP0..STEP2 = first 3 cycles
      mulh_active     = 1'b1;
      step();                           // busy cycle 2 (values hold)
      step();                           // busy cycle 3 (values hold)
      step();                           // 3rd multicycle cycle done -> off
      mult_multicycle = 1'b0;
      step();                           // busy cycle 4 (mc=0 now)
      if (stall_i > 0) begin            // external hold, mult_ready=1
        mult_ready = 1'b1;
        wb_ready   = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready   = 1'b1;
      end
      mult_ready = 1'b1;
      ex_valid   = 1'b1;                // FINISH cycle
      ex_ready   = 1'b1;
      mulh_active = 1'b0;
    end else begin
      // ---- plain MUL: single cycle (optionally held externally first)
      mult_ready = 1'b1;
      if (stall_i == 0) begin
        ex_valid = 1'b1;
        ex_ready = 1'b1;
      end else begin
        ex_valid = 1'b0;                // external stall: WB holds the result
        ex_ready = 1'b0;
        wb_ready = 1'b0;
        repeat (stall_i - 1) step();
        step();
        wb_ready = 1'b1;
        ex_valid = 1'b1;
        ex_ready = 1'b1;
      end
    end
    cur_pc += 4;
  endtask

  // Reset-kill: start an MULH, then yank rst_n mid-flight.  The monitors
  // must publish it as killed_by_reset (scoreboard skips it, coverage
  // counts it in its reset group).
  task automatic do_mul_kill();
    issue(i_m(MULH, 5'd11, 5'd1, 5'd2));
    step();
    set_idle();
    mult_en          = 1'b1;
    mult_operator    = MUL_H;
    mult_signed_mode = 2'b11;
    mult_operand_a   = 32'h1234_5678;
    mult_operand_b   = 32'h9ABC_DEF0;
    mult_multicycle  = 1'b1;
    mult_ready       = 1'b0;
    rf_alu_we        = 1'b1;
    rf_alu_waddr     = 6'd11;
    step();                           // still busy...
    // ---- reset strikes: first posedge with rst_n=0 closes the transaction
    step();
    rst_n    = 1'b0;
    set_idle();                       // units off while reset is active
    step();                           // second reset cycle
    rst_n    = 1'b1;
    step();                           // healthy again (monitors were reset)
    // no cur_pc++ — this instruction never completed
  endtask

  // Reset-kill during a long DIVU (divisor 0 -> would take 35 cycles).
  task automatic do_div_kill();
    issue(i_m(DIVU, 5'd13, 5'd1, 5'd2));
    step();
    set_idle();
    alu_en        = 1'b1;
    alu_operator  = ALU_DIVU;
    alu_operand_a = 32'd0;            // divisor 0 = slowest divider op
    alu_operand_b = 32'h1234_5678;
    alu_ready     = 1'b0;
    ex_ready      = 1'b0;
    ex_valid      = 1'b0;
    rf_alu_we     = 1'b1;
    rf_alu_waddr  = 6'd13;
    step();                           // busy...
    step();                           // busy...
    step();
    rst_n    = 1'b0;
    set_idle();
    step();
    rst_n    = 1'b1;
    step();
  endtask

  // Idle bubbles: the ID stage's exact pattern while it has nothing to send.
  task automatic do_bubble(input int n = 1);
    repeat (n) begin
      step();
      set_idle();
      alu_en       = 1'b1;            // ALU loaded with the idle instruction
      alu_operator = ALU_SLTU;
      ex_ready     = 1'b1;            // passes straight through
      // we=0 and branch_in_ex=0 from set_idle() — the looks_like_bubble shape
    end
  endtask

  // Fully quiet cycles (no unit active at all).
  task automatic do_idle(input int n = 1);
    repeat (n) begin
      step();
      set_idle();
    end
  endtask

  // ---------------------------------------------------------------------------
  // +mini_prog=simple -> only the 3-instruction program above; default = full
  bit                               prog_simple = 1'b1; // bundle: always the 3-instruction program

  // The scenario: a directed program that lights up every check in the
  // scoreboard / monitors / coverage.  Structure:
  //   1. reset, 2. MUL side, 3. ALU side, 4. DIV latency corners,
  //   5. misaligned + reset-kills, 6. trailing bubbles/idle.
  // ---------------------------------------------------------------------------
  initial begin : scenario
    scenario_done = 1'b0;
    rst_n         = 1'b0;             // hold reset for a few cycles
    set_idle();
    repeat (4) step();
    rst_n = 1'b1;
    step();

    // Program select: +mini_prog=simple runs ONLY the 3 instructions below
    // (easy to watch in the console / waveform); default = the full scenario.
    begin
      string pname;
      if ($value$plusargs("mini_prog=%s", pname) && pname == "simple")
        prog_simple = 1;
    end
    $display("[MINI] program = %s", prog_simple ? "SIMPLE (3 instructions)" : "FULL");

    if (prog_simple) begin
      // ================= SIMPLE: 3 instructions — edit here ==============
      // 1. MUL x5 = x1*x2 = 7*6, 1 cycle
      do_mul(i_m(MUL, 5'd5, 5'd1, 5'd2), MUL, 32'h0000_0007, 32'h0000_0006, 5'd5);
      // 2. MULH signed: high32(-1 * 3), 5 cycles (shows the multicycle shape)
      do_mul(i_m(MULH, 5'd6, 5'd1, 5'd2), MULH, 32'hFFFF_FFFF, 32'h0000_0003, 5'd6);
      // 3. plain ALU add: 0x12345678 + 0x11112222
      do_alu(i_add(5'd12, 5'd1, 5'd2), ALU_ADD, 32'h1234_5678, 32'h1111_2222, .rd_i(5'd12));
      do_bubble(1);
      // ===============================================================
    end else begin
    // ================= MUL side (sb: result, latency, wb, tag) ==============
    // MUL, 1 cycle: 7*6 = 42
    do_mul(i_m(MUL, 5'd5, 5'd1, 5'd2), MUL, 32'h0000_0007, 32'h0000_0006, 5'd5);
    // MULH signed: high32(-1 * 3)
    do_mul(i_m(MULH, 5'd6, 5'd1, 5'd2), MULH, 32'hFFFF_FFFF, 32'h0000_0003, 5'd6);
    // MULHU unsigned high32 of the same bits
    do_mul(i_m(MULHU, 5'd7, 5'd1, 5'd2), MULHU, 32'hFFFF_FFFF, 32'h0000_0003, 5'd7);
    // MULHSU: a signed, b unsigned
    do_mul(i_m(MULHSU, 5'd8, 5'd1, 5'd2), MULHSU, 32'hFFFF_FFFF, 32'h0000_0003, 5'd8);
    do_bubble(2);                     // RTL-style idle between instructions
    // MUL with 1 external stall cycle (net must still be 1 multiplier cycle)
    do_mul(i_m(MUL, 5'd9, 5'd1, 5'd2), MUL, 32'hDEAD_BEEF, 32'hCAFE_BABE, 5'd9, 1);
    // MULH with 2 external stall cycles (net 5, total 7, stall 2)
    do_mul(i_m(MULH, 5'd10, 5'd1, 5'd2), MULH, 32'h0123_4567, 32'h89AB_CDEF, 5'd10, 2);
    // reset kills a running MULH -> killed_by_reset path
    do_mul_kill();
    do_idle(2);
    // corner operands: all-ones * all-ones
    do_mul(i_m(MUL, 5'd11, 5'd1, 5'd2), MUL, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 5'd11);

    // ================= ALU side =============================================
    do_alu(i_add (5'd12, 5'd1, 5'd2), ALU_ADD, 32'h1234_5678, 32'h1111_2222, .rd_i(5'd12));
    do_alu(i_sub (5'd13, 5'd1, 5'd2), ALU_SUB, 32'h0000_0005, 32'h0000_0008, .rd_i(5'd13));
    do_alu(i_xor (5'd14, 5'd1, 5'd2), ALU_XOR, 32'hF0F0_F0F0, 32'h0FF0_0FF0, .rd_i(5'd14));
    do_alu(i_sll (5'd15, 5'd1, 5'd2), ALU_SLL, 32'h0000_0001, 32'h0000_0011, .rd_i(5'd15)); // sh=17
    do_alu(i_sra (5'd16, 5'd1, 5'd2), ALU_SRA, 32'h8000_0000, 32'h0000_0004, .rd_i(5'd16));
    do_alu(i_slt (5'd17, 5'd1, 5'd2), ALU_SLTS, 32'hFFFF_FFFF, 32'h0000_0001, .rd_i(5'd17)); // -1 < 1
    do_alu(i_sltu(5'd18, 5'd1, 5'd2), ALU_SLTU, 32'hFFFF_FFFF, 32'h0000_0001, .rd_i(5'd18)); // 2^32-1 !< 1
    do_alu(i_addi(5'd19, 5'd1, 12'h025), ALU_ADD, 32'h0000_1000, 32'h0000_0025, .rd_i(5'd19));
    do_alu(i_andi(5'd20, 5'd1, 12'h0F0), ALU_AND, 32'hABCD_EF12, 32'h0000_00F0, .rd_i(5'd20));
    do_alu(i_ori (5'd21, 5'd1, 12'h301), ALU_OR,  32'hABCD_0000, 32'h0000_0301, .rd_i(5'd21));
    do_alu(i_srai(5'd22, 5'd1, 5'd8),    ALU_SRA, 32'hF000_0000, 32'h0000_0008, .rd_i(5'd22));
    do_bubble(1);
    // LUI: a=0, b=imm_u, result = imm_u (decoder cross-check)
    do_alu(i_lui(5'd23, 20'h12345), ALU_ADD, 32'h0, 32'h1234_5000, .rd_i(5'd23));
    // AUIPC: a=pc, b=imm_u, result = pc + imm_u
    do_alu(i_auipc(5'd24, 20'h000AB), ALU_ADD, cur_pc, 32'h000A_B000, .rd_i(5'd24));
    // JAL / JALR link value: a=pc, b=4, result = pc+4
    do_alu(i_jal(5'd25, 21'h00010), ALU_ADD, cur_pc, 32'd4, .rd_i(5'd25));
    do_alu(i_jalr(5'd26, 5'd1, 12'h000), ALU_ADD, cur_pc, 32'd4, .rd_i(5'd26));
    // branch taken: a == b -> cmp=1, branch_in_ex=1, we=0
    do_alu(i_beq(5'd1, 5'd2, 13'h008), ALU_EQ, 32'h0000_0042, 32'h0000_0042,
           .br_i(1'b1), .we_i(1'b0), .rd_i(5'd0));
    // branch NOT taken AND leaving with ex_valid=0 (branch shortcut path)
    do_alu(i_bne(5'd1, 5'd2, 13'h008), ALU_NE, 32'h0000_0042, 32'h0000_0042,
           .br_i(1'b1), .we_i(1'b0), .exv_i(1'b0), .rd_i(5'd0));
    // aligned load + store: address through the ALU, no port-b write
    do_alu(i_lw(5'd27, 5'd1, 12'h010), ALU_ADD, 32'h2000_0000, 32'h0000_0010,
           .lsu_i(1'b1), .we_i(1'b0), .rd_i(5'd27));
    do_alu(i_sw(5'd2, 5'd1, 12'h014), ALU_ADD, 32'h2000_0000, 32'h0000_0014,
           .lsu_i(1'b1), .we_i(1'b0), .rd_i(5'd0));
    do_bubble(1);

    // ================= DIV/REM latency corners (sb: div latency + result) ===
    // DIVU, divisor >= 0x80000000 -> 6-bit clb wrap -> FASTEST (3 cycles)
    do_alu(i_m(DIVU, 5'd28, 5'd1, 5'd2), ALU_DIVU, 32'h8000_0000, 32'hFFFF_FFFF, .rd_i(5'd28));
    // DIVU by zero -> SLOWEST (35 cycles)
    do_alu(i_m(DIVU, 5'd29, 5'd1, 5'd2), ALU_DIVU, 32'h0000_0000, 32'h1234_5678, .rd_i(5'd29));
    // DIV signed, divisor=1 -> 34 cycles
    do_alu(i_m(DIV, 5'd30, 5'd1, 5'd2), ALU_DIV, 32'h0000_0001, 32'h0000_0005, .rd_i(5'd30));
    // REM signed, negative divisor -> 34 cycles
    do_alu(i_m(REM, 5'd31, 5'd1, 5'd2), ALU_REM, 32'hFFFF_FFFF, 32'h0000_0064, .rd_i(5'd31));
    // REMU, divisor=4 -> 32 cycles
    do_alu(i_m(REMU, 5'd12, 5'd1, 5'd2), ALU_REMU, 32'h0000_0004, 32'h0000_0064, .rd_i(5'd12));
    // DIV signed by -1 of INT_MIN -> signed overflow corner result
    do_alu(i_m(DIV, 5'd13, 5'd1, 5'd2), ALU_DIV, 32'hFFFF_FFFF, 32'h8000_0000, .rd_i(5'd13));
    // DIV with an external stall folded in (net must still equal the model)
    do_alu(i_m(DIV, 5'd14, 5'd1, 5'd2), ALU_DIV, 32'h0000_0010, 32'h0000_00FF,
           .rd_i(5'd14), .stall_i(2));

    // ================= misaligned split accesses (2-pass rules) =============
    // LH at an odd address -> two ADD passes, second one tagged "misaligned"
    do_misaligned(i_load(3'b001, 5'd15, 5'd1, 12'h003), 32'h2000_0000, 32'h0000_0003, 5'd15);
    // SW at an odd address -> same shape, store flavour
    do_misaligned(i_store(3'b010, 5'd2, 5'd1, 12'h001), 32'h2000_0000, 32'h0000_0001, 5'd0);
    do_bubble(1);

    // ================= reset-kill during a long DIVU ========================
    do_div_kill();
    do_idle(2);

    // ================= closing traffic ======================================
    do_alu(i_add(5'd16, 5'd3, 5'd4), ALU_ADD, 32'h0BAD_CAFE, 32'h600D_0001, .rd_i(5'd16));
    do_mul(i_m(MUL, 5'd17, 5'd3, 5'd4), MUL, 32'h0000_1234, 32'h0000_5678, 5'd17);
    do_bubble(2);
    end // else: full program

    do_idle(4);                       // let every monitor publish its last txn

    scenario_done = 1'b1;
  end

endmodule : mini_dut

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> tb/mini/mini_plain_tb.sv
// =============================================================================
// mini_plain_tb.sv  (top module of the PLAIN mini bench — tb/mini/)
// -----------------------------------------------------------------------------
// WHAT THIS FILE IS:
//   The NO-UVM twin of mini_tb.sv.  Same clock/wires/interface/mini_dut
//   wiring, but instead of the UVM agents + scoreboard it instantiates the
//   plain-SV checkers that the big smoke bench uses (mul_smoke_checker +
//   alu_smoke_checker — the RTL-validated twins of the UVM monitors):
//
//     mini_dut  ──drives──►  alu_mul_if  ──sensed by──►  both checkers
//
//   So the SAME checking logic runs twice in the project: class-based UVM
//   (mini_tb.sv) and procedural plain SV (this file) — one of each to watch
//   before integrating with the real cv32e40p core.
//
//   Plusargs (defaults set by run_mini_plain.sh):
//     +mini_prog=simple   only the 3 instructions in mini_dut (default here)
//     +mini_prog=full     the complete directed scenario
//     +verbose            per-instruction print from the MUL checker
//     +verbose_alu        per-instruction print from the ALU checker
//     +vcd                dump mini_plain.vcd (needs Verilator --trace)
//
// END-OF-TEST CONTRACT (mirrors tb_smoke / mini_tb):
//   MINI_PLAIN TEST PASSED requires
//     - mul checker saw >=1 transaction and 0 errors, and
//     - alu checker saw >=1 transaction and 0 errors.
// =============================================================================
`timescale 1ns/1ps

module mini_plain_tb;
  import cv32e40p_pkg::*;        // alu_opcode_e / mul_opcode_e for the wires

  // ---------------------------------------------------------------------------
  // 1. Clock — free-running, 10 ns period (same style as mini_tb).
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 2. Wires + shared interface + behavioural core — identical wiring to
  //    mini_tb.sv so both tops observe EXACTLY the same signals.
  // ---------------------------------------------------------------------------
  logic        rst_n;
  logic        ex_ready, ex_valid, lsu_ready_ex, wb_ready;
  logic        branch_in_ex, lsu_en, data_misaligned_ex;
  logic        alu_en, alu_cmp_result, alu_ready;
  alu_opcode_e alu_operator;
  logic [31:0] alu_operand_a, alu_operand_b, alu_operand_c, alu_result;
  logic        mult_en, mult_sel_subword, mult_ready, mult_multicycle, mulh_active;
  mul_opcode_e mult_operator;
  logic [ 1:0] mult_signed_mode;
  logic [31:0] mult_operand_a, mult_operand_b, mult_operand_c, mult_result;
  logic [ 4:0] mult_imm;
  logic        rf_alu_we;
  logic [ 5:0] rf_alu_waddr;
  logic [31:0] rf_alu_wdata;
  logic        id_valid, is_decoding;
  logic [31:0] pc_id, instr_id;
  logic        scenario_done;

  alu_mul_if vif (
    .clk                (clk),
    .rst_n              (rst_n),
    .ex_ready           (ex_ready),
    .ex_valid           (ex_valid),
    .lsu_ready_ex       (lsu_ready_ex),
    .wb_ready           (wb_ready),
    .branch_in_ex       (branch_in_ex),
    .lsu_en             (lsu_en),
    .data_misaligned_ex (data_misaligned_ex),
    .alu_en             (alu_en),
    .alu_operator       (alu_operator),
    .alu_operand_a      (alu_operand_a),
    .alu_operand_b      (alu_operand_b),
    .alu_operand_c      (alu_operand_c),
    .alu_result         (alu_result),
    .alu_cmp_result     (alu_cmp_result),
    .alu_ready          (alu_ready),
    .mult_en            (mult_en),
    .mult_operator      (mult_operator),
    .mult_signed_mode   (mult_signed_mode),
    .mult_operand_a     (mult_operand_a),
    .mult_operand_b     (mult_operand_b),
    .mult_operand_c     (mult_operand_c),
    .mult_sel_subword   (mult_sel_subword),
    .mult_imm           (mult_imm),
    .mult_result        (mult_result),
    .mult_ready         (mult_ready),
    .mult_multicycle    (mult_multicycle),
    .mulh_active        (mulh_active),
    .rf_alu_we          (rf_alu_we),
    .rf_alu_waddr       (rf_alu_waddr),
    .rf_alu_wdata       (rf_alu_wdata),
    .id_valid           (id_valid),
    .is_decoding        (is_decoding),
    .pc_id              (pc_id),
    .instr_id           (instr_id)
  );

  mini_dut dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .ex_ready           (ex_ready),
    .ex_valid           (ex_valid),
    .lsu_ready_ex       (lsu_ready_ex),
    .wb_ready           (wb_ready),
    .branch_in_ex       (branch_in_ex),
    .lsu_en             (lsu_en),
    .data_misaligned_ex (data_misaligned_ex),
    .alu_en             (alu_en),
    .alu_operator       (alu_operator),
    .alu_operand_a      (alu_operand_a),
    .alu_operand_b      (alu_operand_b),
    .alu_operand_c      (alu_operand_c),
    .alu_result         (alu_result),
    .alu_cmp_result     (alu_cmp_result),
    .alu_ready          (alu_ready),
    .mult_en            (mult_en),
    .mult_operator      (mult_operator),
    .mult_signed_mode   (mult_signed_mode),
    .mult_operand_a     (mult_operand_a),
    .mult_operand_b     (mult_operand_b),
    .mult_operand_c     (mult_operand_c),
    .mult_sel_subword   (mult_sel_subword),
    .mult_imm           (mult_imm),
    .mult_result        (mult_result),
    .mult_ready         (mult_ready),
    .mult_multicycle    (mult_multicycle),
    .mulh_active        (mulh_active),
    .rf_alu_we          (rf_alu_we),
    .rf_alu_waddr       (rf_alu_waddr),
    .rf_alu_wdata       (rf_alu_wdata),
    .id_valid           (id_valid),
    .is_decoding        (is_decoding),
    .pc_id              (pc_id),
    .instr_id           (instr_id),
    .scenario_done      (scenario_done)
  );

  // ---------------------------------------------------------------------------
  // 3. The SAME plain-SV checkers the big RTL smoke bench uses — this is the
  //    whole point of this top: identical checking logic, no UVM anywhere.
  // ---------------------------------------------------------------------------
  bit verbose, verbose_alu;
  mul_smoke_checker chk  (.vif(vif), .verbose(verbose));
  alu_smoke_checker achk (.vif(vif), .verbose(verbose_alu));

  initial begin
    verbose     = 1'b1;   // per-instruction print always on
    verbose_alu = 1'b1;
    if (1'b1) begin       // always dump mini_plain.vcd
      $dumpfile("mini_plain.vcd");
      $dumpvars(0, mini_plain_tb);
    end
  end

  // ---------------------------------------------------------------------------
  // 4. Scenario finished -> wait a few cycles for the last publications, then
  //    print the summary and the verdict (contract same as mini_tb/smoke).
  // ---------------------------------------------------------------------------
  int unsigned n_errors;

  initial begin
    wait (scenario_done === 1'b1);
    repeat (5) @(posedge clk);

    n_errors = chk.n_err + achk.n_err;
    $display("MINI_PLAIN: MUL checker: %0d transactions (MUL %0d, MULH* %0d), %0d errors",
             chk.n_txn, chk.n_mul, chk.n_mulh, chk.n_err);
    $display("MINI_PLAIN: ALU checker: %0d transactions (%0d bubbles), %0d errors",
             achk.n_txn, achk.n_bubbles, achk.n_err);
    if (n_errors == 0 && chk.n_txn > 0 && achk.n_txn > 0)
      $display("MINI_PLAIN TEST PASSED");
    else
      $display("MINI_PLAIN TEST FAILED (%0d errors, mul_txn=%0d alu_txn=%0d)",
               n_errors, chk.n_txn, achk.n_txn);
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Watchdog — the full scenario is a few hundred cycles; 5000 is a margin.
  // ---------------------------------------------------------------------------
  initial begin
    repeat (5000) @(posedge clk);
    $display("MINI_PLAIN_WATCHDOG: scenario_done=%b", scenario_done);
    $fatal(1, "mini plain bench watchdog expired");
  end

endmodule : mini_plain_tb
