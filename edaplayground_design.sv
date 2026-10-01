// ====================================================================
// DESIGN.SV (All RTL packages & modules concatenated for EDA Playground)
// ====================================================================

// -------------------- START OF rtl/package/cv32e40p_apu_core_pkg.sv --------------------
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
// Engineer:       Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    APU-core package                                           //
// Project Name:   RISC-V                                                     //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    core package of RISC-V core for shared APU                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

package cv32e40p_apu_core_pkg;

  // APU interface
  parameter APU_NARGS_CPU = 3;
  parameter APU_WOP_CPU = 6;
  parameter APU_NDSFLAGS_CPU = 15;
  parameter APU_NUSFLAGS_CPU = 5;

endpackage  // cv32e40p_apu_core_pkg

// -------------------- END OF rtl/package/cv32e40p_apu_core_pkg.sv --------------------

// -------------------- START OF rtl/package/cv32e40p_fpu_pkg.sv --------------------
// Copyright 2020 Silicon Labs, Inc.
//
// This file, and derivatives thereof are licensed under the
// Solderpad License, Version 2.0 (the "License").
//
// Use of this file means you agree to the terms and conditions
// of the license and are in full compliance with the License.
//
// You may obtain a copy of the License at:
//
//     https://solderpad.org/licenses/SHL-2.0/
//
// Unless required by applicable law or agreed to in writing, software
// and hardware implementations thereof distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
//
// See the License for the specific language governing permissions and
// limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Arjan Bink - arjan.bink@silabs.com                         //
//                                                                            //
// Design Name:    FPU package                                                //
// Project Name:   CV32E40P                                                   //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    FPU types needed for FPNEW integration. A local copy was   //
//                 made to avoid a github dependency to non-OpenHW modules.   //
//                                                                            //
//                 If the FPU is used (FPU=1), then the types and parameters  //
//                 in this package must match with the corresponding types    //
//                 and parameters in the src/fpnew_pkg.sv package of          //
//                 https://github.com/pulp-platform/fpnew/                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

package cv32e40p_fpu_pkg;

  // ---------
  // FP TYPES
  // ---------
  // | Enumerator | Format           | Width  | EXP_BITS | MAN_BITS
  // |:----------:|------------------|-------:|:--------:|:--------:
  // | FP32       | IEEE binary32    | 32 bit | 8        | 23
  // | FP64       | IEEE binary64    | 64 bit | 11       | 52
  // | FP16       | IEEE binary16    | 16 bit | 5        | 10
  // | FP8        | binary8          |  8 bit | 5        | 2
  // | FP16ALT    | binary16alt      | 16 bit | 8        | 7
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!


  localparam int unsigned NUM_FP_FORMATS = 5;  // change me to add formats
  localparam int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  // FP formats
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    FP32    = 'd0,
    FP64    = 'd1,
    FP16    = 'd2,
    FP8     = 'd3,
    FP16ALT = 'd4
    // add new formats here
  } fp_format_e;

  // ---------
  // INT TYPES
  // ---------
  // | Enumerator | Width  |
  // |:----------:|-------:|
  // | INT8       |  8 bit |
  // | INT16      | 16 bit |
  // | INT32      | 32 bit |
  // | INT64      | 64 bit |
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!

  localparam int unsigned NUM_INT_FORMATS = 4;  // change me to add formats
  localparam int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Int formats
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,
    INT16,
    INT32,
    INT64
    // add new formats here
  } int_format_e;

  // --------------
  // FP OPERATIONS
  // --------------

  localparam int unsigned OP_BITS = 4;

  typedef enum logic [OP_BITS-1:0] {
    FMADD,
    FNMSUB,
    ADD,
    MUL,  // ADDMUL operation group
    DIV,
    SQRT,  // DIVSQRT operation group
    SGNJ,
    MINMAX,
    CMP,
    CLASSIFY,  // NONCOMP operation group
    F2F,
    F2I,
    I2F,
    CPKAB,
    CPKCD  // CONV operation group
  } operation_e;

endpackage

// -------------------- END OF rtl/package/cv32e40p_fpu_pkg.sv --------------------

// -------------------- START OF rtl/package/cv32e40p_pkg.sv --------------------
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

// -------------------- END OF rtl/package/cv32e40p_pkg.sv --------------------

// -------------------- START OF rtl/cv32e40p_aligner.sv --------------------
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
// Engineer:       Pasquale Davide Schiavone - pschiavo@iis.ee.ethz.ch        //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@greenwaves-technologies.com            //
//                                                                            //
// Design Name:    Instrctuon Aligner                                         //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_aligner (
    input logic clk,
    input logic rst_n,

    input  logic fetch_valid_i,
    output logic aligner_ready_o,  //prevents overwriting the fethced instruction

    input logic if_valid_i,

    input  logic [31:0] fetch_rdata_i,
    output logic [31:0] instr_aligned_o,
    output logic        instr_valid_o,

    input logic [31:0] branch_addr_i,
    input logic        branch_i,  // Asserted if we are branching/jumping now

    input logic [31:0] hwlp_addr_i,
    input logic        hwlp_update_pc_i,

    output logic [31:0] pc_o
);

  enum logic [2:0] {
    ALIGNED32,
    MISALIGNED32,
    MISALIGNED16,
    BRANCH_MISALIGNED,
    WAIT_VALID_BRANCH
  }
      state, next_state;

  logic [15:0] r_instr_h;
  logic [31:0] hwlp_addr_q;
  logic [31:0] pc_q, pc_n;
  logic update_state;
  logic [31:0] pc_plus4, pc_plus2;
  logic aligner_ready_q, hwlp_update_pc_q;

  assign pc_o     = pc_q;

  assign pc_plus2 = pc_q + 2;
  assign pc_plus4 = pc_q + 4;

  always_ff @(posedge clk or negedge rst_n) begin : proc_SEQ_FSM
    if (~rst_n) begin
      state            <= ALIGNED32;
      r_instr_h        <= '0;
      hwlp_addr_q      <= '0;
      pc_q             <= '0;
      aligner_ready_q  <= 1'b0;
      hwlp_update_pc_q <= 1'b0;
    end else begin
      if (update_state) begin
        pc_q             <= pc_n;
        state            <= next_state;
        r_instr_h        <= fetch_rdata_i[31:16];
        aligner_ready_q  <= aligner_ready_o;
        hwlp_update_pc_q <= 1'b0;
      end else begin
        if (hwlp_update_pc_i) begin
          hwlp_addr_q      <= hwlp_addr_i;  // Save the JUMP target address to keep pc_n up to date during the stall
          hwlp_update_pc_q <= 1'b1;
        end

      end
    end
  end

  always_comb begin

    //default outputs
    pc_n            = pc_q;
    instr_valid_o   = fetch_valid_i;
    instr_aligned_o = fetch_rdata_i;
    aligner_ready_o = 1'b1;
    update_state    = 1'b0;
    next_state      = state;


    case (state)
      ALIGNED32: begin
        if (fetch_rdata_i[1:0] == 2'b11) begin
          /*
                  Before we fetched a 32bit aligned instruction
                  Therefore, now the address is aligned too and it is 32bits
                */
          next_state      = ALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = fetch_rdata_i;
          //gate id_valid with fetch_valid as the next state should be evaluated only if mem content is valid
          update_state    = fetch_valid_i & if_valid_i;
          if (hwlp_update_pc_i || hwlp_update_pc_q)
            pc_n = hwlp_update_pc_i ? hwlp_addr_i : hwlp_addr_q;
        end else begin
          /*
                  Before we fetched a 32bit aligned instruction
                  Therefore, now the address is aligned too and it is 16bits
                */
          next_state      = MISALIGNED32;
          pc_n            = pc_plus2;
          instr_aligned_o = fetch_rdata_i;  //only the first 16b are used
          //gate id_valid with fetch_valid as the next state should be evaluated only if mem content is valid
          update_state    = fetch_valid_i & if_valid_i;
        end
      end


      MISALIGNED32: begin
        if (r_instr_h[1:0] == 2'b11) begin
          /*
                  Before we fetched a 32bit misaligned instruction
                  So now the beginning of the next instruction is the stored one
                  The istruction is 32bits so it is misaligned again
                */
          next_state      = MISALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = {fetch_rdata_i[15:0], r_instr_h[15:0]};
          //gate id_valid with fetch_valid as the next state should be evaluated only if mem content is valid
          update_state    = fetch_valid_i & if_valid_i;
        end else begin
          /*
                  Before we fetched a 32bit misaligned instruction
                  So now the beginning of the next instruction is the stored one
                  The istruction is 16bits misaligned
                */
          instr_aligned_o = {fetch_rdata_i[31:16], r_instr_h[15:0]};  //only the first 16b are used
          next_state      = MISALIGNED16;
          instr_valid_o   = 1'b1;
          pc_n            = pc_plus2;
          //we cannot overwrite the 32bit instruction just fetched
          //so tell the IF stage to stall, the coming instruction goes to the FIFO
          aligner_ready_o = !fetch_valid_i;
          //not need to gate id_valid with fetch_valid as the next state depends only on r_instr_h
          update_state    = if_valid_i;
        end
      end


      MISALIGNED16: begin
        //this is 1 as we holded the value before with raw_instr_hold_o
        instr_valid_o = !aligner_ready_q || fetch_valid_i;
        if (fetch_rdata_i[1:0] == 2'b11) begin
          /*
                  Before we fetched a 16bit misaligned instruction
                  So now the beginning of the next instruction is the new one
                  The istruction is 32bits so it is aligned
                */
          next_state      = ALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = fetch_rdata_i;
          //no gate id_valid with fetch_valid as the next state sdepends only on mem content that has be held the previous cycle with raw_instr_hold_o
          update_state    = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
        end else begin
          /*
                  Before we fetched a 16bit misaligned  instruction
                  So now the beginning of the next instruction is the new one
                  The istruction is 16bit aligned
                */
          next_state = MISALIGNED32;
          pc_n = pc_plus2;
          instr_aligned_o = fetch_rdata_i;  //only the first 16b are used
          //no gate id_valid with fetch_valid as the next state sdepends only on mem content that has be held the previous cycle with raw_instr_hold_o
          update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
        end
      end


      BRANCH_MISALIGNED: begin
        //we jumped to a misaligned location, so now we received {TARGET, XXXX}
        if (fetch_rdata_i[17:16] == 2'b11) begin
          /*
                  We jumped to a misaligned location that contains 32bits instruction
                */
          next_state      = MISALIGNED32;
          instr_valid_o   = 1'b0;
          pc_n            = pc_q;
          instr_aligned_o = fetch_rdata_i;
          //gate id_valid with fetch_valid as the next state should be evaluated only if mem content is valid
          update_state    = fetch_valid_i & if_valid_i;
        end else begin
          /*
                  We jumped to a misaligned location that contains 16bits instruction, as we consumed the whole word, we can preted to start again from ALIGNED32
                */
          next_state = ALIGNED32;
          pc_n = pc_plus2;
          instr_aligned_o = {
            fetch_rdata_i[31:16], fetch_rdata_i[31:16]
          };  //only the first 16b are used
          //gate id_valid with fetch_valid as the next state should be evaluated only if mem content is valid
          update_state = fetch_valid_i & if_valid_i;
        end
      end

    endcase  // state


    // JUMP, BRANCH, SPECIAL JUMP control
    if (branch_i) begin
      update_state = 1'b1;
      pc_n         = branch_addr_i;
      next_state   = branch_addr_i[1] ? BRANCH_MISALIGNED : ALIGNED32;
    end

  end

  /*
  When a branch is taken in EX, if_valid_i is asserted because the BRANCH is resolved also in
  case of stalls. This is because the branch information is stored in the IF stage (in the prefetcher)
  when branch_i is asserted. We introduced here an apparently unuseful  special case for
  the JUMPS for a cleaner and more robust HW: theoretically, we don't need to save the instruction
  after a taken branch in EX, thus we will not do it.
*/

  //////////////////////////////////////////////////////////////////////////////
  // Assertions
  //////////////////////////////////////////////////////////////////////////////

`ifdef CV32E40P_ASSERT_ON

  // Hardware Loop check
  property p_hwlp_update_pc;
    @(posedge clk) disable iff (!rst_n) (1'b1) |-> (!(hwlp_update_pc_i && hwlp_update_pc_q));
  endproperty

  a_hwlp_update_pc :
  assert property (p_hwlp_update_pc);

`endif

endmodule

// -------------------- END OF rtl/cv32e40p_aligner.sv --------------------

// -------------------- START OF rtl/cv32e40p_alu.sv --------------------
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
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    ALU                                                        //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Arithmetic logic unit of the pipelined processor           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_alu
  import cv32e40p_pkg::*;
(
    input logic               clk,
    input logic               rst_n,
    input logic               enable_i,
    input alu_opcode_e        operator_i,
    input logic        [31:0] operand_a_i,
    input logic        [31:0] operand_b_i,
    input logic        [31:0] operand_c_i,

    input logic [1:0] vector_mode_i,
    input logic [4:0] bmask_a_i,
    input logic [4:0] bmask_b_i,
    input logic [1:0] imm_vec_ext_i,

    input logic       is_clpx_i,
    input logic       is_subrot_i,
    input logic [1:0] clpx_shift_i,

    output logic [31:0] result_o,
    output logic        comparison_result_o,

    output logic ready_o,
    input  logic ex_ready_i
);

  logic [31:0] operand_a_rev;
  logic [31:0] operand_a_neg;
  logic [31:0] operand_a_neg_rev;

  assign operand_a_neg = ~operand_a_i;

  // bit reverse operand_a for left shifts and bit counting
  generate
    genvar k;
    for (k = 0; k < 32; k++) begin : gen_operand_a_rev
      assign operand_a_rev[k] = operand_a_i[31-k];
    end
  endgenerate

  // bit reverse operand_a_neg for left shifts and bit counting
  generate
    genvar m;
    for (m = 0; m < 32; m++) begin : gen_operand_a_neg_rev
      assign operand_a_neg_rev[m] = operand_a_neg[31-m];
    end
  endgenerate

  logic [31:0] operand_b_neg;

  assign operand_b_neg = ~operand_b_i;


  logic [ 5:0] div_shift;
  logic        div_valid;
  logic [31:0] bmask;

  //////////////////////////////////////////////////////////////////////////////////////////
  //   ____            _   _ _   _                      _      _       _     _            //
  //  |  _ \ __ _ _ __| |_(_) |_(_) ___  _ __   ___  __| |    / \   __| | __| | ___ _ __  //
  //  | |_) / _` | '__| __| | __| |/ _ \| '_ \ / _ \/ _` |   / _ \ / _` |/ _` |/ _ \ '__| //
  //  |  __/ (_| | |  | |_| | |_| | (_) | | | |  __/ (_| |  / ___ \ (_| | (_| |  __/ |    //
  //  |_|   \__,_|_|   \__|_|\__|_|\___/|_| |_|\___|\__,_| /_/   \_\__,_|\__,_|\___|_|    //
  //                                                                                      //
  //////////////////////////////////////////////////////////////////////////////////////////

  logic        adder_op_b_negate;
  logic [31:0] adder_op_a, adder_op_b;
  logic [35:0] adder_in_a, adder_in_b;
  logic [31:0] adder_result;
  logic [36:0] adder_result_expanded;


  assign adder_op_b_negate = (operator_i == ALU_SUB) || (operator_i == ALU_SUBR) ||
                             (operator_i == ALU_SUBU) || (operator_i == ALU_SUBUR) || is_subrot_i;

  // prepare operand a
  assign adder_op_a = (operator_i == ALU_ABS) ? operand_a_neg : (is_subrot_i ? {
    operand_b_i[15:0], operand_a_i[31:16]
  } : operand_a_i);

  // prepare operand b
  assign adder_op_b = adder_op_b_negate ? (is_subrot_i ? ~{
    operand_a_i[15:0], operand_b_i[31:16]
  } : operand_b_neg) : operand_b_i;

  // prepare carry
  always_comb begin
    adder_in_a[0]     = 1'b1;
    adder_in_a[8:1]   = adder_op_a[7:0];
    adder_in_a[9]     = 1'b1;
    adder_in_a[17:10] = adder_op_a[15:8];
    adder_in_a[18]    = 1'b1;
    adder_in_a[26:19] = adder_op_a[23:16];
    adder_in_a[27]    = 1'b1;
    adder_in_a[35:28] = adder_op_a[31:24];

    adder_in_b[0]     = 1'b0;
    adder_in_b[8:1]   = adder_op_b[7:0];
    adder_in_b[9]     = 1'b0;
    adder_in_b[17:10] = adder_op_b[15:8];
    adder_in_b[18]    = 1'b0;
    adder_in_b[26:19] = adder_op_b[23:16];
    adder_in_b[27]    = 1'b0;
    adder_in_b[35:28] = adder_op_b[31:24];

    if (adder_op_b_negate || (operator_i == ALU_ABS || operator_i == ALU_CLIP)) begin
      // special case for subtractions and absolute number calculations
      adder_in_b[0] = 1'b1;

      case (vector_mode_i)
        VEC_MODE16: begin
          adder_in_b[18] = 1'b1;
        end

        VEC_MODE8: begin
          adder_in_b[9]  = 1'b1;
          adder_in_b[18] = 1'b1;
          adder_in_b[27] = 1'b1;
        end
      endcase

    end else begin
      // take care of partitioning the adder for the addition case
      case (vector_mode_i)
        VEC_MODE16: begin
          adder_in_a[18] = 1'b0;
        end

        VEC_MODE8: begin
          adder_in_a[9]  = 1'b0;
          adder_in_a[18] = 1'b0;
          adder_in_a[27] = 1'b0;
        end
      endcase
    end
  end

  // actual adder
  assign adder_result_expanded = $signed(adder_in_a) + $signed(adder_in_b);
  assign adder_result = {
    adder_result_expanded[35:28],
    adder_result_expanded[26:19],
    adder_result_expanded[17:10],
    adder_result_expanded[8:1]
  };


  // normalization stage
  logic [31:0] adder_round_value;
  logic [31:0] adder_round_result;

  assign adder_round_value  = ((operator_i == ALU_ADDR) || (operator_i == ALU_SUBR) ||
                               (operator_i == ALU_ADDUR) || (operator_i == ALU_SUBUR)) ?
                                {
    1'b0, bmask[31:1]
  } : '0;
  assign adder_round_result = adder_result + adder_round_value;


  ////////////////////////////////////////
  //  ____  _   _ ___ _____ _____       //
  // / ___|| | | |_ _|  ___|_   _|      //
  // \___ \| |_| || || |_    | |        //
  //  ___) |  _  || ||  _|   | |        //
  // |____/|_| |_|___|_|     |_|        //
  //                                    //
  ////////////////////////////////////////

  logic        shift_left;  // should we shift left
  logic        shift_use_round;
  logic        shift_arithmetic;

  logic [31:0] shift_amt_left;  // amount of shift, if to the left
  logic [31:0] shift_amt;  // amount of shift, to the right
  logic [31:0] shift_amt_int;  // amount of shift, used for the actual shifters
  logic [31:0] shift_amt_norm;  // amount of shift, used for normalization
  logic [31:0] shift_op_a;  // input of the shifter
  logic [31:0] shift_result;
  logic [31:0] shift_right_result;
  logic [31:0] shift_left_result;
  logic [15:0] clpx_shift_ex;

  // shifter is also used for preparing operand for division
  assign shift_amt = div_valid ? div_shift : operand_b_i;

  // by reversing the bits of the input, we also have to reverse the order of shift amounts
  always_comb begin
    case (vector_mode_i)
      VEC_MODE16: begin
        shift_amt_left[15:0]  = shift_amt[31:16];
        shift_amt_left[31:16] = shift_amt[15:0];
      end

      VEC_MODE8: begin
        shift_amt_left[7:0]   = shift_amt[31:24];
        shift_amt_left[15:8]  = shift_amt[23:16];
        shift_amt_left[23:16] = shift_amt[15:8];
        shift_amt_left[31:24] = shift_amt[7:0];
      end

      default: // VEC_MODE32
      begin
        shift_amt_left[31:0] = shift_amt[31:0];
      end
    endcase
  end

  // ALU_FL1 and ALU_CBL are used for the bit counting ops later
  assign shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||
                      (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||
                      (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                      (operator_i == ALU_REM) || (operator_i == ALU_REMU) ||
                      (operator_i == ALU_BREV);

  assign shift_use_round = (operator_i == ALU_ADD)   || (operator_i == ALU_SUB)   ||
                           (operator_i == ALU_ADDR)  || (operator_i == ALU_SUBR)  ||
                           (operator_i == ALU_ADDU)  || (operator_i == ALU_SUBU)  ||
                           (operator_i == ALU_ADDUR) || (operator_i == ALU_SUBUR);

  assign shift_arithmetic = (operator_i == ALU_SRA)  || (operator_i == ALU_BEXT) ||
                            (operator_i == ALU_ADD)  || (operator_i == ALU_SUB)  ||
                            (operator_i == ALU_ADDR) || (operator_i == ALU_SUBR);

  // choose the bit reversed or the normal input for shift operand a
  assign shift_op_a    = shift_left ? operand_a_rev :
                          (shift_use_round ? adder_round_result : operand_a_i);
  assign shift_amt_int = shift_use_round ? shift_amt_norm :
                          (shift_left ? shift_amt_left : shift_amt);

  assign shift_amt_norm = is_clpx_i ? {clpx_shift_ex, clpx_shift_ex} : {4{3'b000, bmask_b_i}};

  assign clpx_shift_ex = $unsigned(clpx_shift_i);

  // right shifts, we let the synthesizer optimize this
  logic [63:0] shift_op_a_32;

  assign shift_op_a_32 = (operator_i == ALU_ROR) ? {
        shift_op_a, shift_op_a
      } : $signed(
          {{32{shift_arithmetic & shift_op_a[31]}}, shift_op_a}
      );

  always_comb begin
    case (vector_mode_i)
      VEC_MODE16: begin
        shift_right_result[31:16] = $signed(
            {shift_arithmetic & shift_op_a[31], shift_op_a[31:16]}
        ) >>> shift_amt_int[19:16];
        shift_right_result[15:0] = $signed(
            {shift_arithmetic & shift_op_a[15], shift_op_a[15:0]}
        ) >>> shift_amt_int[3:0];
      end

      VEC_MODE8: begin
        shift_right_result[31:24] = $signed(
            {shift_arithmetic & shift_op_a[31], shift_op_a[31:24]}
        ) >>> shift_amt_int[26:24];
        shift_right_result[23:16] = $signed(
            {shift_arithmetic & shift_op_a[23], shift_op_a[23:16]}
        ) >>> shift_amt_int[18:16];
        shift_right_result[15:8] = $signed(
            {shift_arithmetic & shift_op_a[15], shift_op_a[15:8]}
        ) >>> shift_amt_int[10:8];
        shift_right_result[7:0] = $signed(
            {shift_arithmetic & shift_op_a[7], shift_op_a[7:0]}
        ) >>> shift_amt_int[2:0];
      end

      default: // VEC_MODE32
      begin
        shift_right_result = shift_op_a_32 >> shift_amt_int[4:0];
      end
    endcase
    ;  // case (vec_mode_i)
  end

  // bit reverse the shift_right_result for left shifts
  genvar j;
  generate
    for (j = 0; j < 32; j++) begin : gen_shift_left_result
      assign shift_left_result[j] = shift_right_result[31-j];
    end
  endgenerate

  assign shift_result = shift_left ? shift_left_result : shift_right_result;


  //////////////////////////////////////////////////////////////////
  //   ____ ___  __  __ ____   _    ____  ___ ____   ___  _   _   //
  //  / ___/ _ \|  \/  |  _ \ / \  |  _ \|_ _/ ___| / _ \| \ | |  //
  // | |  | | | | |\/| | |_) / _ \ | |_) || |\___ \| | | |  \| |  //
  // | |__| |_| | |  | |  __/ ___ \|  _ < | | ___) | |_| | |\  |  //
  //  \____\___/|_|  |_|_| /_/   \_\_| \_\___|____/ \___/|_| \_|  //
  //                                                              //
  //////////////////////////////////////////////////////////////////

  logic [ 3:0] is_equal;
  logic [ 3:0] is_greater;  // handles both signed and unsigned forms

  // 8-bit vector comparisons, basic building blocks
  logic [ 3:0] cmp_signed;
  logic [ 3:0] is_equal_vec;
  logic [ 3:0] is_greater_vec;
  logic [31:0] operand_b_eq;
  logic        is_equal_clip;


  //second == comparator for CLIP instructions
  always_comb begin
    operand_b_eq = operand_b_neg;
    if (operator_i == ALU_CLIPU) operand_b_eq = '0;
    else operand_b_eq = operand_b_neg;
  end
  assign is_equal_clip = operand_a_i == operand_b_eq;

  always_comb begin
    cmp_signed = 4'b0;

    unique case (operator_i)
      ALU_GTS,
      ALU_GES,
      ALU_LTS,
      ALU_LES,
      ALU_SLTS,
      ALU_SLETS,
      ALU_MIN,
      ALU_MAX,
      ALU_ABS,
      ALU_CLIP,
      ALU_CLIPU: begin
        case (vector_mode_i)
          VEC_MODE8:  cmp_signed[3:0] = 4'b1111;
          VEC_MODE16: cmp_signed[3:0] = 4'b1010;
          default:    cmp_signed[3:0] = 4'b1000;
        endcase
      end

      default: ;
    endcase
  end

  // generate vector equal and greater than signals, cmp_signed decides if the
  // comparison is done signed or unsigned
  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : gen_is_vec
      assign is_equal_vec[i] = (operand_a_i[8*i+7:8*i] == operand_b_i[8*i+7:i*8]);
      assign is_greater_vec[i] = $signed(
          {operand_a_i[8*i+7] & cmp_signed[i], operand_a_i[8*i+7:8*i]}
      ) > $signed(
          {operand_b_i[8*i+7] & cmp_signed[i], operand_b_i[8*i+7:i*8]}
      );
    end
  endgenerate

  // generate the real equal and greater than signals that take the vector
  // mode into account
  always_comb begin
    // 32-bit mode
    is_equal[3:0] = {4{is_equal_vec[3] & is_equal_vec[2] & is_equal_vec[1] & is_equal_vec[0]}};
    is_greater[3:0] = {4{is_greater_vec[3] | (is_equal_vec[3] & (is_greater_vec[2]
                                            | (is_equal_vec[2] & (is_greater_vec[1]
                                             | (is_equal_vec[1] & (is_greater_vec[0]))))))}};

    case (vector_mode_i)
      VEC_MODE16: begin
        is_equal[1:0]   = {2{is_equal_vec[0] & is_equal_vec[1]}};
        is_equal[3:2]   = {2{is_equal_vec[2] & is_equal_vec[3]}};
        is_greater[1:0] = {2{is_greater_vec[1] | (is_equal_vec[1] & is_greater_vec[0])}};
        is_greater[3:2] = {2{is_greater_vec[3] | (is_equal_vec[3] & is_greater_vec[2])}};
      end

      VEC_MODE8: begin
        is_equal[3:0]   = is_equal_vec[3:0];
        is_greater[3:0] = is_greater_vec[3:0];
      end

      default: ;  // see default assignment
    endcase
  end

  // generate comparison result
  logic [3:0] cmp_result;

  always_comb begin
    cmp_result = is_equal;
    unique case (operator_i)
      ALU_EQ:                                 cmp_result = is_equal;
      ALU_NE:                                 cmp_result = ~is_equal;
      ALU_GTS, ALU_GTU:                       cmp_result = is_greater;
      ALU_GES, ALU_GEU:                       cmp_result = is_greater | is_equal;
      ALU_LTS, ALU_SLTS, ALU_LTU, ALU_SLTU:   cmp_result = ~(is_greater | is_equal);
      ALU_SLETS, ALU_SLETU, ALU_LES, ALU_LEU: cmp_result = ~is_greater;
      default:                                ;
    endcase
  end

  assign comparison_result_o = cmp_result[3];


  // min/max/abs handling
  logic [31:0] result_minmax;
  logic [ 3:0] sel_minmax;
  logic        do_min;
  logic [31:0] minmax_b;

  assign minmax_b = (operator_i == ALU_ABS) ? adder_result : operand_b_i;

  assign do_min   = (operator_i == ALU_MIN)  || (operator_i == ALU_MINU) ||
                    (operator_i == ALU_CLIP) || (operator_i == ALU_CLIPU);

  assign sel_minmax[3:0] = is_greater ^ {4{do_min}};

  assign result_minmax[31:24] = (sel_minmax[3] == 1'b1) ? operand_a_i[31:24] : minmax_b[31:24];
  assign result_minmax[23:16] = (sel_minmax[2] == 1'b1) ? operand_a_i[23:16] : minmax_b[23:16];
  assign result_minmax[15:8] = (sel_minmax[1] == 1'b1) ? operand_a_i[15:8] : minmax_b[15:8];
  assign result_minmax[7:0] = (sel_minmax[0] == 1'b1) ? operand_a_i[7:0] : minmax_b[7:0];

  //////////////////////////////////////////////////
  // Clip
  //////////////////////////////////////////////////
  logic [31:0] clip_result;  // result of clip and clip

  always_comb begin
    clip_result = result_minmax;
    if (operator_i == ALU_CLIPU) begin
      if (operand_a_i[31] || is_equal_clip) begin
        clip_result = '0;
      end else begin
        clip_result = result_minmax;
      end
    end else begin
      //CLIP
      if (adder_result_expanded[36] || is_equal_clip) begin
        clip_result = operand_b_neg;
      end else begin
        clip_result = result_minmax;
      end
    end

  end

  //////////////////////////////////////////////////
  //  ____  _   _ _   _ _____ _____ _     _____   //
  // / ___|| | | | | | |  ___|  ___| |   | ____|  //
  // \___ \| |_| | | | | |_  | |_  | |   |  _|    //
  //  ___) |  _  | |_| |  _| |  _| | |___| |___   //
  // |____/|_| |_|\___/|_|   |_|   |_____|_____|  //
  //                                              //
  //////////////////////////////////////////////////

  logic [3:0][1:0] shuffle_byte_sel;  // select byte in register: 31:24, 23:16, 15:8, 7:0
  logic [3:0]      shuffle_reg_sel;  // select register: rD/rS2 or rS1
  logic [1:0]      shuffle_reg1_sel;  // select register rD or rS2 for next stage
  logic [1:0]      shuffle_reg0_sel;
  logic [3:0]      shuffle_through;

  logic [31:0] shuffle_r1, shuffle_r0;
  logic [31:0] shuffle_r1_in, shuffle_r0_in;
  logic [31:0] shuffle_result;
  logic [31:0] pack_result;


  always_comb begin
    shuffle_reg_sel  = '0;
    shuffle_reg1_sel = 2'b01;
    shuffle_reg0_sel = 2'b10;
    shuffle_through  = '1;

    unique case (operator_i)
      ALU_EXT, ALU_EXTS: begin
        if (operator_i == ALU_EXTS) shuffle_reg1_sel = 2'b11;

        if (vector_mode_i == VEC_MODE8) begin
          shuffle_reg_sel[3:1] = 3'b111;
          shuffle_reg_sel[0]   = 1'b0;
        end else begin
          shuffle_reg_sel[3:2] = 2'b11;
          shuffle_reg_sel[1:0] = 2'b00;
        end
      end

      ALU_PCKLO: begin
        shuffle_reg1_sel = 2'b00;

        if (vector_mode_i == VEC_MODE8) begin
          shuffle_through = 4'b0011;
          shuffle_reg_sel = 4'b0001;
        end else begin
          shuffle_reg_sel = 4'b0011;
        end
      end

      ALU_PCKHI: begin
        shuffle_reg1_sel = 2'b00;

        if (vector_mode_i == VEC_MODE8) begin
          shuffle_through = 4'b1100;
          shuffle_reg_sel = 4'b0100;
        end else begin
          shuffle_reg_sel = 4'b0011;
        end
      end

      ALU_SHUF2: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_reg_sel[3] = ~operand_b_i[26];
            shuffle_reg_sel[2] = ~operand_b_i[18];
            shuffle_reg_sel[1] = ~operand_b_i[10];
            shuffle_reg_sel[0] = ~operand_b_i[2];
          end

          VEC_MODE16: begin
            shuffle_reg_sel[3] = ~operand_b_i[17];
            shuffle_reg_sel[2] = ~operand_b_i[17];
            shuffle_reg_sel[1] = ~operand_b_i[1];
            shuffle_reg_sel[0] = ~operand_b_i[1];
          end
          default: ;
        endcase
      end

      ALU_INS: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_reg0_sel = 2'b00;
            unique case (imm_vec_ext_i)
              2'b00: begin
                shuffle_reg_sel[3:0] = 4'b1110;
              end
              2'b01: begin
                shuffle_reg_sel[3:0] = 4'b1101;
              end
              2'b10: begin
                shuffle_reg_sel[3:0] = 4'b1011;
              end
              2'b11: begin
                shuffle_reg_sel[3:0] = 4'b0111;
              end
            endcase
          end
          VEC_MODE16: begin
            shuffle_reg0_sel   = 2'b01;
            shuffle_reg_sel[3] = ~imm_vec_ext_i[0];
            shuffle_reg_sel[2] = ~imm_vec_ext_i[0];
            shuffle_reg_sel[1] = imm_vec_ext_i[0];
            shuffle_reg_sel[0] = imm_vec_ext_i[0];
          end
          default: ;
        endcase
      end

      default: ;
    endcase
  end

  always_comb begin
    shuffle_byte_sel = '0;

    // byte selector
    unique case (operator_i)
      ALU_EXTS, ALU_EXT: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_byte_sel[3] = imm_vec_ext_i[1:0];
            shuffle_byte_sel[2] = imm_vec_ext_i[1:0];
            shuffle_byte_sel[1] = imm_vec_ext_i[1:0];
            shuffle_byte_sel[0] = imm_vec_ext_i[1:0];
          end

          VEC_MODE16: begin
            shuffle_byte_sel[3] = {imm_vec_ext_i[0], 1'b1};
            shuffle_byte_sel[2] = {imm_vec_ext_i[0], 1'b1};
            shuffle_byte_sel[1] = {imm_vec_ext_i[0], 1'b1};
            shuffle_byte_sel[0] = {imm_vec_ext_i[0], 1'b0};
          end

          default: ;
        endcase
      end

      ALU_PCKLO: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_byte_sel[3] = 2'b00;
            shuffle_byte_sel[2] = 2'b00;
            shuffle_byte_sel[1] = 2'b00;
            shuffle_byte_sel[0] = 2'b00;
          end

          VEC_MODE16: begin
            shuffle_byte_sel[3] = 2'b01;
            shuffle_byte_sel[2] = 2'b00;
            shuffle_byte_sel[1] = 2'b01;
            shuffle_byte_sel[0] = 2'b00;
          end

          default: ;
        endcase
      end

      ALU_PCKHI: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_byte_sel[3] = 2'b00;
            shuffle_byte_sel[2] = 2'b00;
            shuffle_byte_sel[1] = 2'b00;
            shuffle_byte_sel[0] = 2'b00;
          end

          VEC_MODE16: begin
            shuffle_byte_sel[3] = 2'b11;
            shuffle_byte_sel[2] = 2'b10;
            shuffle_byte_sel[1] = 2'b11;
            shuffle_byte_sel[0] = 2'b10;
          end

          default: ;
        endcase
      end

      ALU_SHUF2, ALU_SHUF: begin
        unique case (vector_mode_i)
          VEC_MODE8: begin
            shuffle_byte_sel[3] = operand_b_i[25:24];
            shuffle_byte_sel[2] = operand_b_i[17:16];
            shuffle_byte_sel[1] = operand_b_i[9:8];
            shuffle_byte_sel[0] = operand_b_i[1:0];
          end

          VEC_MODE16: begin
            shuffle_byte_sel[3] = {operand_b_i[16], 1'b1};
            shuffle_byte_sel[2] = {operand_b_i[16], 1'b0};
            shuffle_byte_sel[1] = {operand_b_i[0], 1'b1};
            shuffle_byte_sel[0] = {operand_b_i[0], 1'b0};
          end
          default: ;
        endcase
      end

      ALU_INS: begin
        shuffle_byte_sel[3] = 2'b11;
        shuffle_byte_sel[2] = 2'b10;
        shuffle_byte_sel[1] = 2'b01;
        shuffle_byte_sel[0] = 2'b00;
      end

      default: ;
    endcase
  end

  assign shuffle_r0_in = shuffle_reg0_sel[1] ?
                          operand_a_i :
                          (shuffle_reg0_sel[0] ? {2{operand_a_i[15:0]}} : {4{operand_a_i[7:0]}});

  assign shuffle_r1_in = shuffle_reg1_sel[1] ? {
    {8{operand_a_i[31]}}, {8{operand_a_i[23]}}, {8{operand_a_i[15]}}, {8{operand_a_i[7]}}
  } : (shuffle_reg1_sel[0] ? operand_c_i : operand_b_i);

  assign shuffle_r0[31:24] = shuffle_byte_sel[3][1] ?
                              (shuffle_byte_sel[3][0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) :
                              (shuffle_byte_sel[3][0] ? shuffle_r0_in[15: 8] : shuffle_r0_in[ 7: 0]);
  assign shuffle_r0[23:16] = shuffle_byte_sel[2][1] ?
                              (shuffle_byte_sel[2][0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) :
                              (shuffle_byte_sel[2][0] ? shuffle_r0_in[15: 8] : shuffle_r0_in[ 7: 0]);
  assign shuffle_r0[15: 8] = shuffle_byte_sel[1][1] ?
                              (shuffle_byte_sel[1][0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) :
                              (shuffle_byte_sel[1][0] ? shuffle_r0_in[15: 8] : shuffle_r0_in[ 7: 0]);
  assign shuffle_r0[ 7: 0] = shuffle_byte_sel[0][1] ?
                              (shuffle_byte_sel[0][0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) :
                              (shuffle_byte_sel[0][0] ? shuffle_r0_in[15: 8] : shuffle_r0_in[ 7: 0]);

  assign shuffle_r1[31:24] = shuffle_byte_sel[3][1] ?
                              (shuffle_byte_sel[3][0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) :
                              (shuffle_byte_sel[3][0] ? shuffle_r1_in[15: 8] : shuffle_r1_in[ 7: 0]);
  assign shuffle_r1[23:16] = shuffle_byte_sel[2][1] ?
                              (shuffle_byte_sel[2][0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) :
                              (shuffle_byte_sel[2][0] ? shuffle_r1_in[15: 8] : shuffle_r1_in[ 7: 0]);
  assign shuffle_r1[15: 8] = shuffle_byte_sel[1][1] ?
                              (shuffle_byte_sel[1][0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) :
                              (shuffle_byte_sel[1][0] ? shuffle_r1_in[15: 8] : shuffle_r1_in[ 7: 0]);
  assign shuffle_r1[ 7: 0] = shuffle_byte_sel[0][1] ?
                              (shuffle_byte_sel[0][0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) :
                              (shuffle_byte_sel[0][0] ? shuffle_r1_in[15: 8] : shuffle_r1_in[ 7: 0]);

  assign shuffle_result[31:24] = shuffle_reg_sel[3] ? shuffle_r1[31:24] : shuffle_r0[31:24];
  assign shuffle_result[23:16] = shuffle_reg_sel[2] ? shuffle_r1[23:16] : shuffle_r0[23:16];
  assign shuffle_result[15:8] = shuffle_reg_sel[1] ? shuffle_r1[15:8] : shuffle_r0[15:8];
  assign shuffle_result[7:0] = shuffle_reg_sel[0] ? shuffle_r1[7:0] : shuffle_r0[7:0];

  assign pack_result[31:24] = shuffle_through[3] ? shuffle_result[31:24] : operand_c_i[31:24];
  assign pack_result[23:16] = shuffle_through[2] ? shuffle_result[23:16] : operand_c_i[23:16];
  assign pack_result[15:8] = shuffle_through[1] ? shuffle_result[15:8] : operand_c_i[15:8];
  assign pack_result[7:0] = shuffle_through[0] ? shuffle_result[7:0] : operand_c_i[7:0];


  /////////////////////////////////////////////////////////////////////
  //   ____  _ _      ____                  _      ___               //
  //  | __ )(_) |_   / ___|___  _   _ _ __ | |_   / _ \ _ __  ___    //
  //  |  _ \| | __| | |   / _ \| | | | '_ \| __| | | | | '_ \/ __|   //
  //  | |_) | | |_  | |__| (_) | |_| | | | | |_  | |_| | |_) \__ \_  //
  //  |____/|_|\__|  \____\___/ \__,_|_| |_|\__|  \___/| .__/|___(_) //
  //                                                   |_|           //
  /////////////////////////////////////////////////////////////////////

  logic [31:0] ff_input;  // either op_a_i or its bit reversed version
  logic [ 5:0] cnt_result;  // population count
  logic [ 5:0] clb_result;  // count leading bits
  logic [ 4:0] ff1_result;  // holds the index of the first '1'
  logic        ff_no_one;  // if no ones are found
  logic [ 4:0] fl1_result;  // holds the index of the last '1'
  logic [ 5:0] bitop_result;  // result of all bitop operations muxed together

  cv32e40p_popcnt popcnt_i (
      .in_i    (operand_a_i),
      .result_o(cnt_result)
  );

  always_comb begin
    ff_input = '0;

    case (operator_i)
      ALU_FF1: ff_input = operand_a_i;

      ALU_DIVU, ALU_REMU, ALU_FL1: ff_input = operand_a_rev;

      ALU_DIV, ALU_REM, ALU_CLB: begin
        if (operand_a_i[31]) ff_input = operand_a_neg_rev;
        else ff_input = operand_a_rev;
      end
    endcase
  end

  cv32e40p_ff_one ff_one_i (
      .in_i       (ff_input),
      .first_one_o(ff1_result),
      .no_ones_o  (ff_no_one)
  );

  // special case if ff1_res is 0 (no 1 found), then we keep the 0
  // this is done in the result mux
  assign fl1_result = 5'd31 - ff1_result;
  assign clb_result = ff1_result - 5'd1;

  always_comb begin
    bitop_result = '0;
    case (operator_i)
      ALU_FF1: bitop_result = ff_no_one ? 6'd32 : {1'b0, ff1_result};
      ALU_FL1: bitop_result = ff_no_one ? 6'd32 : {1'b0, fl1_result};
      ALU_CNT: bitop_result = cnt_result;
      ALU_CLB: begin
        if (ff_no_one) begin
          if (operand_a_i[31]) bitop_result = 6'd31;
          else bitop_result = '0;
        end else begin
          bitop_result = clb_result;
        end
      end
      default: ;
    endcase
  end


  ////////////////////////////////////////////////
  //  ____  _ _     __  __             _        //
  // | __ )(_) |_  |  \/  | __ _ _ __ (_)_ __   //
  // |  _ \| | __| | |\/| |/ _` | '_ \| | '_ \  //
  // | |_) | | |_  | |  | | (_| | | | | | |_) | //
  // |____/|_|\__| |_|  |_|\__,_|_| |_|_| .__/  //
  //                                    |_|     //
  ////////////////////////////////////////////////

  logic extract_is_signed;
  logic extract_sign;
  logic [31:0] bmask_first, bmask_inv;
  logic [31:0] bextins_and;
  logic [31:0] bextins_result, bclr_result, bset_result;


  // construct bit mask for insert/extract/bclr/bset
  // bmask looks like this 00..0011..1100..00
  assign bmask_first       = {32'hFFFFFFFE} << bmask_a_i;
  assign bmask             = (~bmask_first) << bmask_b_i;
  assign bmask_inv         = ~bmask;

  assign bextins_and       = (operator_i == ALU_BINS) ? operand_c_i : {32{extract_sign}};

  assign extract_is_signed = (operator_i == ALU_BEXT);
  assign extract_sign      = extract_is_signed & shift_result[bmask_a_i];

  assign bextins_result    = (bmask & shift_result) | (bextins_and & bmask_inv);

  assign bclr_result       = operand_a_i & bmask_inv;
  assign bset_result       = operand_a_i | bmask;

  /////////////////////////////////////////////////////////////////////////////////
  //  ____ _____ _______     _____  ________      ________ _____   _____ ______  //
  // |  _ \_   _|__   __|   |  __ \|  ____\ \    / /  ____|  __ \ / ____|  ____| //
  // | |_) || |    | |______| |__) | |__   \ \  / /| |__  | |__) | (___ | |__    //
  // |  _ < | |    | |______|  _  /|  __|   \ \/ / |  __| |  _  / \___ \|  __|   //
  // | |_) || |_   | |      | | \ \| |____   \  /  | |____| | \ \ ____) | |____  //
  // |____/_____|  |_|      |_|  \_\______|   \/   |______|_|  \_\_____/|______| //
  //                                                                             //
  /////////////////////////////////////////////////////////////////////////////////

  logic [31:0] radix_2_rev;
  logic [31:0] radix_4_rev;
  logic [31:0] radix_8_rev;
  logic [31:0] reverse_result;
  logic [ 1:0] radix_mux_sel;

  assign radix_mux_sel = bmask_a_i[1:0];

  generate
    // radix-2 bit reverse
    for (j = 0; j < 32; j++) begin : gen_radix_2_rev
      assign radix_2_rev[j] = shift_result[31-j];
    end
    // radix-4 bit reverse
    for (j = 0; j < 16; j++) begin : gen_radix_4_rev
      assign radix_4_rev[2*j+1:2*j] = shift_result[31-j*2:31-j*2-1];
    end
    // radix-8 bit reverse
    for (j = 0; j < 10; j++) begin : gen_radix_8_rev
      assign radix_8_rev[3*j+2:3*j] = shift_result[31-j*3:31-j*3-2];
    end
    assign radix_8_rev[31:30] = 2'b0;
  endgenerate

  always_comb begin
    reverse_result = '0;

    unique case (radix_mux_sel)
      2'b00: reverse_result = radix_2_rev;
      2'b01: reverse_result = radix_4_rev;
      2'b10: reverse_result = radix_8_rev;

      default: reverse_result = radix_2_rev;
    endcase
  end

  ////////////////////////////////////////////////////
  //  ____ _____     __     __  ____  _____ __  __  //
  // |  _ \_ _\ \   / /    / / |  _ \| ____|  \/  | //
  // | | | | | \ \ / /    / /  | |_) |  _| | |\/| | //
  // | |_| | |  \ V /    / /   |  _ <| |___| |  | | //
  // |____/___|  \_/    /_/    |_| \_\_____|_|  |_| //
  //                                                //
  ////////////////////////////////////////////////////

  logic [31:0] result_div;
  logic        div_ready;
  logic        div_signed;
  logic        div_op_a_signed;
  logic [ 5:0] div_shift_int;

  assign div_signed = operator_i[0];

  assign div_op_a_signed = operand_a_i[31] & div_signed;

  assign div_shift_int = ff_no_one ? 6'd31 : clb_result;
  assign div_shift = div_shift_int + (div_op_a_signed ? 6'd0 : 6'd1);

  assign div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                     (operator_i == ALU_REM) || (operator_i == ALU_REMU));

  // inputs A and B are swapped
  cv32e40p_alu_div alu_div_i (
      .Clk_CI (clk),
      .Rst_RBI(rst_n),

      // input IF
      .OpA_DI      (operand_b_i),
      .OpB_DI      (shift_left_result),
      .OpBShift_DI (div_shift),
      .OpBIsZero_SI((cnt_result == 0)),

      .OpBSign_SI(div_op_a_signed),
      .OpCode_SI (operator_i[1:0]),

      .Res_DO(result_div),

      // Hand-Shake
      .InVld_SI (div_valid),
      .OutRdy_SI(ex_ready_i),
      .OutVld_SO(div_ready)
  );

  ////////////////////////////////////////////////////////
  //   ____                 _ _     __  __              //
  //  |  _ \ ___  ___ _   _| | |_  |  \/  |_   ___  __  //
  //  | |_) / _ \/ __| | | | | __| | |\/| | | | \ \/ /  //
  //  |  _ <  __/\__ \ |_| | | |_  | |  | | |_| |>  <   //
  //  |_| \_\___||___/\__,_|_|\__| |_|  |_|\__,_/_/\_\  //
  //                                                    //
  ////////////////////////////////////////////////////////

  always_comb begin
    result_o = '0;

    unique case (operator_i)
      // Standard Operations
      ALU_AND: result_o = operand_a_i & operand_b_i;
      ALU_OR:  result_o = operand_a_i | operand_b_i;
      ALU_XOR: result_o = operand_a_i ^ operand_b_i;

      // Shift Operations
      ALU_ADD, ALU_ADDR, ALU_ADDU, ALU_ADDUR,
      ALU_SUB, ALU_SUBR, ALU_SUBU, ALU_SUBUR,
      ALU_SLL,
      ALU_SRL, ALU_SRA,
      ALU_ROR:
      result_o = shift_result;

      // bit manipulation instructions
      ALU_BINS, ALU_BEXT, ALU_BEXTU: result_o = bextins_result;

      ALU_BCLR: result_o = bclr_result;
      ALU_BSET: result_o = bset_result;

      // Bit reverse instruction
      ALU_BREV: result_o = reverse_result;

      // pack and shuffle operations
      ALU_SHUF, ALU_SHUF2, ALU_PCKLO, ALU_PCKHI, ALU_EXT, ALU_EXTS, ALU_INS: result_o = pack_result;

      // Min/Max/Ins
      ALU_MIN, ALU_MINU, ALU_MAX, ALU_MAXU: result_o = result_minmax;

      //Abs/Cplxconj , ABS is used to do 0 - A for Cplxconj
      ALU_ABS: result_o = is_clpx_i ? {adder_result[31:16], operand_a_i[15:0]} : result_minmax;

      ALU_CLIP, ALU_CLIPU: result_o = clip_result;

      // Comparison Operations
      ALU_EQ, ALU_NE, ALU_GTU, ALU_GEU, ALU_LTU, ALU_LEU, ALU_GTS, ALU_GES, ALU_LTS, ALU_LES: begin
        result_o[31:24] = {8{cmp_result[3]}};
        result_o[23:16] = {8{cmp_result[2]}};
        result_o[15:8]  = {8{cmp_result[1]}};
        result_o[7:0]   = {8{cmp_result[0]}};
      end
      // Non-vector comparisons
      ALU_SLTS, ALU_SLTU, ALU_SLETS, ALU_SLETU: result_o = {31'b0, comparison_result_o};

      ALU_FF1, ALU_FL1, ALU_CLB, ALU_CNT: result_o = {26'h0, bitop_result[5:0]};

      // Division Unit Commands
      ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU: result_o = result_div;

      default: ;  // default case to suppress unique warning
    endcase
  end

  assign ready_o = div_ready;

endmodule

// -------------------- END OF rtl/cv32e40p_alu.sv --------------------

// -------------------- START OF rtl/cv32e40p_alu_div.sv --------------------
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///////////////////////////////////////////////////////////////////////////////
// File       : Simple Serial Divider
// Ver        : 1.0
// Date       : 15.03.2016
///////////////////////////////////////////////////////////////////////////////
//
// Description: this is a simple serial divider for signed integers (int32).
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Michael Schaffner (schaffner@iis.ee.ethz.ch)
//              Andreas Traber    (atraber@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module cv32e40p_alu_div #(
    parameter C_WIDTH     = 32,
    parameter C_LOG_WIDTH = 6
) (
    input  logic                   Clk_CI,
    input  logic                   Rst_RBI,
    // input IF
    input  logic [    C_WIDTH-1:0] OpA_DI,
    input  logic [    C_WIDTH-1:0] OpB_DI,
    input  logic [C_LOG_WIDTH-1:0] OpBShift_DI,
    input  logic                   OpBIsZero_SI,
    //
    input  logic                   OpBSign_SI,  // gate this to 0 in case of unsigned ops
    input  logic [            1:0] OpCode_SI,  // 0: udiv, 2: urem, 1: div, 3: rem
    // handshake
    input  logic                   InVld_SI,
    // output IF
    input  logic                   OutRdy_SI,
    output logic                   OutVld_SO,
    output logic [    C_WIDTH-1:0] Res_DO
);

  ///////////////////////////////////////////////////////////////////////////////
  // signal declarations
  ///////////////////////////////////////////////////////////////////////////////

  logic [C_WIDTH-1:0] ResReg_DP, ResReg_DN;
  logic [C_WIDTH-1:0] ResReg_DP_rev;
  logic [C_WIDTH-1:0] AReg_DP, AReg_DN;
  logic [C_WIDTH-1:0] BReg_DP, BReg_DN;

  logic RemSel_SN, RemSel_SP;
  logic CompInv_SN, CompInv_SP;
  logic ResInv_SN, ResInv_SP;

  logic [C_WIDTH-1:0] AddMux_D;
  logic [C_WIDTH-1:0] AddOut_D;
  logic [C_WIDTH-1:0] AddTmp_D;
  logic [C_WIDTH-1:0] BMux_D;
  logic [C_WIDTH-1:0] OutMux_D;

  logic [C_LOG_WIDTH-1:0] Cnt_DP, Cnt_DN;
  logic CntZero_S;

  logic ARegEn_S, BRegEn_S, ResRegEn_S, ABComp_S, PmSel_S, LoadEn_S;

  enum logic [1:0] {
    IDLE,
    DIVIDE,
    FINISH
  }
      State_SN, State_SP;


  ///////////////////////////////////////////////////////////////////////////////
  // datapath
  ///////////////////////////////////////////////////////////////////////////////

  assign PmSel_S  = LoadEn_S & ~(OpCode_SI[0] & (OpA_DI[$high(OpA_DI)] ^ OpBSign_SI));

  // muxes
  assign AddMux_D = (LoadEn_S) ? OpA_DI : BReg_DP;

  // attention: logical shift in case of negative operand B!
  assign BMux_D   = (LoadEn_S) ? OpB_DI : {CompInv_SP, (BReg_DP[$high(BReg_DP):1])};

  genvar index;
  generate
    for (index = 0; index < C_WIDTH; index++) begin : gen_bit_swapping
      assign ResReg_DP_rev[index] = ResReg_DP[C_WIDTH-1-index];
    end
  endgenerate

  assign OutMux_D = (RemSel_SP) ? AReg_DP : ResReg_DP_rev;

  // invert if necessary
  assign Res_DO = (ResInv_SP) ? -$signed(OutMux_D) : OutMux_D;

  // main comparator
  assign ABComp_S    = ((AReg_DP == BReg_DP) | ((AReg_DP > BReg_DP) ^ CompInv_SP)) & ((|AReg_DP) | OpBIsZero_SI);

  // main adder
  assign AddTmp_D = (LoadEn_S) ? 0 : AReg_DP;
  assign AddOut_D = (PmSel_S) ? AddTmp_D + AddMux_D : AddTmp_D - $signed(AddMux_D);

  ///////////////////////////////////////////////////////////////////////////////
  // counter
  ///////////////////////////////////////////////////////////////////////////////

  assign Cnt_DN = (LoadEn_S) ? OpBShift_DI : (~CntZero_S) ? Cnt_DP - 1 : Cnt_DP;

  assign CntZero_S = ~(|Cnt_DP);

  ///////////////////////////////////////////////////////////////////////////////
  // FSM
  ///////////////////////////////////////////////////////////////////////////////

  always_comb begin : p_fsm
    // default
    State_SN   = State_SP;

    OutVld_SO  = 1'b0;

    LoadEn_S   = 1'b0;

    ARegEn_S   = 1'b0;
    BRegEn_S   = 1'b0;
    ResRegEn_S = 1'b0;

    case (State_SP)
      /////////////////////////////////
      IDLE: begin
        OutVld_SO = 1'b1;

        if (InVld_SI) begin
          OutVld_SO = 1'b0;
          ARegEn_S  = 1'b1;
          BRegEn_S  = 1'b1;
          LoadEn_S  = 1'b1;
          State_SN  = DIVIDE;
        end
      end
      /////////////////////////////////
      DIVIDE: begin

        ARegEn_S   = ABComp_S;
        BRegEn_S   = 1'b1;
        ResRegEn_S = 1'b1;

        // calculation finished
        // one more divide cycle (32nd divide cycle)
        if (CntZero_S) begin
          State_SN = FINISH;
        end
      end
      /////////////////////////////////
      FINISH: begin
        OutVld_SO = 1'b1;

        if (OutRdy_SI) begin
          State_SN = IDLE;
        end
      end
      /////////////////////////////////
      default:  /* default */;
      /////////////////////////////////
    endcase
  end


  ///////////////////////////////////////////////////////////////////////////////
  // regs
  ///////////////////////////////////////////////////////////////////////////////

  // get flags
  assign RemSel_SN = (LoadEn_S) ? OpCode_SI[1] : RemSel_SP;
  assign CompInv_SN = (LoadEn_S) ? OpBSign_SI : CompInv_SP;
  assign ResInv_SN = (LoadEn_S) ? (~OpBIsZero_SI | OpCode_SI[1]) & OpCode_SI[0] & (OpA_DI[$high(
      OpA_DI
  )] ^ OpBSign_SI) : ResInv_SP;

  assign AReg_DN = (ARegEn_S) ? AddOut_D : AReg_DP;
  assign BReg_DN = (BRegEn_S) ? BMux_D : BReg_DP;
  assign ResReg_DN = (LoadEn_S) ? '0 : (ResRegEn_S) ? {
    ABComp_S, ResReg_DP[$high(ResReg_DP):1]
  } : ResReg_DP;

  always_ff @(posedge Clk_CI or negedge Rst_RBI) begin : p_regs
    if (~Rst_RBI) begin
      State_SP   <= IDLE;
      AReg_DP    <= '0;
      BReg_DP    <= '0;
      ResReg_DP  <= '0;
      Cnt_DP     <= '0;
      RemSel_SP  <= 1'b0;
      CompInv_SP <= 1'b0;
      ResInv_SP  <= 1'b0;
    end else begin
      State_SP   <= State_SN;
      AReg_DP    <= AReg_DN;
      BReg_DP    <= BReg_DN;
      ResReg_DP  <= ResReg_DN;
      Cnt_DP     <= Cnt_DN;
      RemSel_SP  <= RemSel_SN;
      CompInv_SP <= CompInv_SN;
      ResInv_SP  <= ResInv_SN;
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // assertions
  ///////////////////////////////////////////////////////////////////////////////

`ifdef CV32E40P_ASSERT_ON
  initial begin : p_assertions
    assert (C_LOG_WIDTH == $clog2(C_WIDTH + 1))
    else $error("C_LOG_WIDTH must be $clog2(C_WIDTH+1)");
  end
`endif

endmodule  // serDiv

// -------------------- END OF rtl/cv32e40p_alu_div.sv --------------------

// -------------------- START OF rtl/cv32e40p_apu_disp.sv --------------------
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
// Engineer:       Lukas Mueller - lukasmue@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Simple APU dispatcher                                      //
// Project Name:   PULP                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Dispatcher for sending instructions to the Marx            //
//                 interconnect.                                              //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_apu_disp (
    input logic clk_i,
    input logic rst_ni,

    // request input
    input logic       enable_i,
    input logic [1:0] apu_lat_i,
    input logic [5:0] apu_waddr_i,

    // response output
    output logic [5:0] apu_waddr_o,
    output logic       apu_multicycle_o,
    output logic       apu_singlecycle_o,

    // active signal
    output logic active_o,

    // stall signals
    output logic stall_o,

    // dependency checks
    input  logic            is_decoding_i,
    input  logic [2:0][5:0] read_regs_i,
    input  logic [2:0]      read_regs_valid_i,
    output logic            read_dep_o,
    output logic            read_dep_for_jalr_o,

    input  logic [1:0][5:0] write_regs_i,
    input  logic [1:0]      write_regs_valid_i,
    output logic            write_dep_o,

    // perf counter stuff
    output logic perf_type_o,
    output logic perf_cont_o,

    // apu-interconnect
    // handshake signals
    output logic apu_req_o,
    input  logic apu_gnt_i,
    // response channel
    input  logic apu_rvalid_i

);

  logic [5:0] addr_req, addr_inflight, addr_waiting;
  logic [5:0] addr_inflight_dn, addr_waiting_dn;
  logic valid_req, valid_inflight, valid_waiting;
  logic valid_inflight_dn, valid_waiting_dn;
  logic returned_req, returned_inflight, returned_waiting;

  logic       req_accepted;
  logic       active;
  logic [1:0] apu_lat;


  logic [2:0] read_deps_req, read_deps_inflight, read_deps_waiting;
  logic [1:0] write_deps_req, write_deps_inflight, write_deps_waiting;
  logic read_dep_req, read_dep_inflight, read_dep_waiting;
  logic write_dep_req, write_dep_inflight, write_dep_waiting;

  logic stall_full, stall_type, stall_nack;

  // Generate request signal; do not generate request if stalled unless it's a nack stall
  assign valid_req         = enable_i & !(stall_full | stall_type);
  assign addr_req          = apu_waddr_i;

  assign req_accepted      = valid_req & apu_gnt_i;

  //
  // In-flight instructions
  //
  // Check whether the instructions have returned
  assign returned_req      = valid_req & apu_rvalid_i & !valid_inflight & !valid_waiting;
  assign returned_inflight = valid_inflight & (apu_rvalid_i) & !valid_waiting;
  assign returned_waiting  = valid_waiting & (apu_rvalid_i);

  // Inflight and waiting registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      valid_inflight <= 1'b0;
      valid_waiting  <= 1'b0;
      addr_inflight  <= '0;
      addr_waiting   <= '0;
    end else begin
      valid_inflight <= valid_inflight_dn;
      valid_waiting  <= valid_waiting_dn;
      addr_inflight  <= addr_inflight_dn;
      addr_waiting   <= addr_waiting_dn;
    end
  end

  always_comb begin
    valid_inflight_dn = valid_inflight;
    valid_waiting_dn  = valid_waiting;
    addr_inflight_dn  = addr_inflight;
    addr_waiting_dn   = addr_waiting;

    if (req_accepted & !returned_req) begin  // this is a multicycle request
      valid_inflight_dn = 1'b1;
      addr_inflight_dn  = addr_req;
      if (valid_inflight & !(returned_inflight)) begin  // we already have an inflight instruction!
        valid_waiting_dn = 1'b1;
        addr_waiting_dn  = addr_inflight;
      end
      if (returned_waiting) begin // we have received a new request and waiting goes out of the pipe but will be refilled
        valid_waiting_dn = 1'b1;
        addr_waiting_dn  = addr_inflight;
      end
    end // no new request
     else if (returned_inflight) begin // multicycle request has returned
      valid_inflight_dn = '0;
      valid_waiting_dn  = '0;
      addr_inflight_dn  = '0;
      addr_waiting_dn   = '0;
    end else if (returned_waiting) begin  // multicycle request has returned
      valid_waiting_dn = '0;
      addr_waiting_dn  = '0;
    end
  end

  //
  // Active type
  //
  // Dispatcher is active when there is an unreturned instruction
  assign active = valid_inflight | valid_waiting;

  // Store the latency type whenever there is a request
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      apu_lat <= '0;
    end else begin
      if (valid_req) begin
        apu_lat <= apu_lat_i;
      end
    end
  end

  //
  // Dependency checks
  //
  // There is a dependency if the register is equal to one of the instructions
  generate
    for (genvar i = 0; i < 3; i++) begin : gen_read_deps
      assign read_deps_req[i]      = (read_regs_i[i] == addr_req) & read_regs_valid_i[i];
      assign read_deps_inflight[i] = (read_regs_i[i] == addr_inflight) & read_regs_valid_i[i];
      assign read_deps_waiting[i]  = (read_regs_i[i] == addr_waiting) & read_regs_valid_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2; i++) begin : gen_write_deps
      assign write_deps_req[i]      = (write_regs_i[i] == addr_req) & write_regs_valid_i[i];
      assign write_deps_inflight[i] = (write_regs_i[i] == addr_inflight) & write_regs_valid_i[i];
      assign write_deps_waiting[i]  = (write_regs_i[i] == addr_waiting) & write_regs_valid_i[i];
    end
  endgenerate

  // Reduce the individual dependency signals into one read and one write dependency
  assign read_dep_req = |read_deps_req & valid_req & !returned_req;
  assign read_dep_inflight = |read_deps_inflight & valid_inflight & !returned_inflight;
  assign read_dep_waiting = |read_deps_waiting & valid_waiting & !returned_waiting;
  assign write_dep_req = |write_deps_req & valid_req & !returned_req;
  assign write_dep_inflight = |write_deps_inflight & valid_inflight & !returned_inflight;
  assign write_dep_waiting = |write_deps_waiting & valid_waiting & !returned_waiting;

  assign read_dep_o = (read_dep_req | read_dep_inflight | read_dep_waiting) & is_decoding_i;
  assign write_dep_o = (write_dep_req | write_dep_inflight | write_dep_waiting) & is_decoding_i;

  assign read_dep_for_jalr_o = is_decoding_i & ((|read_deps_req & enable_i) |
                                                (|read_deps_inflight & valid_inflight) |
                                                (|read_deps_waiting & valid_waiting));

  //
  // Stall signals
  //
  // Stall if we cannot store any more outstanding requests
  assign stall_full = valid_inflight & valid_waiting;
  // Stall if there is a type conflict. if apu is active we can only issue requests with a larger or equal latency
  // than the latency of the inflight operation (apu_lat_i>=apu_lat). otherwise operations would overtake each other!
  // so we stall if: (apu_lat_i = 1 & apu_lat = 2/3) | (apu_lat_i = 2 & apu_lat = 3) | (apu_lat_i = 3 (multicycle))
  assign stall_type      = enable_i  & active & ((apu_lat_i==2'h1) | ((apu_lat_i==2'h2) & (apu_lat==2'h3)) | (apu_lat_i==2'h3));
  assign stall_nack = valid_req & !apu_gnt_i;
  assign stall_o = stall_full | stall_type | stall_nack;

  //
  // Generate Apu_master request
  //
  assign apu_req_o = valid_req;


  // Determine write register based on where the instruction returned.
  always_comb begin
    apu_waddr_o = '0;
    if (returned_req) apu_waddr_o = addr_req;
    if (returned_inflight) apu_waddr_o = addr_inflight;
    if (returned_waiting) apu_waddr_o = addr_waiting;
  end

  // Output active signal
  assign active_o = active;

  // Performance counter signals
  assign perf_type_o = stall_type;
  assign perf_cont_o = stall_nack;

  assign apu_multicycle_o = (apu_lat == 2'h3);
  assign apu_singlecycle_o = ~(valid_inflight | valid_waiting);

  //
  // Assertions
  //

`ifdef CV32E40P_ASSERT_ON
  assert property (@(posedge clk_i) (apu_rvalid_i) |-> (valid_req | valid_inflight | valid_waiting))
  else $warning("[APU Dispatcher] instruction returned while no instruction is in-flight");
`endif

endmodule

// -------------------- END OF rtl/cv32e40p_apu_disp.sv --------------------

// -------------------- START OF rtl/cv32e40p_compressed_decoder.sv --------------------
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
// Engineer:       Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
// Additional contributions by:                                               //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Compressed instruction decoder                             //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decodes RISC-V compressed instructions into their RV32     //
//                 equivalent. This module is fully combinatorial.            //
//                 Float extensions added                                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_compressed_decoder #(
    parameter FPU   = 0,
    parameter ZFINX = 0
) (
    input  logic [31:0] instr_i,
    output logic [31:0] instr_o,
    output logic        is_compressed_o,
    output logic        illegal_instr_o
);

  import cv32e40p_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  //   ____                                                 _   ____                     _            //
  //  / ___|___  _ __ ___  _ __  _ __ ___  ___ ___  ___  __| | |  _ \  ___  ___ ___   __| | ___ _ __  //
  // | |   / _ \| '_ ` _ \| '_ \| '__/ _ \/ __/ __|/ _ \/ _` | | | | |/ _ \/ __/ _ \ / _` |/ _ \ '__| //
  // | |__| (_) | | | | | | |_) | | |  __/\__ \__ \  __/ (_| | | |_| |  __/ (_| (_) | (_| |  __/ |    //
  //  \____\___/|_| |_| |_| .__/|_|  \___||___/___/\___|\__,_| |____/ \___|\___\___/ \__,_|\___|_|    //
  //                      |_|                                                                         //
  //////////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    illegal_instr_o = 1'b0;
    instr_o         = '0;

    unique case (instr_i[1:0])
      // C0
      2'b00: begin
        unique case (instr_i[15:13])
          3'b000: begin
            // c.addi4spn -> addi rd', x2, imm
            instr_o = {
              2'b0,
              instr_i[10:7],
              instr_i[12:11],
              instr_i[5],
              instr_i[6],
              2'b00,
              5'h02,
              3'b000,
              2'b01,
              instr_i[4:2],
              OPCODE_OPIMM
            };
            if (instr_i[12:5] == 8'b0) illegal_instr_o = 1'b1;
          end

          3'b001: begin
            // c.fld -> fld rd', imm(rs1')
            if (FPU == 1 && ZFINX == 0)
              // instr_i[12:10]-> offset[5:3],  instr_i[6:5]-> offset[7:6]
              instr_o = {
                4'b0,
                instr_i[6:5],
                instr_i[12:10],
                3'b000,
                2'b01,
                instr_i[9:7],
                3'b011,
                2'b01,
                instr_i[4:2],
                OPCODE_LOAD_FP
              };
            else illegal_instr_o = 1'b1;
          end

          3'b010: begin
            // c.lw -> lw rd', imm(rs1')
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12:10],
              instr_i[6],
              2'b00,
              2'b01,
              instr_i[9:7],
              3'b010,
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD
            };
          end

          3'b011: begin
            // c.flw -> flw rd', imm(rs1')
            if (FPU == 1 && ZFINX == 0)
              instr_o = {
                5'b0,
                instr_i[5],
                instr_i[12:10],
                instr_i[6],
                2'b00,
                2'b01,
                instr_i[9:7],
                3'b010,
                2'b01,
                instr_i[4:2],
                OPCODE_LOAD_FP
              };
            else illegal_instr_o = 1'b1;
          end

          3'b101: begin
            // c.fsd -> fsd rs2', imm(rs1')
            if (FPU == 1 && ZFINX == 0)
              // instr_i[12:10] -> offset[5:3], instr_i[6:5] -> offset[7:6]
              instr_o = {
                4'b0,
                instr_i[6:5],
                instr_i[12],
                2'b01,
                instr_i[4:2],
                2'b01,
                instr_i[9:7],
                3'b011,
                instr_i[11:10],
                3'b000,
                OPCODE_STORE_FP
              };
            else illegal_instr_o = 1'b1;
          end

          3'b110: begin
            // c.sw -> sw rs2', imm(rs1')
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b010,
              instr_i[11:10],
              instr_i[6],
              2'b00,
              OPCODE_STORE
            };
          end

          3'b111: begin
            // c.fsw -> fsw rs2', imm(rs1')
            if (FPU == 1 && ZFINX == 0)
              instr_o = {
                5'b0,
                instr_i[5],
                instr_i[12],
                2'b01,
                instr_i[4:2],
                2'b01,
                instr_i[9:7],
                3'b010,
                instr_i[11:10],
                instr_i[6],
                2'b00,
                OPCODE_STORE_FP
              };
            else illegal_instr_o = 1'b1;
          end
          default: begin
            illegal_instr_o = 1'b1;
          end
        endcase
      end


      // C1
      2'b01: begin
        unique case (instr_i[15:13])
          3'b000: begin
            // c.addi -> addi rd, rd, nzimm
            // c.nop
            instr_o = {
              {6{instr_i[12]}},
              instr_i[12],
              instr_i[6:2],
              instr_i[11:7],
              3'b0,
              instr_i[11:7],
              OPCODE_OPIMM
            };
          end

          3'b001, 3'b101: begin
            // 001: c.jal -> jal x1, imm
            // 101: c.j   -> jal x0, imm
            instr_o = {
              instr_i[12],
              instr_i[8],
              instr_i[10:9],
              instr_i[6],
              instr_i[7],
              instr_i[2],
              instr_i[11],
              instr_i[5:3],
              {9{instr_i[12]}},
              4'b0,
              ~instr_i[15],
              OPCODE_JAL
            };
          end

          3'b010: begin
            if (instr_i[11:7] == 5'b0) begin
              // Hint -> addi x0, x0, nzimm
              instr_o = {
                {6{instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OPIMM
              };
            end else begin
              // c.li -> addi rd, x0, nzimm
              instr_o = {
                {6{instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OPIMM
              };
            end
          end

          3'b011: begin
            if ({instr_i[12], instr_i[6:2]} == 6'b0) begin
              illegal_instr_o = 1'b1;
            end else begin
              if (instr_i[11:7] == 5'h02) begin
                // c.addi16sp -> addi x2, x2, nzimm
                instr_o = {
                  {3{instr_i[12]}},
                  instr_i[4:3],
                  instr_i[5],
                  instr_i[2],
                  instr_i[6],
                  4'b0,
                  5'h02,
                  3'b000,
                  5'h02,
                  OPCODE_OPIMM
                };
              end else if (instr_i[11:7] == 5'b0) begin
                // Hint -> lui x0, imm
                instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
              end else begin
                // c.lui -> lui rd, imm
                instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
              end
            end
          end

          3'b100: begin
            unique case (instr_i[11:10])
              2'b00, 2'b01: begin
                // 00: c.srli -> srli rd, rd, shamt
                // 01: c.srai -> srai rd, rd, shamt
                if (instr_i[12] == 1'b1) begin
                  // Reserved for future custom extensions (instr_o don't care)
                  instr_o = {
                    1'b0,
                    instr_i[10],
                    5'b0,
                    instr_i[6:2],
                    2'b01,
                    instr_i[9:7],
                    3'b101,
                    2'b01,
                    instr_i[9:7],
                    OPCODE_OPIMM
                  };
                  illegal_instr_o = 1'b1;
                end else begin
                  if (instr_i[6:2] == 5'b0) begin
                    // Hint
                    instr_o = {
                      1'b0,
                      instr_i[10],
                      5'b0,
                      instr_i[6:2],
                      2'b01,
                      instr_i[9:7],
                      3'b101,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OPIMM
                    };
                  end else begin
                    instr_o = {
                      1'b0,
                      instr_i[10],
                      5'b0,
                      instr_i[6:2],
                      2'b01,
                      instr_i[9:7],
                      3'b101,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OPIMM
                    };
                  end
                end
              end

              2'b10: begin
                // c.andi -> andi rd, rd, imm
                instr_o = {
                  {6{instr_i[12]}},
                  instr_i[12],
                  instr_i[6:2],
                  2'b01,
                  instr_i[9:7],
                  3'b111,
                  2'b01,
                  instr_i[9:7],
                  OPCODE_OPIMM
                };
              end

              2'b11: begin
                unique case ({
                  instr_i[12], instr_i[6:5]
                })
                  3'b000: begin
                    // c.sub -> sub rd', rd', rs2'
                    instr_o = {
                      2'b01,
                      5'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b000,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b001: begin
                    // c.xor -> xor rd', rd', rs2'
                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b100,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b010: begin
                    // c.or  -> or  rd', rd', rs2'
                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b110,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b011: begin
                    // c.and -> and rd', rd', rs2'
                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b111,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b100, 3'b101, 3'b110, 3'b111: begin
                    // 100: c.subw
                    // 101: c.addw
                    illegal_instr_o = 1'b1;
                  end
                endcase
              end
            endcase
          end

          3'b110, 3'b111: begin
            // 0: c.beqz -> beq rs1', x0, imm
            // 1: c.bnez -> bne rs1', x0, imm
            instr_o = {
              {4{instr_i[12]}},
              instr_i[6:5],
              instr_i[2],
              5'b0,
              2'b01,
              instr_i[9:7],
              2'b00,
              instr_i[13],
              instr_i[11:10],
              instr_i[4:3],
              instr_i[12],
              OPCODE_BRANCH
            };
          end
        endcase
      end

      // C2
      2'b10: begin
        unique case (instr_i[15:13])
          3'b000: begin
            if (instr_i[12] == 1'b1) begin
              // Reserved for future extensions (instr_o don't care)
              instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              illegal_instr_o = 1'b1;
            end else begin
              if ((instr_i[6:2] == 5'b0) || (instr_i[11:7] == 5'b0)) begin
                // Hint -> slli rd, rd, shamt 
                instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              end else begin
                // c.slli -> slli rd, rd, shamt
                instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              end
            end
          end

          3'b001: begin
            // c.fldsp -> fld rd, imm(x2)
            if (FPU == 1 && ZFINX == 0)
              // instr_i[6:5] -> offset[4:3], instr_i[4:2] -> offset[8:6], instr_i[12] -> offset[5]
              instr_o = {
                3'b0,
                instr_i[4:2],
                instr_i[12],
                instr_i[6:5],
                3'b000,
                5'h02,
                3'b011,
                instr_i[11:7],
                OPCODE_LOAD_FP
              };
            else illegal_instr_o = 1'b1;
          end

          3'b010: begin
            // c.lwsp -> lw rd, imm(x2)
            instr_o = {
              4'b0,
              instr_i[3:2],
              instr_i[12],
              instr_i[6:4],
              2'b00,
              5'h02,
              3'b010,
              instr_i[11:7],
              OPCODE_LOAD
            };
            if (instr_i[11:7] == 5'b0) illegal_instr_o = 1'b1;
          end

          3'b011: begin
            // c.flwsp -> flw rd, imm(x2)
            if (FPU == 1 && ZFINX == 0)
              instr_o = {
                4'b0,
                instr_i[3:2],
                instr_i[12],
                instr_i[6:4],
                2'b00,
                5'h02,
                3'b010,
                instr_i[11:7],
                OPCODE_LOAD_FP
              };
            else illegal_instr_o = 1'b1;
          end

          3'b100: begin
            if (instr_i[12] == 1'b0) begin
              if (instr_i[6:2] == 5'b0) begin
                // c.jr -> jalr x0, rd/rs1, 0
                instr_o = {12'b0, instr_i[11:7], 3'b0, 5'b0, OPCODE_JALR};
                // c.jr with rs1 = 0 is reserved
                if (instr_i[11:7] == 5'b0) illegal_instr_o = 1'b1;
              end else begin
                if (instr_i[11:7] == 5'b0) begin
                  // Hint -> add x0, x0, rs2
                  instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OP};
                end else begin
                  // c.mv -> add rd, x0, rs2
                  instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OP};
                end
              end
            end else begin
              if (instr_i[6:2] == 5'b0) begin
                if (instr_i[11:7] == 5'b0) begin
                  // c.ebreak -> ebreak
                  instr_o = {32'h00_10_00_73};
                end else begin
                  // c.jalr -> jalr x1, rs1, 0
                  instr_o = {12'b0, instr_i[11:7], 3'b000, 5'b00001, OPCODE_JALR};
                end
              end else begin
                if (instr_i[11:7] == 5'b0) begin
                  // Hint -> add x0, x0, rs2
                  instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OP};
                end else begin
                  // c.add -> add rd, rd, rs2
                  instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OP};
                end
              end
            end
          end

          3'b101: begin
            // c.fsdsp -> fsd rs2, imm(x2)
            if (FPU == 1 && ZFINX == 0)
              // instr_i[12:10] -> offset[5:3], instr_i[9:7] -> offset[8:6]
              instr_o = {
                3'b0,
                instr_i[9:7],
                instr_i[12],
                instr_i[6:2],
                5'h02,
                3'b011,
                instr_i[11:10],
                3'b000,
                OPCODE_STORE_FP
              };
            else illegal_instr_o = 1'b1;
          end
          3'b110: begin
            // c.swsp -> sw rs2, imm(x2)
            instr_o = {
              4'b0,
              instr_i[8:7],
              instr_i[12],
              instr_i[6:2],
              5'h02,
              3'b010,
              instr_i[11:9],
              2'b00,
              OPCODE_STORE
            };
          end

          3'b111: begin
            // c.fswsp -> fsw rs2, imm(x2)
            if (FPU == 1 && ZFINX == 0)
              instr_o = {
                4'b0,
                instr_i[8:7],
                instr_i[12],
                instr_i[6:2],
                5'h02,
                3'b010,
                instr_i[11:9],
                2'b00,
                OPCODE_STORE_FP
              };
            else illegal_instr_o = 1'b1;
          end
        endcase
      end

      default: begin
        // 32 bit (or more) instruction
        instr_o = instr_i;
      end
    endcase
  end

  assign is_compressed_o = (instr_i[1:0] != 2'b11);

endmodule

// -------------------- END OF rtl/cv32e40p_compressed_decoder.sv --------------------

// -------------------- START OF rtl/cv32e40p_controller.sv --------------------
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
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                 Robert Balas - balasr@iis.ee.ethz.ch                       //
//                 Andrea Bettati - andrea.bettati@studenti.unipr.it          //
//                                                                            //
// Design Name:    Main controller                                            //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Main CPU controller of the processor                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_controller import cv32e40p_pkg::*;
#(
  parameter COREV_CLUSTER = 0,
  parameter COREV_PULP    = 0,
  parameter FPU           = 0
)
(
  input  logic        clk,                        // Gated clock
  input  logic        clk_ungated_i,              // Ungated clock
  input  logic        rst_n,

  input  logic        fetch_enable_i,             // Start the decoding
  output logic        ctrl_busy_o,                // Core is busy processing instructions
  output logic        is_decoding_o,              // Core is in decoding state
  input  logic        is_fetch_failed_i,

  // decoder related signals
  output logic        deassert_we_o,              // deassert write enable for next instruction

  input  logic        illegal_insn_i,             // decoder encountered an invalid instruction
  input  logic        ecall_insn_i,               // decoder encountered an ecall instruction
  input  logic        mret_insn_i,                // decoder encountered an mret instruction
  input  logic        uret_insn_i,                // decoder encountered an uret instruction

  input  logic        dret_insn_i,                // decoder encountered an dret instruction

  input  logic        mret_dec_i,
  input  logic        uret_dec_i,
  input  logic        dret_dec_i,

  input  logic        wfi_i,                      // decoder wants to execute a WFI
  input  logic        ebrk_insn_i,                // decoder encountered an ebreak instruction
  input  logic        fencei_insn_i,              // decoder encountered an fence.i instruction
  input  logic        csr_status_i,               // decoder encountered an csr status instruction

  output logic        hwlp_mask_o,                // prevent writes on the hwloop instructions in case interrupt are taken

  // from IF/ID pipeline
  input  logic        instr_valid_i,              // instruction coming from IF/ID pipeline is valid

  // from prefetcher
  output logic        instr_req_o,                // Start fetching instructions

  // to prefetcher
  output logic        pc_set_o,                   // jump to address set by pc_mux
  output logic [3:0]  pc_mux_o,                   // Selector in the Fetch stage to select the rigth PC (normal, jump ...)
  output logic [2:0]  exc_pc_mux_o,               // Selects target PC for exception
  output logic [1:0]  trap_addr_mux_o,            // Selects trap address base

  // HWLoop signls
  input  logic [31:0]       pc_id_i,

  // from hwloop_regs
  input  logic [1:0] [31:0] hwlp_start_addr_i,
  input  logic [1:0] [31:0] hwlp_end_addr_i,
  input  logic [1:0] [31:0] hwlp_counter_i,

  // to hwloop_regs
  output logic [1:0]        hwlp_dec_cnt_o,

  output logic              hwlp_jump_o,
  output logic [31:0]       hwlp_targ_addr_o,

  // LSU
  input  logic        data_req_ex_i,              // data memory access is currently performed in EX stage
  input  logic        data_we_ex_i,
  input  logic        data_misaligned_i,
  input  logic        data_load_event_i,
  input  logic        data_err_i,
  output logic        data_err_ack_o,

  // from ALU
  input  logic        mult_multicycle_i,          // multiplier is taken multiple cycles and uses op c as storage

  // APU dependency checks
  input  logic        apu_en_i,
  input  logic        apu_read_dep_i,
  input  logic        apu_read_dep_for_jalr_i,
  input  logic        apu_write_dep_i,

  output logic        apu_stall_o,

  // jump/branch signals
  input  logic        branch_taken_ex_i,          // branch taken signal from EX ALU
  input  logic [1:0]  ctrl_transfer_insn_in_id_i,               // jump is being calculated in ALU
  input  logic [1:0]  ctrl_transfer_insn_in_dec_i,              // jump is being calculated in ALU

  // Interrupt Controller Signals
  input  logic        irq_req_ctrl_i,
  input  logic        irq_sec_ctrl_i,
  input  logic [4:0]  irq_id_ctrl_i,
  input  logic        irq_wu_ctrl_i,
  input  PrivLvl_t    current_priv_lvl_i,

  output logic        irq_ack_o,
  output logic [4:0]  irq_id_o,

  output logic [4:0]  exc_cause_o,

  // Debug Signal
  output logic         debug_mode_o,
  output logic [2:0]   debug_cause_o,
  output logic         debug_csr_save_o,
  input  logic         debug_req_i,
  input  logic         debug_single_step_i,
  input  logic         debug_ebreakm_i,
  input  logic         debug_ebreaku_i,
  input  logic         trigger_match_i,
  output logic         debug_p_elw_no_sleep_o,
  output logic         debug_wfi_no_sleep_o,
  output logic         debug_havereset_o,
  output logic         debug_running_o,
  output logic         debug_halted_o,

  // Wakeup Signal
  output logic        wake_from_sleep_o,

  output logic        csr_save_if_o,
  output logic        csr_save_id_o,
  output logic        csr_save_ex_o,
  output logic [5:0]  csr_cause_o,
  output logic        csr_irq_sec_o,
  output logic        csr_restore_mret_id_o,
  output logic        csr_restore_uret_id_o,

  output logic        csr_restore_dret_id_o,

  output logic        csr_save_cause_o,


  // Regfile target
  input  logic        regfile_we_id_i,            // currently decoded we enable
  input  logic [5:0]  regfile_alu_waddr_id_i,     // currently decoded target address

  // Forwarding signals from regfile
  input  logic        regfile_we_ex_i,            // FW: write enable from  EX stage
  input  logic [5:0]  regfile_waddr_ex_i,         // FW: write address from EX stage
  input  logic        regfile_we_wb_i,            // FW: write enable from  WB stage
  input  logic        regfile_alu_we_fw_i,        // FW: ALU/MUL write enable from  EX stage

  // forwarding signals
  output logic [1:0]  operand_a_fw_mux_sel_o,     // regfile ra data selector form ID stage
  output logic [1:0]  operand_b_fw_mux_sel_o,     // regfile rb data selector form ID stage
  output logic [1:0]  operand_c_fw_mux_sel_o,     // regfile rc data selector form ID stage

  // forwarding detection signals
  input logic         reg_d_ex_is_reg_a_i,
  input logic         reg_d_ex_is_reg_b_i,
  input logic         reg_d_ex_is_reg_c_i,
  input logic         reg_d_wb_is_reg_a_i,
  input logic         reg_d_wb_is_reg_b_i,
  input logic         reg_d_wb_is_reg_c_i,
  input logic         reg_d_alu_is_reg_a_i,
  input logic         reg_d_alu_is_reg_b_i,
  input logic         reg_d_alu_is_reg_c_i,

  // stall signals
  output logic        halt_if_o,
  output logic        halt_id_o,

  output logic        misaligned_stall_o,
  output logic        jr_stall_o,
  output logic        load_stall_o,

  input  logic        id_ready_i,                 // ID stage is ready
  input  logic        id_valid_i,                 // ID stage is valid

  input  logic        ex_valid_i,                 // EX stage is done

  input  logic        wb_ready_i,                 // WB stage is ready

  // Performance Counters
  output logic        perf_pipeline_stall_o       // stall due to cv.elw extra cycles
);

  // FSM state encoding
  ctrl_state_e ctrl_fsm_cs, ctrl_fsm_ns;

  // Debug state
  debug_state_e debug_fsm_cs, debug_fsm_ns;

  logic jump_done, jump_done_q, jump_in_dec, branch_in_id;

  logic data_err_q;

  logic debug_mode_q, debug_mode_n;
  logic ebrk_force_debug_mode;
  logic is_hwlp_body;
  logic illegal_insn_q, illegal_insn_n;
  logic debug_req_entry_q, debug_req_entry_n;
  logic debug_force_wakeup_q, debug_force_wakeup_n;

  logic hwlp_end0_eq_pc;
  logic hwlp_end1_eq_pc;
  logic hwlp_counter0_gt_1;
  logic hwlp_counter1_gt_1;
  logic hwlp_counter0_eq_1;
  logic hwlp_counter1_eq_1;
  logic hwlp_counter0_eq_0;
  logic hwlp_counter1_eq_0;
  logic hwlp_end0_eq_pc_plus4;
  logic hwlp_end1_eq_pc_plus4;
  logic hwlp_start0_leq_pc;
  logic hwlp_start1_leq_pc;
  logic hwlp_end0_geq_pc;
  logic hwlp_end1_geq_pc;
  // Auxiliary signals to make hwlp_jump_o last only one cycle (converting it into a pulse)
  logic hwlp_end_4_id_d, hwlp_end_4_id_q;

  logic debug_req_q;
  logic debug_req_pending;

  // qualify wfi vs nosleep locally 
  logic wfi_active;


  ////////////////////////////////////////////////////////////////////////////////////////////
  //   ____ ___  ____  _____    ____ ___  _   _ _____ ____   ___  _     _     _____ ____    //
  //  / ___/ _ \|  _ \| ____|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |   | |   | ____|  _ \   //
  // | |  | | | | |_) |  _|   | |  | | | |  \| | | | | |_) | | | | |   | |   |  _| | |_) |  //
  // | |__| |_| |  _ <| |___  | |__| |_| | |\  | | | |  _ <| |_| | |___| |___| |___|  _ <   //
  //  \____\___/|_| \_\_____|  \____\___/|_| \_| |_| |_| \_\\___/|_____|_____|_____|_| \_\  //
  //                                                                                        //
  ////////////////////////////////////////////////////////////////////////////////////////////

  always_comb
  begin
    // Default values

    instr_req_o            = 1'b1;

    data_err_ack_o         = 1'b0;

    csr_save_if_o          = 1'b0;
    csr_save_id_o          = 1'b0;
    csr_save_ex_o          = 1'b0;
    csr_restore_mret_id_o  = 1'b0;
    csr_restore_uret_id_o  = 1'b0;

    csr_restore_dret_id_o  = 1'b0;

    csr_save_cause_o       = 1'b0;

    exc_cause_o            = '0;
    exc_pc_mux_o           = EXC_PC_IRQ;
    trap_addr_mux_o        = TRAP_MACHINE;

    csr_cause_o            = '0;
    csr_irq_sec_o          = 1'b0;

    pc_mux_o               = PC_BOOT;
    pc_set_o               = 1'b0;
    jump_done              = jump_done_q;

    ctrl_fsm_ns            = ctrl_fsm_cs;

    ctrl_busy_o            = 1'b1;

    halt_if_o              = 1'b0;
    halt_id_o              = 1'b0;
    is_decoding_o          = 1'b0;
    irq_ack_o              = 1'b0;
    irq_id_o               = 5'b0;

    jump_in_dec            = ctrl_transfer_insn_in_dec_i == BRANCH_JALR || ctrl_transfer_insn_in_dec_i == BRANCH_JAL;

    branch_in_id           = ctrl_transfer_insn_in_id_i == BRANCH_COND;

    ebrk_force_debug_mode  = (debug_ebreakm_i && current_priv_lvl_i == PRIV_LVL_M) ||
                             (debug_ebreaku_i && current_priv_lvl_i == PRIV_LVL_U);
    debug_csr_save_o       = 1'b0;
    debug_cause_o          = DBG_CAUSE_EBREAK;
    debug_mode_n           = debug_mode_q;

    illegal_insn_n         = illegal_insn_q;
    // a trap towards the debug unit is generated when one of the
    // following conditions are true:
    // - ebreak instruction encountered
    // - single-stepping mode enabled
    // - illegal instruction exception and IIE bit is set
    // - IRQ and INTE bit is set and no exception is currently running
    // - Debuger requests halt

    debug_req_entry_n       = debug_req_entry_q;

    debug_force_wakeup_n    = debug_force_wakeup_q;

    perf_pipeline_stall_o   = 1'b0;

    hwlp_mask_o             = 1'b0;

    hwlp_dec_cnt_o          = '0;
    hwlp_end_4_id_d         = 1'b0;

    // When the controller tells to hwlp-jump, the prefetcher does not always jump immediately,
    // but the aligner immediately modifies pc_id to HWLP_BEGIN. This condition on hwlp_targ_addr_o
    // ensures that the target is kept constant even if pc_id is no more HWLP_END
    hwlp_targ_addr_o        = ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && !(hwlp_start0_leq_pc && hwlp_end0_geq_pc)) ? hwlp_start_addr_i[1] : hwlp_start_addr_i[0];

    unique case (ctrl_fsm_cs)
      // We were just reset, wait for fetch_enable
      RESET:
      begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        if (fetch_enable_i == 1'b1)
        begin
          ctrl_fsm_ns = BOOT_SET;
        end
      end

      // copy boot address to instr fetch address
      BOOT_SET:
      begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b1;
        pc_mux_o      = PC_BOOT;
        pc_set_o      = 1'b1;
        if (debug_req_pending) begin
            ctrl_fsm_ns = DBG_TAKEN_IF;
            debug_force_wakeup_n = 1'b1;
        end else begin
            ctrl_fsm_ns   = FIRST_FETCH;
        end
      end

      WAIT_SLEEP:
      begin
        is_decoding_o = 1'b0;
        ctrl_busy_o   = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;
        ctrl_fsm_ns   = SLEEP;
      end

      // instruction in if_stage is already valid
      SLEEP:
      begin
        // we begin execution when an
        // interrupt has arrived
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;

        // normal execution flow
        // in debug mode or single step mode we leave immediately (wfi=nop)
        if (wake_from_sleep_o) begin
          if (debug_req_pending) begin
              ctrl_fsm_ns = DBG_TAKEN_IF;
              debug_force_wakeup_n = 1'b1;
          end else begin
              ctrl_fsm_ns  = FIRST_FETCH;
          end
        end else begin
          ctrl_busy_o = 1'b0;
        end
      end

      FIRST_FETCH:
      begin
        is_decoding_o = 1'b0;

        // ID stage is always ready
        ctrl_fsm_ns = DECODE;

        // handle interrupts
        if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
          // This assumes that the pipeline is always flushed before
          // going to sleep.
          // Debug mode takes precedence over irq (see DECODE:)

          // Taken IRQ
          halt_if_o         = 1'b1;
          halt_id_o         = 1'b1;

          pc_set_o          = 1'b1;
          pc_mux_o          = PC_EXCEPTION;
          exc_pc_mux_o      = EXC_PC_IRQ;
          exc_cause_o       = irq_id_ctrl_i;
          csr_irq_sec_o     = irq_sec_ctrl_i;

          // IRQ interface
          irq_ack_o         = 1'b1;
          irq_id_o          = irq_id_ctrl_i;

          if (irq_sec_ctrl_i)
            trap_addr_mux_o  = TRAP_MACHINE;
          else
            trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

          csr_save_cause_o  = 1'b1;
          csr_cause_o       = {1'b1,irq_id_ctrl_i};
          csr_save_if_o     = 1'b1;
        end
      end

      DECODE:
      begin

          if (branch_taken_ex_i)
          begin //taken branch
            // there is a branch in the EX stage that is taken

            is_decoding_o = 1'b0;

            pc_mux_o      = PC_BRANCH;
            pc_set_o      = 1'b1;

            // if we want to debug, flush the pipeline
            // the current_pc_if will take the value of the next instruction to
            // be executed (NPC)

          end  //taken branch

          else if (data_err_i)
          begin //data error
            // the current LW or SW have been blocked by the PMP

            is_decoding_o     = 1'b0;
            halt_if_o         = 1'b1;
            halt_id_o         = 1'b1;
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode

            csr_cause_o       = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
            ctrl_fsm_ns       = FLUSH_WB;

          end  //data error

          else if (is_fetch_failed_i)
          begin

            // the current instruction has been blocked by the PMP

            is_decoding_o     = 1'b0;
            halt_id_o         = 1'b1;
            halt_if_o         = 1'b1;
            csr_save_if_o     = 1'b1;
            csr_save_cause_o  = !debug_mode_q;

            //no jump in this stage as we have to wait one cycle to go to Machine Mode

            csr_cause_o       = {1'b0, EXC_CAUSE_INSTR_FAULT};
            ctrl_fsm_ns       = FLUSH_WB;


          end
          // decode and execute instructions only if the current conditional
          // branch in the EX stage is either not taken, or there is no
          // conditional branch in the EX stage
          else if (instr_valid_i) //valid block
          begin: blk_decode_level1 // now analyze the current instruction in the ID stage

            is_decoding_o = 1'b1;
            illegal_insn_n = 1'b0;

            if ( (debug_req_pending || trigger_match_i) & ~debug_mode_q )
              begin
                //Serving the debug
                is_decoding_o     = COREV_PULP ? 1'b0 : 1'b1;
                halt_if_o         = 1'b1;
                halt_id_o         = 1'b1;
                ctrl_fsm_ns       = DBG_FLUSH;
                debug_req_entry_n = 1'b1;
              end
            else if (irq_req_ctrl_i && ~debug_mode_q)
              begin
                // Taken IRQ
                hwlp_mask_o       = COREV_PULP ? 1'b1 : 1'b0;

                is_decoding_o     = 1'b0;
                halt_if_o         = 1'b1;
                halt_id_o         = 1'b1;

                pc_set_o          = 1'b1;
                pc_mux_o          = PC_EXCEPTION;
                exc_pc_mux_o      = EXC_PC_IRQ;
                exc_cause_o       = irq_id_ctrl_i;
                csr_irq_sec_o     = irq_sec_ctrl_i;

                // IRQ interface
                irq_ack_o         = 1'b1;
                irq_id_o          = irq_id_ctrl_i;

                if (irq_sec_ctrl_i)
                  trap_addr_mux_o  = TRAP_MACHINE;
                else
                  trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

                csr_save_cause_o  = 1'b1;
                csr_cause_o       = {1'b1,irq_id_ctrl_i};
                csr_save_id_o     = 1'b1;
              end
            else
              begin

                if (illegal_insn_i) begin

                  halt_if_o         = 1'b1;
                  halt_id_o         = 1'b0;
                  ctrl_fsm_ns       = id_ready_i ? FLUSH_EX : DECODE;
                  illegal_insn_n    = 1'b1;

                end else begin

                  //decoding block
                  unique case (1'b1)

                    jump_in_dec: begin
                    // handle unconditional jumps
                    // we can jump directly since we know the address already
                    // we don't need to worry about conditional branches here as they
                    // will be evaluated in the EX stage
                      pc_mux_o = PC_JUMP;
                      // if there is a jr stall, wait for it to be gone
                      if ((~jr_stall_o) && (~jump_done_q)) begin
                        pc_set_o    = 1'b1;
                        jump_done   = 1'b1;
                      end
                    end

                    ebrk_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;

                      if (debug_mode_q)
                        // we got back to the park loop in the debug rom
                        ctrl_fsm_ns = DBG_FLUSH;

                      else if (ebrk_force_debug_mode) begin
                        // debug module commands us to enter debug mode anyway
                        ctrl_fsm_ns  = DBG_FLUSH;
                      end else begin
                        // otherwise just a normal ebreak exception
                        ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                      end

                    end

                    wfi_active: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;
                      ctrl_fsm_ns           = id_ready_i ? FLUSH_EX : DECODE;
                    end

                    ecall_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;
                      ctrl_fsm_ns           = id_ready_i ? FLUSH_EX : DECODE;
                    end

                    fencei_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;
                      ctrl_fsm_ns           = id_ready_i ? FLUSH_EX : DECODE;
                    end

                    mret_insn_i | uret_insn_i | dret_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;
                      ctrl_fsm_ns           = id_ready_i ? FLUSH_EX : DECODE;
                    end

                    csr_status_i: begin
                      halt_if_o     = 1'b1;
                      ctrl_fsm_ns   = id_ready_i ? FLUSH_EX : DECODE;
                    end

                    data_load_event_i: begin
                      ctrl_fsm_ns   = id_ready_i ? ELW_EXE : DECODE;
                      halt_if_o     = 1'b1;
                    end

                    default: begin

                      if(is_hwlp_body) begin
                        //we are at the inside of an HWloop, thus change state

                        //We stay here in case we returned from the second last instruction, otherwise the next cycle
                        //in DECODE_HWLOOP we miss to jump, we jump at PC_END.
                        //This way looses a cycle but it's a corner case of returning from exceptions or interrupts

                        ctrl_fsm_ns  = hwlp_end0_eq_pc_plus4 || hwlp_end1_eq_pc_plus4 ? DECODE : DECODE_HWLOOP;

                        // we can be at the end of HWloop due to a return from interrupt or ecall or ebreak or exceptions
                        if(hwlp_end0_eq_pc && hwlp_counter0_gt_1) begin
                          pc_mux_o         = PC_HWLOOP;
                          if (~jump_done_q) begin
                            pc_set_o          = 1'b1;
                            // Keep the instruction and the related address in the Aligner if
                            // ID is stalled during a jump
                            jump_done         = 1'b1;
                            hwlp_dec_cnt_o[0] = 1'b1;
                          end
                        end
                        if (hwlp_end1_eq_pc && hwlp_counter1_gt_1) begin
                          pc_mux_o         = PC_HWLOOP;
                          if (~jump_done_q) begin
                            pc_set_o          = 1'b1;
                            // Keep the instruction and the related address in the Aligner if
                            // ID is stalled during a jump
                            jump_done         = 1'b1;
                            hwlp_dec_cnt_o[1] = 1'b1;
                          end
                        end
                      end

                      if (hwlp_end0_eq_pc && hwlp_counter0_eq_1) begin
                        hwlp_dec_cnt_o[0] = 1'b1;
                      end
                      if (hwlp_end1_eq_pc && hwlp_counter1_eq_1) begin
                        hwlp_dec_cnt_o[1] = 1'b1;
                      end

                    end

                  endcase // unique case (1'b1)
                end

                if (debug_single_step_i & ~debug_mode_q) begin
                    // prevent any more instructions from executing
                    halt_if_o = 1'b1;

                    // we don't handle dret here because its should be illegal
                    // anyway in this context

                    // illegal, ecall, ebrk and xrettransition to later to a DBG
                    // state since we need the return address which is
                    // determined later

                    if (id_ready_i) begin
                    // make sure the current instruction has been executed
                        unique case(1'b1)

                        illegal_insn_i | ecall_insn_i:
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        (~ebrk_force_debug_mode & ebrk_insn_i):
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        mret_insn_i | uret_insn_i:
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        branch_in_id:
                        begin
                            ctrl_fsm_ns    = DBG_WAIT_BRANCH;
                        end

                        default:
                            // regular instruction or ebrk force debug
                            ctrl_fsm_ns = DBG_FLUSH;
                        endcase // unique case (1'b1)
                    end
                end

              end // else: !if (irq_req_ctrl_i && ~debug_mode_q)

          end  //valid block
          else begin
            is_decoding_o         = 1'b0;
            perf_pipeline_stall_o = data_load_event_i;
          end
      end

      DECODE_HWLOOP:
      begin
        if (COREV_PULP) begin
          if (instr_valid_i) // valid block
          begin // now analyze the current instruction in the ID stage

            is_decoding_o = 1'b1;

            if ( (debug_req_pending || trigger_match_i) & ~debug_mode_q )
              begin
                //Serving the debug
                is_decoding_o     = COREV_PULP ? 1'b0 : 1'b1;
                halt_if_o         = 1'b1;
                halt_id_o         = 1'b1;
                ctrl_fsm_ns       = DBG_FLUSH;
                debug_req_entry_n = 1'b1;
             end
            else if (irq_req_ctrl_i && ~debug_mode_q)
              begin
                // Taken IRQ
                hwlp_mask_o       = COREV_PULP ? 1'b1 : 1'b0;

                is_decoding_o     = 1'b0;
                halt_if_o         = 1'b1;
                halt_id_o         = 1'b1;

                pc_set_o          = 1'b1;
                pc_mux_o          = PC_EXCEPTION;
                exc_pc_mux_o      = EXC_PC_IRQ;
                exc_cause_o       = irq_id_ctrl_i;
                csr_irq_sec_o     = irq_sec_ctrl_i;

                // IRQ interface
                irq_ack_o         = 1'b1;
                irq_id_o          = irq_id_ctrl_i;

                if (irq_sec_ctrl_i)
                  trap_addr_mux_o  = TRAP_MACHINE;
                else
                  trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

                csr_save_cause_o  = 1'b1;
                csr_cause_o       = {1'b1,irq_id_ctrl_i};
                csr_save_id_o     = 1'b1;

                ctrl_fsm_ns       = DECODE;
              end
            else
              begin

                if (illegal_insn_i) begin

                  halt_if_o         = 1'b1;
                  halt_id_o         = 1'b1;
                  ctrl_fsm_ns       = FLUSH_EX;
                  illegal_insn_n    = 1'b1;

                end else begin

                  //decoding block
                  unique case (1'b1)

                    ebrk_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;

                      if (debug_mode_q)
                        // we got back to the park loop in the debug rom
                        ctrl_fsm_ns = DBG_FLUSH;

                      else if (ebrk_force_debug_mode)
                        // debug module commands us to enter debug mode anyway
                        ctrl_fsm_ns  = DBG_FLUSH;

                      else begin
                        // otherwise just a normal ebreak exception
                        ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE_HWLOOP;
                      end

                    end

                    ecall_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b0;
                      ctrl_fsm_ns   = id_ready_i ? FLUSH_EX : DECODE_HWLOOP;
                    end

                    csr_status_i: begin
                      halt_if_o     = 1'b1;
                      ctrl_fsm_ns   = id_ready_i ? FLUSH_EX : DECODE_HWLOOP;
                    end

                    data_load_event_i: begin
                      ctrl_fsm_ns   = id_ready_i ? ELW_EXE : DECODE_HWLOOP;
                      halt_if_o     = 1'b1;
                    end

                    default: begin

                       // we can be at the end of HWloop due to a return from interrupt or ecall or ebreak or exceptions
                      if(hwlp_end1_eq_pc_plus4) begin
                          if(hwlp_counter1_gt_1) begin
                            hwlp_end_4_id_d  = 1'b1;
                            hwlp_targ_addr_o = hwlp_start_addr_i[1];
                            ctrl_fsm_ns      = DECODE_HWLOOP;
                          end else
                            ctrl_fsm_ns      = is_hwlp_body ? DECODE_HWLOOP : DECODE;
                      end

                      if(hwlp_end0_eq_pc_plus4) begin
                          if(hwlp_counter0_gt_1) begin
                            hwlp_end_4_id_d  = 1'b1;
                            hwlp_targ_addr_o = hwlp_start_addr_i[0];
                            ctrl_fsm_ns      = DECODE_HWLOOP;
                          end else
                            ctrl_fsm_ns      = is_hwlp_body ? DECODE_HWLOOP : DECODE;
                      end

                      hwlp_dec_cnt_o[0] = hwlp_end0_eq_pc && !hwlp_counter0_eq_0;
                      hwlp_dec_cnt_o[1] = hwlp_end1_eq_pc && !hwlp_counter1_eq_0;

                    end
                  endcase // unique case (1'b1)
                end // else: !if(illegal_insn_i)

                if (debug_single_step_i & ~debug_mode_q) begin
                    // prevent any more instructions from executing
                    halt_if_o = 1'b1;

                    // we don't handle dret here because its should be illegal
                    // anyway in this context

                    // illegal, ecall, ebrk and xrettransition to later to a DBG
                    // state since we need the return address which is
                    // determined later

                    if (id_ready_i) begin
                    // make sure the current instruction has been executed
                        unique case(1'b1)

                        illegal_insn_i | ecall_insn_i:
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        (~ebrk_force_debug_mode & ebrk_insn_i):
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        mret_insn_i | uret_insn_i:
                        begin
                            ctrl_fsm_ns = FLUSH_EX;
                        end

                        branch_in_id:
                        begin
                            ctrl_fsm_ns = DBG_WAIT_BRANCH;
                        end

                        default:
                            // regular instruction or ebrk force debug
                            ctrl_fsm_ns = DBG_FLUSH;
                        endcase // unique case (1'b1)
                    end
                end // if (debug_single_step_i & ~debug_mode_q)

              end // else: !if (irq_req_ctrl_i && ~debug_mode_q)

          end // block: blk_decode_level1 : valid block
          else begin
            is_decoding_o         = 1'b0;
            perf_pipeline_stall_o = data_load_event_i;
          end
        end
      end

      // flush the pipeline, insert NOP into EX stage
      FLUSH_EX:
      begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        if (data_err_i)
        begin //data error
            // the current LW or SW have been blocked by the PMP
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode
            csr_cause_o       = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
            ctrl_fsm_ns       = FLUSH_WB;
            //putting illegal to 0 as if it was 1, the core is going to jump to the exception of the EX stage,
            //so the illegal was never executed
            illegal_insn_n    = 1'b0;
        end  //data erro
        else if (ex_valid_i) begin
          //check done to prevent data harzard in the CSR registers
          ctrl_fsm_ns = FLUSH_WB;

          if(illegal_insn_q) begin
            csr_save_id_o     = 1'b1;
            csr_save_cause_o  = !debug_mode_q;
            csr_cause_o       = {1'b0, EXC_CAUSE_ILLEGAL_INSN};
          end else begin
            unique case (1'b1)
              ebrk_insn_i: begin
                csr_save_id_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                csr_cause_o       = {1'b0, EXC_CAUSE_BREAKPOINT};
              end
              ecall_insn_i: begin
                csr_save_id_o     = 1'b1;
                csr_save_cause_o  = !debug_mode_q;
                csr_cause_o       = {1'b0, current_priv_lvl_i == PRIV_LVL_U ? EXC_CAUSE_ECALL_UMODE : EXC_CAUSE_ECALL_MMODE};
              end
              default:;
            endcase // unique case (1'b1)
          end

        end
      end

      IRQ_FLUSH_ELW:
      begin
        if (COREV_CLUSTER == 1'b1) begin
          is_decoding_o = 1'b0;

          halt_if_o     = 1'b1;
          halt_id_o     = 1'b1;

          ctrl_fsm_ns   = DECODE;

          perf_pipeline_stall_o = data_load_event_i;

          if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
            // Taken IRQ
            is_decoding_o     = 1'b0;
            halt_if_o         = 1'b1;
            halt_id_o         = 1'b1;

            pc_set_o          = 1'b1;
            pc_mux_o          = PC_EXCEPTION;
            exc_pc_mux_o      = EXC_PC_IRQ;
            exc_cause_o       = irq_id_ctrl_i;
            csr_irq_sec_o     = irq_sec_ctrl_i;

            // IRQ interface
            irq_ack_o         = 1'b1;
            irq_id_o          = irq_id_ctrl_i;

            if (irq_sec_ctrl_i)
              trap_addr_mux_o  = TRAP_MACHINE;
            else
              trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

            csr_save_cause_o  = 1'b1;
            csr_cause_o       = {1'b1,irq_id_ctrl_i};
            csr_save_id_o     = 1'b1;
          end
        end
      end

      ELW_EXE:
      begin
        if (COREV_CLUSTER == 1'b1) begin
          is_decoding_o = 1'b0;

          halt_if_o   = 1'b1;
          halt_id_o   = 1'b1;

          //if we are here, a cv.elw is executing now in the EX stage
          //or if an interrupt has been received
          //the ID stage contains the PC_ID of the cv.elw, therefore halt_id is set to invalid the instruction
          //If an interrupt occurs, we replay the ELW
          //No needs to check irq_int_req_i since in the EX stage there is only the cv.elw, no CSR pendings
          if(id_ready_i)
            ctrl_fsm_ns = ((debug_req_pending || trigger_match_i) & ~debug_mode_q) ? DBG_FLUSH : IRQ_FLUSH_ELW;
            // if from the ELW EXE we go to IRQ_FLUSH_ELW, it is assumed that if there was an IRQ req together with the grant and IE was valid, then
            // there must be no hazard due to xIE
          else
            ctrl_fsm_ns = ELW_EXE;

          perf_pipeline_stall_o = data_load_event_i;
        end
      end

      // flush the pipeline, insert NOP into EX and WB stage
      FLUSH_WB:
      begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        ctrl_fsm_ns = DECODE;

        if(data_err_q) begin
            //PMP data_error
            pc_mux_o              = PC_EXCEPTION;
            pc_set_o              = 1'b1;
            trap_addr_mux_o       = TRAP_MACHINE;
            //little hack during testing
            exc_pc_mux_o          = EXC_PC_EXCEPTION;
            exc_cause_o           = data_we_ex_i ? EXC_CAUSE_LOAD_FAULT : EXC_CAUSE_STORE_FAULT;

        end
        else if (is_fetch_failed_i) begin
            //instruction fetch error
            pc_mux_o              = PC_EXCEPTION;
            pc_set_o              = 1'b1;
            trap_addr_mux_o       = TRAP_MACHINE;
            exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
            exc_cause_o           = EXC_CAUSE_INSTR_FAULT;

        end
        else begin
          if(illegal_insn_q) begin
              //exceptions
              pc_mux_o              = PC_EXCEPTION;
              pc_set_o              = 1'b1;
              trap_addr_mux_o       = TRAP_MACHINE;
              exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
              illegal_insn_n        = 1'b0;
              if (debug_single_step_i && ~debug_mode_q)
                  ctrl_fsm_ns = DBG_TAKEN_IF;
          end else begin
            unique case(1'b1)
              ebrk_insn_i: begin
                  //ebreak
                  pc_mux_o              = PC_EXCEPTION;
                  pc_set_o              = 1'b1;
                  trap_addr_mux_o       = TRAP_MACHINE;
                  exc_pc_mux_o          = EXC_PC_EXCEPTION;

                  if (debug_single_step_i && ~debug_mode_q)
                      ctrl_fsm_ns = DBG_TAKEN_IF;
              end
              ecall_insn_i: begin
                  //ecall
                  pc_mux_o              = PC_EXCEPTION;
                  pc_set_o              = 1'b1;
                  trap_addr_mux_o       = TRAP_MACHINE;
                  exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;

                  if (debug_single_step_i && ~debug_mode_q)
                      ctrl_fsm_ns = DBG_TAKEN_IF;
              end

              mret_insn_i: begin
                 csr_restore_mret_id_o =  !debug_mode_q;
                 ctrl_fsm_ns           = XRET_JUMP;
              end
              uret_insn_i: begin
                 csr_restore_uret_id_o =  !debug_mode_q;
                 ctrl_fsm_ns           = XRET_JUMP;
              end
              dret_insn_i: begin
                  csr_restore_dret_id_o = 1'b1;
                  ctrl_fsm_ns           = XRET_JUMP;
              end

              csr_status_i: begin

                if(hwlp_end0_eq_pc && hwlp_counter0_gt_1) begin
                    pc_mux_o         = PC_HWLOOP;
                    pc_set_o          = 1'b1;
                    hwlp_dec_cnt_o[0] = 1'b1;
              end
                if(hwlp_end1_eq_pc && hwlp_counter1_gt_1) begin
                    pc_mux_o         = PC_HWLOOP;
                    pc_set_o          = 1'b1;
                    hwlp_dec_cnt_o[1] = 1'b1;
                end
              end

              wfi_i: begin
                  if ( debug_req_pending) begin
                      ctrl_fsm_ns = DBG_TAKEN_IF;
                      debug_force_wakeup_n = 1'b1;
                  end else begin
                    ctrl_fsm_ns = WAIT_SLEEP;
                  end
              end
              fencei_insn_i: begin
                  // we just jump to instruction after the fence.i since that
                  // forces the instruction cache to refetch
                  pc_mux_o              = PC_FENCEI;
                  pc_set_o              = 1'b1;
              end
              default:;
            endcase
          end
        end

      end

      XRET_JUMP:
      begin
        is_decoding_o = 1'b0;
        ctrl_fsm_ns   = DECODE;
        unique case(1'b1)
          mret_dec_i: begin
              //mret
              pc_mux_o              = debug_mode_q ? PC_EXCEPTION : PC_MRET;
              pc_set_o              = 1'b1;
              exc_pc_mux_o          = EXC_PC_DBE; // only used if in debug_mode
          end
          uret_dec_i: begin
              //uret
              pc_mux_o              = debug_mode_q ? PC_EXCEPTION : PC_URET;
              pc_set_o              = 1'b1;
              exc_pc_mux_o          = EXC_PC_DBE; // only used if in debug_mode
          end
          dret_dec_i: begin
              //dret
              // this case is only reachable while in debug_mode
              pc_mux_o              = PC_DRET;
              pc_set_o              = 1'b1;
              debug_mode_n          = 1'b0;
          end
          default:;
        endcase

        if (debug_single_step_i && ~debug_mode_q) begin
          ctrl_fsm_ns = DBG_TAKEN_IF;
        end
      end

      // a branch was in ID when trying to go to debug rom. Wait until we can
      // determine branch target address (for saving into dpc) before proceeding
      DBG_WAIT_BRANCH:
      begin
        is_decoding_o = 1'b0;
        halt_if_o = 1'b1;

        if (branch_taken_ex_i) begin
          // there is a branch in the EX stage that is taken
          pc_mux_o = PC_BRANCH;
          pc_set_o = 1'b1;
        end

        ctrl_fsm_ns = DBG_FLUSH;
      end

      // We enter this state when we encounter
      // 1. ebreak during debug mode
      // 2. trigger match
      // 3. ebreak with forced entry into debug mode (ebreakm or ebreaku set).
      // 4. halt request during decode
      // Regular ebreak's go through FLUSH_EX and FLUSH_WB.
      // For 1. we don't update dcsr and dpc while for 2., 3., & 4. we do
      // dpc is set to the address of ebreak and trigger match
      // not to the next instruction's (which is why we save the pc in id).
      DBG_TAKEN_ID:
      begin
        is_decoding_o     = 1'b0;
        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_DBD;
        // If not in debug mode then save cause and dpc csrs
        // else it was an ebreak in debug mode, so don't update csrs
        if (~debug_mode_q) begin
            csr_save_cause_o = 1'b1;
            csr_save_id_o    = 1'b1;
            debug_csr_save_o = 1'b1;
            if (trigger_match_i)
                debug_cause_o = DBG_CAUSE_TRIGGER; // pri 4 (highest)
            else if (ebrk_force_debug_mode & ebrk_insn_i)
                debug_cause_o = DBG_CAUSE_EBREAK; // pri 3
            else if (debug_req_entry_q)
                debug_cause_o = DBG_CAUSE_HALTREQ;// pri 2 and 1

        end
        debug_req_entry_n  = 1'b0;
        ctrl_fsm_ns        = DECODE;
        debug_mode_n       = 1'b1;
      end

      // We enter this state for single stepping
      // DPC is set the next instruction to be executed/fetched
      DBG_TAKEN_IF:
      begin
        is_decoding_o     = 1'b0;
        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_DBD;
        csr_save_cause_o  = 1'b1;
        debug_csr_save_o  = 1'b1;
        if (debug_force_wakeup_q) 
            debug_cause_o = DBG_CAUSE_HALTREQ;
        else if (debug_single_step_i)
            debug_cause_o = DBG_CAUSE_STEP; // pri 0
        csr_save_if_o   = 1'b1;
        ctrl_fsm_ns     = DECODE;
        debug_mode_n    = 1'b1;
        debug_force_wakeup_n = 1'b0;
      end


      DBG_FLUSH:
      begin
        is_decoding_o = 1'b0;

        halt_if_o   = 1'b1;
        halt_id_o   = 1'b1;

        perf_pipeline_stall_o = data_load_event_i;

        if (data_err_i)
        begin //data error
            // the current LW or SW have been blocked by the PMP
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode
            csr_cause_o       = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
            ctrl_fsm_ns       = FLUSH_WB;
        end  //data error
        else begin
          if(debug_mode_q                          |
             trigger_match_i                       |
             (ebrk_force_debug_mode & ebrk_insn_i) |
             data_load_event_i                     |
             debug_req_entry_q                     )
            begin
              ctrl_fsm_ns = DBG_TAKEN_ID;
            end else
            begin
              // else must be debug_single_step_i
              ctrl_fsm_ns = DBG_TAKEN_IF;
            end
        end
      end
      // Debug end

      default: begin
        is_decoding_o = 1'b0;
        instr_req_o = 1'b0;
        ctrl_fsm_ns = RESET;
      end
    endcase
  end



generate
  if(COREV_PULP) begin : gen_hwlp
    //////////////////////////////////////////////////////////////////////////////
    // Convert hwlp_jump_o to a pulse
    //////////////////////////////////////////////////////////////////////////////

    // hwlp_jump_o should last one cycle only, as the prefetcher
    // reacts immediately. If it last more cycles, the prefetcher
    // goes on requesting HWLP_BEGIN more than one time (wrong!).
    // This signal is not controlled by id_ready because otherwise,
    // in case of stall, the jump would happen at the end of the stall.

    // Make hwlp_jump_o last only one cycle
    assign hwlp_jump_o = (hwlp_end_4_id_d && !hwlp_end_4_id_q) ? 1'b1 : 1'b0;

    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        hwlp_end_4_id_q <= 1'b0;
      end else begin
        hwlp_end_4_id_q <= hwlp_end_4_id_d;
      end
    end

    assign hwlp_end0_eq_pc         = hwlp_end_addr_i[0] == pc_id_i + 4;   // Equivalent to hwlp_end_addr_i[0] - 4 == pc_id_i
    assign hwlp_end1_eq_pc         = hwlp_end_addr_i[1] == pc_id_i + 4;   // Equivalent to hwlp_end_addr_i[1] - 4 == pc_id_i
    assign hwlp_counter0_gt_1      = hwlp_counter_i[0] > 1;
    assign hwlp_counter1_gt_1      = hwlp_counter_i[1] > 1;
    assign hwlp_counter0_eq_1      = hwlp_counter_i[0] == 1;
    assign hwlp_counter1_eq_1      = hwlp_counter_i[1] == 1;
    assign hwlp_counter0_eq_0      = hwlp_counter_i[0] == 0;
    assign hwlp_counter1_eq_0      = hwlp_counter_i[1] == 0;
    assign hwlp_end0_eq_pc_plus4   = hwlp_end_addr_i[0] == pc_id_i + 8;   // Equivalent to hwlp_end_addr_i[0] - 4 == pc_id_i + 4
    assign hwlp_end1_eq_pc_plus4   = hwlp_end_addr_i[1] == pc_id_i + 8;   // Equivalent to hwlp_end_addr_i[1] - 4 == pc_id_i + 4
    assign hwlp_start0_leq_pc      = hwlp_start_addr_i[0] <= pc_id_i;
    assign hwlp_start1_leq_pc      = hwlp_start_addr_i[1] <= pc_id_i;
    assign hwlp_end0_geq_pc        = hwlp_end_addr_i[0] >= pc_id_i + 4;   // Equivalent to hwlp_end_addr_i[0] - 4 >= pc_id_i
    assign hwlp_end1_geq_pc        = hwlp_end_addr_i[1] >= pc_id_i + 4;   // Equivalent to hwlp_end_addr_i[1] - 4 >= pc_id_i;
    assign is_hwlp_body            = ((hwlp_start0_leq_pc && hwlp_end0_geq_pc) && hwlp_counter0_gt_1) ||  ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && hwlp_counter1_gt_1);

  end else begin : gen_no_hwlp

    assign hwlp_jump_o             = 1'b0;
    assign hwlp_end_4_id_q         = 1'b0;
    assign hwlp_end0_eq_pc         = 1'b0;
    assign hwlp_end1_eq_pc         = 1'b0;
    assign hwlp_counter0_gt_1      = 1'b0;
    assign hwlp_counter1_gt_1      = 1'b0;
    assign hwlp_counter0_eq_1      = 1'b0;
    assign hwlp_counter1_eq_1      = 1'b0;
    assign hwlp_counter0_eq_0      = 1'b0;
    assign hwlp_counter1_eq_0      = 1'b0;
    assign hwlp_end0_eq_pc_plus4   = 1'b0;
    assign hwlp_end1_eq_pc_plus4   = 1'b0;
    assign hwlp_start0_leq_pc      = 1'b0;
    assign hwlp_start1_leq_pc      = 1'b0;
    assign hwlp_end0_geq_pc        = 1'b0;
    assign hwlp_end1_geq_pc        = 1'b0;
    assign is_hwlp_body            = 1'b0;

  end

endgenerate

  /////////////////////////////////////////////////////////////
  //  ____  _        _ _    ____            _             _  //
  // / ___|| |_ __ _| | |  / ___|___  _ __ | |_ _ __ ___ | | //
  // \___ \| __/ _` | | | | |   / _ \| '_ \| __| '__/ _ \| | //
  //  ___) | || (_| | | | | |__| (_) | | | | |_| | | (_) | | //
  // |____/ \__\__,_|_|_|  \____\___/|_| |_|\__|_|  \___/|_| //
  //                                                         //
  /////////////////////////////////////////////////////////////
  always_comb
  begin
    load_stall_o   = 1'b0;
    deassert_we_o  = 1'b0;

    // deassert WE when the core is not decoding instructions
    if (~is_decoding_o)
      deassert_we_o = 1'b1;

    // deassert WE in case of illegal instruction
    if (illegal_insn_i)
      deassert_we_o = 1'b1;

    // Stall because of load operation
    if (
          ( (data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1) ||
           (wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1)
          ) &&
          ( (reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1) || (reg_d_ex_is_reg_c_i == 1'b1) ||
            (is_decoding_o && (regfile_we_id_i && !data_misaligned_i) && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)) )
       )
    begin
      deassert_we_o   = 1'b1;
      load_stall_o    = 1'b1;
    end

    // Stall because of jr path
    // - always stall if a result is to be forwarded to the PC
    // we don't care about in which state the ctrl_fsm is as we deassert_we
    // anyway when we are not in DECODE
    if ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
        (((regfile_we_wb_i == 1'b1) && (reg_d_wb_is_reg_a_i == 1'b1)) ||
         ((regfile_we_ex_i == 1'b1) && (reg_d_ex_is_reg_a_i == 1'b1)) ||
         ((regfile_alu_we_fw_i == 1'b1) && (reg_d_alu_is_reg_a_i == 1'b1)) ||
         (FPU && (apu_read_dep_for_jalr_i == 1'b1))
        )
       )
    begin
      jr_stall_o      = 1'b1;
      deassert_we_o   = 1'b1;
    end
    else
    begin
      jr_stall_o     = 1'b0;
    end
  end


  // stall because of misaligned data access
  assign misaligned_stall_o = data_misaligned_i;

  // APU dependency stalls (data hazards)
  assign apu_stall_o = apu_read_dep_i | (apu_write_dep_i & ~apu_en_i);

  // Forwarding control unit
  always_comb
  begin
    // default assignements
    operand_a_fw_mux_sel_o = SEL_REGFILE;
    operand_b_fw_mux_sel_o = SEL_REGFILE;
    operand_c_fw_mux_sel_o = SEL_REGFILE;

    // Forwarding WB -> ID
    if (regfile_we_wb_i == 1'b1)
    begin
      if (reg_d_wb_is_reg_a_i == 1'b1)
        operand_a_fw_mux_sel_o = SEL_FW_WB;
      if (reg_d_wb_is_reg_b_i == 1'b1)
        operand_b_fw_mux_sel_o = SEL_FW_WB;
      if (reg_d_wb_is_reg_c_i == 1'b1)
        operand_c_fw_mux_sel_o = SEL_FW_WB;
    end

    // Forwarding EX -> ID
    if (regfile_alu_we_fw_i == 1'b1)
    begin
     if (reg_d_alu_is_reg_a_i == 1'b1)
       operand_a_fw_mux_sel_o = SEL_FW_EX;
     if (reg_d_alu_is_reg_b_i == 1'b1)
       operand_b_fw_mux_sel_o = SEL_FW_EX;
     if (reg_d_alu_is_reg_c_i == 1'b1)
       operand_c_fw_mux_sel_o = SEL_FW_EX;
    end

    // for misaligned memory accesses
    if (data_misaligned_i)
    begin
      operand_a_fw_mux_sel_o  = SEL_FW_EX;
      operand_b_fw_mux_sel_o  = SEL_REGFILE;
    end else if (mult_multicycle_i) begin
      operand_c_fw_mux_sel_o  = SEL_FW_EX;
    end
  end

  // update registers
  always_ff @(posedge clk , negedge rst_n)
  begin : UPDATE_REGS
    if ( rst_n == 1'b0 )
    begin
      ctrl_fsm_cs        <= RESET;
      jump_done_q        <= 1'b0;
      data_err_q         <= 1'b0;

      debug_mode_q       <= 1'b0;
      illegal_insn_q     <= 1'b0;

      debug_req_entry_q  <= 1'b0;
      debug_force_wakeup_q <= 1'b0;
    end
    else
    begin
      ctrl_fsm_cs        <= ctrl_fsm_ns;

      // clear when id is valid (no instruction incoming)
      jump_done_q        <= jump_done & (~id_ready_i);

      data_err_q         <= data_err_i;

      debug_mode_q       <= debug_mode_n;

      illegal_insn_q     <= illegal_insn_n;

      debug_req_entry_q  <= debug_req_entry_n;
      debug_force_wakeup_q <= debug_force_wakeup_n;
    end
  end

  // wakeup from sleep conditions
  assign wake_from_sleep_o = irq_wu_ctrl_i || debug_req_pending || debug_mode_q;

  // debug mode
  assign debug_mode_o = debug_mode_q;
  assign debug_req_pending = debug_req_i || debug_req_q;

  // Do not let cv.elw cause core_sleep_o during debug
  assign debug_p_elw_no_sleep_o = debug_mode_q || debug_req_q || debug_single_step_i || trigger_match_i;

  // Do not let WFI cause core_sleep_o (but treat as NOP):
  //
  // - During debug
  // - For PULP Cluster (only cv.elw can trigger sleep)

  assign debug_wfi_no_sleep_o = debug_mode_q || debug_req_pending || debug_single_step_i || trigger_match_i || COREV_CLUSTER;

  // Gate off wfi 
  assign wfi_active = wfi_i & ~debug_wfi_no_sleep_o;

  // sticky version of debug_req (must be on clk_ungated_i such that incoming pulse before core is enabled is not missed)
  always_ff @(posedge clk_ungated_i, negedge rst_n)
    if ( !rst_n )
      debug_req_q <= 1'b0;
    else
      if( debug_req_i )
        debug_req_q <= 1'b1;
      else if( debug_mode_q )
        debug_req_q <= 1'b0;

  // Debug state FSM
  always_ff @(posedge clk , negedge rst_n)
  begin
    if ( rst_n == 1'b0 )
    begin
      debug_fsm_cs <= HAVERESET;
    end
    else
    begin
      debug_fsm_cs <= debug_fsm_ns;
    end
  end

  always_comb
  begin
    debug_fsm_ns = debug_fsm_cs;

    case (debug_fsm_cs)
      HAVERESET:
      begin
        if (debug_mode_n || (ctrl_fsm_ns == FIRST_FETCH)) begin
          if (debug_mode_n) begin
            debug_fsm_ns = HALTED;
          end else begin
            debug_fsm_ns = RUNNING;
          end
        end
      end

      RUNNING:
      begin
        if (debug_mode_n) begin
          debug_fsm_ns = HALTED;
        end
      end

      HALTED:
      begin
        if (!debug_mode_n) begin
          debug_fsm_ns = RUNNING;
        end
      end

      default: begin
        debug_fsm_ns = HAVERESET;
      end
    endcase
  end

  assign debug_havereset_o = debug_fsm_cs[HAVERESET_INDEX];
  assign debug_running_o = debug_fsm_cs[RUNNING_INDEX];
  assign debug_halted_o = debug_fsm_cs[HALTED_INDEX];

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

`ifdef CV32E40P_ASSERT_ON

  // make sure that taken branches do not happen back-to-back, as this is not
  // possible without branch prediction in the IF stage
  assert property (
    @(posedge clk) (branch_taken_ex_i) |=> (~branch_taken_ex_i) ) else $warning("Two branches back-to-back are taken");

  // ELW_EXE and IRQ_FLUSH_ELW states are only used for COREV_CLUSTER = 1
  property p_pulp_cluster_only_states;
     @(posedge clk) (1'b1) |-> ( !((COREV_CLUSTER == 1'b0) && ((ctrl_fsm_cs == ELW_EXE) || (ctrl_fsm_cs == IRQ_FLUSH_ELW))) );
  endproperty

  a_pulp_cluster_only_states : assert property(p_pulp_cluster_only_states);

  // WAIT_SLEEP and SLEEP states are never used for COREV_CLUSTER = 1
  property p_pulp_cluster_excluded_states;
     @(posedge clk) (1'b1) |-> ( !((COREV_CLUSTER == 1'b1) && ((ctrl_fsm_cs == SLEEP) || (ctrl_fsm_cs == WAIT_SLEEP))) );
  endproperty

  a_pulp_cluster_excluded_states : assert property(p_pulp_cluster_excluded_states);

  generate
  if (COREV_PULP) begin : gen_pulp_xpulp_assertions

    // HWLoop 0 and 1 having target address constraints
    property p_hwlp_same_target_address;
       @(posedge clk) (hwlp_counter_i[1] > 1 && hwlp_counter_i[0] > 1) |-> ( hwlp_end_addr_i[1] - 4 >= hwlp_end_addr_i[0] - 4 + 8 );
    endproperty

    a_hwlp_same_target_address : assert property(p_hwlp_same_target_address) else $warning("%t, HWLoops target address do not respect constraints", $time);

  end else begin : gen_no_pulp_xpulp_assertions

    property p_no_hwlp;
       @(posedge clk) (1'b1) |-> ((pc_mux_o != PC_HWLOOP) && (ctrl_fsm_cs != DECODE_HWLOOP) &&
                                  (hwlp_mask_o == 1'b0) && (is_hwlp_body == 'b0) &&
                                  (hwlp_start_addr_i == 'b0) && (hwlp_end_addr_i == 'b0) && (hwlp_counter_i[1] == 32'b0) && (hwlp_counter_i[0] == 32'b0) &&
                                  (hwlp_dec_cnt_o == 2'b0) && (hwlp_jump_o == 1'b0) && (hwlp_targ_addr_o == 32'b0) &&
                                  (hwlp_end0_eq_pc == 1'b0) && (hwlp_end1_eq_pc == 1'b0) && (hwlp_counter0_gt_1 == 1'b0) && (hwlp_counter1_gt_1 == 1'b0) &&
                                  (hwlp_counter0_eq_1 == 1'b0) && (hwlp_counter1_eq_1 == 1'b0) &&
                                  (hwlp_end0_eq_pc_plus4 == 1'b0) && (hwlp_end1_eq_pc_plus4 == 1'b0) && (hwlp_start0_leq_pc == 0) && (hwlp_start1_leq_pc == 0) &&
                                  (hwlp_end0_geq_pc == 1'b0) && (hwlp_end1_geq_pc == 1'b0) && (hwlp_end_4_id_d == 1'b0) && (hwlp_end_4_id_q == 1'b0));
    endproperty

    a_no_hwlp : assert property(p_no_hwlp);

  end
  endgenerate

  // Ensure DBG_TAKEN_IF can only be enterred if in single step mode or woken
  // up from sleep by debug_req_i
         
  a_single_step_dbg_taken_if : assert property (@(posedge clk)  disable iff (!rst_n)  (ctrl_fsm_ns==DBG_TAKEN_IF) |-> ((~debug_mode_q && debug_single_step_i) || debug_force_wakeup_n));

  // Ensure DBG_FLUSH state is only one cycle. This implies that cause is either trigger, debug_req_entry, or ebreak
  a_dbg_flush : assert property (@(posedge clk)  disable iff (!rst_n)  (ctrl_fsm_cs==DBG_FLUSH) |-> (ctrl_fsm_ns!=DBG_FLUSH) );

  // Ensure that debug state outputs are one-hot
  a_debug_state_onehot : assert property (@(posedge clk) $onehot({debug_havereset_o, debug_running_o, debug_halted_o}));

  // Ensure that debug_halted_o equals debug_mode_q
  a_debug_halted_equals_debug_mode : assert property (@(posedge clk) disable iff (!rst_n) (1'b1) |-> (debug_mode_q == debug_halted_o));

  // Ensure ID always ready in FIRST_FETCH state
  a_first_fetch_id_ready : assert property (@(posedge clk) disable iff (!rst_n) (ctrl_fsm_cs == FIRST_FETCH) |-> (id_ready_i == 1'b1));

  // Ensure that the only way to get to DBG_TAKEN_IF from DBG_FLUSH is if debug_single_step_i is asserted
  a_dbg_flush_to_taken_if : assert property (@(posedge clk) disable iff (!rst_n) (ctrl_fsm_cs == DBG_FLUSH) && (ctrl_fsm_ns == DBG_TAKEN_IF) |-> debug_single_step_i);

`endif

endmodule // cv32e40p_controller

// -------------------- END OF rtl/cv32e40p_controller.sv --------------------

// -------------------- START OF rtl/cv32e40p_core.sv --------------------
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
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Top level module                                           //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Top level module of the RISC-V core.                       //
//                 added APU, FPU parameter to include the APU_dispatcher     //
//                 and the FPU                                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_core
  import cv32e40p_apu_core_pkg::*;
#(
    parameter COREV_PULP =  0,  // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
    parameter COREV_CLUSTER = 0,  // PULP Cluster interface (incl. cv.elw)
    parameter FPU = 0,  // Floating Point Unit (interfaced via APU interface)
    parameter FPU_ADDMUL_LAT = 0,  // Floating-Point ADDition/MULtiplication lane pipeline registers number
    parameter FPU_OTHERS_LAT = 0,  // Floating-Point COMParison/CONVersion lanes pipeline registers number
    parameter ZFINX = 0,  // Float-in-General Purpose registers
    parameter NUM_MHPMCOUNTERS = 1
) (
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    input logic pulp_clock_en_i,  // PULP clock enable (only used if COREV_CLUSTER = 1)
    input logic scan_cg_en_i,  // Enable all clock gates for testing

    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    input logic [31:0] boot_addr_i,
    input logic [31:0] mtvec_addr_i,
    input logic [31:0] dm_halt_addr_i,
    input logic [31:0] hart_id_i,
    input logic [31:0] dm_exception_addr_i,

    // Instruction memory interface
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,

    // Data memory interface
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,

    // apu-interconnect
    // handshake signals
    output logic                              apu_req_o,
    input  logic                              apu_gnt_i,
    // request channel
    output logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_o,
    output logic [     APU_WOP_CPU-1:0]       apu_op_o,
    output logic [APU_NDSFLAGS_CPU-1:0]       apu_flags_o,
    // response channel
    input  logic                              apu_rvalid_i,
    input  logic [                31:0]       apu_result_i,
    input  logic [APU_NUSFLAGS_CPU-1:0]       apu_flags_i,

    // Interrupt inputs
    input  logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o,

    // Debug Interface
    input  logic debug_req_i,
    output logic debug_havereset_o,
    output logic debug_running_o,
    output logic debug_halted_o,

    // CPU Control Signals
    input  logic fetch_enable_i,
    output logic core_sleep_o
);

  import cv32e40p_pkg::*;

  // Unused parameters and signals (left in code for future design extensions)
  localparam PULP_SECURE = 0;
  localparam N_PMP_ENTRIES = 16;
  localparam USE_PMP = 0;  // if PULP_SECURE is 1, you can still not use the PMP
  localparam A_EXTENSION = 0;
  localparam DEBUG_TRIGGER_EN = 1;

  // PULP bus interface behavior
  // If enabled will allow non-stable address phase signals during waited instructions requests and
  // will re-introduce combinatorial paths from instr_rvalid_i to instr_req_o and from from data_rvalid_i
  // to data_req_o
  localparam PULP_OBI = 0;

  // Unused signals related to above unused parameters
  // Left in code (with their original _i, _o postfixes) for future design extensions;
  // these used to be former inputs/outputs of RI5CY

  logic [5:0] data_atop_o;  // atomic operation, only active if parameter `A_EXTENSION != 0`
  logic       irq_sec_i;
  logic       sec_lvl_o;

  localparam N_HWLP = 2;
  localparam APU = (FPU == 1) ? 1 : 0;

  // IF/ID signals
  logic        instr_valid_id;
  logic [31:0] instr_rdata_id;  // Instruction sampled inside IF stage
  logic        is_compressed_id;
  logic        illegal_c_insn_id;
  logic        is_fetch_failed_id;

  logic        clear_instr_valid;
  logic        pc_set;

  logic [ 3:0] pc_mux_id;  // Mux selector for next PC
  logic [ 2:0] exc_pc_mux_id;  // Mux selector for exception PC
  logic [ 4:0] m_exc_vec_pc_mux_id;  // Mux selector for vectored IRQ PC
  logic [ 4:0] u_exc_vec_pc_mux_id;  // Mux selector for vectored IRQ PC
  logic [ 4:0] exc_cause;

  logic [ 1:0] trap_addr_mux;

  logic [31:0] pc_if;  // Program counter in IF stage
  logic [31:0] pc_id;  // Program counter in ID stage

  // ID performance counter signals
  logic        is_decoding;

  logic        useincr_addr_ex;  // Active when post increment
  logic        data_misaligned;

  logic        mult_multicycle;

  // Jump and branch target and decision (EX->IF)
  logic [31:0] jump_target_id, jump_target_ex;
  logic               branch_in_ex;
  logic               branch_decision;
  logic        [ 1:0] ctrl_transfer_insn_in_dec;

  logic               ctrl_busy;
  logic               if_busy;
  logic               lsu_busy;
  logic               apu_busy;

  logic        [31:0] pc_ex;  // PC of last executed branch or cv.elw

  // ALU Control
  logic               alu_en_ex;
  alu_opcode_e        alu_operator_ex;
  logic        [31:0] alu_operand_a_ex;
  logic        [31:0] alu_operand_b_ex;
  logic        [31:0] alu_operand_c_ex;
  logic        [ 4:0] bmask_a_ex;
  logic        [ 4:0] bmask_b_ex;
  logic        [ 1:0] imm_vec_ext_ex;
  logic        [ 1:0] alu_vec_mode_ex;
  logic alu_is_clpx_ex, alu_is_subrot_ex;
  logic        [                 1:0]       alu_clpx_shift_ex;

  // Multiplier Control
  mul_opcode_e                              mult_operator_ex;
  logic        [                31:0]       mult_operand_a_ex;
  logic        [                31:0]       mult_operand_b_ex;
  logic        [                31:0]       mult_operand_c_ex;
  logic                                     mult_en_ex;
  logic                                     mult_sel_subword_ex;
  logic        [                 1:0]       mult_signed_mode_ex;
  logic        [                 4:0]       mult_imm_ex;
  logic        [                31:0]       mult_dot_op_a_ex;
  logic        [                31:0]       mult_dot_op_b_ex;
  logic        [                31:0]       mult_dot_op_c_ex;
  logic        [                 1:0]       mult_dot_signed_ex;
  logic                                     mult_is_clpx_ex;
  logic        [                 1:0]       mult_clpx_shift_ex;
  logic                                     mult_clpx_img_ex;

  // FPU
  logic                                     fs_off;
  logic        [            C_RM-1:0]       frm_csr;
  logic        [         C_FFLAG-1:0]       fflags_csr;
  logic                                     fflags_we;
  logic                                     fregs_we;

  // APU
  logic                                     apu_en_ex;
  logic        [APU_NDSFLAGS_CPU-1:0]       apu_flags_ex;
  logic        [     APU_WOP_CPU-1:0]       apu_op_ex;
  logic        [                 1:0]       apu_lat_ex;
  logic        [   APU_NARGS_CPU-1:0][31:0] apu_operands_ex;
  logic        [                 5:0]       apu_waddr_ex;

  logic        [                 2:0][ 5:0] apu_read_regs;
  logic        [                 2:0]       apu_read_regs_valid;
  logic                                     apu_read_dep;
  logic                                     apu_read_dep_for_jalr;
  logic        [                 1:0][ 5:0] apu_write_regs;
  logic        [                 1:0]       apu_write_regs_valid;
  logic                                     apu_write_dep;

  logic                                     perf_apu_type;
  logic                                     perf_apu_cont;
  logic                                     perf_apu_dep;
  logic                                     perf_apu_wb;

  // Register Write Control
  logic        [                 5:0]       regfile_waddr_ex;
  logic                                     regfile_we_ex;
  logic        [                 5:0]       regfile_waddr_fw_wb_o;  // From WB to ID
  logic                                     regfile_we_wb;
  logic                                     regfile_we_wb_power;
  logic        [                31:0]       regfile_wdata;

  logic        [                 5:0]       regfile_alu_waddr_ex;
  logic                                     regfile_alu_we_ex;

  logic        [                 5:0]       regfile_alu_waddr_fw;
  logic                                     regfile_alu_we_fw;
  logic                                     regfile_alu_we_fw_power;
  logic        [                31:0]       regfile_alu_wdata_fw;

  // CSR control
  logic                                     csr_access_ex;
  csr_opcode_e                              csr_op_ex;
  logic [23:0] mtvec, utvec;
  logic        [ 1:0] mtvec_mode;
  logic        [ 1:0] utvec_mode;

  csr_opcode_e        csr_op;
  csr_num_e           csr_addr;
  csr_num_e           csr_addr_int;
  logic        [31:0] csr_rdata;
  logic        [31:0] csr_wdata;
  PrivLvl_t           current_priv_lvl;

  // Data Memory Control:  From ID stage (id-ex pipe) <--> load store unit
  logic               data_we_ex;
  logic        [ 5:0] data_atop_ex;
  logic        [ 1:0] data_type_ex;
  logic        [ 1:0] data_sign_ext_ex;
  logic        [ 1:0] data_reg_offset_ex;
  logic               data_req_ex;
  logic               data_load_event_ex;
  logic               data_misaligned_ex;

  logic               p_elw_start;  // Start of cv.elw load (when data_req_o is sent)
  logic               p_elw_finish;  // Finish of cv.elw load (when data_rvalid_i is received)

  logic        [31:0] lsu_rdata;

  // stall control
  logic               halt_if;
  logic               id_ready;
  logic               ex_ready;

  logic               id_valid;
  logic               ex_valid;
  logic               wb_valid;

  logic               lsu_ready_ex;
  logic               lsu_ready_wb;

  logic               apu_ready_wb;

  // Signals between instruction core interface and pipe (if and id stages)
  logic               instr_req_int;  // Id stage asserts a req to instruction core interface

  // Interrupts
  logic m_irq_enable, u_irq_enable;
  logic csr_irq_sec;
  logic [31:0] mepc, uepc, depc;
  logic [             31:0]       mie_bypass;
  logic [             31:0]       mip;

  logic                           csr_save_cause;
  logic                           csr_save_if;
  logic                           csr_save_id;
  logic                           csr_save_ex;
  logic [              5:0]       csr_cause;
  logic                           csr_restore_mret_id;
  logic                           csr_restore_uret_id;
  logic                           csr_restore_dret_id;
  logic                           csr_mtvec_init;

  // HPM related control signals
  logic [             31:0]       mcounteren;

  // debug mode and dcsr configuration
  logic                           debug_mode;
  logic [              2:0]       debug_cause;
  logic                           debug_csr_save;
  logic                           debug_single_step;
  logic                           debug_ebreakm;
  logic                           debug_ebreaku;
  logic                           trigger_match;
  logic                           debug_p_elw_no_sleep;

  // Hardware loop controller signals
  logic [       N_HWLP-1:0][31:0] hwlp_start;
  logic [       N_HWLP-1:0][31:0] hwlp_end;
  logic [       N_HWLP-1:0][31:0] hwlp_cnt;

  logic [             31:0]       hwlp_target;
  logic                           hwlp_jump;

  // Performance Counters
  logic                           mhpmevent_minstret;
  logic                           mhpmevent_load;
  logic                           mhpmevent_store;
  logic                           mhpmevent_jump;
  logic                           mhpmevent_branch;
  logic                           mhpmevent_branch_taken;
  logic                           mhpmevent_compressed;
  logic                           mhpmevent_jr_stall;
  logic                           mhpmevent_imiss;
  logic                           mhpmevent_ld_stall;
  logic                           mhpmevent_pipe_stall;

  logic                           perf_imiss;

  // Wake signal
  logic                           wake_from_sleep;

  // PMP signals
  logic [N_PMP_ENTRIES-1:0][31:0] pmp_addr;
  logic [N_PMP_ENTRIES-1:0][ 7:0] pmp_cfg;

  logic                           data_req_pmp;
  logic [             31:0]       data_addr_pmp;
  logic                           data_gnt_pmp;
  logic                           data_err_pmp;
  logic                           data_err_ack;
  logic                           instr_req_pmp;
  logic                           instr_gnt_pmp;
  logic [             31:0]       instr_addr_pmp;
  logic                           instr_err_pmp;

  // Mux selector for vectored IRQ PC
  assign m_exc_vec_pc_mux_id = (mtvec_mode == 2'b0) ? 5'h0 : exc_cause;
  assign u_exc_vec_pc_mux_id = (utvec_mode == 2'b0) ? 5'h0 : exc_cause;

  // PULP_SECURE == 0
  assign irq_sec_i = 1'b0;

  // APU master signals
  assign apu_flags_o = apu_flags_ex;

  //////////////////////////////////////////////////////////////////////////////////////////////
  //   ____ _            _      __  __                                                   _    //
  //  / ___| | ___   ___| | __ |  \/  | __ _ _ __   __ _  __ _  ___ _ __ ___   ___ _ __ | |_  //
  // | |   | |/ _ \ / __| |/ / | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _ \ '_ \| __| //
  // | |___| | (_) | (__|   <  | |  | | (_| | | | | (_| | (_| |  __/ | | | | |  __/ | | | |_  //
  //  \____|_|\___/ \___|_|\_\ |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|\___|_| |_|\__| //
  //                                                     |___/                                //
  //////////////////////////////////////////////////////////////////////////////////////////////

  logic clk;
  logic fetch_enable;

  cv32e40p_sleep_unit #(
      .COREV_CLUSTER(COREV_CLUSTER)
  ) sleep_unit_i (
      // Clock, reset interface
      .clk_ungated_i(clk_i),  // Ungated clock
      .rst_n        (rst_ni),
      .clk_gated_o  (clk),  // Gated clock
      .scan_cg_en_i (scan_cg_en_i),

      // Core sleep
      .core_sleep_o(core_sleep_o),

      // Fetch enable
      .fetch_enable_i(fetch_enable_i),
      .fetch_enable_o(fetch_enable),

      // Core status
      .if_busy_i  (if_busy),
      .ctrl_busy_i(ctrl_busy),
      .lsu_busy_i (lsu_busy),
      .apu_busy_i (apu_busy),

      // PULP cluster
      .pulp_clock_en_i       (pulp_clock_en_i),
      .p_elw_start_i         (p_elw_start),
      .p_elw_finish_i        (p_elw_finish),
      .debug_p_elw_no_sleep_i(debug_p_elw_no_sleep),

      // WFI wake
      .wake_from_sleep_i(wake_from_sleep)
  );


  //////////////////////////////////////////////////
  //   ___ _____   ____ _____  _    ____ _____    //
  //  |_ _|  ___| / ___|_   _|/ \  / ___| ____|   //
  //   | || |_    \___ \ | | / _ \| |  _|  _|     //
  //   | ||  _|    ___) || |/ ___ \ |_| | |___    //
  //  |___|_|     |____/ |_/_/   \_\____|_____|   //
  //                                              //
  //////////////////////////////////////////////////
  cv32e40p_if_stage #(
      .COREV_PULP (COREV_PULP),
      .PULP_OBI   (PULP_OBI),
      .PULP_SECURE(PULP_SECURE),
      .FPU        (FPU),
      .ZFINX      (ZFINX)
  ) if_stage_i (
      .clk  (clk),
      .rst_n(rst_ni),

      // boot address
      .boot_addr_i        (boot_addr_i[31:0]),
      .dm_exception_addr_i(dm_exception_addr_i[31:0]),

      // debug mode halt address
      .dm_halt_addr_i(dm_halt_addr_i[31:0]),

      // trap vector location
      .m_trap_base_addr_i(mtvec),
      .u_trap_base_addr_i(utvec),
      .trap_addr_mux_i   (trap_addr_mux),

      // instruction request control
      .req_i(instr_req_int),

      // instruction cache interface
      .instr_req_o    (instr_req_pmp),
      .instr_addr_o   (instr_addr_pmp),
      .instr_gnt_i    (instr_gnt_pmp),
      .instr_rvalid_i (instr_rvalid_i),
      .instr_rdata_i  (instr_rdata_i),
      .instr_err_i    (1'b0),  // Bus error (not used yet)
      .instr_err_pmp_i(instr_err_pmp),  // PMP error

      // outputs to ID stage
      .instr_valid_id_o (instr_valid_id),
      .instr_rdata_id_o (instr_rdata_id),
      .is_fetch_failed_o(is_fetch_failed_id),

      // control signals
      .clear_instr_valid_i(clear_instr_valid),
      .pc_set_i           (pc_set),

      .mepc_i(mepc),  // exception return address
      .uepc_i(uepc),  // exception return address

      .depc_i(depc),  // debug return address

      .pc_mux_i    (pc_mux_id),  // sel for pc multiplexer
      .exc_pc_mux_i(exc_pc_mux_id),


      .pc_id_o(pc_id),
      .pc_if_o(pc_if),

      .is_compressed_id_o (is_compressed_id),
      .illegal_c_insn_id_o(illegal_c_insn_id),

      .m_exc_vec_pc_mux_i(m_exc_vec_pc_mux_id),
      .u_exc_vec_pc_mux_i(u_exc_vec_pc_mux_id),

      .csr_mtvec_init_o(csr_mtvec_init),

      // from hwloop registers
      .hwlp_jump_i  (hwlp_jump),
      .hwlp_target_i(hwlp_target),


      // Jump targets
      .jump_target_id_i(jump_target_id),
      .jump_target_ex_i(jump_target_ex),

      // pipeline stalls
      .halt_if_i (halt_if),
      .id_ready_i(id_ready),

      .if_busy_o   (if_busy),
      .perf_imiss_o(perf_imiss)
  );


  /////////////////////////////////////////////////
  //   ___ ____    ____ _____  _    ____ _____   //
  //  |_ _|  _ \  / ___|_   _|/ \  / ___| ____|  //
  //   | || | | | \___ \ | | / _ \| |  _|  _|    //
  //   | || |_| |  ___) || |/ ___ \ |_| | |___   //
  //  |___|____/  |____/ |_/_/   \_\____|_____|  //
  //                                             //
  /////////////////////////////////////////////////
  cv32e40p_id_stage #(
      .COREV_PULP      (COREV_PULP),
      .COREV_CLUSTER   (COREV_CLUSTER),
      .N_HWLP          (N_HWLP),
      .PULP_SECURE     (PULP_SECURE),
      .USE_PMP         (USE_PMP),
      .A_EXTENSION     (A_EXTENSION),
      .APU             (APU),
      .FPU             (FPU),
      .FPU_ADDMUL_LAT  (FPU_ADDMUL_LAT),
      .FPU_OTHERS_LAT  (FPU_OTHERS_LAT),
      .ZFINX           (ZFINX),
      .APU_NARGS_CPU   (APU_NARGS_CPU),
      .APU_WOP_CPU     (APU_WOP_CPU),
      .APU_NDSFLAGS_CPU(APU_NDSFLAGS_CPU),
      .APU_NUSFLAGS_CPU(APU_NUSFLAGS_CPU),
      .DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
  ) id_stage_i (
      .clk          (clk),  // Gated clock
      .clk_ungated_i(clk_i),  // Ungated clock
      .rst_n        (rst_ni),

      .scan_cg_en_i(scan_cg_en_i),

      // Processor Enable
      .fetch_enable_i               ( fetch_enable         ),     // Delayed version so that clock can remain gated until fetch enabled
      .ctrl_busy_o(ctrl_busy),
      .is_decoding_o(is_decoding),

      // Interface to instruction memory
      .instr_valid_i(instr_valid_id),
      .instr_rdata_i(instr_rdata_id),
      .instr_req_o  (instr_req_int),

      // Jumps and branches
      .branch_in_ex_o             (branch_in_ex),
      .branch_decision_i          (branch_decision),
      .jump_target_o              (jump_target_id),
      .ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec),

      // IF and ID control signals
      .clear_instr_valid_o(clear_instr_valid),
      .pc_set_o           (pc_set),
      .pc_mux_o           (pc_mux_id),
      .exc_pc_mux_o       (exc_pc_mux_id),
      .exc_cause_o        (exc_cause),
      .trap_addr_mux_o    (trap_addr_mux),

      .is_fetch_failed_i(is_fetch_failed_id),

      .pc_id_i(pc_id),

      .is_compressed_i (is_compressed_id),
      .illegal_c_insn_i(illegal_c_insn_id),

      // Stalls
      .halt_if_o(halt_if),

      .id_ready_o(id_ready),
      .ex_ready_i(ex_ready),
      .wb_ready_i(lsu_ready_wb),

      .id_valid_o(id_valid),
      .ex_valid_i(ex_valid),

      // From the Pipeline ID/EX
      .pc_ex_o(pc_ex),

      .alu_en_ex_o        (alu_en_ex),
      .alu_operator_ex_o  (alu_operator_ex),
      .alu_operand_a_ex_o (alu_operand_a_ex),
      .alu_operand_b_ex_o (alu_operand_b_ex),
      .alu_operand_c_ex_o (alu_operand_c_ex),
      .bmask_a_ex_o       (bmask_a_ex),
      .bmask_b_ex_o       (bmask_b_ex),
      .imm_vec_ext_ex_o   (imm_vec_ext_ex),
      .alu_vec_mode_ex_o  (alu_vec_mode_ex),
      .alu_is_clpx_ex_o   (alu_is_clpx_ex),
      .alu_is_subrot_ex_o (alu_is_subrot_ex),
      .alu_clpx_shift_ex_o(alu_clpx_shift_ex),

      .regfile_waddr_ex_o(regfile_waddr_ex),
      .regfile_we_ex_o   (regfile_we_ex),

      .regfile_alu_we_ex_o   (regfile_alu_we_ex),
      .regfile_alu_waddr_ex_o(regfile_alu_waddr_ex),

      // MUL
      .mult_operator_ex_o   (mult_operator_ex),  // from ID to EX stage
      .mult_en_ex_o         (mult_en_ex),  // from ID to EX stage
      .mult_sel_subword_ex_o(mult_sel_subword_ex),  // from ID to EX stage
      .mult_signed_mode_ex_o(mult_signed_mode_ex),  // from ID to EX stage
      .mult_operand_a_ex_o  (mult_operand_a_ex),  // from ID to EX stage
      .mult_operand_b_ex_o  (mult_operand_b_ex),  // from ID to EX stage
      .mult_operand_c_ex_o  (mult_operand_c_ex),  // from ID to EX stage
      .mult_imm_ex_o        (mult_imm_ex),  // from ID to EX stage

      .mult_dot_op_a_ex_o  (mult_dot_op_a_ex),  // from ID to EX stage
      .mult_dot_op_b_ex_o  (mult_dot_op_b_ex),  // from ID to EX stage
      .mult_dot_op_c_ex_o  (mult_dot_op_c_ex),  // from ID to EX stage
      .mult_dot_signed_ex_o(mult_dot_signed_ex),  // from ID to EX stage
      .mult_is_clpx_ex_o   (mult_is_clpx_ex),  // from ID to EX stage
      .mult_clpx_shift_ex_o(mult_clpx_shift_ex),  // from ID to EX stage
      .mult_clpx_img_ex_o  (mult_clpx_img_ex),  // from ID to EX stage

      // FPU
      .fs_off_i(fs_off),
      .frm_i   (frm_csr),

      // APU
      .apu_en_ex_o      (apu_en_ex),
      .apu_op_ex_o      (apu_op_ex),
      .apu_lat_ex_o     (apu_lat_ex),
      .apu_operands_ex_o(apu_operands_ex),
      .apu_flags_ex_o   (apu_flags_ex),
      .apu_waddr_ex_o   (apu_waddr_ex),

      .apu_read_regs_o        (apu_read_regs),
      .apu_read_regs_valid_o  (apu_read_regs_valid),
      .apu_read_dep_i         (apu_read_dep),
      .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr),
      .apu_write_regs_o       (apu_write_regs),
      .apu_write_regs_valid_o (apu_write_regs_valid),
      .apu_write_dep_i        (apu_write_dep),
      .apu_perf_dep_o         (perf_apu_dep),
      .apu_busy_i             (apu_busy),

      // CSR ID/EX
      .csr_access_ex_o      (csr_access_ex),
      .csr_op_ex_o          (csr_op_ex),
      .current_priv_lvl_i   (current_priv_lvl),
      .csr_irq_sec_o        (csr_irq_sec),
      .csr_cause_o          (csr_cause),
      .csr_save_if_o        (csr_save_if),  // control signal to save pc
      .csr_save_id_o        (csr_save_id),  // control signal to save pc
      .csr_save_ex_o        (csr_save_ex),  // control signal to save pc
      .csr_restore_mret_id_o(csr_restore_mret_id),  // control signal to restore pc
      .csr_restore_uret_id_o(csr_restore_uret_id),  // control signal to restore pc

      .csr_restore_dret_id_o(csr_restore_dret_id),  // control signal to restore pc

      .csr_save_cause_o(csr_save_cause),

      // hardware loop signals to IF hwlp controller
      .hwlp_start_o(hwlp_start),
      .hwlp_end_o  (hwlp_end),
      .hwlp_cnt_o  (hwlp_cnt),

      .hwlp_jump_o  (hwlp_jump),
      .hwlp_target_o(hwlp_target),

      // LSU
      .data_req_ex_o       (data_req_ex),  // to load store unit
      .data_we_ex_o        (data_we_ex),  // to load store unit
      .atop_ex_o           (data_atop_ex),
      .data_type_ex_o      (data_type_ex),  // to load store unit
      .data_sign_ext_ex_o  (data_sign_ext_ex),  // to load store unit
      .data_reg_offset_ex_o(data_reg_offset_ex),  // to load store unit
      .data_load_event_ex_o(data_load_event_ex),  // to load store unit

      .data_misaligned_ex_o(data_misaligned_ex),  // to load store unit

      .prepost_useincr_ex_o(useincr_addr_ex),
      .data_misaligned_i   (data_misaligned),
      .data_err_i          (data_err_pmp),
      .data_err_ack_o      (data_err_ack),

      // Interrupt Signals
      .irq_i         (irq_i),
      .irq_sec_i     ((PULP_SECURE) ? irq_sec_i : 1'b0),
      .mie_bypass_i  (mie_bypass),
      .mip_o         (mip),
      .m_irq_enable_i(m_irq_enable),
      .u_irq_enable_i(u_irq_enable),
      .irq_ack_o     (irq_ack_o),
      .irq_id_o      (irq_id_o),

      // Debug Signal
      .debug_mode_o          (debug_mode),
      .debug_cause_o         (debug_cause),
      .debug_csr_save_o      (debug_csr_save),
      .debug_req_i           (debug_req_i),
      .debug_havereset_o     (debug_havereset_o),
      .debug_running_o       (debug_running_o),
      .debug_halted_o        (debug_halted_o),
      .debug_single_step_i   (debug_single_step),
      .debug_ebreakm_i       (debug_ebreakm),
      .debug_ebreaku_i       (debug_ebreaku),
      .trigger_match_i       (trigger_match),
      .debug_p_elw_no_sleep_o(debug_p_elw_no_sleep),

      // Wakeup Signal
      .wake_from_sleep_o(wake_from_sleep),

      // Forward Signals
      .regfile_waddr_wb_i   (regfile_waddr_fw_wb_o),  // Write address ex-wb pipeline
      .regfile_we_wb_i      (regfile_we_wb),  // write enable for the register file
      .regfile_we_wb_power_i(regfile_we_wb_power),
      .regfile_wdata_wb_i   (regfile_wdata),  // write data to commit in the register file

      .regfile_alu_waddr_fw_i   (regfile_alu_waddr_fw),
      .regfile_alu_we_fw_i      (regfile_alu_we_fw),
      .regfile_alu_we_fw_power_i(regfile_alu_we_fw_power),
      .regfile_alu_wdata_fw_i   (regfile_alu_wdata_fw),

      // from ALU
      .mult_multicycle_i(mult_multicycle),

      // Performance Counters
      .mhpmevent_minstret_o    (mhpmevent_minstret),
      .mhpmevent_load_o        (mhpmevent_load),
      .mhpmevent_store_o       (mhpmevent_store),
      .mhpmevent_jump_o        (mhpmevent_jump),
      .mhpmevent_branch_o      (mhpmevent_branch),
      .mhpmevent_branch_taken_o(mhpmevent_branch_taken),
      .mhpmevent_compressed_o  (mhpmevent_compressed),
      .mhpmevent_jr_stall_o    (mhpmevent_jr_stall),
      .mhpmevent_imiss_o       (mhpmevent_imiss),
      .mhpmevent_ld_stall_o    (mhpmevent_ld_stall),
      .mhpmevent_pipe_stall_o  (mhpmevent_pipe_stall),

      .perf_imiss_i(perf_imiss),
      .mcounteren_i(mcounteren)
  );


  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////
  cv32e40p_ex_stage #(
      .COREV_PULP      (COREV_PULP),
      .FPU             (FPU),
      .APU_NARGS_CPU   (APU_NARGS_CPU),
      .APU_WOP_CPU     (APU_WOP_CPU),
      .APU_NDSFLAGS_CPU(APU_NDSFLAGS_CPU),
      .APU_NUSFLAGS_CPU(APU_NUSFLAGS_CPU)
  ) ex_stage_i (
      // Global signals: Clock and active low asynchronous reset
      .clk  (clk),
      .rst_n(rst_ni),

      // Alu signals from ID stage
      .alu_en_i        (alu_en_ex),
      .alu_operator_i  (alu_operator_ex),  // from ID/EX pipe registers
      .alu_operand_a_i (alu_operand_a_ex),  // from ID/EX pipe registers
      .alu_operand_b_i (alu_operand_b_ex),  // from ID/EX pipe registers
      .alu_operand_c_i (alu_operand_c_ex),  // from ID/EX pipe registers
      .bmask_a_i       (bmask_a_ex),  // from ID/EX pipe registers
      .bmask_b_i       (bmask_b_ex),  // from ID/EX pipe registers
      .imm_vec_ext_i   (imm_vec_ext_ex),  // from ID/EX pipe registers
      .alu_vec_mode_i  (alu_vec_mode_ex),  // from ID/EX pipe registers
      .alu_is_clpx_i   (alu_is_clpx_ex),  // from ID/EX pipe registers
      .alu_is_subrot_i (alu_is_subrot_ex),  // from ID/Ex pipe registers
      .alu_clpx_shift_i(alu_clpx_shift_ex),  // from ID/EX pipe registers

      // Multipler
      .mult_operator_i   (mult_operator_ex),  // from ID/EX pipe registers
      .mult_operand_a_i  (mult_operand_a_ex),  // from ID/EX pipe registers
      .mult_operand_b_i  (mult_operand_b_ex),  // from ID/EX pipe registers
      .mult_operand_c_i  (mult_operand_c_ex),  // from ID/EX pipe registers
      .mult_en_i         (mult_en_ex),  // from ID/EX pipe registers
      .mult_sel_subword_i(mult_sel_subword_ex),  // from ID/EX pipe registers
      .mult_signed_mode_i(mult_signed_mode_ex),  // from ID/EX pipe registers
      .mult_imm_i        (mult_imm_ex),  // from ID/EX pipe registers
      .mult_dot_op_a_i   (mult_dot_op_a_ex),  // from ID/EX pipe registers
      .mult_dot_op_b_i   (mult_dot_op_b_ex),  // from ID/EX pipe registers
      .mult_dot_op_c_i   (mult_dot_op_c_ex),  // from ID/EX pipe registers
      .mult_dot_signed_i (mult_dot_signed_ex),  // from ID/EX pipe registers
      .mult_is_clpx_i    (mult_is_clpx_ex),  // from ID/EX pipe registers
      .mult_clpx_shift_i (mult_clpx_shift_ex),  // from ID/EX pipe registers
      .mult_clpx_img_i   (mult_clpx_img_ex),  // from ID/EX pipe registers

      .mult_multicycle_o(mult_multicycle),  // to ID/EX pipe registers

      .data_req_i          (data_req_o),  // from ID/EX pipeline
      .data_rvalid_i       (data_rvalid_i),  // from ID/EX pipeline
      .data_misaligned_ex_i(data_misaligned_ex),  // from ID/EX pipeline
      .data_misaligned_i   (data_misaligned),

      .ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec),

      // FPU
      .fpu_fflags_we_o(fflags_we),
      .fpu_fflags_o   (fflags_csr),

      // APU
      .apu_en_i      (apu_en_ex),
      .apu_op_i      (apu_op_ex),
      .apu_lat_i     (apu_lat_ex),
      .apu_operands_i(apu_operands_ex),
      .apu_waddr_i   (apu_waddr_ex),

      .apu_read_regs_i        (apu_read_regs),
      .apu_read_regs_valid_i  (apu_read_regs_valid),
      .apu_read_dep_o         (apu_read_dep),
      .apu_read_dep_for_jalr_o(apu_read_dep_for_jalr),
      .apu_write_regs_i       (apu_write_regs),
      .apu_write_regs_valid_i (apu_write_regs_valid),
      .apu_write_dep_o        (apu_write_dep),

      .apu_perf_type_o(perf_apu_type),
      .apu_perf_cont_o(perf_apu_cont),
      .apu_perf_wb_o  (perf_apu_wb),
      .apu_ready_wb_o (apu_ready_wb),
      .apu_busy_o     (apu_busy),

      // apu-interconnect
      // handshake signals
      .apu_req_o     (apu_req_o),
      .apu_gnt_i     (apu_gnt_i),
      // request channel
      .apu_operands_o(apu_operands_o),
      .apu_op_o      (apu_op_o),
      // response channel
      .apu_rvalid_i  (apu_rvalid_i),
      .apu_result_i  (apu_result_i),
      .apu_flags_i   (apu_flags_i),

      .lsu_en_i   (data_req_ex),
      .lsu_rdata_i(lsu_rdata),

      // interface with CSRs
      .csr_access_i(csr_access_ex),
      .csr_rdata_i (csr_rdata),

      // From ID Stage: Regfile control signals
      .branch_in_ex_i     (branch_in_ex),
      .regfile_alu_waddr_i(regfile_alu_waddr_ex),
      .regfile_alu_we_i   (regfile_alu_we_ex),

      .regfile_waddr_i(regfile_waddr_ex),
      .regfile_we_i   (regfile_we_ex),

      // Output of ex stage pipeline
      .regfile_waddr_wb_o   (regfile_waddr_fw_wb_o),
      .regfile_we_wb_o      (regfile_we_wb),
      .regfile_we_wb_power_o(regfile_we_wb_power),
      .regfile_wdata_wb_o   (regfile_wdata),

      // To IF: Jump and branch target and decision
      .jump_target_o    (jump_target_ex),
      .branch_decision_o(branch_decision),

      // To ID stage: Forwarding signals
      .regfile_alu_waddr_fw_o   (regfile_alu_waddr_fw),
      .regfile_alu_we_fw_o      (regfile_alu_we_fw),
      .regfile_alu_we_fw_power_o(regfile_alu_we_fw_power),
      .regfile_alu_wdata_fw_o   (regfile_alu_wdata_fw),

      // stall control
      .is_decoding_i (is_decoding),
      .lsu_ready_ex_i(lsu_ready_ex),
      .lsu_err_i     (data_err_pmp),

      .ex_ready_o(ex_ready),
      .ex_valid_o(ex_valid),
      .wb_ready_i(lsu_ready_wb)
  );


  ////////////////////////////////////////////////////////////////////////////////////////
  //    _     ___    _    ____    ____ _____ ___  ____  _____   _   _ _   _ ___ _____   //
  //   | |   / _ \  / \  |  _ \  / ___|_   _/ _ \|  _ \| ____| | | | | \ | |_ _|_   _|  //
  //   | |  | | | |/ _ \ | | | | \___ \ | || | | | |_) |  _|   | | | |  \| || |  | |    //
  //   | |__| |_| / ___ \| |_| |  ___) || || |_| |  _ <| |___  | |_| | |\  || |  | |    //
  //   |_____\___/_/   \_\____/  |____/ |_| \___/|_| \_\_____|  \___/|_| \_|___| |_|    //
  //                                                                                    //
  ////////////////////////////////////////////////////////////////////////////////////////

  cv32e40p_load_store_unit #(
      .PULP_OBI(PULP_OBI)
  ) load_store_unit_i (
      .clk  (clk),
      .rst_n(rst_ni),

      //output to data memory
      .data_req_o    (data_req_pmp),
      .data_gnt_i    (data_gnt_pmp),
      .data_rvalid_i (data_rvalid_i),
      .data_err_i    (1'b0),  // Bus error (not used yet)
      .data_err_pmp_i(data_err_pmp),  // PMP error

      .data_addr_o (data_addr_pmp),
      .data_we_o   (data_we_o),
      .data_atop_o (data_atop_o),
      .data_be_o   (data_be_o),
      .data_wdata_o(data_wdata_o),
      .data_rdata_i(data_rdata_i),

      // signal from ex stage
      .data_we_ex_i        (data_we_ex),
      .data_atop_ex_i      (data_atop_ex),
      .data_type_ex_i      (data_type_ex),
      .data_wdata_ex_i     (alu_operand_c_ex),
      .data_reg_offset_ex_i(data_reg_offset_ex),
      .data_load_event_ex_i(data_load_event_ex),
      .data_sign_ext_ex_i  (data_sign_ext_ex),  // sign extension

      .data_rdata_ex_o  (lsu_rdata),
      .data_req_ex_i    (data_req_ex),
      .operand_a_ex_i   (alu_operand_a_ex),
      .operand_b_ex_i   (alu_operand_b_ex),
      .addr_useincr_ex_i(useincr_addr_ex),

      .data_misaligned_ex_i(data_misaligned_ex),  // from ID/EX pipeline
      .data_misaligned_o   (data_misaligned),

      .p_elw_start_o (p_elw_start),
      .p_elw_finish_o(p_elw_finish),

      // control signals
      .lsu_ready_ex_o(lsu_ready_ex),
      .lsu_ready_wb_o(lsu_ready_wb),

      .busy_o(lsu_busy)
  );

  // Tracer signal
  assign wb_valid = lsu_ready_wb;


  //////////////////////////////////////
  //        ____ ____  ____           //
  //       / ___/ ___||  _ \ ___      //
  //      | |   \___ \| |_) / __|     //
  //      | |___ ___) |  _ <\__ \     //
  //       \____|____/|_| \_\___/     //
  //                                  //
  //   Control and Status Registers   //
  //////////////////////////////////////

  cv32e40p_cs_registers #(
      .N_HWLP          (N_HWLP),
      .A_EXTENSION     (A_EXTENSION),
      .FPU             (FPU),
      .ZFINX           (ZFINX),
      .APU             (APU),
      .PULP_SECURE     (PULP_SECURE),
      .USE_PMP         (USE_PMP),
      .N_PMP_ENTRIES   (N_PMP_ENTRIES),
      .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS),
      .COREV_PULP      (COREV_PULP),
      .COREV_CLUSTER   (COREV_CLUSTER),
      .DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
  ) cs_registers_i (
      .clk  (clk),
      .rst_n(rst_ni),

      // Hart ID from outside
      .hart_id_i       (hart_id_i),
      .mtvec_o         (mtvec),
      .utvec_o         (utvec),
      .mtvec_mode_o    (mtvec_mode),
      .utvec_mode_o    (utvec_mode),
      // mtvec address
      .mtvec_addr_i    (mtvec_addr_i[31:0]),
      .csr_mtvec_init_i(csr_mtvec_init),
      // Interface to CSRs (SRAM like)
      .csr_addr_i      (csr_addr),
      .csr_wdata_i     (csr_wdata),
      .csr_op_i        (csr_op),
      .csr_rdata_o     (csr_rdata),

      .fs_off_o   (fs_off),
      .frm_o      (frm_csr),
      .fflags_i   (fflags_csr),
      .fflags_we_i(fflags_we),
      .fregs_we_i (fregs_we),

      // Interrupt related control signals
      .mie_bypass_o  (mie_bypass),
      .mip_i         (mip),
      .m_irq_enable_o(m_irq_enable),
      .u_irq_enable_o(u_irq_enable),
      .csr_irq_sec_i (csr_irq_sec),
      .sec_lvl_o     (sec_lvl_o),
      .mepc_o        (mepc),
      .uepc_o        (uepc),

      // HPM related control signals
      .mcounteren_o(mcounteren),

      // debug
      .debug_mode_i       (debug_mode),
      .debug_cause_i      (debug_cause),
      .debug_csr_save_i   (debug_csr_save),
      .depc_o             (depc),
      .debug_single_step_o(debug_single_step),
      .debug_ebreakm_o    (debug_ebreakm),
      .debug_ebreaku_o    (debug_ebreaku),
      .trigger_match_o    (trigger_match),

      .priv_lvl_o(current_priv_lvl),

      .pmp_addr_o(pmp_addr),
      .pmp_cfg_o (pmp_cfg),

      .pc_if_i(pc_if),
      .pc_id_i(pc_id),
      .pc_ex_i(pc_ex),

      .csr_save_if_i     (csr_save_if),
      .csr_save_id_i     (csr_save_id),
      .csr_save_ex_i     (csr_save_ex),
      .csr_restore_mret_i(csr_restore_mret_id),
      .csr_restore_uret_i(csr_restore_uret_id),

      .csr_restore_dret_i(csr_restore_dret_id),

      .csr_cause_i     (csr_cause),
      .csr_save_cause_i(csr_save_cause),

      // from hwloop registers
      .hwlp_start_i(hwlp_start),
      .hwlp_end_i  (hwlp_end),
      .hwlp_cnt_i  (hwlp_cnt),

      // performance counter related signals
      .mhpmevent_minstret_i    (mhpmevent_minstret),
      .mhpmevent_load_i        (mhpmevent_load),
      .mhpmevent_store_i       (mhpmevent_store),
      .mhpmevent_jump_i        (mhpmevent_jump),
      .mhpmevent_branch_i      (mhpmevent_branch),
      .mhpmevent_branch_taken_i(mhpmevent_branch_taken),
      .mhpmevent_compressed_i  (mhpmevent_compressed),
      .mhpmevent_jr_stall_i    (mhpmevent_jr_stall),
      .mhpmevent_imiss_i       (mhpmevent_imiss),
      .mhpmevent_ld_stall_i    (mhpmevent_ld_stall),
      .mhpmevent_pipe_stall_i  (mhpmevent_pipe_stall),
      .apu_typeconflict_i      (perf_apu_type),
      .apu_contention_i        (perf_apu_cont),
      .apu_dep_i               (perf_apu_dep),
      .apu_wb_i                (perf_apu_wb)
  );

  //  CSR access
  assign csr_addr = csr_addr_int;
  assign csr_wdata = alu_operand_a_ex;
  assign csr_op = csr_op_ex;

  assign csr_addr_int = csr_num_e'(csr_access_ex ? alu_operand_b_ex[11:0] : '0);

  //  Floating-Point registers write
  assign fregs_we     = (FPU & !ZFINX) ? ((regfile_alu_we_fw && regfile_alu_waddr_fw[5]) ||
                                          (regfile_we_wb     && regfile_waddr_fw_wb_o[5]))
                                       : 1'b0;

  ///////////////////////////
  //   ____  __  __ ____   //
  //  |  _ \|  \/  |  _ \  //
  //  | |_) | |\/| | |_) | //
  //  |  __/| |  | |  __/  //
  //  |_|   |_|  |_|_|     //
  //                       //
  ///////////////////////////

  generate
    if (PULP_SECURE && USE_PMP) begin : gen_pmp
      cv32e40p_pmp #(
          .N_PMP_ENTRIES(N_PMP_ENTRIES)
      ) pmp_unit_i (
          .clk  (clk),
          .rst_n(rst_ni),

          .pmp_privil_mode_i(current_priv_lvl),

          .pmp_addr_i(pmp_addr),
          .pmp_cfg_i (pmp_cfg),


          .data_req_i (data_req_pmp),
          .data_addr_i(data_addr_pmp),
          .data_we_i  (data_we_o),
          .data_gnt_o (data_gnt_pmp),

          .data_req_o    (data_req_o),
          .data_gnt_i    (data_gnt_i),
          .data_addr_o   (data_addr_o),
          .data_err_o    (data_err_pmp),
          .data_err_ack_i(data_err_ack),

          .instr_req_i (instr_req_pmp),
          .instr_addr_i(instr_addr_pmp),
          .instr_gnt_o (instr_gnt_pmp),

          .instr_req_o (instr_req_o),
          .instr_gnt_i (instr_gnt_i),
          .instr_addr_o(instr_addr_o),
          .instr_err_o (instr_err_pmp)
      );
    end else begin : gen_no_pmp
      assign instr_req_o   = instr_req_pmp;
      assign instr_addr_o  = instr_addr_pmp;
      assign instr_gnt_pmp = instr_gnt_i;
      assign instr_err_pmp = 1'b0;

      assign data_req_o    = data_req_pmp;
      assign data_addr_o   = data_addr_pmp;
      assign data_gnt_pmp  = data_gnt_i;
      assign data_err_pmp  = 1'b0;
    end
  endgenerate

`ifdef CV32E40P_ASSERT_ON

  //----------------------------------------------------------------------------
  // Assumptions
  //----------------------------------------------------------------------------

  generate
    if (COREV_CLUSTER) begin : gen_pulp_cluster_assumptions

      // Assumptions/requirements on the environment when pulp_clock_en_i = 0
      property p_env_req_0;
        @(posedge clk_i) disable iff (!rst_ni) (pulp_clock_en_i == 1'b0) |-> (irq_i == 'b0) && (debug_req_i == 1'b0) &&
                                                                            (instr_rvalid_i == 1'b0) && (instr_gnt_i == 1'b0) &&
                                                                            (data_rvalid_i == 1'b0) && (data_gnt_i == 1'b0);
      endproperty

      a_env_req_0 :
      assume property (p_env_req_0);

      // Assumptions/requirements on the environment when core_sleep_o = 0
      property p_env_req_1;
        @(posedge clk_i) disable iff (!rst_ni) (core_sleep_o == 1'b0) |-> (pulp_clock_en_i == 1'b1);
      endproperty

      a_env_req_1 :
      assume property (p_env_req_1);

    end
  endgenerate

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

  generate
    if (!COREV_CLUSTER) begin : gen_no_pulp_cluster_assertions
      // Check that a taken IRQ is actually enabled (e.g. that we do not react to an IRQ that was just disabled in MIE)
      property p_irq_enabled_0;
        @(posedge clk) disable iff (!rst_ni) (pc_set && (pc_mux_id == PC_EXCEPTION) && (exc_pc_mux_id == EXC_PC_IRQ)) |->
         (cs_registers_i.mie_n[exc_cause] && cs_registers_i.mstatus_q.mie);
      endproperty

      a_irq_enabled_0 :
      assert property (p_irq_enabled_0);

      // Check that a taken IRQ was for an enabled cause and that mstatus.mie gets disabled
      property p_irq_enabled_1;
        @(posedge clk) disable iff (!rst_ni) (pc_set && (pc_mux_id == PC_EXCEPTION) && (exc_pc_mux_id == EXC_PC_IRQ)) |=>
         (cs_registers_i.mcause_q[5] && cs_registers_i.mie_q[cs_registers_i.mcause_q[4:0]] && !cs_registers_i.mstatus_q.mie);
      endproperty

      a_irq_enabled_1 :
      assert property (p_irq_enabled_1);
    end
  endgenerate

  generate
    if (!COREV_PULP) begin : gen_no_pulp_xpulp_assertions

      // Illegal, ECALL, EBRK checks excluded for PULP due to other definition for for Hardware Loop

      // First illegal instruction decoded
      logic        first_illegal_found;
      logic        first_ecall_found;
      logic        first_ebrk_found;
      logic [31:0] expected_illegal_mepc;
      logic [31:0] expected_ecall_mepc;
      logic [31:0] expected_ebrk_mepc;

      always_ff @(posedge clk, negedge rst_ni) begin
        if (rst_ni == 1'b0) begin
          first_illegal_found   <= 1'b0;
          first_ecall_found     <= 1'b0;
          first_ebrk_found      <= 1'b0;
          expected_illegal_mepc <= 32'b0;
          expected_ecall_mepc   <= 32'b0;
          expected_ebrk_mepc    <= 32'b0;
        end else begin
          if (!first_illegal_found && is_decoding && id_valid && id_stage_i.illegal_insn_dec && !id_stage_i.controller_i.debug_mode_n) begin
            first_illegal_found   <= 1'b1;
            expected_illegal_mepc <= pc_id;
          end
          if (!first_ecall_found && is_decoding && id_valid && id_stage_i.ecall_insn_dec && !id_stage_i.controller_i.debug_mode_n) begin
            first_ecall_found   <= 1'b1;
            expected_ecall_mepc <= pc_id;
          end
          if (!first_ebrk_found && is_decoding && id_valid && id_stage_i.ebrk_insn_dec && (id_stage_i.controller_i.ctrl_fsm_ns != DBG_FLUSH)) begin
            first_ebrk_found   <= 1'b1;
            expected_ebrk_mepc <= pc_id;
          end
        end
      end

      // First mepc write for illegal instruction exception
      logic        first_cause_illegal_found;
      logic        first_cause_ecall_found;
      logic        first_cause_ebrk_found;
      logic [31:0] actual_illegal_mepc;
      logic [31:0] actual_ecall_mepc;
      logic [31:0] actual_ebrk_mepc;

      always_ff @(posedge clk, negedge rst_ni) begin
        if (rst_ni == 1'b0) begin
          first_cause_illegal_found <= 1'b0;
          first_cause_ecall_found   <= 1'b0;
          first_cause_ebrk_found    <= 1'b0;
          actual_illegal_mepc       <= 32'b0;
          actual_ecall_mepc         <= 32'b0;
          actual_ebrk_mepc          <= 32'b0;
        end else begin
          if (!first_cause_illegal_found && (cs_registers_i.csr_cause_i == {
                1'b0, EXC_CAUSE_ILLEGAL_INSN
              }) && csr_save_cause) begin
            first_cause_illegal_found <= 1'b1;
            actual_illegal_mepc       <= cs_registers_i.mepc_n;
          end
          if (!first_cause_ecall_found && (cs_registers_i.csr_cause_i == {
                1'b0, EXC_CAUSE_ECALL_MMODE
              }) && csr_save_cause) begin
            first_cause_ecall_found <= 1'b1;
            actual_ecall_mepc       <= cs_registers_i.mepc_n;
          end
          if (!first_cause_ebrk_found && (cs_registers_i.csr_cause_i == {
                1'b0, EXC_CAUSE_BREAKPOINT
              }) && csr_save_cause) begin
            first_cause_ebrk_found <= 1'b1;
            actual_ebrk_mepc       <= cs_registers_i.mepc_n;
          end
        end
      end

      // Check that mepc is updated with PC of illegal instruction
      property p_illegal_mepc;
        @(posedge clk) disable iff (!rst_ni) (first_illegal_found && first_cause_illegal_found) |=> (expected_illegal_mepc == actual_illegal_mepc);
      endproperty

      a_illegal_mepc :
      assert property (p_illegal_mepc);

      // Check that mepc is updated with PC of the ECALL instruction
      property p_ecall_mepc;
        @(posedge clk) disable iff (!rst_ni) (first_ecall_found && first_cause_ecall_found) |=> (expected_ecall_mepc == actual_ecall_mepc);
      endproperty

      a_ecall_mepc :
      assert property (p_ecall_mepc);

      // Check that mepc is updated with PC of EBRK instruction
      property p_ebrk_mepc;
        @(posedge clk) disable iff (!rst_ni) (first_ebrk_found && first_cause_ebrk_found) |=> (expected_ebrk_mepc == actual_ebrk_mepc);
      endproperty

      a_ebrk_mepc :
      assert property (p_ebrk_mepc);

    end
  endgenerate

  // Single Step only decodes one instruction in non debug mode and next instruction decode is in debug mode
  logic inst_taken;
  assign inst_taken = id_valid && is_decoding;

  a_single_step :
  assert property
  (
    @(posedge clk) disable iff (!rst_ni)
    (inst_taken && debug_single_step && ~debug_mode)
    ##1 inst_taken [->1]
    |-> (debug_mode && debug_single_step));

`endif

endmodule

// -------------------- END OF rtl/cv32e40p_core.sv --------------------

// -------------------- START OF rtl/cv32e40p_cs_registers.sv --------------------
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
// Engineer:       Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
// Additional contributions by:                                               //
//                 Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                 Andrea Bettati - andrea.bettati@studenti.unipr.it          //
//                                                                            //
// Design Name:    Control and Status Registers                               //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Control and Status Registers (CSRs) loosely following the  //
//                 RiscV draft priviledged instruction set spec (v1.9)        //
//                 Added Floating point support                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_cs_registers
  import cv32e40p_pkg::*;
#(
    parameter N_HWLP           = 2,
    parameter APU              = 0,
    parameter A_EXTENSION      = 0,
    parameter FPU              = 0,
    parameter ZFINX            = 0,
    parameter PULP_SECURE      = 0,
    parameter USE_PMP          = 0,
    parameter N_PMP_ENTRIES    = 16,
    parameter NUM_MHPMCOUNTERS = 1,
    parameter COREV_PULP       = 0,
    parameter COREV_CLUSTER    = 0,
    parameter DEBUG_TRIGGER_EN = 1
) (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Hart ID
    input  logic [31:0] hart_id_i,
    output logic [23:0] mtvec_o,
    output logic [23:0] utvec_o,
    output logic [ 1:0] mtvec_mode_o,
    output logic [ 1:0] utvec_mode_o,

    // Used for mtvec address
    input logic [31:0] mtvec_addr_i,
    input logic        csr_mtvec_init_i,

    // Interface to registers (SRAM like)
    input  csr_num_e           csr_addr_i,
    input  logic        [31:0] csr_wdata_i,
    input  csr_opcode_e        csr_op_i,
    output logic        [31:0] csr_rdata_o,

    output logic               fs_off_o,
    output logic [        2:0] frm_o,
    input  logic [C_FFLAG-1:0] fflags_i,
    input  logic               fflags_we_i,
    input  logic               fregs_we_i,

    // Interrupts
    output logic [31:0] mie_bypass_o,
    input  logic [31:0] mip_i,
    output logic        m_irq_enable_o,
    output logic        u_irq_enable_o,

    //csr_irq_sec_i is always 0 if PULP_SECURE is zero
    input  logic        csr_irq_sec_i,
    output logic        sec_lvl_o,
    output logic [31:0] mepc_o,
    output logic [31:0] uepc_o,
    //mcounteren_o is always 0 if PULP_SECURE is zero
    output logic [31:0] mcounteren_o,

    // debug
    input  logic        debug_mode_i,
    input  logic [ 2:0] debug_cause_i,
    input  logic        debug_csr_save_i,
    output logic [31:0] depc_o,
    output logic        debug_single_step_o,
    output logic        debug_ebreakm_o,
    output logic        debug_ebreaku_o,
    output logic        trigger_match_o,


    output logic [N_PMP_ENTRIES-1:0][31:0] pmp_addr_o,
    output logic [N_PMP_ENTRIES-1:0][ 7:0] pmp_cfg_o,

    output PrivLvl_t priv_lvl_o,

    input logic [31:0] pc_if_i,
    input logic [31:0] pc_id_i,
    input logic [31:0] pc_ex_i,

    input logic csr_save_if_i,
    input logic csr_save_id_i,
    input logic csr_save_ex_i,

    input logic csr_restore_mret_i,
    input logic csr_restore_uret_i,

    input logic                    csr_restore_dret_i,
    //coming from controller
    input logic [       5:0]       csr_cause_i,
    //coming from controller
    input logic                    csr_save_cause_i,
    // Hardware loops
    input logic [N_HWLP-1:0][31:0] hwlp_start_i,
    input logic [N_HWLP-1:0][31:0] hwlp_end_i,
    input logic [N_HWLP-1:0][31:0] hwlp_cnt_i,

    // Performance Counters
    input logic mhpmevent_minstret_i,
    input logic mhpmevent_load_i,
    input logic mhpmevent_store_i,
    input logic mhpmevent_jump_i,  // Jump instruction retired (j, jr, jal, jalr)
    input logic mhpmevent_branch_i,  // Branch instruction retired (beq, bne, etc.)
    input logic mhpmevent_branch_taken_i,  // Branch instruction taken
    input logic mhpmevent_compressed_i,
    input logic mhpmevent_jr_stall_i,
    input logic mhpmevent_imiss_i,
    input logic mhpmevent_ld_stall_i,
    input logic mhpmevent_pipe_stall_i,
    input logic apu_typeconflict_i,
    input logic apu_contention_i,
    input logic apu_dep_i,
    input logic apu_wb_i
);

  localparam NUM_HPM_EVENTS = 16;

  localparam MTVEC_MODE = 2'b01;

  localparam MAX_N_PMP_ENTRIES = 16;
  localparam MAX_N_PMP_CFG = 4;
  localparam N_PMP_CFG = N_PMP_ENTRIES % 4 == 0 ? N_PMP_ENTRIES / 4 : N_PMP_ENTRIES / 4 + 1;

  localparam MSTATUS_UIE_BIT = 0;
  localparam MSTATUS_SIE_BIT = 1;
  localparam MSTATUS_MIE_BIT = 3;
  localparam MSTATUS_UPIE_BIT = 4;
  localparam MSTATUS_SPIE_BIT = 5;
  localparam MSTATUS_MPIE_BIT = 7;
  localparam MSTATUS_SPP_BIT = 8;
  localparam MSTATUS_MPP_BIT_LOW = 11;
  localparam MSTATUS_MPP_BIT_HIGH = 12;
  localparam MSTATUS_FS_BIT_LOW = 13;
  localparam MSTATUS_FS_BIT_HIGH = 14;
  localparam MSTATUS_MPRV_BIT = 17;
  localparam MSTATUS_SD_BIT = 31;

  // misa
  localparam logic [1:0] MXL = 2'd1;  // M-XLEN: XLEN in M-Mode for RV32
  localparam logic [31:0] MISA_VALUE = (32'(A_EXTENSION) << 0)  // A - Atomic Instructions extension
  | (1 << 2)  // C - Compressed extension
  | (0 << 3)  // D - Double precision floating-point extension
  | (0 << 4)  // E - RV32E base ISA
  | (32'(FPU == 1 && ZFINX == 0) << 5)  // F - Single precision floating-point extension
  | (1 << 8)  // I - RV32I/64I/128I base ISA
  | (1 << 12)  // M - Integer Multiply/Divide extension
  | (0 << 13)  // N - User level interrupts supported
  | (0 << 18)  // S - Supervisor mode implemented
  | (32'(PULP_SECURE) << 20)  // U - User mode implemented
  | (32'(COREV_PULP || COREV_CLUSTER) << 23)  // X - Non-standard extensions present
  | (32'(MXL) << 30);  // M-XLEN

  // This local parameter when set to 1 makes the Perf Counters not compliant with RISC-V
  // as it does not implement mcycle and minstret
  // but only HPMCOUNTERs (depending on NUM_MHPMCOUNTERS)
  localparam PULP_PERF_COUNTERS = 0;

  typedef struct packed {
    logic [MAX_N_PMP_ENTRIES-1:0][31:0] pmpaddr;
    logic [MAX_N_PMP_CFG-1:0][31:0] pmpcfg_packed;
    logic [MAX_N_PMP_ENTRIES-1:0][7:0] pmpcfg;
  } Pmp_t;

  // CSR update logic
  logic [31:0] csr_wdata_int;
  logic [31:0] csr_rdata_int;
  logic        csr_we_int;

  // FPU 
  logic [C_RM-1:0] frm_q, frm_n;
  logic [C_FFLAG-1:0] fflags_q, fflags_n;
  logic fcsr_update;

  // Interrupt control signals
  logic [31:0] mepc_q, mepc_n;
  logic [31:0] uepc_q, uepc_n;
  // Trigger
  logic [31:0] tmatch_control_rdata;
  logic [31:0] tmatch_value_rdata;
  logic [15:0] tinfo_types;
  // Debug
  Dcsr_t dcsr_q, dcsr_n;
  logic [31:0] depc_q, depc_n;
  logic [31:0] dscratch0_q, dscratch0_n;
  logic [31:0] dscratch1_q, dscratch1_n;
  logic [31:0] mscratch_q, mscratch_n;

  logic [31:0] exception_pc;
  Status_t mstatus_q, mstatus_n;
  logic mstatus_we_int;
  FS_t mstatus_fs_q, mstatus_fs_n;
  logic [5:0] mcause_q, mcause_n;
  logic [5:0] ucause_q, ucause_n;
  logic [23:0] mtvec_n, mtvec_q;
  logic [23:0] utvec_n, utvec_q;
  logic [1:0] mtvec_mode_n, mtvec_mode_q;
  logic [1:0] utvec_mode_n, utvec_mode_q;

  logic [31:0] mip;  // Bits are masked according to IRQ_MASK
  logic [31:0] mie_q, mie_n;  // Bits are masked according to IRQ_MASK

  logic [31:0] csr_mie_wdata;
  logic        csr_mie_we;

  logic        is_irq;
  PrivLvl_t priv_lvl_n, priv_lvl_q;
  Pmp_t pmp_reg_q, pmp_reg_n;
  //clock gating for pmp regs
  logic [MAX_N_PMP_ENTRIES-1:0]                        pmpaddr_we;
  logic [MAX_N_PMP_ENTRIES-1:0]                        pmpcfg_we;

  // Performance Counter Signals
  logic [                 31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_q;  // performance counters
  logic [31:0][31:0] mhpmevent_q, mhpmevent_n;  // event enable
  logic [31:0] mcounteren_q, mcounteren_n;  // user mode counter enable
  logic [31:0] mcountinhibit_q, mcountinhibit_n;  // performance counter enable
  logic [NUM_HPM_EVENTS-1:0] hpm_events;  // events for performance counters
  logic [31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_increment;  // increment of mhpmcounter_q
  logic [31:0] mhpmcounter_write_lower;  // write 32 lower bits of mhpmcounter_q
  logic [31:0] mhpmcounter_write_upper;  // write 32 upper bits mhpmcounter_q
  logic [31:0] mhpmcounter_write_increment;  // write increment of mhpmcounter_q

  assign is_irq = csr_cause_i[5];

  // mip CSR
  assign mip = mip_i;

  // mie_n is used instead of mie_q such that a CSR write to the MIE register can
  // affect the instruction immediately following it.

  // MIE CSR operation logic
  always_comb begin
    csr_mie_wdata = csr_wdata_i;
    csr_mie_we    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_mie_wdata = csr_wdata_i;
      CSR_OP_SET:   csr_mie_wdata = csr_wdata_i | mie_q;
      CSR_OP_CLEAR: csr_mie_wdata = (~csr_wdata_i) & mie_q;
      CSR_OP_READ: begin
        csr_mie_wdata = csr_wdata_i;
        csr_mie_we    = 1'b0;
      end
    endcase
  end

  assign mie_bypass_o = ((csr_addr_i == CSR_MIE) && csr_mie_we) ? csr_mie_wdata & IRQ_MASK : mie_q;

  ////////////////////////////////////////////
  //   ____ ____  ____    ____              //
  //  / ___/ ___||  _ \  |  _ \ ___  __ _   //
  // | |   \___ \| |_) | | |_) / _ \/ _` |  //
  // | |___ ___) |  _ <  |  _ <  __/ (_| |  //
  //  \____|____/|_| \_\ |_| \_\___|\__, |  //
  //                                |___/   //
  ////////////////////////////////////////////

  // NOTE!!!: Any new CSR register added in this file must also be
  //   added to the valid CSR register list cv32e40p_decoder.v

  genvar j;


  if (PULP_SECURE == 1) begin : gen_pulp_secure_read_logic
    // read logic
    always_comb begin
      case (csr_addr_i)
        // fcsr: Floating-Point Control and Status Register (frm + fflags).
        CSR_FFLAGS: csr_rdata_int = (FPU == 1) ? {27'b0, fflags_q} : '0;
        CSR_FRM:    csr_rdata_int = (FPU == 1) ? {29'b0, frm_q} : '0;
        CSR_FCSR:   csr_rdata_int = (FPU == 1) ? {24'b0, frm_q, fflags_q} : '0;

        // mstatus
        CSR_MSTATUS:
        csr_rdata_int = {
          14'b0,
          mstatus_q.mprv,
          4'b0,
          mstatus_q.mpp,
          3'b0,
          mstatus_q.mpie,
          2'h0,
          mstatus_q.upie,
          mstatus_q.mie,
          2'h0,
          mstatus_q.uie
        };

        // misa: machine isa register
        CSR_MISA: csr_rdata_int = MISA_VALUE;

        // mie: machine interrupt enable
        CSR_MIE: begin
          csr_rdata_int = mie_q;
        end

        // mtvec: machine trap-handler base address
        CSR_MTVEC: csr_rdata_int = {mtvec_q, 6'h0, mtvec_mode_q};
        // mscratch: machine scratch
        CSR_MSCRATCH: csr_rdata_int = mscratch_q;
        // mepc: exception program counter
        CSR_MEPC: csr_rdata_int = mepc_q;
        // mcause: exception cause
        CSR_MCAUSE: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};
        // mip: interrupt pending
        CSR_MIP: begin
          csr_rdata_int = mip;
        end

        // mhartid: unique hardware thread id
        CSR_MHARTID: csr_rdata_int = hart_id_i;

        // mvendorid: Machine Vendor ID
        CSR_MVENDORID: csr_rdata_int = {MVENDORID_BANK, MVENDORID_OFFSET};

        // marchid: Machine Architecture ID
        CSR_MARCHID: csr_rdata_int = MARCHID;

        // unimplemented, read 0 CSRs
        CSR_MIMPID, CSR_MTVAL: csr_rdata_int = 'b0;

        // mcounteren: Machine Counter-Enable
        CSR_MCOUNTEREN: csr_rdata_int = mcounteren_q;

        CSR_TSELECT, CSR_TDATA3, CSR_MCONTEXT, CSR_SCONTEXT: csr_rdata_int = 'b0;  // Always read 0
        CSR_TDATA1: csr_rdata_int = tmatch_control_rdata;
        CSR_TDATA2: csr_rdata_int = tmatch_value_rdata;
        CSR_TINFO: csr_rdata_int = tinfo_types;

        CSR_DCSR: csr_rdata_int = dcsr_q;  //
        CSR_DPC: csr_rdata_int = depc_q;
        CSR_DSCRATCH0: csr_rdata_int = dscratch0_q;  //
        CSR_DSCRATCH1: csr_rdata_int = dscratch1_q;  //

        // Hardware Performance Monitor
        CSR_MCYCLE,
      CSR_MINSTRET,
      CSR_MHPMCOUNTER3,
      CSR_MHPMCOUNTER4,  CSR_MHPMCOUNTER5,  CSR_MHPMCOUNTER6,  CSR_MHPMCOUNTER7,
      CSR_MHPMCOUNTER8,  CSR_MHPMCOUNTER9,  CSR_MHPMCOUNTER10, CSR_MHPMCOUNTER11,
      CSR_MHPMCOUNTER12, CSR_MHPMCOUNTER13, CSR_MHPMCOUNTER14, CSR_MHPMCOUNTER15,
      CSR_MHPMCOUNTER16, CSR_MHPMCOUNTER17, CSR_MHPMCOUNTER18, CSR_MHPMCOUNTER19,
      CSR_MHPMCOUNTER20, CSR_MHPMCOUNTER21, CSR_MHPMCOUNTER22, CSR_MHPMCOUNTER23,
      CSR_MHPMCOUNTER24, CSR_MHPMCOUNTER25, CSR_MHPMCOUNTER26, CSR_MHPMCOUNTER27,
      CSR_MHPMCOUNTER28, CSR_MHPMCOUNTER29, CSR_MHPMCOUNTER30, CSR_MHPMCOUNTER31,
      CSR_CYCLE,
      CSR_INSTRET,
      CSR_HPMCOUNTER3,
      CSR_HPMCOUNTER4,  CSR_HPMCOUNTER5,  CSR_HPMCOUNTER6,  CSR_HPMCOUNTER7,
      CSR_HPMCOUNTER8,  CSR_HPMCOUNTER9,  CSR_HPMCOUNTER10, CSR_HPMCOUNTER11,
      CSR_HPMCOUNTER12, CSR_HPMCOUNTER13, CSR_HPMCOUNTER14, CSR_HPMCOUNTER15,
      CSR_HPMCOUNTER16, CSR_HPMCOUNTER17, CSR_HPMCOUNTER18, CSR_HPMCOUNTER19,
      CSR_HPMCOUNTER20, CSR_HPMCOUNTER21, CSR_HPMCOUNTER22, CSR_HPMCOUNTER23,
      CSR_HPMCOUNTER24, CSR_HPMCOUNTER25, CSR_HPMCOUNTER26, CSR_HPMCOUNTER27,
      CSR_HPMCOUNTER28, CSR_HPMCOUNTER29, CSR_HPMCOUNTER30, CSR_HPMCOUNTER31:
        csr_rdata_int = mhpmcounter_q[csr_addr_i[4:0]][31:0];

        CSR_MCYCLEH,
      CSR_MINSTRETH,
      CSR_MHPMCOUNTER3H,
      CSR_MHPMCOUNTER4H,  CSR_MHPMCOUNTER5H,  CSR_MHPMCOUNTER6H,  CSR_MHPMCOUNTER7H,
      CSR_MHPMCOUNTER8H,  CSR_MHPMCOUNTER9H,  CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H,
      CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H, CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H,
      CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H, CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H,
      CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H, CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H,
      CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H,
      CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H,
      CSR_CYCLEH,
      CSR_INSTRETH,
      CSR_HPMCOUNTER3H,
      CSR_HPMCOUNTER4H,  CSR_HPMCOUNTER5H,  CSR_HPMCOUNTER6H,  CSR_HPMCOUNTER7H,
      CSR_HPMCOUNTER8H,  CSR_HPMCOUNTER9H,  CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H,
      CSR_HPMCOUNTER12H, CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H,
      CSR_HPMCOUNTER16H, CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H,
      CSR_HPMCOUNTER20H, CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_HPMCOUNTER23H,
      CSR_HPMCOUNTER24H, CSR_HPMCOUNTER25H, CSR_HPMCOUNTER26H, CSR_HPMCOUNTER27H,
      CSR_HPMCOUNTER28H, CSR_HPMCOUNTER29H, CSR_HPMCOUNTER30H, CSR_HPMCOUNTER31H:
        csr_rdata_int = mhpmcounter_q[csr_addr_i[4:0]][63:32];

        CSR_MCOUNTINHIBIT: csr_rdata_int = mcountinhibit_q;

        CSR_MHPMEVENT3,
      CSR_MHPMEVENT4,  CSR_MHPMEVENT5,  CSR_MHPMEVENT6,  CSR_MHPMEVENT7,
      CSR_MHPMEVENT8,  CSR_MHPMEVENT9,  CSR_MHPMEVENT10, CSR_MHPMEVENT11,
      CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15,
      CSR_MHPMEVENT16, CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19,
      CSR_MHPMEVENT20, CSR_MHPMEVENT21, CSR_MHPMEVENT22, CSR_MHPMEVENT23,
      CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26, CSR_MHPMEVENT27,
      CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31:
        csr_rdata_int = mhpmevent_q[csr_addr_i[4:0]];

        // hardware loops  (not official)
        CSR_LPSTART0: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_start_i[0];
        CSR_LPEND0:   csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_end_i[0];
        CSR_LPCOUNT0: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_cnt_i[0];
        CSR_LPSTART1: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_start_i[1];
        CSR_LPEND1:   csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_end_i[1];
        CSR_LPCOUNT1: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_cnt_i[1];

        // PMP config registers
        CSR_PMPCFG0: csr_rdata_int = USE_PMP ? pmp_reg_q.pmpcfg_packed[0] : '0;
        CSR_PMPCFG1: csr_rdata_int = USE_PMP ? pmp_reg_q.pmpcfg_packed[1] : '0;
        CSR_PMPCFG2: csr_rdata_int = USE_PMP ? pmp_reg_q.pmpcfg_packed[2] : '0;
        CSR_PMPCFG3: csr_rdata_int = USE_PMP ? pmp_reg_q.pmpcfg_packed[3] : '0;

        CSR_PMPADDR0, CSR_PMPADDR1, CSR_PMPADDR2, CSR_PMPADDR3,
      CSR_PMPADDR4, CSR_PMPADDR5, CSR_PMPADDR6, CSR_PMPADDR7,
      CSR_PMPADDR8, CSR_PMPADDR9, CSR_PMPADDR10, CSR_PMPADDR11,
      CSR_PMPADDR12, CSR_PMPADDR13, CSR_PMPADDR14, CSR_PMPADDR15 :
        csr_rdata_int = USE_PMP ? pmp_reg_q.pmpaddr[csr_addr_i[3:0]] : '0;

        /* USER CSR */
        // ustatus
        CSR_USTATUS: csr_rdata_int = {27'b0, mstatus_q.upie, 3'h0, mstatus_q.uie};
        // utvec: user trap-handler base address
        CSR_UTVEC: csr_rdata_int = {utvec_q, 6'h0, utvec_mode_q};
        // duplicated mhartid: unique hardware thread id (not official)
        CSR_UHARTID: csr_rdata_int = !COREV_PULP ? 'b0 : hart_id_i;
        // uepc: exception program counter
        CSR_UEPC: csr_rdata_int = uepc_q;
        // ucause: exception cause
        CSR_UCAUSE: csr_rdata_int = {ucause_q[5], 26'h0, ucause_q[4:0]};

        // current priv level (not official)
        CSR_PRIVLV: csr_rdata_int = !COREV_PULP ? 'b0 : {30'h0, priv_lvl_q};

        default: csr_rdata_int = '0;
      endcase
    end
  end else begin : gen_no_pulp_secure_read_logic  // PULP_SECURE == 0
    // read logic
    always_comb begin

      case (csr_addr_i)
        // fcsr: Floating-Point Control and Status Register (frm + fflags).
        CSR_FFLAGS: csr_rdata_int = (FPU == 1) ? {27'b0, fflags_q} : '0;
        CSR_FRM: csr_rdata_int = (FPU == 1) ? {29'b0, frm_q} : '0;
        CSR_FCSR: csr_rdata_int = (FPU == 1) ? {24'b0, frm_q, fflags_q} : '0;
        // mstatus: always M-mode, contains IE bit
        CSR_MSTATUS:
        csr_rdata_int = {
          (FPU == 1 && ZFINX == 0) ? (mstatus_fs_q == FS_DIRTY ? 1'b1 : 1'b0) : 1'b0,
          13'b0,
          mstatus_q.mprv,
          2'b0,
          (FPU == 1 && ZFINX == 0) ? mstatus_fs_q : FS_OFF,
          mstatus_q.mpp,
          3'b0,
          mstatus_q.mpie,
          2'h0,
          mstatus_q.upie,
          mstatus_q.mie,
          2'h0,
          mstatus_q.uie
        };
        // misa: machine isa register
        CSR_MISA: csr_rdata_int = MISA_VALUE;
        // mie: machine interrupt enable
        CSR_MIE: begin
          csr_rdata_int = mie_q;
        end

        // mtvec: machine trap-handler base address
        CSR_MTVEC: csr_rdata_int = {mtvec_q, 6'h0, mtvec_mode_q};
        // mscratch: machine scratch
        CSR_MSCRATCH: csr_rdata_int = mscratch_q;
        // mepc: exception program counter
        CSR_MEPC: csr_rdata_int = mepc_q;
        // mcause: exception cause
        CSR_MCAUSE: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};
        // mip: interrupt pending
        CSR_MIP: begin
          csr_rdata_int = mip;
        end
        // mhartid: unique hardware thread id
        CSR_MHARTID: csr_rdata_int = hart_id_i;

        // mvendorid: Machine Vendor ID
        CSR_MVENDORID: csr_rdata_int = {MVENDORID_BANK, MVENDORID_OFFSET};

        // marchid: Machine Architecture ID
        CSR_MARCHID: csr_rdata_int = MARCHID;

        // mimpid, Machine Implementation ID
        CSR_MIMPID: begin
          csr_rdata_int = (FPU || COREV_PULP || COREV_CLUSTER) ? 32'h1 : 'b0;
        end

        // unimplemented, read 0 CSRs
        CSR_MTVAL: csr_rdata_int = 'b0;

        CSR_TSELECT, CSR_TDATA3, CSR_MCONTEXT, CSR_SCONTEXT: csr_rdata_int = 'b0;  // Always read 0
        CSR_TDATA1: csr_rdata_int = tmatch_control_rdata;
        CSR_TDATA2: csr_rdata_int = tmatch_value_rdata;
        CSR_TINFO: csr_rdata_int = tinfo_types;

        CSR_DCSR: csr_rdata_int = dcsr_q;  //
        CSR_DPC: csr_rdata_int = depc_q;
        CSR_DSCRATCH0: csr_rdata_int = dscratch0_q;  //
        CSR_DSCRATCH1: csr_rdata_int = dscratch1_q;  //

        // Hardware Performance Monitor
        CSR_MCYCLE,
      CSR_MINSTRET,
      CSR_MHPMCOUNTER3,
      CSR_MHPMCOUNTER4,  CSR_MHPMCOUNTER5,  CSR_MHPMCOUNTER6,  CSR_MHPMCOUNTER7,
      CSR_MHPMCOUNTER8,  CSR_MHPMCOUNTER9,  CSR_MHPMCOUNTER10, CSR_MHPMCOUNTER11,
      CSR_MHPMCOUNTER12, CSR_MHPMCOUNTER13, CSR_MHPMCOUNTER14, CSR_MHPMCOUNTER15,
      CSR_MHPMCOUNTER16, CSR_MHPMCOUNTER17, CSR_MHPMCOUNTER18, CSR_MHPMCOUNTER19,
      CSR_MHPMCOUNTER20, CSR_MHPMCOUNTER21, CSR_MHPMCOUNTER22, CSR_MHPMCOUNTER23,
      CSR_MHPMCOUNTER24, CSR_MHPMCOUNTER25, CSR_MHPMCOUNTER26, CSR_MHPMCOUNTER27,
      CSR_MHPMCOUNTER28, CSR_MHPMCOUNTER29, CSR_MHPMCOUNTER30, CSR_MHPMCOUNTER31,
      CSR_CYCLE,
      CSR_INSTRET,
      CSR_HPMCOUNTER3,
      CSR_HPMCOUNTER4,  CSR_HPMCOUNTER5,  CSR_HPMCOUNTER6,  CSR_HPMCOUNTER7,
      CSR_HPMCOUNTER8,  CSR_HPMCOUNTER9,  CSR_HPMCOUNTER10, CSR_HPMCOUNTER11,
      CSR_HPMCOUNTER12, CSR_HPMCOUNTER13, CSR_HPMCOUNTER14, CSR_HPMCOUNTER15,
      CSR_HPMCOUNTER16, CSR_HPMCOUNTER17, CSR_HPMCOUNTER18, CSR_HPMCOUNTER19,
      CSR_HPMCOUNTER20, CSR_HPMCOUNTER21, CSR_HPMCOUNTER22, CSR_HPMCOUNTER23,
      CSR_HPMCOUNTER24, CSR_HPMCOUNTER25, CSR_HPMCOUNTER26, CSR_HPMCOUNTER27,
      CSR_HPMCOUNTER28, CSR_HPMCOUNTER29, CSR_HPMCOUNTER30, CSR_HPMCOUNTER31:
        csr_rdata_int = mhpmcounter_q[csr_addr_i[4:0]][31:0];

        CSR_MCYCLEH,
      CSR_MINSTRETH,
      CSR_MHPMCOUNTER3H,
      CSR_MHPMCOUNTER4H,  CSR_MHPMCOUNTER5H,  CSR_MHPMCOUNTER6H,  CSR_MHPMCOUNTER7H,
      CSR_MHPMCOUNTER8H,  CSR_MHPMCOUNTER9H,  CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H,
      CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H, CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H,
      CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H, CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H,
      CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H, CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H,
      CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H,
      CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H,
      CSR_CYCLEH,
      CSR_INSTRETH,
      CSR_HPMCOUNTER3H,
      CSR_HPMCOUNTER4H,  CSR_HPMCOUNTER5H,  CSR_HPMCOUNTER6H,  CSR_HPMCOUNTER7H,
      CSR_HPMCOUNTER8H,  CSR_HPMCOUNTER9H,  CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H,
      CSR_HPMCOUNTER12H, CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H,
      CSR_HPMCOUNTER16H, CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H,
      CSR_HPMCOUNTER20H, CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_HPMCOUNTER23H,
      CSR_HPMCOUNTER24H, CSR_HPMCOUNTER25H, CSR_HPMCOUNTER26H, CSR_HPMCOUNTER27H,
      CSR_HPMCOUNTER28H, CSR_HPMCOUNTER29H, CSR_HPMCOUNTER30H, CSR_HPMCOUNTER31H:
        csr_rdata_int = (MHPMCOUNTER_WIDTH == 64) ? mhpmcounter_q[csr_addr_i[4:0]][63:32] : '0;

        CSR_MCOUNTINHIBIT: csr_rdata_int = mcountinhibit_q;

        CSR_MHPMEVENT3,
      CSR_MHPMEVENT4,  CSR_MHPMEVENT5,  CSR_MHPMEVENT6,  CSR_MHPMEVENT7,
      CSR_MHPMEVENT8,  CSR_MHPMEVENT9,  CSR_MHPMEVENT10, CSR_MHPMEVENT11,
      CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15,
      CSR_MHPMEVENT16, CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19,
      CSR_MHPMEVENT20, CSR_MHPMEVENT21, CSR_MHPMEVENT22, CSR_MHPMEVENT23,
      CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26, CSR_MHPMEVENT27,
      CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31:
        csr_rdata_int = mhpmevent_q[csr_addr_i[4:0]];

        // hardware loops  (not official)
        CSR_LPSTART0: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_start_i[0];
        CSR_LPEND0:   csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_end_i[0];
        CSR_LPCOUNT0: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_cnt_i[0];
        CSR_LPSTART1: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_start_i[1];
        CSR_LPEND1:   csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_end_i[1];
        CSR_LPCOUNT1: csr_rdata_int = !COREV_PULP ? 'b0 : hwlp_cnt_i[1];

        /* USER CSR */
        // dublicated mhartid: unique hardware thread id (not official)
        CSR_UHARTID: csr_rdata_int = !COREV_PULP ? 'b0 : hart_id_i;
        // current priv level (not official)
        CSR_PRIVLV: csr_rdata_int = !COREV_PULP ? 'b0 : {30'h0, priv_lvl_q};
        // Zfinx (not official)
        CSR_ZFINX: csr_rdata_int = (FPU == 1 && ZFINX == 1) ? 32'h1 : 32'h0;
        default: csr_rdata_int = '0;
      endcase
    end
  end  //PULP_SECURE

  if (PULP_SECURE == 1) begin : gen_pulp_secure_write_logic
    // write logic
    always_comb begin
      fflags_n                = fflags_q;
      frm_n                   = frm_q;
      mscratch_n              = mscratch_q;
      mepc_n                  = mepc_q;
      uepc_n                  = uepc_q;
      depc_n                  = depc_q;
      dcsr_n                  = dcsr_q;
      dscratch0_n             = dscratch0_q;
      dscratch1_n             = dscratch1_q;

      mstatus_n               = mstatus_q;
      mcause_n                = mcause_q;
      ucause_n                = ucause_q;
      exception_pc            = pc_id_i;
      priv_lvl_n              = priv_lvl_q;
      mtvec_n                 = csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q;
      utvec_n                 = utvec_q;
      mtvec_mode_n            = mtvec_mode_q;
      utvec_mode_n            = utvec_mode_q;
      pmp_reg_n.pmpaddr       = pmp_reg_q.pmpaddr;
      pmp_reg_n.pmpcfg_packed = pmp_reg_q.pmpcfg_packed;
      pmpaddr_we              = '0;
      pmpcfg_we               = '0;

      mie_n                   = mie_q;

      if (FPU == 1) if (fflags_we_i) fflags_n = fflags_i | fflags_q;

      case (csr_addr_i)
        // fcsr: Floating-Point Control and Status Register (frm, fflags, fprec).
        CSR_FFLAGS: if (csr_we_int) fflags_n = (FPU == 1) ? csr_wdata_int[C_FFLAG-1:0] : '0;
        CSR_FRM:    if (csr_we_int) frm_n = (FPU == 1) ? csr_wdata_int[C_RM-1:0] : '0;
        CSR_FCSR:
        if (csr_we_int) begin
          fflags_n = (FPU == 1) ? csr_wdata_int[C_FFLAG-1:0] : '0;
          frm_n    = (FPU == 1) ? csr_wdata_int[C_RM+C_FFLAG-1:C_FFLAG] : '0;
        end

        // mstatus: IE bit
        CSR_MSTATUS:
        if (csr_we_int) begin
          mstatus_n = '{
              uie: csr_wdata_int[MSTATUS_UIE_BIT],
              mie: csr_wdata_int[MSTATUS_MIE_BIT],
              upie: csr_wdata_int[MSTATUS_UPIE_BIT],
              mpie: csr_wdata_int[MSTATUS_MPIE_BIT],
              mpp: PrivLvl_t'(csr_wdata_int[MSTATUS_MPP_BIT_HIGH:MSTATUS_MPP_BIT_LOW]),
              mprv: csr_wdata_int[MSTATUS_MPRV_BIT]
          };
        end
        // mie: machine interrupt enable
        CSR_MIE:
        if (csr_we_int) begin
          mie_n = csr_wdata_int & IRQ_MASK;
        end
        // mtvec: machine trap-handler base address
        CSR_MTVEC:
        if (csr_we_int) begin
          mtvec_n      = csr_wdata_int[31:8];
          mtvec_mode_n = {1'b0, csr_wdata_int[0]};  // Only direct and vectored mode are supported
        end
        // mscratch: machine scratch
        CSR_MSCRATCH:
        if (csr_we_int) begin
          mscratch_n = csr_wdata_int;
        end
        // mepc: exception program counter
        CSR_MEPC:
        if (csr_we_int) begin
          mepc_n = csr_wdata_int & ~32'b1;  // force 16-bit alignment
        end
        // mcause
        CSR_MCAUSE: if (csr_we_int) mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};

        // Debug
        CSR_DCSR:
        if (csr_we_int) begin
          // Following are read-only and never assigned here (dcsr_q value is used):
          //
          // - xdebugver
          // - cause
          // - nmip

          dcsr_n.ebreakm = csr_wdata_int[15];
          dcsr_n.ebreaks = 1'b0;  // ebreaks (implemented as WARL)
          dcsr_n.ebreaku = csr_wdata_int[12];
          dcsr_n.stepie = csr_wdata_int[11];  // stepie
          dcsr_n.stopcount = 1'b0;  // stopcount
          dcsr_n.stoptime = 1'b0;  // stoptime
          dcsr_n.mprven = 1'b0;  // mprven
          dcsr_n.step = csr_wdata_int[2];
          dcsr_n.prv       = (PrivLvl_t'(csr_wdata_int[1:0]) == PRIV_LVL_M) ? PRIV_LVL_M : PRIV_LVL_U; // prv (implemented as WARL)
        end

        CSR_DPC:
        if (csr_we_int) begin
          depc_n = csr_wdata_int & ~32'b1;  // force 16-bit alignment
        end

        CSR_DSCRATCH0:
        if (csr_we_int) begin
          dscratch0_n = csr_wdata_int;
        end

        CSR_DSCRATCH1:
        if (csr_we_int) begin
          dscratch1_n = csr_wdata_int;
        end

        // PMP config registers
        CSR_PMPCFG0:
        if (csr_we_int) begin
          pmp_reg_n.pmpcfg_packed[0] = csr_wdata_int;
          pmpcfg_we[3:0] = 4'b1111;
        end
        CSR_PMPCFG1:
        if (csr_we_int) begin
          pmp_reg_n.pmpcfg_packed[1] = csr_wdata_int;
          pmpcfg_we[7:4] = 4'b1111;
        end
        CSR_PMPCFG2:
        if (csr_we_int) begin
          pmp_reg_n.pmpcfg_packed[2] = csr_wdata_int;
          pmpcfg_we[11:8] = 4'b1111;
        end
        CSR_PMPCFG3:
        if (csr_we_int) begin
          pmp_reg_n.pmpcfg_packed[3] = csr_wdata_int;
          pmpcfg_we[15:12] = 4'b1111;
        end

        CSR_PMPADDR0, CSR_PMPADDR1, CSR_PMPADDR2, CSR_PMPADDR3,
      CSR_PMPADDR4, CSR_PMPADDR5, CSR_PMPADDR6, CSR_PMPADDR7,
      CSR_PMPADDR8, CSR_PMPADDR9, CSR_PMPADDR10, CSR_PMPADDR11,
      CSR_PMPADDR12, CSR_PMPADDR13, CSR_PMPADDR14, CSR_PMPADDR15 :
        if (csr_we_int) begin
          pmp_reg_n.pmpaddr[csr_addr_i[3:0]] = csr_wdata_int;
          pmpaddr_we[csr_addr_i[3:0]] = 1'b1;
        end


        /* USER CSR */
        // ucause: exception cause
        CSR_USTATUS:
        if (csr_we_int) begin
          mstatus_n = '{
              uie: csr_wdata_int[MSTATUS_UIE_BIT],
              mie: mstatus_q.mie,
              upie: csr_wdata_int[MSTATUS_UPIE_BIT],
              mpie: mstatus_q.mpie,
              mpp: mstatus_q.mpp,
              mprv: mstatus_q.mprv
          };
        end
        // utvec: user trap-handler base address
        CSR_UTVEC:
        if (csr_we_int) begin
          utvec_n      = csr_wdata_int[31:8];
          utvec_mode_n = {1'b0, csr_wdata_int[0]};  // Only direct and vectored mode are supported
        end
        // uepc: exception program counter
        CSR_UEPC:
        if (csr_we_int) begin
          uepc_n = csr_wdata_int;
        end
        // ucause: exception cause
        CSR_UCAUSE: if (csr_we_int) ucause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
      endcase

      // exception controller gets priority over other writes
      unique case (1'b1)

        csr_save_cause_i: begin

          unique case (1'b1)
            csr_save_if_i: exception_pc = pc_if_i;
            csr_save_id_i: exception_pc = pc_id_i;
            csr_save_ex_i: exception_pc = pc_ex_i;
            default: ;
          endcase

          unique case (priv_lvl_q)

            PRIV_LVL_U: begin
              if (~is_irq) begin
                //Exceptions, Ecall U --> M
                priv_lvl_n     = PRIV_LVL_M;
                mstatus_n.mpie = mstatus_q.uie;
                mstatus_n.mie  = 1'b0;
                mstatus_n.mpp  = PRIV_LVL_U;
                if (debug_csr_save_i) depc_n = exception_pc;
                else mepc_n = exception_pc;
                mcause_n = csr_cause_i;

              end else begin
                if (~csr_irq_sec_i) begin
                  //U --> U
                  priv_lvl_n     = PRIV_LVL_U;
                  mstatus_n.upie = mstatus_q.uie;
                  mstatus_n.uie  = 1'b0;
                  if (debug_csr_save_i) depc_n = exception_pc;
                  else uepc_n = exception_pc;
                  ucause_n = csr_cause_i;

                end else begin
                  //U --> M
                  priv_lvl_n     = PRIV_LVL_M;
                  mstatus_n.mpie = mstatus_q.uie;
                  mstatus_n.mie  = 1'b0;
                  mstatus_n.mpp  = PRIV_LVL_U;
                  if (debug_csr_save_i) depc_n = exception_pc;
                  else mepc_n = exception_pc;
                  mcause_n = csr_cause_i;
                end
              end
            end  //PRIV_LVL_U

            PRIV_LVL_M: begin
              if (debug_csr_save_i) begin
                // all interrupts are masked, don't update cause, epc, tval dpc
                // and mpstatus
                dcsr_n.prv   = PRIV_LVL_M;
                dcsr_n.cause = debug_cause_i;
                depc_n       = exception_pc;
              end else begin
                //Exceptions or Interrupts from PRIV_LVL_M always do M --> M
                priv_lvl_n     = PRIV_LVL_M;
                mstatus_n.mpie = mstatus_q.mie;
                mstatus_n.mie  = 1'b0;
                mstatus_n.mpp  = PRIV_LVL_M;
                mepc_n         = exception_pc;
                mcause_n       = csr_cause_i;
              end
            end  //PRIV_LVL_M
            default: ;

          endcase

        end  //csr_save_cause_i

        csr_restore_uret_i: begin  //URET
          //mstatus_q.upp is implicitly 0, i.e PRIV_LVL_U
          mstatus_n.uie  = mstatus_q.upie;
          priv_lvl_n     = PRIV_LVL_U;
          mstatus_n.upie = 1'b1;
        end  //csr_restore_uret_i

        csr_restore_mret_i: begin  //MRET
          unique case (mstatus_q.mpp)
            PRIV_LVL_U: begin
              mstatus_n.uie  = mstatus_q.mpie;
              priv_lvl_n     = PRIV_LVL_U;
              mstatus_n.mpie = 1'b1;
              mstatus_n.mpp  = PRIV_LVL_U;
            end
            PRIV_LVL_M: begin
              mstatus_n.mie  = mstatus_q.mpie;
              priv_lvl_n     = PRIV_LVL_M;
              mstatus_n.mpie = 1'b1;
              mstatus_n.mpp  = PRIV_LVL_U;
            end
            default: ;
          endcase
        end  //csr_restore_mret_i


        csr_restore_dret_i: begin  //DRET
          // Restore to the recorded privilege level
          priv_lvl_n = dcsr_q.prv;

        end  //csr_restore_dret_i

        default: ;
      endcase
    end
  end else begin : gen_no_pulp_secure_write_logic  //PULP_SECURE == 0
    // write logic
    always_comb begin
      if (FPU == 1) begin
        fflags_n = fflags_q;
        frm_n = frm_q;
        if (ZFINX == 0) begin
          mstatus_fs_n = mstatus_fs_q;
          fcsr_update  = 1'b0;
        end
      end
      mscratch_n = mscratch_q;
      mepc_n = mepc_q;
      uepc_n = 'b0;  // Not used if PULP_SECURE == 0
      depc_n = depc_q;
      dcsr_n = dcsr_q;
      dscratch0_n = dscratch0_q;
      dscratch1_n = dscratch1_q;

      mstatus_we_int = 1'b0;
      mstatus_n = mstatus_q;
      mcause_n = mcause_q;
      ucause_n = '0;  // Not used if PULP_SECURE == 0
      exception_pc = pc_id_i;
      priv_lvl_n = priv_lvl_q;
      mtvec_n = csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q;
      utvec_n = '0;  // Not used if PULP_SECURE == 0
      pmp_reg_n.pmpaddr = '0;  // Not used if PULP_SECURE == 0
      pmp_reg_n.pmpcfg_packed = '0;  // Not used if PULP_SECURE == 0
      pmp_reg_n.pmpcfg = '0;  // Not used if PULP_SECURE == 0
      pmpaddr_we = '0;
      pmpcfg_we = '0;

      mie_n = mie_q;
      mtvec_mode_n = mtvec_mode_q;
      utvec_mode_n = '0;  // Not used if PULP_SECURE == 0

      case (csr_addr_i)
        // fcsr: Floating-Point Control and Status Register (frm, fflags, fprec).
        CSR_FFLAGS:
        if (FPU == 1) begin
          if (csr_we_int) begin
            fflags_n = csr_wdata_int[C_FFLAG-1:0];
            if (ZFINX == 0) begin
              fcsr_update = 1'b1;
            end
          end
        end
        CSR_FRM:
        if (FPU == 1) begin
          if (csr_we_int) begin
            frm_n = csr_wdata_int[C_RM-1:0];
            if (ZFINX == 0) begin
              fcsr_update = 1'b1;
            end
          end
        end
        CSR_FCSR:
        if (FPU == 1) begin
          if (csr_we_int) begin
            fflags_n = csr_wdata_int[C_FFLAG-1:0];
            frm_n    = csr_wdata_int[C_RM+C_FFLAG-1:C_FFLAG];
            if (ZFINX == 0) begin
              fcsr_update = 1'b1;
            end
          end
        end

        // mstatus
        CSR_MSTATUS:
        if (csr_we_int) begin
          mstatus_n = '{
              uie: csr_wdata_int[MSTATUS_UIE_BIT],
              mie: csr_wdata_int[MSTATUS_MIE_BIT],
              upie: csr_wdata_int[MSTATUS_UPIE_BIT],
              mpie: csr_wdata_int[MSTATUS_MPIE_BIT],
              mpp: PrivLvl_t'(csr_wdata_int[MSTATUS_MPP_BIT_HIGH:MSTATUS_MPP_BIT_LOW]),
              mprv: csr_wdata_int[MSTATUS_MPRV_BIT]
          };
          if (FPU == 1 && ZFINX == 0) begin
            mstatus_we_int = 1'b1;
            mstatus_fs_n   = FS_t'(csr_wdata_int[MSTATUS_FS_BIT_HIGH:MSTATUS_FS_BIT_LOW]);
          end
        end
        // mie: machine interrupt enable
        CSR_MIE:
        if (csr_we_int) begin
          mie_n = csr_wdata_int & IRQ_MASK;
        end
        // mtvec: machine trap-handler base address
        CSR_MTVEC:
        if (csr_we_int) begin
          mtvec_n      = csr_wdata_int[31:8];
          mtvec_mode_n = {1'b0, csr_wdata_int[0]};  // Only direct and vectored mode are supported
        end
        // mscratch: machine scratch
        CSR_MSCRATCH:
        if (csr_we_int) begin
          mscratch_n = csr_wdata_int;
        end
        // mepc: exception program counter
        CSR_MEPC:
        if (csr_we_int) begin
          mepc_n = csr_wdata_int & ~32'b1;  // force 16-bit alignment
        end
        // mcause
        CSR_MCAUSE: if (csr_we_int) mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};

        CSR_DCSR:
        if (csr_we_int) begin
          // Following are read-only and never assigned here (dcsr_q value is used):
          //
          // - xdebugver
          // - cause
          // - nmip

          dcsr_n.ebreakm   = csr_wdata_int[15];
          dcsr_n.ebreaks   = 1'b0;  // ebreaks (implemented as WARL)
          dcsr_n.ebreaku   = 1'b0;  // ebreaku (implemented as WARL)
          dcsr_n.stepie    = csr_wdata_int[11];  // stepie
          dcsr_n.stopcount = 1'b0;  // stopcount
          dcsr_n.stoptime  = 1'b0;  // stoptime
          dcsr_n.mprven    = 1'b0;  // mprven
          dcsr_n.step      = csr_wdata_int[2];
          dcsr_n.prv       = PRIV_LVL_M;  // prv (implemendted as WARL)
        end

        CSR_DPC:
        if (csr_we_int) begin
          depc_n = csr_wdata_int & ~32'b1;  // force 16-bit alignment
        end

        CSR_DSCRATCH0:
        if (csr_we_int) begin
          dscratch0_n = csr_wdata_int;
        end

        CSR_DSCRATCH1:
        if (csr_we_int) begin
          dscratch1_n = csr_wdata_int;
        end

      endcase

      if (FPU == 1) begin
        if (fflags_we_i) begin
          fflags_n = fflags_i | fflags_q;
        end

        if (ZFINX == 0) begin
          // FPU Register File/Flags implicit update or modified by CSR instructions
          if ((fregs_we_i && !(mstatus_we_int && mstatus_fs_n != FS_DIRTY)) || fflags_we_i || fcsr_update) begin
            mstatus_fs_n = FS_DIRTY;
          end
        end
      end

      // exception controller gets priority over other writes
      unique case (1'b1)

        csr_save_cause_i: begin
          unique case (1'b1)
            csr_save_if_i: exception_pc = pc_if_i;
            csr_save_id_i: exception_pc = pc_id_i;
            csr_save_ex_i: exception_pc = pc_ex_i;
            default: ;
          endcase

          if (debug_csr_save_i) begin
            // all interrupts are masked, don't update cause, epc, tval dpc and
            // mpstatus
            dcsr_n.prv   = PRIV_LVL_M;
            dcsr_n.cause = debug_cause_i;
            depc_n       = exception_pc;
          end else begin
            priv_lvl_n     = PRIV_LVL_M;
            mstatus_n.mpie = mstatus_q.mie;
            mstatus_n.mie  = 1'b0;
            mstatus_n.mpp  = PRIV_LVL_M;
            mepc_n         = exception_pc;
            mcause_n       = csr_cause_i;
          end
        end  //csr_save_cause_i

        csr_restore_mret_i: begin  //MRET
          mstatus_n.mie  = mstatus_q.mpie;
          priv_lvl_n     = PRIV_LVL_M;
          mstatus_n.mpie = 1'b1;
          mstatus_n.mpp  = PRIV_LVL_M;
        end  //csr_restore_mret_i

        csr_restore_dret_i: begin  //DRET
          // Restore to the recorded privilege level
          priv_lvl_n = dcsr_q.prv;
        end  //csr_restore_dret_i

        default: ;
      endcase
    end
  end  //PULP_SECURE

  // CSR operation logic
  always_comb begin
    csr_wdata_int = csr_wdata_i;
    csr_we_int    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;
      CSR_OP_SET:   csr_wdata_int = csr_wdata_i | csr_rdata_o;
      CSR_OP_CLEAR: csr_wdata_int = (~csr_wdata_i) & csr_rdata_o;

      CSR_OP_READ: begin
        csr_wdata_int = csr_wdata_i;
        csr_we_int    = 1'b0;
      end
    endcase
  end

  assign csr_rdata_o = csr_rdata_int;

  // directly output some registers
  assign m_irq_enable_o = mstatus_q.mie && !(dcsr_q.step && !dcsr_q.stepie);
  assign u_irq_enable_o = mstatus_q.uie && !(dcsr_q.step && !dcsr_q.stepie);
  assign priv_lvl_o = priv_lvl_q;
  assign sec_lvl_o = priv_lvl_q[0];

  // mstatus_fs_q = FS_OFF, FPU not enabled
  assign fs_off_o = (FPU == 1 && ZFINX == 0) ? (mstatus_fs_q == FS_OFF ? 1'b1 : 1'b0) : 1'b0;
  assign frm_o = (FPU == 1) ? frm_q : '0;

  assign mtvec_o = mtvec_q;
  assign utvec_o = utvec_q;
  assign mtvec_mode_o = mtvec_mode_q;
  assign utvec_mode_o = utvec_mode_q;

  assign mepc_o = mepc_q;
  assign uepc_o = uepc_q;

  assign mcounteren_o = PULP_SECURE ? mcounteren_q : '0;

  assign depc_o = depc_q;

  assign pmp_addr_o = pmp_reg_q.pmpaddr;
  assign pmp_cfg_o = pmp_reg_q.pmpcfg;

  assign debug_single_step_o = dcsr_q.step;
  assign debug_ebreakm_o = dcsr_q.ebreakm;
  assign debug_ebreaku_o = dcsr_q.ebreaku;

  generate
    if (PULP_SECURE == 1) begin : gen_pmp_user

      for (j = 0; j < N_PMP_ENTRIES; j++) begin : CS_PMP_CFG
        assign pmp_reg_n.pmpcfg[j] = pmp_reg_n.pmpcfg_packed[j/4][8*((j%4)+1)-1:8*(j%4)];
        assign pmp_reg_q.pmpcfg_packed[j/4][8*((j%4)+1)-1:8*(j%4)] = pmp_reg_q.pmpcfg[j];
      end

      for (j = 0; j < N_PMP_ENTRIES; j++) begin : CS_PMP_REGS_FF
        always_ff @(posedge clk, negedge rst_n) begin
          if (rst_n == 1'b0) begin
            pmp_reg_q.pmpcfg[j]  <= '0;
            pmp_reg_q.pmpaddr[j] <= '0;
          end else begin
            if (pmpcfg_we[j]) pmp_reg_q.pmpcfg[j] <= USE_PMP ? pmp_reg_n.pmpcfg[j] : '0;
            if (pmpaddr_we[j]) pmp_reg_q.pmpaddr[j] <= USE_PMP ? pmp_reg_n.pmpaddr[j] : '0;
          end
        end
      end  //CS_PMP_REGS_FF

      always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
          uepc_q       <= '0;
          ucause_q     <= '0;
          utvec_q      <= '0;
          utvec_mode_q <= MTVEC_MODE;
          priv_lvl_q   <= PRIV_LVL_M;
        end else begin
          uepc_q       <= uepc_n;
          ucause_q     <= ucause_n;
          utvec_q      <= utvec_n;
          utvec_mode_q <= utvec_mode_n;
          priv_lvl_q   <= priv_lvl_n;
        end
      end
    end else begin : gen_no_pmp_user
      assign pmp_reg_q    = '0;
      assign uepc_q       = '0;
      assign ucause_q     = '0;
      assign utvec_q      = '0;
      assign utvec_mode_q = '0;
      assign priv_lvl_q   = PRIV_LVL_M;
    end
  endgenerate

  // actual registers
  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      if (FPU == 1) begin
        frm_q <= '0;
        fflags_q <= '0;
        if (ZFINX == 0) begin
          mstatus_fs_q <= FS_OFF;
        end
      end
      mstatus_q <= '{
          uie: 1'b0,
          mie: 1'b0,
          upie: 1'b0,
          mpie: 1'b0,
          mpp: PRIV_LVL_M,
          mprv: 1'b0
      };
      mepc_q <= '0;
      mcause_q <= '0;

      depc_q <= '0;
      dcsr_q <= '{
          xdebugver: XDEBUGVER_STD,
          cause: DBG_CAUSE_NONE,  // 3'h0
          prv: PRIV_LVL_M,
          default: '0
      };
      dscratch0_q <= '0;
      dscratch1_q <= '0;
      mscratch_q <= '0;
      mie_q <= '0;
      mtvec_q <= '0;
      mtvec_mode_q <= MTVEC_MODE;
    end else begin
      // update CSRs
      if (FPU == 1) begin
        frm_q    <= frm_n;
        fflags_q <= fflags_n;
        if (ZFINX == 0) begin
          mstatus_fs_q <= mstatus_fs_n;
        end
      end
      if (PULP_SECURE == 1) begin
        mstatus_q <= mstatus_n;
      end else begin
        mstatus_q <= '{
            uie: 1'b0,
            mie: mstatus_n.mie,
            upie: 1'b0,
            mpie: mstatus_n.mpie,
            mpp: PRIV_LVL_M,
            mprv: 1'b0
        };
      end
      mepc_q       <= mepc_n;
      mcause_q     <= mcause_n;
      depc_q       <= depc_n;
      dcsr_q       <= dcsr_n;
      dscratch0_q  <= dscratch0_n;
      dscratch1_q  <= dscratch1_n;
      mscratch_q   <= mscratch_n;
      mie_q        <= mie_n;
      mtvec_q      <= mtvec_n;
      mtvec_mode_q <= mtvec_mode_n;
    end
  end
  ////////////////////////////////////////////////////////////////////////
  //  ____       _                   _____     _                        //
  // |  _ \  ___| |__  _   _  __ _  |_   _| __(_) __ _  __ _  ___ _ __  //
  // | | | |/ _ \ '_ \| | | |/ _` |   | || '__| |/ _` |/ _` |/ _ \ '__| //
  // | |_| |  __/ |_) | |_| | (_| |   | || |  | | (_| | (_| |  __/ |    //
  // |____/ \___|_.__/ \__,_|\__, |   |_||_|  |_|\__, |\__, |\___|_|    //
  //                         |___/               |___/ |___/            //
  ////////////////////////////////////////////////////////////////////////

  if (DEBUG_TRIGGER_EN) begin : gen_trigger_regs
    // Register values
    logic        tmatch_control_exec_q;
    logic [31:0] tmatch_value_q;
    // Write enables
    logic        tmatch_control_we;
    logic        tmatch_value_we;

    // Write select
    assign tmatch_control_we = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA1);
    assign tmatch_value_we   = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA2);


    // Registers
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        tmatch_control_exec_q <= 'b0;
        tmatch_value_q        <= 'b0;
      end else begin
        if (tmatch_control_we) tmatch_control_exec_q <= csr_wdata_int[2];
        if (tmatch_value_we) tmatch_value_q <= csr_wdata_int[31:0];
      end
    end

    // All supported trigger types
    assign tinfo_types = 1 << TTYPE_MCONTROL;

    // Assign read data
    // TDATA0 - only support simple address matching
    assign tmatch_control_rdata = {
      TTYPE_MCONTROL,  // type    : address/data match
      1'b1,  // dmode   : access from D mode only
      6'h00,  // maskmax : exact match only
      1'b0,  // hit     : not supported
      1'b0,  // select  : address match only
      1'b0,  // timing  : match before execution
      2'b00,  // sizelo  : match any access
      4'h1,  // action  : enter debug mode
      1'b0,  // chain   : not supported
      4'h0,  // match   : simple match
      1'b1,  // m       : match in m-mode
      1'b0,  // 0       : zero
      1'b0,  // s       : not supported
      PULP_SECURE == 1,  // u       : match in u-mode
      tmatch_control_exec_q,  // execute : match instruction address
      1'b0,  // store   : not supported
      1'b0
    };  // load    : not supported

    // TDATA1 - address match value only
    assign tmatch_value_rdata = tmatch_value_q;

    // Breakpoint matching
    // We match against the next address, as the breakpoint must be taken before execution
    assign trigger_match_o = tmatch_control_exec_q & (pc_id_i[31:0] == tmatch_value_q[31:0]);

  end else begin : gen_no_trigger_regs
    assign tinfo_types          = 'b0;
    assign tmatch_control_rdata = 'b0;
    assign tmatch_value_rdata   = 'b0;
    assign trigger_match_o      = 'b0;
  end

  /////////////////////////////////////////////////////////////////
  //   ____            __     ____                  _            //
  // |  _ \ ___ _ __ / _|   / ___|___  _   _ _ __ | |_ ___ _ __  //
  // | |_) / _ \ '__| |_   | |   / _ \| | | | '_ \| __/ _ \ '__| //
  // |  __/  __/ |  |  _|  | |__| (_) | |_| | | | | ||  __/ |    //
  // |_|   \___|_|  |_|(_)  \____\___/ \__,_|_| |_|\__\___|_|    //
  //                                                             //
  /////////////////////////////////////////////////////////////////

  // ------------------------
  // Events to count
  assign hpm_events[0] = 1'b1;  // cycle counter
  assign hpm_events[1] = mhpmevent_minstret_i;  // instruction counter
  assign hpm_events[2] = mhpmevent_ld_stall_i;  // nr of load use hazards
  assign hpm_events[3] = mhpmevent_jr_stall_i;  // nr of jump register hazards
  assign hpm_events[4]  = mhpmevent_imiss_i;                             // cycles waiting for instruction fetches, excluding jumps and branches
  assign hpm_events[5] = mhpmevent_load_i;  // nr of loads
  assign hpm_events[6] = mhpmevent_store_i;  // nr of stores
  assign hpm_events[7] = mhpmevent_jump_i;  // nr of jumps (unconditional)
  assign hpm_events[8] = mhpmevent_branch_i;  // nr of branches (conditional)
  assign hpm_events[9] = mhpmevent_branch_taken_i;  // nr of taken branches (conditional)
  assign hpm_events[10] = mhpmevent_compressed_i;  // compressed instruction counter
  assign hpm_events[11] = COREV_CLUSTER ? mhpmevent_pipe_stall_i : 1'b0;  // extra cycles from ELW
  assign hpm_events[12] = !APU ? 1'b0 : apu_typeconflict_i && !apu_dep_i;
  assign hpm_events[13] = !APU ? 1'b0 : apu_contention_i;
  assign hpm_events[14] = !APU ? 1'b0 : apu_dep_i && !apu_contention_i;
  assign hpm_events[15] = !APU ? 1'b0 : apu_wb_i;

  // ------------------------
  // address decoder for performance counter registers
  logic mcounteren_we;
  logic mcountinhibit_we;
  logic mhpmevent_we;

  assign mcounteren_we = csr_we_int & (csr_addr_i == CSR_MCOUNTEREN);
  assign mcountinhibit_we = csr_we_int & (csr_addr_i == CSR_MCOUNTINHIBIT);
  assign mhpmevent_we     = csr_we_int & ( (csr_addr_i == CSR_MHPMEVENT3  )||
                                           (csr_addr_i == CSR_MHPMEVENT4  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT5  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT6  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT7  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT8  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT9  ) ||
                                           (csr_addr_i == CSR_MHPMEVENT10 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT11 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT12 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT13 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT14 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT15 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT16 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT17 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT18 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT19 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT20 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT21 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT22 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT23 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT24 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT25 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT26 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT27 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT28 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT29 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT30 ) ||
                                           (csr_addr_i == CSR_MHPMEVENT31 ) );

  // ------------------------
  // Increment value for performance counters
  genvar incr_gidx;
  generate
    for (incr_gidx = 0; incr_gidx < 32; incr_gidx++) begin : gen_mhpmcounter_increment
      assign mhpmcounter_increment[incr_gidx] = mhpmcounter_q[incr_gidx] + 1;
    end
  endgenerate

  // ------------------------
  // next value for performance counters and control registers
  always_comb begin
    mcounteren_n    = mcounteren_q;
    mcountinhibit_n = mcountinhibit_q;
    mhpmevent_n     = mhpmevent_q;

    // User Mode Enable
    if (PULP_SECURE && mcounteren_we) mcounteren_n = csr_wdata_int;

    // Inhibit Control
    if (mcountinhibit_we) mcountinhibit_n = csr_wdata_int;

    // Event Control
    if (mhpmevent_we) mhpmevent_n[csr_addr_i[4:0]] = csr_wdata_int;
  end

  genvar wcnt_gidx;
  generate
    for (wcnt_gidx = 0; wcnt_gidx < 32; wcnt_gidx++) begin : gen_mhpmcounter_write

      // Write lower counter bits
      assign mhpmcounter_write_lower[wcnt_gidx] = csr_we_int && (csr_addr_i == (CSR_MCYCLE + wcnt_gidx));

      // Write upper counter bits
      assign mhpmcounter_write_upper[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                  csr_we_int && (csr_addr_i == (CSR_MCYCLEH + wcnt_gidx)) && (MHPMCOUNTER_WIDTH == 64);

      // Increment counter
      if (!PULP_PERF_COUNTERS) begin : gen_no_pulp_perf_counters
        if (wcnt_gidx == 0) begin : gen_mhpmcounter_mcycle
          // mcycle = mhpmcounter[0] : count every cycle (if not inhibited)
          assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx];
        end else if (wcnt_gidx == 2) begin : gen_mhpmcounter_minstret
          // minstret = mhpmcounter[2]  : count every retired instruction (if not inhibited)
          assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx] &&
                                                          hpm_events[1];
        end else if( (wcnt_gidx>2) && (wcnt_gidx<(NUM_MHPMCOUNTERS+3))) begin : gen_mhpmcounter
          // add +1 if any event is enabled and active
          assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx] &&
                                                          |(hpm_events & mhpmevent_q[wcnt_gidx][NUM_HPM_EVENTS-1:0]);
        end else begin : gen_mhpmcounter_not_implemented
          assign mhpmcounter_write_increment[wcnt_gidx] = 1'b0;
        end
      end else begin : gen_pulp_perf_counters
        // PULP PERF COUNTERS share all events in one register (not compliant with RISC-V)
        assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                        !mhpmcounter_write_upper[wcnt_gidx] &&
                                                        !mcountinhibit_q[wcnt_gidx] &&
                                                        |(hpm_events & mhpmevent_q[wcnt_gidx][NUM_HPM_EVENTS-1:0]);
      end
    end
  endgenerate

  // ------------------------
  // HPM Registers
  //  Counter Registers: mhpcounter_q[]
  genvar cnt_gidx;
  generate
    for (cnt_gidx = 0; cnt_gidx < 32; cnt_gidx++) begin : gen_mhpmcounter
      // mcyclce  is located at index 0
      // there is no counter at index 1
      // minstret is located at index 2
      // Programable HPM counters start at index 3
      if ((cnt_gidx == 1) || (cnt_gidx >= (NUM_MHPMCOUNTERS + 3))) begin : gen_non_implemented
        assign mhpmcounter_q[cnt_gidx] = 'b0;
      end else begin : gen_implemented
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) begin
            mhpmcounter_q[cnt_gidx] <= 'b0;
          end else begin
            if (PULP_PERF_COUNTERS && (cnt_gidx == 2 || cnt_gidx == 0)) begin
              mhpmcounter_q[cnt_gidx] <= 'b0;
            end else begin
              if (mhpmcounter_write_lower[cnt_gidx]) begin
                mhpmcounter_q[cnt_gidx][31:0] <= csr_wdata_int;
              end else if (mhpmcounter_write_upper[cnt_gidx]) begin
                mhpmcounter_q[cnt_gidx][63:32] <= csr_wdata_int;
              end else if (mhpmcounter_write_increment[cnt_gidx]) begin
                mhpmcounter_q[cnt_gidx] <= mhpmcounter_increment[cnt_gidx];
              end
            end
          end
      end
    end
  endgenerate

  //  Event Register: mhpevent_q[]
  genvar evt_gidx;
  generate
    for (evt_gidx = 0; evt_gidx < 32; evt_gidx++) begin : gen_mhpmevent
      // programable HPM events start at index3
      if ((evt_gidx < 3) || (evt_gidx >= (NUM_MHPMCOUNTERS + 3))) begin : gen_non_implemented
        assign mhpmevent_q[evt_gidx] = 'b0;
      end else begin : gen_implemented
        if (NUM_HPM_EVENTS < 32) begin : gen_tie_off
          assign mhpmevent_q[evt_gidx][31:NUM_HPM_EVENTS] = 'b0;
        end
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) mhpmevent_q[evt_gidx][NUM_HPM_EVENTS-1:0] <= 'b0;
          else
            mhpmevent_q[evt_gidx][NUM_HPM_EVENTS-1:0] <= mhpmevent_n[evt_gidx][NUM_HPM_EVENTS-1:0];
      end
    end
  endgenerate

  //  Enable Regsiter: mcounteren_q
  genvar en_gidx;
  generate
    for (en_gidx = 0; en_gidx < 32; en_gidx++) begin : gen_mcounteren
      if( (PULP_SECURE == 0) ||
          (en_gidx == 1) ||
          (en_gidx >= (NUM_MHPMCOUNTERS+3) ) )
        begin : gen_non_implemented
        assign mcounteren_q[en_gidx] = 'b0;
      end else begin : gen_implemented
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) mcounteren_q[en_gidx] <= 'b0;  // default disable
          else mcounteren_q[en_gidx] <= mcounteren_n[en_gidx];
      end
    end
  endgenerate

  //  Inhibit Regsiter: mcountinhibit_q
  //  Note: implemented counters are disabled out of reset to save power
  genvar inh_gidx;
  generate
    for (inh_gidx = 0; inh_gidx < 32; inh_gidx++) begin : gen_mcountinhibit
      if ((inh_gidx == 1) || (inh_gidx >= (NUM_MHPMCOUNTERS + 3))) begin : gen_non_implemented
        assign mcountinhibit_q[inh_gidx] = 'b0;
      end else begin : gen_implemented
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) mcountinhibit_q[inh_gidx] <= 'b1;  // default disable
          else mcountinhibit_q[inh_gidx] <= mcountinhibit_n[inh_gidx];
      end
    end
  endgenerate

`ifdef CV32E40P_ASSERT_ON

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

  // Check that mie_bypass_o equals mie_n
  a_mie_bypass :
  assert property (@(posedge clk) disable iff (!rst_n) (1'b1) |-> (mie_bypass_o == mie_n));

`endif

endmodule

// -------------------- END OF rtl/cv32e40p_cs_registers.sv --------------------

// -------------------- START OF rtl/cv32e40p_decoder.sv --------------------
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
// Engineer        Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Additional contributions by:                                               //
//                 Matthias Baer - baermatt@student.ethz.ch                   //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Decoder                                                    //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decoder                                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_decoder
  import cv32e40p_pkg::*;
  import cv32e40p_apu_core_pkg::*;
  import cv32e40p_fpu_pkg::*;
#(
  parameter COREV_PULP        = 1,              // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding cv.elw)
  parameter COREV_CLUSTER     = 0,              // PULP ISA Extension cv.elw (need COREV_PULP = 1)
  parameter A_EXTENSION       = 0,
  parameter FPU               = 0,
  parameter FPU_ADDMUL_LAT    = 0,
  parameter FPU_OTHERS_LAT    = 0,
  parameter ZFINX             = 0,
  parameter PULP_SECURE       = 0,
  parameter USE_PMP           = 0,
  parameter APU_WOP_CPU       = 6,
  parameter DEBUG_TRIGGER_EN  = 1
)
(
  // signals running to/from controller
  input  logic        deassert_we_i,           // deassert we, we are stalled or not active

  output logic        illegal_insn_o,          // illegal instruction encountered
  output logic        ebrk_insn_o,             // trap instruction encountered

  output logic        mret_insn_o,             // return from exception instruction encountered (M)
  output logic        uret_insn_o,             // return from exception instruction encountered (S)
  output logic        dret_insn_o,             // return from debug (M)

  output logic        mret_dec_o,              // return from exception instruction encountered (M) without deassert
  output logic        uret_dec_o,              // return from exception instruction encountered (S) without deassert
  output logic        dret_dec_o,              // return from debug (M) without deassert

  output logic        ecall_insn_o,            // environment call (syscall) instruction encountered
  output logic        wfi_o       ,            // pipeline flush is requested

  output logic        fencei_insn_o,           // fence.i instruction

  output logic        rega_used_o,             // rs1 is used by current instruction
  output logic        regb_used_o,             // rs2 is used by current instruction
  output logic        regc_used_o,             // rs3 is used by current instruction

  output logic        reg_fp_a_o,              // fp reg a is used
  output logic        reg_fp_b_o,              // fp reg b is used
  output logic        reg_fp_c_o,              // fp reg c is used
  output logic        reg_fp_d_o,              // fp reg d is used

  output logic [ 0:0] bmask_a_mux_o,           // bit manipulation mask a mux
  output logic [ 1:0] bmask_b_mux_o,           // bit manipulation mask b mux
  output logic        alu_bmask_a_mux_sel_o,   // bit manipulation mask a mux (reg or imm)
  output logic        alu_bmask_b_mux_sel_o,   // bit manipulation mask b mux (reg or imm)

  // from IF/ID pipeline
  input  logic [31:0] instr_rdata_i,           // instruction read from instr memory/cache
  input  logic        illegal_c_insn_i,        // compressed instruction decode failed

  // ALU signals
  output logic        alu_en_o,                // ALU enable
  output alu_opcode_e alu_operator_o, // ALU operation selection
  output logic [2:0]  alu_op_a_mux_sel_o,      // operand a selection: reg value, PC, immediate or zero
  output logic [2:0]  alu_op_b_mux_sel_o,      // operand b selection: reg value or immediate
  output logic [1:0]  alu_op_c_mux_sel_o,      // operand c selection: reg value or jump target
  output logic        alu_vec_o,               // vectorial instruction
  output logic [1:0]  alu_vec_mode_o,          // selects between 32 bit, 16 bit and 8 bit vectorial modes
  output logic        scalar_replication_o,    // scalar replication enable
  output logic        scalar_replication_c_o,  // scalar replication enable for operand C
  output logic [0:0]  imm_a_mux_sel_o,         // immediate selection for operand a
  output logic [3:0]  imm_b_mux_sel_o,         // immediate selection for operand b
  output logic [1:0]  regc_mux_o,              // register c selection: S3, RD or 0
  output logic        is_clpx_o,               // whether the instruction is complex (pulpv3) or not
  output logic        is_subrot_o,

  // MUL related control signals
  output mul_opcode_e mult_operator_o,         // Multiplication operation selection
  output logic        mult_int_en_o,           // perform integer multiplication
  output logic        mult_dot_en_o,           // perform dot multiplication
  output logic [0:0]  mult_imm_mux_o,          // Multiplication immediate mux selector
  output logic        mult_sel_subword_o,      // Select subwords for 16x16 bit of multiplier
  output logic [1:0]  mult_signed_mode_o,      // Multiplication in signed mode
  output logic [1:0]  mult_dot_signed_o,       // Dot product in signed mode

  // FPU
  input  logic            fs_off_i, // Floating-Point State field from MSTATUS
  input  logic [C_RM-1:0] frm_i,    // Rounding mode from float CSR

  output logic [cv32e40p_fpu_pkg::FP_FORMAT_BITS-1:0]  fpu_dst_fmt_o,   // fpu destination format
  output logic [cv32e40p_fpu_pkg::FP_FORMAT_BITS-1:0]  fpu_src_fmt_o,   // fpu source format
  output logic [cv32e40p_fpu_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt_o,   // fpu integer format (for casts)

  // APU
  output logic                   apu_en_o,
  output logic [APU_WOP_CPU-1:0] apu_op_o,
  output logic [1:0]             apu_lat_o,
  output logic [2:0]             fp_rnd_mode_o,

  // register file related signals
  output logic        regfile_mem_we_o,        // write enable for regfile
  output logic        regfile_alu_we_o,        // write enable for 2nd regfile port
  output logic        regfile_alu_we_dec_o,    // write enable for 2nd regfile port without deassert
  output logic        regfile_alu_waddr_sel_o, // Select register write address for ALU/MUL operations

  // CSR manipulation
  output logic        csr_access_o,            // access to CSR
  output logic        csr_status_o,            // access to xstatus CSR
  output csr_opcode_e csr_op_o,                // operation to perform on CSR
  input  PrivLvl_t    current_priv_lvl_i,      // The current privilege level

  // LD/ST unit signals
  output logic        data_req_o,              // start transaction to data memory
  output logic        data_we_o,               // data memory write enable
  output logic        prepost_useincr_o,       // when not active bypass the alu result for address calculation
  output logic [1:0]  data_type_o,             // data type on data memory: byte, half word or word
  output logic [1:0]  data_sign_extension_o,   // sign extension on read data from data memory / NaN boxing
  output logic [1:0]  data_reg_offset_o,       // offset in byte inside register for stores
  output logic        data_load_event_o,       // data request is in the special event range

  // Atomic memory access
  output logic [5:0] atop_o,

  // hwloop signals
  output logic [2:0]  hwlp_we_o,               // write enable for hwloop regs
  output logic [1:0]  hwlp_target_mux_sel_o,   // selects immediate for hwloop target
  output logic [1:0]  hwlp_start_mux_sel_o,    // selects hwloop start address input
  output logic        hwlp_cnt_mux_sel_o,      // selects hwloop counter input

  input  logic        debug_mode_i,            // processor is in debug mode
  input  logic        debug_wfi_no_sleep_i,    // do not let WFI cause sleep

  // jump/branches
  output logic [1:0]  ctrl_transfer_insn_in_dec_o,  // control transfer instruction without deassert
  output logic [1:0]  ctrl_transfer_insn_in_id_o,   // control transfer instructio is decoded
  output logic [1:0]  ctrl_transfer_target_mux_sel_o,        // jump target selection

  // HPM related control signals
  input  logic [31:0] mcounteren_i
);

  // write enable/request control
  logic       regfile_mem_we;
  logic       regfile_alu_we;
  logic       data_req;
  logic [2:0] hwlp_we;
  logic       csr_illegal;
  logic [1:0] ctrl_transfer_insn;

  csr_opcode_e csr_op;

  logic       alu_en;
  logic       mult_int_en;
  logic       mult_dot_en;
  logic       apu_en;

  // this instruction needs floating-point rounding-mode verification
  logic check_fprm;

  logic [cv32e40p_fpu_pkg::OP_BITS-1:0] fpu_op;     // fpu operation
  logic                                 fpu_op_mod; // fpu operation modifier
  logic                                 fpu_vec_op; // fpu vectorial operation
  // unittypes for latencies to help us decode for APU
  enum logic[1:0] {ADDMUL, DIVSQRT, NONCOMP, CONV} fp_op_group;


  /////////////////////////////////////////////
  //   ____                     _            //
  //  |  _ \  ___  ___ ___   __| | ___ _ __  //
  //  | | | |/ _ \/ __/ _ \ / _` |/ _ \ '__| //
  //  | |_| |  __/ (_| (_) | (_| |  __/ |    //
  //  |____/ \___|\___\___/ \__,_|\___|_|    //
  //                                         //
  /////////////////////////////////////////////

  always_comb
  begin: instruction_decoder
    ctrl_transfer_insn             = BRANCH_NONE;
    ctrl_transfer_target_mux_sel_o = JT_JAL;

    alu_en                         = 1'b1;
    alu_operator_o                 = ALU_SLTU;
    alu_op_a_mux_sel_o             = OP_A_REGA_OR_FWD;
    alu_op_b_mux_sel_o             = OP_B_REGB_OR_FWD;
    alu_op_c_mux_sel_o             = OP_C_REGC_OR_FWD;
    alu_vec_o                      = 1'b0;
    alu_vec_mode_o                 = VEC_MODE32;
    scalar_replication_o           = 1'b0;
    scalar_replication_c_o         = 1'b0;
    regc_mux_o                     = REGC_ZERO;
    imm_a_mux_sel_o                = IMMA_ZERO;
    imm_b_mux_sel_o                = IMMB_I;

    mult_int_en                    = 1'b0;
    mult_dot_en                    = 1'b0;
    mult_operator_o                = MUL_I;
    mult_imm_mux_o                 = MIMM_ZERO;
    mult_signed_mode_o             = 2'b00;
    mult_sel_subword_o             = 1'b0;
    mult_dot_signed_o              = 2'b00;

    apu_en                         = 1'b0;
    apu_op_o                       = '0;
    apu_lat_o                      = '0;
    fp_rnd_mode_o                  = '0;
    fpu_op                         = cv32e40p_fpu_pkg::SGNJ;
    fpu_op_mod                     = 1'b0;
    fpu_vec_op                     = 1'b0;
    fpu_dst_fmt_o                  = cv32e40p_fpu_pkg::FP32;
    fpu_src_fmt_o                  = cv32e40p_fpu_pkg::FP32;
    fpu_int_fmt_o                  = cv32e40p_fpu_pkg::INT32;
    check_fprm                     = 1'b0;
    fp_op_group                    = ADDMUL;

    regfile_mem_we                 = 1'b0;
    regfile_alu_we                 = 1'b0;
    regfile_alu_waddr_sel_o        = 1'b1;

    prepost_useincr_o              = 1'b1;

    hwlp_we                        = 3'b0;
    hwlp_target_mux_sel_o          = 2'b0;
    hwlp_start_mux_sel_o           = 2'b0;
    hwlp_cnt_mux_sel_o             = 1'b0;

    csr_access_o                   = 1'b0;
    csr_status_o                   = 1'b0;
    csr_illegal                    = 1'b0;
    csr_op                         = CSR_OP_READ;
    mret_insn_o                    = 1'b0;
    uret_insn_o                    = 1'b0;

    dret_insn_o                    = 1'b0;

    data_we_o                      = 1'b0;
    data_type_o                    = 2'b00;
    data_sign_extension_o          = 2'b00;
    data_reg_offset_o              = 2'b00;
    data_req                       = 1'b0;
    data_load_event_o              = 1'b0;

    atop_o                         = 6'b000000;

    illegal_insn_o                 = 1'b0;
    ebrk_insn_o                    = 1'b0;
    ecall_insn_o                   = 1'b0;
    wfi_o                          = 1'b0;

    fencei_insn_o                  = 1'b0;

    rega_used_o                    = 1'b0;
    regb_used_o                    = 1'b0;
    regc_used_o                    = 1'b0;
    reg_fp_a_o                     = 1'b0;
    reg_fp_b_o                     = 1'b0;
    reg_fp_c_o                     = 1'b0;
    reg_fp_d_o                     = 1'b0;

    bmask_a_mux_o                  = BMASK_A_ZERO;
    bmask_b_mux_o                  = BMASK_B_ZERO;
    alu_bmask_a_mux_sel_o          = BMASK_A_IMM;
    alu_bmask_b_mux_sel_o          = BMASK_B_IMM;

    is_clpx_o                      = 1'b0;
    is_subrot_o                    = 1'b0;

    mret_dec_o                     = 1'b0;
    uret_dec_o                     = 1'b0;
    dret_dec_o                     = 1'b0;

    unique case (instr_rdata_i[6:0])

      //////////////////////////////////////
      //      _ _   _ __  __ ____  ____   //
      //     | | | | |  \/  |  _ \/ ___|  //
      //  _  | | | | | |\/| | |_) \___ \  //
      // | |_| | |_| | |  | |  __/ ___) | //
      //  \___/ \___/|_|  |_|_|   |____/  //
      //                                  //
      //////////////////////////////////////

      OPCODE_JAL: begin   // Jump and Link
        ctrl_transfer_target_mux_sel_o = JT_JAL;
        ctrl_transfer_insn    = BRANCH_JAL;
        // Calculate and store PC+4
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_PCINCR;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
        // Calculate jump target (= PC + UJ imm)
      end

      OPCODE_JALR: begin  // Jump and Link Register
        ctrl_transfer_target_mux_sel_o = JT_JALR;
        ctrl_transfer_insn    = BRANCH_JALR;
        // Calculate and store PC+4
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_PCINCR;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
        // Calculate jump target (= RS1 + I imm)
        rega_used_o         = 1'b1;

        if (instr_rdata_i[14:12] != 3'b0) begin
          ctrl_transfer_insn = BRANCH_NONE;
          regfile_alu_we     = 1'b0;
          illegal_insn_o     = 1'b1;
        end
      end

      OPCODE_BRANCH: begin // Branch
        ctrl_transfer_target_mux_sel_o = JT_COND;
        ctrl_transfer_insn             = BRANCH_COND;
        alu_op_c_mux_sel_o             = OP_C_JT;
        rega_used_o                    = 1'b1;
        regb_used_o                    = 1'b1;

        unique case (instr_rdata_i[14:12])
          3'b000 : alu_operator_o = ALU_EQ;
          3'b001 : alu_operator_o = ALU_NE;
          3'b100 : alu_operator_o = ALU_LTS;
          3'b101 : alu_operator_o = ALU_GES;
          3'b110 : alu_operator_o = ALU_LTU;
          3'b111 : alu_operator_o = ALU_GEU;
          default: illegal_insn_o = 1'b1;
        endcase
      end


      //////////////////////////////////
      //  _     ____    ______ _____  //
      // | |   |  _ \  / / ___|_   _| //
      // | |   | | | |/ /\___ \ | |   //
      // | |___| |_| / /  ___) || |   //
      // |_____|____/_/  |____/ |_|   //
      //                              //
      //////////////////////////////////

      OPCODE_STORE: begin
        data_req           = 1'b1;
        data_we_o          = 1'b1;
        rega_used_o        = 1'b1;
        regb_used_o        = 1'b1;
        alu_operator_o     = ALU_ADD;
        // pass write data through ALU operand c
        alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
        // offset from immediate
        imm_b_mux_sel_o    = IMMB_S;
        alu_op_b_mux_sel_o = OP_B_IMM;

        // store size
        unique case (instr_rdata_i[14:12])
          3'b000 : data_type_o = 2'b10; // SB
          3'b001 : data_type_o = 2'b01; // SH
          3'b010 : data_type_o = 2'b00; // SW
          default: begin
            illegal_insn_o = 1'b1;
            data_req       = 1'b0;
            data_we_o      = 1'b0;
          end
        endcase
      end

      OPCODE_LOAD: begin
        data_req           = 1'b1;
        regfile_mem_we     = 1'b1;
        rega_used_o        = 1'b1;
        alu_operator_o     = ALU_ADD;
        // offset from immediate
        alu_op_b_mux_sel_o = OP_B_IMM;
        imm_b_mux_sel_o    = IMMB_I;

        // sign/zero extension
        data_sign_extension_o = {1'b0,~instr_rdata_i[14]};

        // load size
        unique case (instr_rdata_i[14:12])
          3'b000, 3'b100: data_type_o = 2'b10; // LB/LBU
          3'b001, 3'b101: data_type_o = 2'b01; // LH/LHU
          3'b010        : data_type_o = 2'b00; // LW
          default: begin
            illegal_insn_o = 1'b1;
          end
        endcase
      end

      OPCODE_AMO: begin
        if (A_EXTENSION) begin : decode_amo
          if (instr_rdata_i[14:12] == 3'b010) begin // RV32A Extension (word)
            data_req          = 1'b1;
            data_type_o       = 2'b00;
            rega_used_o       = 1'b1;
            regb_used_o       = 1'b1;
            regfile_mem_we    = 1'b1;
            prepost_useincr_o = 1'b0; // only use alu_operand_a as address (not a+b)
            alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;

            data_sign_extension_o = 1'b1;

            // Apply AMO instruction at `atop_o`.
            atop_o = {1'b1, instr_rdata_i[31:27]};

            unique case (instr_rdata_i[31:27])
              AMO_LR: begin
                data_we_o = 1'b0;
              end
              AMO_SC,
              AMO_SWAP,
              AMO_ADD,
              AMO_XOR,
              AMO_AND,
              AMO_OR,
              AMO_MIN,
              AMO_MAX,
              AMO_MINU,
              AMO_MAXU: begin
                data_we_o = 1'b1;
                alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD; // pass write data through ALU operand c
              end
              default : illegal_insn_o = 1'b1;
            endcase
          end
          else begin
            illegal_insn_o = 1'b1;
          end
        end else begin : no_decode_amo
          illegal_insn_o = 1'b1;
        end
      end

      //////////////////////////
      //     _    _    _   _  //
      //    / \  | |  | | | | //
      //   / _ \ | |  | | | | //
      //  / ___ \| |__| |_| | //
      // /_/   \_\_____\___/  //
      //                      //
      //////////////////////////

      OPCODE_LUI: begin  // Load Upper Immediate
        alu_op_a_mux_sel_o  = OP_A_IMM;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_a_mux_sel_o     = IMMA_ZERO;
        imm_b_mux_sel_o     = IMMB_U;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
      end

      OPCODE_AUIPC: begin  // Add Upper Immediate to PC
        alu_op_a_mux_sel_o  = OP_A_CURRPC;
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_U;
        alu_operator_o      = ALU_ADD;
        regfile_alu_we      = 1'b1;
      end

      OPCODE_OPIMM: begin // Register-Immediate ALU Operations
        alu_op_b_mux_sel_o  = OP_B_IMM;
        imm_b_mux_sel_o     = IMMB_I;
        regfile_alu_we      = 1'b1;
        rega_used_o         = 1'b1;

        unique case (instr_rdata_i[14:12])
          3'b000: alu_operator_o = ALU_ADD;  // Add Immediate
          3'b010: alu_operator_o = ALU_SLTS; // Set to one if Lower Than Immediate
          3'b011: alu_operator_o = ALU_SLTU; // Set to one if Lower Than Immediate Unsigned
          3'b100: alu_operator_o = ALU_XOR;  // Exclusive Or with Immediate
          3'b110: alu_operator_o = ALU_OR;   // Or with Immediate
          3'b111: alu_operator_o = ALU_AND;  // And with Immediate

          3'b001: begin
            alu_operator_o = ALU_SLL;  // Shift Left Logical by Immediate
            if (instr_rdata_i[31:25] != 7'b0)
              illegal_insn_o = 1'b1;
          end

          3'b101: begin
            if (instr_rdata_i[31:25] == 7'b0)
              alu_operator_o = ALU_SRL;  // Shift Right Logical by Immediate
            else if (instr_rdata_i[31:25] == 7'b010_0000)
              alu_operator_o = ALU_SRA;  // Shift Right Arithmetically by Immediate
            else
              illegal_insn_o = 1'b1;
          end


        endcase
      end

      OPCODE_OP: begin

        // PREFIX 11
        if (instr_rdata_i[31:30] == 2'b11) begin
          illegal_insn_o = 1'b1;

        // PREFIX 10
        end else if (instr_rdata_i[31:30] == 2'b10) begin
          if (instr_rdata_i[29:25] == 5'b00000) begin
            illegal_insn_o = 1'b1;

          ///////////////////////
          // VECTORIAL FLOAT OPS
          ///////////////////////
          end else begin
            // Vectorial FP
            if (FPU == 1 && C_XFVEC == 1) begin

              // using APU instead of ALU
              alu_en           = 1'b0;
              apu_en           = 1'b1;
              // by default, set all registers to FP registers and use 2
              rega_used_o      = 1'b1;
              regb_used_o      = 1'b1;
              if (ZFINX == 0) begin
                reg_fp_a_o     = 1'b1;
                reg_fp_b_o     = 1'b1;
                reg_fp_d_o     = 1'b1;
              end else begin
                reg_fp_a_o     = 1'b0;
                reg_fp_b_o     = 1'b0;
                reg_fp_d_o     = 1'b0;
              end
              fpu_vec_op       = 1'b1;
              // replication bit comes from instruction (can change for some ops)
              scalar_replication_o = instr_rdata_i[14];
              // by default we need to verify rm is legal but assume it is for now
              check_fprm       = 1'b1;
              fp_rnd_mode_o    = frm_i; // all vectorial ops have rm from fcsr

              // Decode Formats
              unique case (instr_rdata_i[13:12])
                // FP32
                2'b00: begin
                  fpu_dst_fmt_o  = cv32e40p_fpu_pkg::FP32;
                  alu_vec_mode_o = VEC_MODE32;
                end
                // FP16ALT
                2'b01: begin
                  fpu_dst_fmt_o  = cv32e40p_fpu_pkg::FP16ALT;
                  alu_vec_mode_o = VEC_MODE16;
                end
                // FP16
                2'b10: begin
                  fpu_dst_fmt_o  = cv32e40p_fpu_pkg::FP16;
                  alu_vec_mode_o = VEC_MODE16;
                end
                // FP8
                2'b11: begin
                  fpu_dst_fmt_o  = cv32e40p_fpu_pkg::FP8;
                  alu_vec_mode_o = VEC_MODE8;
                end
              endcase

              // By default, src=dst
              fpu_src_fmt_o = fpu_dst_fmt_o;

              // decode vectorial FP instruction
              unique case (instr_rdata_i[29:25]) inside
                // vfadd.vfmt - Vectorial FP Addition
                5'b00001: begin
                  fpu_op      = cv32e40p_fpu_pkg::ADD;
                  fp_op_group = ADDMUL;
                  // FPnew needs addition operands as operand B and C
                  alu_op_b_mux_sel_o     = OP_B_REGA_OR_FWD;
                  alu_op_c_mux_sel_o     = OP_C_REGB_OR_FWD;
                  scalar_replication_o   = 1'b0;
                  scalar_replication_c_o = instr_rdata_i[14];
                end
                // vfsub.vfmt - Vectorial FP Subtraction
                5'b00010: begin
                  fpu_op      = cv32e40p_fpu_pkg::ADD;
                  fpu_op_mod  = 1'b1;
                  fp_op_group = ADDMUL;
                  // FPnew needs addition operands as operand B and C
                  alu_op_b_mux_sel_o     = OP_B_REGA_OR_FWD;
                  alu_op_c_mux_sel_o     = OP_C_REGB_OR_FWD;
                  scalar_replication_o   = 1'b0;
                  scalar_replication_c_o = instr_rdata_i[14];
                end
                // vfmul.vfmt - Vectorial FP Multiplication
                5'b00011: begin
                  fpu_op      = cv32e40p_fpu_pkg::MUL;
                  fp_op_group = ADDMUL;
                end
                // vfdiv.vfmt - Vectorial FP Division
                5'b00100: begin
                  fpu_op      = cv32e40p_fpu_pkg::DIV;
                  fp_op_group = DIVSQRT;
                end
                // vfmin.vfmt - Vectorial FP Minimum
                5'b00101: begin
                  fpu_op        = cv32e40p_fpu_pkg::MINMAX;
                  fp_rnd_mode_o = 3'b000; // min
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0; // instruction encoded in rm
                end
                // vfmax.vfmt - Vectorial FP Maximum
                5'b00110: begin
                  fpu_op        = cv32e40p_fpu_pkg::MINMAX;
                  fp_rnd_mode_o = 3'b001; // max
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0; // instruction encoded in rm
                end
                // vfsqrt.vfmt - Vectorial FP Square Root
                5'b00111: begin
                  regb_used_o = 1'b0;
                  fpu_op      = cv32e40p_fpu_pkg::SQRT;
                  fp_op_group = DIVSQRT;
                  // rs2 and R must be zero
                  if ((instr_rdata_i[24:20] != 5'b00000) || instr_rdata_i[14]) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                // vfmac.vfmt - Vectorial FP Multiply-Accumulate
                5'b01000: begin
                  regc_used_o = 1'b1;
                  regc_mux_o  = REGC_RD; // third operand is rd
                  if (ZFINX == 0) begin
                    reg_fp_c_o = 1'b1;
                  end else begin
                    reg_fp_c_o = 1'b0;
                  end
                  fpu_op      = cv32e40p_fpu_pkg::FMADD;
                  fp_op_group = ADDMUL;
                end
                // vfmre.vfmt - Vectorial FP Multiply-Reduce
                5'b01001: begin
                  regc_used_o = 1'b1;
                  regc_mux_o  = REGC_RD; // third operand is rd
                  if (ZFINX == 0) begin
                    reg_fp_c_o = 1'b1;
                  end else begin
                    reg_fp_c_o = 1'b0;
                  end
                  fpu_op      = cv32e40p_fpu_pkg::FMADD;
                  fpu_op_mod  = 1'b1;
                  fp_op_group = ADDMUL;
                end
                // Moves, Conversions, Classifications
                5'b01100: begin
                  regb_used_o          = 1'b0;
                  scalar_replication_o = 1'b0;
                  // Decode Operation in rs2
                  unique case (instr_rdata_i[24:20]) inside
                    // vfmv.{x.vfmt/vfmt.x} - Vectorial FP Reg <-> GP Reg Moves
                    5'b00000: begin
                      alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD; // set rs2 = rs1 so we can map FMV to SGNJ in the unit
                      fpu_op             = cv32e40p_fpu_pkg::SGNJ;
                      fp_rnd_mode_o      = 3'b011;  // passthrough without checking nan-box
                      fp_op_group        = NONCOMP;
                      check_fprm         = 1'b0;
                      // GP reg to FP reg
                      if (instr_rdata_i[14]) begin
                        reg_fp_a_o       = 1'b0; // go from integer regfile
                        fpu_op_mod       = 1'b0; // nan-box result
                      end
                      // FP reg to GP reg
                      else begin
                        reg_fp_d_o       = 1'b0; // go to integer regfile
                        fpu_op_mod       = 1'b1; // sign-extend result
                      end
                    end
                    // vfclass.vfmt - Vectorial FP Classifications
                    5'b00001: begin
                      reg_fp_d_o    = 1'b0; // go to integer regfile
                      fpu_op        = cv32e40p_fpu_pkg::CLASSIFY;
                      fp_rnd_mode_o = 3'b000;
                      fp_op_group   = NONCOMP;
                      check_fprm    = 1'b0;
                      // R must not be set
                      if (instr_rdata_i[14]) illegal_insn_o = 1'b1;
                    end
                    // vfcvt.{x.vfmt/vfmt.x} - Vectorial FP <-> Int Conversions
                    5'b0001?: begin
                      fp_op_group = CONV;
                      fpu_op_mod  = instr_rdata_i[14]; // signed/unsigned switch
                      // Integer width matches FP width
                      unique case (instr_rdata_i[13:12])
                        // FP32
                        2'b00 : fpu_int_fmt_o = cv32e40p_fpu_pkg::INT32;
                        // FP16[ALT]
                        2'b01,
                        2'b10: fpu_int_fmt_o = cv32e40p_fpu_pkg::INT16;
                        // FP8
                        2'b11: fpu_int_fmt_o = cv32e40p_fpu_pkg::INT8;
                      endcase
                      // Int to FP conversion
                      if (instr_rdata_i[20]) begin
                        reg_fp_a_o = 1'b0; // go from integer regfile
                        fpu_op     = cv32e40p_fpu_pkg::I2F;
                      end
                      // FP to Int conversion
                      else begin
                        reg_fp_d_o = 1'b0; // go to integer regfile
                        fpu_op     = cv32e40p_fpu_pkg::F2I;
                      end
                    end
                    // vfcvt.vfmt.vfmt - Vectorial FP <-> FP Conversions
                    5'b001??: begin
                      fpu_op      = cv32e40p_fpu_pkg::F2F;
                      fp_op_group = CONV;
                      // check source format
                      unique case (instr_rdata_i[21:20])
                        // Only process instruction if corresponding extension is active (static)
                        2'b00: begin
                          fpu_src_fmt_o = cv32e40p_fpu_pkg::FP32;
                          if (~C_RVF) illegal_insn_o = 1'b1;
                        end
                        2'b01: begin
                          fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                          if (~C_XF16ALT) illegal_insn_o = 1'b1;
                        end
                        2'b10: begin
                          fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16;
                          if (~C_XF16) illegal_insn_o = 1'b1;
                        end
                        2'b11: begin
                          fpu_src_fmt_o = cv32e40p_fpu_pkg::FP8;
                          if (~C_XF8) illegal_insn_o = 1'b1;
                        end
                      endcase
                      // R must not be set
                      if (instr_rdata_i[14]) illegal_insn_o = 1'b1;
                    end
                    // others
                    default : illegal_insn_o = 1'b1;
                  endcase
                end
                // vfsgnj.vfmt - Vectorial FP Sign Injection
                5'b01101: begin
                  fpu_op        = cv32e40p_fpu_pkg::SGNJ;
                  fp_rnd_mode_o = 3'b000; // sgnj
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfsgnjn.vfmt - Vectorial FP Negated Sign Injection
                5'b01110: begin
                  fpu_op        = cv32e40p_fpu_pkg::SGNJ;
                  fp_rnd_mode_o = 3'b001; // sgnjn
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfsgnjx.vfmt - Vectorial FP Xored Sign Injection
                5'b01111: begin
                  fpu_op        = cv32e40p_fpu_pkg::SGNJ;
                  fp_rnd_mode_o = 3'b010; // sgnjx
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfeq.vfmt - Vectorial FP Equals
                5'b10000: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fp_rnd_mode_o = 3'b010; // eq
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfne.vfmt - Vectorial FP Not Equals
                5'b10001: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fpu_op_mod    = 1'b1; // invert output
                  fp_rnd_mode_o = 3'b010; // eq
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vflt.vfmt - Vectorial FP Less Than
                5'b10010: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fp_rnd_mode_o = 3'b001; // lt
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfge.vfmt - Vectorial FP Greater Than or Equals
                5'b10011: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fpu_op_mod    = 1'b1; // invert output
                  fp_rnd_mode_o = 3'b001; // lt
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfle.vfmt - Vectorial FP Less Than or Equals
                5'b10100: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fp_rnd_mode_o = 3'b000; // le
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfgt.vfmt - Vectorial FP Greater Than
                5'b10101: begin
                  reg_fp_d_o    = 1'b0; // go to integer regfile
                  fpu_op        = cv32e40p_fpu_pkg::CMP;
                  fpu_op_mod    = 1'b1; // invert output
                  fp_rnd_mode_o = 3'b000; // le
                  fp_op_group   = NONCOMP;
                  check_fprm    = 1'b0;
                end
                // vfcpk{a-d}.vfmt.s/d
                5'b110??: begin
                  // vfcpk{{a/c}/{b/d}} selection in R bit
                  fpu_op_mod           = instr_rdata_i[14];
                  fp_op_group          = CONV;
                  scalar_replication_o = 1'b0;

                  if (instr_rdata_i[25]) fpu_op = cv32e40p_fpu_pkg::CPKCD; // vfcpk{c/d}
                  else fpu_op = cv32e40p_fpu_pkg::CPKAB; // vfcpk{a/b}

                  // vfcpk{a-d}.vfmt.d - from double
                  if (instr_rdata_i[26]) begin
                    fpu_src_fmt_o  = cv32e40p_fpu_pkg::FP64;
                    if (~C_RVD) illegal_insn_o = 1'b1;
                  end
                  // vfcpk{a-d}.vfmt.s
                  else begin
                    fpu_src_fmt_o  = cv32e40p_fpu_pkg::FP32;
                    if (~C_RVF) illegal_insn_o = 1'b1;
                  end
                  // Resolve legal vfcpk / format combinations (mostly static)
                  if (fpu_op == cv32e40p_fpu_pkg::CPKCD) begin // vfcpk{c/d} not possible unless FP8 and FLEN>=64
                    if (~C_XF8 || ~C_RVD) illegal_insn_o = 1'b1;
                  end else begin
                    if (instr_rdata_i[14]) begin // vfcpkb
                      // vfcpkb not possible for FP32
                      if (fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP32) illegal_insn_o = 1'b1;
                      // vfcpkb not possible for FP16[ALT] if not RVD
                      if (~C_RVD && (fpu_dst_fmt_o != cv32e40p_fpu_pkg::FP8)) illegal_insn_o = 1'b1;
                    end
                  end
                end
                // Rest are illegal instructions
                default: begin
                  illegal_insn_o = 1'b1;
                end
              endcase

              // check enabled formats (static)
              // need RVD for F vectors
              if ((~C_RVF || ~C_RVD) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP32) illegal_insn_o = 1'b1;
              // need RVF for F16 vectors
              if ((~C_XF16 || ~C_RVF) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16) illegal_insn_o = 1'b1;
              // need RVF for F16 vectors
              if ((~C_XF16ALT || ~C_RVF) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16ALT) begin
                illegal_insn_o = 1'b1;
              end
              // need F16 for F8 vectors
              if ((~C_XF8 || (~C_XF16 && ~C_XF16ALT)) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP8) begin
                illegal_insn_o = 1'b1;
              end

              // check rounding mode
              if (check_fprm) begin
                unique case (frm_i) inside
                  [3'b000:3'b100] : ; //legal rounding modes
                  default         : illegal_insn_o = 1'b1;
                endcase
              end

              // Set latencies for FPnew from config. The C_LAT constants contain the number
              // of pipeline registers. the APU takes the following values:
              // 1 = single cycle (no latency), 2 = one pipestage, 3 = two or more pipestages
              case (fp_op_group)
                // ADDMUL has format dependent latency
                ADDMUL : begin
                  unique case (fpu_dst_fmt_o)
                    cv32e40p_fpu_pkg::FP32    : apu_lat_o = (FPU_ADDMUL_LAT<2)? FPU_ADDMUL_LAT+1: 2'h3;
                    cv32e40p_fpu_pkg::FP16    : apu_lat_o = (C_LAT_FP16<2)    ? C_LAT_FP16+1    : 2'h3;
                    cv32e40p_fpu_pkg::FP16ALT : apu_lat_o = (C_LAT_FP16ALT<2) ? C_LAT_FP16ALT+1 : 2'h3;
                    cv32e40p_fpu_pkg::FP8     : apu_lat_o = (C_LAT_FP8<2)     ? C_LAT_FP8+1     : 2'h3;
                    default : ;
                  endcase
                end
                // DIVSQRT is iterative and takes more than 2 cycles
                DIVSQRT : apu_lat_o = 2'h3;
                // NONCOMP uses the same latency for all formats
                NONCOMP : apu_lat_o = (FPU_OTHERS_LAT<2) ? FPU_OTHERS_LAT+1 : 2'h3;
                // CONV uses the same latency for all formats
                CONV    : apu_lat_o = (FPU_OTHERS_LAT<2) ? FPU_OTHERS_LAT+1 : 2'h3;
              endcase

              // Set FPnew OP and OPMOD as the APU op
              apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};

            // no FPU or FPU and no Vectors
            end else begin
              illegal_insn_o = 1'b1;
            end
          end // Vectorial Float Ops

        end  // PREFIX 10

        // PREFIX 00/01
        else begin
          regfile_alu_we = 1'b1;
          rega_used_o    = 1'b1;

          if (~instr_rdata_i[28]) regb_used_o = 1'b1;

          unique case ({instr_rdata_i[30:25], instr_rdata_i[14:12]})
            // RV32I ALU operations
            {6'b00_0000, 3'b000}: alu_operator_o = ALU_ADD;   // Add
            {6'b10_0000, 3'b000}: alu_operator_o = ALU_SUB;   // Sub
            {6'b00_0000, 3'b010}: alu_operator_o = ALU_SLTS;  // Set Lower Than
            {6'b00_0000, 3'b011}: alu_operator_o = ALU_SLTU;  // Set Lower Than Unsigned
            {6'b00_0000, 3'b100}: alu_operator_o = ALU_XOR;   // Xor
            {6'b00_0000, 3'b110}: alu_operator_o = ALU_OR;    // Or
            {6'b00_0000, 3'b111}: alu_operator_o = ALU_AND;   // And
            {6'b00_0000, 3'b001}: alu_operator_o = ALU_SLL;   // Shift Left Logical
            {6'b00_0000, 3'b101}: alu_operator_o = ALU_SRL;   // Shift Right Logical
            {6'b10_0000, 3'b101}: alu_operator_o = ALU_SRA;   // Shift Right Arithmetic

            // supported RV32M instructions
            {6'b00_0001, 3'b000}: begin // mul
              alu_en          = 1'b0;
              mult_int_en     = 1'b1;
              mult_operator_o = MUL_MAC32;
              regc_mux_o      = REGC_ZERO;
            end
            {6'b00_0001, 3'b001}: begin // mulh
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b11;
              mult_operator_o    = MUL_H;
            end
            {6'b00_0001, 3'b010}: begin // mulhsu
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b01;
              mult_operator_o    = MUL_H;
            end
            {6'b00_0001, 3'b011}: begin // mulhu
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b00;
              mult_operator_o    = MUL_H;
            end
            {6'b00_0001, 3'b100}: begin // div
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_DIV;
            end
            {6'b00_0001, 3'b101}: begin // divu
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_DIVU;
            end
            {6'b00_0001, 3'b110}: begin // rem
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_REM;
            end
            {6'b00_0001, 3'b111}: begin // remu
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_REMU;
            end

            default: begin
              illegal_insn_o = 1'b1;
            end
          endcase
        end
      end

      ////////////////////////////
      //  ______ _____  _    _  //
      // |  ____|  __ \| |  | | //
      // | |__  | |__) | |  | | //
      // |  __| |  ___/| |  | | //
      // | |    | |    | |__| | //
      // |_|    |_|     \____/  //
      //                        //
      ////////////////////////////

      // Floating Point arithmetic
      OPCODE_OP_FP: begin
        if (FPU == 1 && (ZFINX == 1 || fs_off_i == 1'b0)) begin

          // using APU instead of ALU
          alu_en           = 1'b0;
          apu_en           = 1'b1;
          // by default, set all registers to FP registers and use 2
          rega_used_o      = 1'b1;
          regb_used_o      = 1'b1;
          if (ZFINX == 0) begin
            reg_fp_a_o     = 1'b1;
            reg_fp_b_o     = 1'b1;
            reg_fp_d_o     = 1'b1;
          end else begin
            reg_fp_a_o     = 1'b0;
            reg_fp_b_o     = 1'b0;
            reg_fp_d_o     = 1'b0;
          end
          // by default we need to verify rm is legal but assume it is for now
          check_fprm       = 1'b1;
          fp_rnd_mode_o    = instr_rdata_i[14:12];

          // Decode Formats (preliminary, can change for some ops)
          unique case (instr_rdata_i[26:25])
            // FP32
            2'b00: fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP32;
            // FP64
            2'b01: fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP64;
            // FP16 or FP16ALT
            2'b10: begin
              // FP16alt encoded in rm field
              if (instr_rdata_i[14:12] == 3'b101) fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
              // this can still change to FP16ALT
              else fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16;
            end
            // FP8
            2'b11: fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP8;
          endcase

          // By default, src=dst
          fpu_src_fmt_o = fpu_dst_fmt_o;

          // decode FP instruction
          unique case (instr_rdata_i[31:27])
            // fadd.fmt - FP Addition
            5'b00000: begin
              fpu_op             = cv32e40p_fpu_pkg::ADD;
              fp_op_group        = ADDMUL;
              apu_op_o           = 2'b0;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
            end
            // fsub.fmt - FP Subtraction
            5'b00001: begin
              fpu_op             = cv32e40p_fpu_pkg::ADD;
              fpu_op_mod         = 1'b1;
              fp_op_group        = ADDMUL;
              apu_op_o           = 2'b1;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
            end
            // fmul.fmt - FP Multiplication
            5'b00010: begin
              fpu_op      = cv32e40p_fpu_pkg::MUL;
              fp_op_group = ADDMUL;
            end
            // fdiv.fmt - FP Division
            5'b00011: begin
              fpu_op      = cv32e40p_fpu_pkg::DIV;
              fp_op_group = DIVSQRT;
            end
            // fsqrt.fmt - FP Square Root
            5'b01011: begin
              regb_used_o = 1'b0;
              fpu_op      = cv32e40p_fpu_pkg::SQRT;
              fp_op_group = DIVSQRT;
              apu_op_o    = 1'b1;
              // rs2 must be zero
              if (instr_rdata_i[24:20] != 5'b00000) illegal_insn_o = 1'b1;
            end
            // fsgn{j[n]/jx}.fmt - FP Sign Injection
            5'b00100: begin
              fpu_op        = cv32e40p_fpu_pkg::SGNJ;
              fp_op_group   = NONCOMP;
              check_fprm    = 1'b0; // instruction encoded in rm, do the check here
              if (C_XF16ALT) begin  // FP16ALT instructions encoded in rm separately (static)
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b010], [3'b100:3'b110]})) begin
                  illegal_insn_o = 1'b1;
                end
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b010]})) illegal_insn_o = 1'b1;
              end
            end
            // fmin/fmax.fmt - FP Minimum / Maximum
            5'b00101: begin
              fpu_op        = cv32e40p_fpu_pkg::MINMAX;
              fp_op_group   = NONCOMP;
              check_fprm    = 1'b0; // instruction encoded in rm, do the check here
              if (C_XF16ALT) begin  // FP16ALT instructions encoded in rm separately (static)
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b001], [3'b100:3'b101]})) begin
                  illegal_insn_o = 1'b1;
                end
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b001]})) illegal_insn_o = 1'b1;
              end
            end
            // fcvt.fmt.fmt - FP to FP Conversion
            5'b01000: begin
              regb_used_o   = 1'b0;
              fpu_op        = cv32e40p_fpu_pkg::F2F;
              fp_op_group   = CONV;
              // bits [22:20] used, other bits must be 0
              if (instr_rdata_i[24:23]) illegal_insn_o = 1'b1;
              // check source format
              unique case (instr_rdata_i[22:20])
                // Only process instruction if corresponding extension is active (static)
                3'b000: begin
                  if (!(C_RVF && (C_XF16 || C_XF16ALT || C_XF8))) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP32;
                end
                3'b001: begin
                  if (~C_RVD) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP64;
                end
                3'b010: begin
                  if (~C_XF16) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16;
                end
                3'b110: begin
                  if (~C_XF16ALT) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end
                3'b011: begin
                  if (~C_XF8) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP8;
                end
                default: illegal_insn_o = 1'b1;
              endcase
            end
            // fmulex.s.fmt - FP Expanding Multiplication to FP32
            5'b01001: begin
              if (~C_XF16 && ~C_XF16ALT && ~C_XF8) illegal_insn_o = 1;
              fpu_op        = cv32e40p_fpu_pkg::MUL;
              fp_op_group   = ADDMUL;
              // set dst format to FP32
              fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP32;
            end
            // fmacex.s.fmt - FP Expanding Multipy-Accumulate to FP32
            5'b01010: begin
              if (~C_XF16 && ~C_XF16ALT && ~C_XF8) illegal_insn_o = 1;
              regc_used_o = 1'b1;
              regc_mux_o  = REGC_RD; // third operand is rd
              if (ZFINX == 0) begin
                reg_fp_c_o = 1'b1;
              end else begin
                reg_fp_c_o = 1'b0;
              end
              fpu_op      = cv32e40p_fpu_pkg::FMADD;
              fp_op_group = ADDMUL;
              // set dst format to FP32
              fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP32;
            end
            // feq/flt/fle.fmt - FP Comparisons
            5'b10100: begin
              fpu_op        = cv32e40p_fpu_pkg::CMP;
              fp_op_group   = NONCOMP;
              reg_fp_d_o    = 1'b0; // go to integer regfile
              check_fprm    = 1'b0; // instruction encoded in rm, do the check here
              if (C_XF16ALT) begin  // FP16ALT instructions encoded in rm separately (static)
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b010], [3'b100:3'b110]})) begin
                  illegal_insn_o = 1'b1;
                end
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000:3'b010]})) illegal_insn_o = 1'b1;
              end
            end
            // fcvt.ifmt.fmt - FP to Int Conversion
            5'b11000: begin
              regb_used_o = 1'b0;
              reg_fp_d_o  = 1'b0; // go to integer regfile
              fpu_op      = cv32e40p_fpu_pkg::F2I;
              fp_op_group = CONV;
              fpu_op_mod  = instr_rdata_i[20]; // signed/unsigned switch
              apu_op_o    = 2'b1;

              unique case (instr_rdata_i[26:25]) //fix for casting to different formats other than FP32
                2'b00: begin
                  if (~C_RVF) illegal_insn_o = 1;
                  else fpu_src_fmt_o = cv32e40p_fpu_pkg::FP32;
                end
                2'b01: begin
                  if (~C_RVD) illegal_insn_o = 1;
                  else fpu_src_fmt_o = cv32e40p_fpu_pkg::FP64;
                end
                2'b10: begin
                  if (instr_rdata_i[14:12] == 3'b101) begin
                    if (~C_XF16ALT) illegal_insn_o = 1;
                    else fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  end else if (~C_XF16) begin
                    illegal_insn_o = 1;
                  end else begin
                    fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16;
                  end
                end
                2'b11: begin
                  if (~C_XF8) illegal_insn_o = 1;
                  else fpu_src_fmt_o = cv32e40p_fpu_pkg::FP8;
                end
              endcase // unique case (instr_rdata_i[26:25])
              // bits [21:20] used, other bits must be 0
              if (instr_rdata_i[24:21]) illegal_insn_o = 1'b1;   // in RV32, no casts to L allowed.
            end
            // fcvt.fmt.ifmt - Int to FP Conversion
            5'b11010: begin
              regb_used_o = 1'b0;
              reg_fp_a_o  = 1'b0; // go from integer regfile
              fpu_op      = cv32e40p_fpu_pkg::I2F;
              fp_op_group = CONV;
              fpu_op_mod  = instr_rdata_i[20]; // signed/unsigned switch
              apu_op_o    = 2'b0;
              // bits [21:20] used, other bits must be 0
              if (instr_rdata_i[24:21]) illegal_insn_o = 1'b1;   // in RV32, no casts to L allowed.
            end
            // move and class
            5'b11100: begin
              regb_used_o = 1'b0;
              reg_fp_d_o  = 1'b0; // go to integer regfile
              fp_op_group = NONCOMP;
              check_fprm  = 1'b0; // instruction encoded in rm, do the check here
              // fmv.x.fmt - FPR to GPR Move
              if ((ZFINX == 0 && instr_rdata_i[14:12] == 3'b000) || (C_XF16ALT && instr_rdata_i[14:12] == 3'b100)) begin
                alu_op_b_mux_sel_o  = OP_B_REGA_OR_FWD; // set rs2 = rs1 so we can map FMV to SGNJ in the unit
                fpu_op              = cv32e40p_fpu_pkg::SGNJ; // mapped to SGNJ-passthrough since no recoding
                fpu_op_mod          = 1'b1;    // sign-extend result
                fp_rnd_mode_o       = 3'b011;  // passthrough without checking nan-box
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end
              // fclass.fmt - FP Classify
              end else if (instr_rdata_i[14:12] == 3'b001 || (C_XF16ALT && instr_rdata_i[14:12] == 3'b101)) begin
                fpu_op        = cv32e40p_fpu_pkg::CLASSIFY;
                fp_rnd_mode_o = 3'b000;
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end
              end else begin
                illegal_insn_o = 1'b1;
              end
              // rs2 must be zero
              if (instr_rdata_i[24:20]) illegal_insn_o = 1'b1;
            end
            // fmv.fmt.x - GPR to FPR Move
            5'b11110: begin
              regb_used_o         = 1'b0;
              reg_fp_a_o          = 1'b0; // go from integer regfile
              alu_op_b_mux_sel_o  = OP_B_REGA_OR_FWD; // set rs2 = rs1 so we can map FMV to SGNJ in the unit
              fpu_op              = cv32e40p_fpu_pkg::SGNJ; // mapped to SGNJ-passthrough since no recoding
              fpu_op_mod          = 1'b0;    // nan-box result
              fp_op_group         = NONCOMP;
              fp_rnd_mode_o       = 3'b011;  // passthrough without checking nan-box
              check_fprm          = 1'b0; // instruction encoded in rm, do the check here
              if ((ZFINX == 0 && instr_rdata_i[14:12] == 3'b000) || (C_XF16ALT && instr_rdata_i[14:12] == 3'b100)) begin
                // FP16ALT uses special encoding here
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
                end
              end else begin
                illegal_insn_o = 1'b1;
              end
              // rs2 must be zero
              if (instr_rdata_i[24:20] != 5'b00000) illegal_insn_o = 1'b1;
            end
            // Rest are illegal instructions
            default: illegal_insn_o = 1'b1;
          endcase

          // check enabled formats (static)
          if (~C_RVF && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP32) illegal_insn_o = 1'b1;
          if ((~C_RVD) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP64) illegal_insn_o = 1'b1;
          if ((~C_XF16) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16) illegal_insn_o = 1'b1;
          if ((~C_XF16ALT) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16ALT) begin
            illegal_insn_o = 1'b1;
          end
          if ((~C_XF8) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP8) illegal_insn_o = 1'b1;

          // check rounding mode
          if (check_fprm) begin
            unique case (instr_rdata_i[14:12]) inside
              [3'b000:3'b100]: ; //legal rounding modes
              3'b101: begin      // Alternative Half-Precsision encded as fmt=10 and rm=101
                if (~C_XF16ALT || fpu_dst_fmt_o != cv32e40p_fpu_pkg::FP16ALT) illegal_insn_o = 1'b1;
                // actual rounding mode from frm csr
                unique case (frm_i) inside
                  [3'b000:3'b100] : fp_rnd_mode_o = frm_i; //legal rounding modes
                  default         : illegal_insn_o = 1'b1;
                endcase
              end
              3'b111: begin
                // rounding mode from frm csr
                unique case (frm_i) inside
                  [3'b000:3'b100] : fp_rnd_mode_o = frm_i; //legal rounding modes
                  default         : illegal_insn_o = 1'b1;
                endcase
              end
              default : illegal_insn_o = 1'b1;
            endcase
          end

          // Set latencies for FPnew from config. The C_LAT constants contain the number
          // of pipeline registers. the APU takes the following values:
          // 1 = single cycle (no latency), 2 = one pipestage, 3 = two or more pipestages
          case (fp_op_group)
            // ADDMUL has format dependent latency
            ADDMUL : begin
              unique case (fpu_dst_fmt_o)
                cv32e40p_fpu_pkg::FP32    : apu_lat_o = (FPU_ADDMUL_LAT<2)? FPU_ADDMUL_LAT+1: 2'h3;
                cv32e40p_fpu_pkg::FP64    : apu_lat_o = (C_LAT_FP64<2)    ? C_LAT_FP64+1    : 2'h3;
                cv32e40p_fpu_pkg::FP16    : apu_lat_o = (C_LAT_FP16<2)    ? C_LAT_FP16+1    : 2'h3;
                cv32e40p_fpu_pkg::FP16ALT : apu_lat_o = (C_LAT_FP16ALT<2) ? C_LAT_FP16ALT+1 : 2'h3;
                cv32e40p_fpu_pkg::FP8     : apu_lat_o = (C_LAT_FP8<2)     ? C_LAT_FP8+1     : 2'h3;
                default : ;
              endcase
            end
            // DIVSQRT is iterative and takes more than 2 cycles
            DIVSQRT : apu_lat_o = 2'h3;
            // NONCOMP uses the same latency for all formats
            NONCOMP : apu_lat_o = (FPU_OTHERS_LAT<2) ? FPU_OTHERS_LAT+1 : 2'h3;
            // CONV uses the same latency for all formats
            CONV    : apu_lat_o = (FPU_OTHERS_LAT<2) ? FPU_OTHERS_LAT+1 : 2'h3;
          endcase

          // Set FPnew OP and OPMOD as the APU op
          apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};

        // No FPU or (ZFINX == 0 && MSTATUS.FS == FS_OFF)
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      // Floating Point fused arithmetic
      OPCODE_OP_FMADD,
      OPCODE_OP_FMSUB,
      OPCODE_OP_FNMSUB,
      OPCODE_OP_FNMADD : begin
        if (FPU == 1 && (ZFINX == 1 || fs_off_i == 1'b0)) begin
          // using APU instead of ALU
          alu_en        = 1'b0;
          apu_en        = 1'b1;
          // all registers are FP registers and use three
          rega_used_o   = 1'b1;
          regb_used_o   = 1'b1;
          regc_used_o   = 1'b1;
          regc_mux_o    = REGC_S4;
          if (ZFINX == 0) begin
            reg_fp_a_o  = 1'b1;
            reg_fp_b_o  = 1'b1;
            reg_fp_c_o  = 1'b1;
            reg_fp_d_o  = 1'b1;
          end else begin
            reg_fp_a_o  = 1'b0;
            reg_fp_b_o  = 1'b0;
            reg_fp_c_o  = 1'b0;
            reg_fp_d_o  = 1'b0;
          end
          fp_rnd_mode_o = instr_rdata_i[14:12];

          // Decode Formats
          unique case (instr_rdata_i[26:25])
            // FP32
            2'b00 : fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP32;
            // FP64
            2'b01 : fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP64;
            // FP16 or FP16ALT
            2'b10 : begin
              // FP16alt encoded in rm field
              if (instr_rdata_i[14:12] == 3'b101) fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16ALT;
              else fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP16;
            end
            // FP8
            2'b11 : fpu_dst_fmt_o = cv32e40p_fpu_pkg::FP8;
          endcase

          // By default, src=dst
          fpu_src_fmt_o = fpu_dst_fmt_o;

          // decode FP intstruction
          unique case (instr_rdata_i[6:0])
            // fmadd.fmt - FP Fused multiply-add
            OPCODE_OP_FMADD : begin
              fpu_op      = cv32e40p_fpu_pkg::FMADD;
              apu_op_o    = 2'b00;
            end
            // fmsub.fmt - FP Fused multiply-subtract
            OPCODE_OP_FMSUB : begin
              fpu_op      = cv32e40p_fpu_pkg::FMADD;
              fpu_op_mod  = 1'b1;
              apu_op_o    = 2'b01;
            end
            // fnmsub.fmt - FP Negated fused multiply-subtract
            OPCODE_OP_FNMSUB : begin
              fpu_op      = cv32e40p_fpu_pkg::FNMSUB;
              apu_op_o    = 2'b10;
            end
            // fnmadd.fmt - FP Negated fused multiply-add
            OPCODE_OP_FNMADD : begin
              fpu_op      = cv32e40p_fpu_pkg::FNMSUB;
              fpu_op_mod  = 1'b1;
              apu_op_o    = 2'b11;
            end
            default : ;
          endcase

          // check enabled formats (static)
          if (~C_RVF && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP32) illegal_insn_o = 1'b1;
          if ((~C_RVD) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP64) illegal_insn_o = 1'b1;
          if ((~C_XF16) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16) illegal_insn_o = 1'b1;
          if ((~C_XF16ALT) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP16ALT) begin
            illegal_insn_o = 1'b1;
          end
          if ((~C_XF8) && fpu_dst_fmt_o == cv32e40p_fpu_pkg::FP8) illegal_insn_o = 1'b1;

          // check rounding mode
          unique case (instr_rdata_i[14:12]) inside
            [3'b000:3'b100]: ; //legal rounding modes
            3'b101: begin      // Alternative Half-Precsision encded as fmt=10 and rm=101
              if (~C_XF16ALT || fpu_dst_fmt_o != cv32e40p_fpu_pkg::FP16ALT) illegal_insn_o = 1'b1;
              // actual rounding mode from frm csr
              unique case (frm_i) inside
                [3'b000:3'b100] : fp_rnd_mode_o = frm_i; //legal rounding modes
                default         : illegal_insn_o = 1'b1;
              endcase
            end
            3'b111: begin
              // rounding mode from frm csr
              unique case (frm_i) inside
                [3'b000:3'b100] : fp_rnd_mode_o = frm_i; //legal rounding modes
                default         : illegal_insn_o = 1'b1;
              endcase
            end
            default : illegal_insn_o = 1'b1;
          endcase

          // Set latencies for FPnew from config. The C_LAT constants contain the number
          // of pipeline registers. the APU takes the following values:
          // 1 = single cycle (no latency), 2 = one pipestage, 3 = two or more pipestages
          // format dependent latency
          unique case (fpu_dst_fmt_o)
            cv32e40p_fpu_pkg::FP32    : apu_lat_o = (FPU_ADDMUL_LAT<2)? FPU_ADDMUL_LAT+1: 2'h3;
            cv32e40p_fpu_pkg::FP64    : apu_lat_o = (C_LAT_FP64<2)    ? C_LAT_FP64+1    : 2'h3;
            cv32e40p_fpu_pkg::FP16    : apu_lat_o = (C_LAT_FP16<2)    ? C_LAT_FP16+1    : 2'h3;
            cv32e40p_fpu_pkg::FP16ALT : apu_lat_o = (C_LAT_FP16ALT<2) ? C_LAT_FP16ALT+1 : 2'h3;
            cv32e40p_fpu_pkg::FP8     : apu_lat_o = (C_LAT_FP8<2)     ? C_LAT_FP8+1     : 2'h3;
            default : ;
          endcase

          // Set FPnew OP and OPMOD as the APU op
          apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
        // No FPU or (ZFINX == 0 && MSTATUS.FS == FS_OFF)
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_STORE_FP: begin
        if (FPU == 1 && ZFINX == 0 && fs_off_i == 1'b0) begin
          data_req            = 1'b1;
          data_we_o           = 1'b1;
          rega_used_o         = 1'b1;
          regb_used_o         = 1'b1;
          alu_operator_o      = ALU_ADD;
          reg_fp_b_o          = 1'b1;

          // offset from immediate
          imm_b_mux_sel_o     = IMMB_S;
          alu_op_b_mux_sel_o  = OP_B_IMM;

          // pass write data through ALU operand c
          alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;

          // Decode data type
          unique case (instr_rdata_i[14:12])
            // fsb - FP8 store
            3'b000 : if (C_XF8) data_type_o = 2'b10;
                     else illegal_insn_o = 1'b1;
            // fsh - FP16 store
            3'b001 : if (C_XF16 | C_XF16ALT) data_type_o = 2'b01;
                     else illegal_insn_o = 1'b1;
            // fsw - FP32 store
            3'b010 : if (C_RVF) data_type_o = 2'b00;
                     else illegal_insn_o = 1'b1;
            // fsd - FP64 store
            3'b011 : if (C_RVD) data_type_o = 2'b00; // 64bit stores unsupported!
                     else illegal_insn_o = 1'b1;
            default: illegal_insn_o = 1'b1;
          endcase

          // sanitize memory bus signals for illegal instr (not sure if needed??)
          if (illegal_insn_o) begin
            data_req       = 1'b0;
            data_we_o      = 1'b0;
          end
        // No FPU or ZFINX or MSTATUS.FS == FS_OFF
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_LOAD_FP: begin
        if (FPU == 1 && ZFINX == 0 && fs_off_i == 1'b0) begin
          data_req            = 1'b1;
          regfile_mem_we      = 1'b1;
          reg_fp_d_o          = 1'b1;
          rega_used_o         = 1'b1;
          alu_operator_o      = ALU_ADD;

          // offset from immediate
          imm_b_mux_sel_o     = IMMB_I;
          alu_op_b_mux_sel_o  = OP_B_IMM;

          // NaN boxing
          data_sign_extension_o = 2'b10;

          // Decode data type
          unique case (instr_rdata_i[14:12])
            // flb - FP8 load
            3'b000 : if (C_XF8) data_type_o = 2'b10;
                     else illegal_insn_o = 1'b1;
            // flh - FP16 load
            3'b001 : if (C_XF16 | C_XF16ALT) data_type_o = 2'b01;
                     else illegal_insn_o = 1'b1;
            // flw - FP32 load
            3'b010 : if (C_RVF) data_type_o = 2'b00;
                     else illegal_insn_o = 1'b1;
            // fld - FP64 load
            3'b011 : if (C_RVD) data_type_o = 2'b00; // 64bit loads unsupported!
                     else illegal_insn_o = 1'b1;
            default: illegal_insn_o = 1'b1;
          endcase
        // No FPU or ZFINX or MSTATUS.FS == FS_OFF
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_CUSTOM_0: begin
        if (COREV_PULP && instr_rdata_i[14:13] != 2'b11) begin // cv.l[bhw][u] and cv.elw
          data_req           = 1'b1;
          regfile_mem_we     = 1'b1;
          rega_used_o        = 1'b1;
          alu_operator_o     = ALU_ADD;
          // offset from immediate
          alu_op_b_mux_sel_o = OP_B_IMM;
          imm_b_mux_sel_o    = IMMB_I;

          // post-increment setup
          if (instr_rdata_i[13:12] != 2'b11) begin
            prepost_useincr_o       = 1'b0;
            regfile_alu_waddr_sel_o = 1'b0;
            regfile_alu_we          = 1'b1;
          end

          // sign/zero extension
          data_sign_extension_o = {1'b0,~instr_rdata_i[14]};

          // load size
          unique case (instr_rdata_i[13:12])
            2'b00  : data_type_o = 2'b10; // LB/LBU
            2'b01  : data_type_o = 2'b01; // LH/LHU
            default: data_type_o = 2'b00; // LW/ELW
          endcase

          // special cv.elw (event load)
          if (instr_rdata_i[13:12] == 2'b11) begin
            if (COREV_CLUSTER) begin
              data_load_event_o = 1'b1;
            end else begin
              // cv.elw only valid for COREV_CLUSTER = 1
              illegal_insn_o    = 1'b1;
            end
          end
        end else if (COREV_PULP) begin   // cv.beqimm and cv.bneimm 
          ctrl_transfer_target_mux_sel_o = JT_COND;
          ctrl_transfer_insn             = BRANCH_COND;
          alu_op_c_mux_sel_o             = OP_C_JT;
          rega_used_o                    = 1'b1;
          // offset from immediate
          alu_op_b_mux_sel_o             = OP_B_IMM;
          imm_b_mux_sel_o                = IMMB_BI;

          if (instr_rdata_i[12] == 1'b0) begin // cv.beqimm
            alu_operator_o      = ALU_EQ;
          end else begin                       // cv.bneimm
            alu_operator_o      = ALU_NE;
          end
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_CUSTOM_1: begin
        if (COREV_PULP) begin
          unique case (instr_rdata_i[14:12])
            3'b000, 3'b001, 3'b010: begin  // Immediate Post-Incremented Store
              data_req                = 1'b1;
              data_we_o               = 1'b1;
              rega_used_o             = 1'b1;
              regb_used_o             = 1'b1;
              alu_operator_o          = ALU_ADD;
              // pass write data through ALU operand c
              alu_op_c_mux_sel_o      = OP_C_REGB_OR_FWD;
              // offset from immediate
              imm_b_mux_sel_o         = IMMB_S;
              alu_op_b_mux_sel_o      = OP_B_IMM;

              // post-increment setup
              prepost_useincr_o       = 1'b0;
              regfile_alu_waddr_sel_o = 1'b0;
              regfile_alu_we          = 1'b1;

              // store size
              unique case (instr_rdata_i[13:12])
                2'b00  : data_type_o = 2'b10; // SB
                2'b01  : data_type_o = 2'b01; // SH
                default: data_type_o = 2'b00; // SW
              endcase
            end

            3'b011 : begin // Plane A
              unique case (instr_rdata_i[31:25])
                7'b0000000, 7'b0000001, 7'b0000010, 7'b0000011,         // Register Post-Incremented          Load
                7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111,         // Register Indexed                   Load
                7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011,         // Register Post-Incremented Unsigned Load
                7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: begin   // Register Indexed          Unsigned Load
                  data_req           = 1'b1;
                  regfile_mem_we     = 1'b1;
                  rega_used_o        = 1'b1;
                  alu_operator_o     = ALU_ADD;
                  // offset from RS2
                  regb_used_o        = 1'b1;
                  alu_op_b_mux_sel_o = OP_B_REGB_OR_FWD;

                  // post-increment setup
                  if (instr_rdata_i[27] == 1'b0) begin
                    prepost_useincr_o       = 1'b0;
                    regfile_alu_waddr_sel_o = 1'b0;
                    regfile_alu_we          = 1'b1;
                  end

                  // sign/zero extension
                  data_sign_extension_o = {1'b0,~instr_rdata_i[28]};

                  // load size
                  unique case ({instr_rdata_i[28],instr_rdata_i[26:25]})
                    3'b000 : data_type_o = 2'b10; // LB
                    3'b001 : data_type_o = 2'b01; // LH
                    3'b010 : data_type_o = 2'b00; // LW
                    3'b100 : data_type_o = 2'b10; // LBU
                    3'b101 : data_type_o = 2'b01; // LHU
                    default: begin
                      illegal_insn_o = 1'b1;
                      data_req       = 1'b0;
                      regfile_mem_we = 1'b0;
                      regfile_alu_we = 1'b0;
                    end
                  endcase
                end

                7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011,         // Register Post-Incremented Store
                7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: begin   // Register Indexed          Store
                  data_req           = 1'b1;
                  data_we_o          = 1'b1;
                  rega_used_o        = 1'b1;
                  regb_used_o        = 1'b1;
                  alu_operator_o     = ALU_ADD;
                  // pass write data through ALU operand c
                  alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
                  // offset from register
                  regc_used_o        = 1'b1;
                  alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                  regc_mux_o         = REGC_RD;

                  // post-increment setup
                  if (instr_rdata_i[27] == 1'b0) begin
                    prepost_useincr_o       = 1'b0;
                    regfile_alu_waddr_sel_o = 1'b0;
                    regfile_alu_we          = 1'b1;
                  end

                  // store size
                  unique case (instr_rdata_i[26:25])
                    2'b00  : data_type_o = 2'b10; // SB
                    2'b01  : data_type_o = 2'b01; // SH
                    2'b10  : data_type_o = 2'b00; // SW
                    default: begin
                      illegal_insn_o = 1'b1;
                      data_req       = 1'b0;
                      data_we_o      = 1'b0;
                      data_type_o    = 2'b00;
                    end
                  endcase
                end

                7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011,
                7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: begin   // Register Bit-Manipulation
                  regfile_alu_we        = 1'b1;
                  rega_used_o           = 1'b1;
                  regb_used_o           = 1'b1;

                  bmask_a_mux_o         = BMASK_A_S3;
                  bmask_b_mux_o         = BMASK_B_S2;
                  alu_op_b_mux_sel_o    = OP_B_IMM;
                  alu_bmask_a_mux_sel_o = BMASK_A_REG;

                  unique case (instr_rdata_i[27:25])
                    3'b000: begin                                      // cv.extractr
                      alu_operator_o        = ALU_BEXT;
                      imm_b_mux_sel_o       = IMMB_S2;
                      bmask_b_mux_o         = BMASK_B_ZERO;
                      alu_op_b_mux_sel_o    = OP_B_BMASK;
                    end
                    3'b001: begin                                      // cv.extractur
                      alu_operator_o        = ALU_BEXTU;
                      imm_b_mux_sel_o       = IMMB_S2;
                      bmask_b_mux_o         = BMASK_B_ZERO;
                      alu_op_b_mux_sel_o    = OP_B_BMASK;
                    end
                    3'b010: begin                                      // cv.insertr
                      alu_operator_o        = ALU_BINS;
                      imm_b_mux_sel_o       = IMMB_S2;
                      regc_used_o           = 1'b1;
                      regc_mux_o            = REGC_RD;
                      alu_op_b_mux_sel_o    = OP_B_BMASK;
                      alu_bmask_b_mux_sel_o = BMASK_B_REG;
                    end
                    3'b100: begin                                      // cv.bclrr
                      alu_operator_o        = ALU_BCLR;
                      alu_bmask_b_mux_sel_o = BMASK_B_REG;
                    end
                    3'b101: begin                                      // cv.bsetr
                      alu_operator_o        = ALU_BSET;
                      alu_bmask_b_mux_sel_o = BMASK_B_REG;
                    end
                    default: illegal_insn_o = 1'b1;
                  endcase
                end

                7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011,
                7'b0100100, 7'b0100101, 7'b0100110, 7'b0100111,
                7'b0101000, 7'b0101001, 7'b0101010, 7'b0101011,
                7'b0101100, 7'b0101101, 7'b0101110, 7'b0101111,
                7'b0110000, 7'b0110001, 7'b0110010, 7'b0110011,
                7'b0110100, 7'b0110101, 7'b0110110, 7'b0110111,
                7'b0111000, 7'b0111001, 7'b0111010, 7'b0111011,
                7'b0111100, 7'b0111101, 7'b0111110, 7'b0111111: begin  // General ALU
                  regfile_alu_we = 1'b1;
                  rega_used_o    = 1'b1;
                  regb_used_o    = 1'b1;

                  unique case (instr_rdata_i[29:25])
                    5'b00000: alu_operator_o = ALU_ROR;                // cv.ror
                    5'b00001: begin                                    // cv.ff1
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_FF1;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b00010: begin                                    // cv.fl1
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_FL1;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b00011: begin                                    // cv.clb
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_CLB;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b00100: begin                                    // cv.cnt
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_CNT;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b01000: begin                                    // cv.abs
                      alu_operator_o = ALU_ABS;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b01001: alu_operator_o = ALU_SLETS;              // cv.slet
                    5'b01010: alu_operator_o = ALU_SLETU;              // cv.sletu
                    5'b01011: alu_operator_o = ALU_MIN;                // cv.min
                    5'b01100: alu_operator_o = ALU_MINU;               // cv.minu
                    5'b01101: alu_operator_o = ALU_MAX;                // cv.max
                    5'b01110: alu_operator_o = ALU_MAXU;               // cv.maxu
                    5'b10000: begin                                    // cv.exths
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_EXTS;
                      alu_vec_mode_o = VEC_MODE16;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b10001: begin                                    // cv.exthz
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_EXT;
                      alu_vec_mode_o = VEC_MODE16;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b10010: begin                                    // cv.extbs
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_EXTS;
                      alu_vec_mode_o = VEC_MODE8;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b10011: begin                                    // cv.extbz
                      regb_used_o    = 1'b0;
                      alu_operator_o = ALU_EXT;
                      alu_vec_mode_o = VEC_MODE8;
                      if (instr_rdata_i[24:20] != 5'b0) begin
                        illegal_insn_o = 1'b1;
                      end
                    end
                    5'b11000: begin                                    // cv.clip
                      regb_used_o        = 1'b0;
                      alu_operator_o     = ALU_CLIP;
                      alu_op_b_mux_sel_o = OP_B_IMM;
                      imm_b_mux_sel_o    = IMMB_CLIP;
                    end
                    5'b11001: begin                                    // cv.clipu
                      regb_used_o        = 1'b0;
                      alu_operator_o     = ALU_CLIPU;
                      alu_op_b_mux_sel_o = OP_B_IMM;
                      imm_b_mux_sel_o    = IMMB_CLIP;
                    end
                    5'b11010: alu_operator_o = ALU_CLIP;               // cv.clipr
                    5'b11011: alu_operator_o = ALU_CLIPU;              // cv.clipur
                    default : illegal_insn_o = 1'b1;
                  endcase
                end

                7'b1000000, 7'b1000001, 7'b1000010, 7'b1000011,
                7'b1000100, 7'b1000101, 7'b1000110, 7'b1000111: begin  // Add/Sub with Normalization and Rounding
                  regfile_alu_we        = 1'b1;
                  rega_used_o           = 1'b1;
                  regb_used_o           = 1'b1;
                  regc_used_o           = 1'b1;
                  regc_mux_o            = REGC_RD;
                  bmask_a_mux_o         = BMASK_A_ZERO;
                  bmask_b_mux_o         = BMASK_B_S3;
                  alu_bmask_b_mux_sel_o = BMASK_B_REG;
                  alu_op_a_mux_sel_o    = OP_A_REGC_OR_FWD;
                  alu_op_b_mux_sel_o    = OP_B_REGA_OR_FWD;

                  unique case (instr_rdata_i[27:25])
                    3'b000: alu_operator_o = ALU_ADD;                  // cv.addNr
                    3'b001: alu_operator_o = ALU_ADDU;                 // cv.adduNr
                    3'b010: alu_operator_o = ALU_ADDR;                 // cv.addRNr
                    3'b011: alu_operator_o = ALU_ADDUR;                // cv.adduRNr
                    3'b100: alu_operator_o = ALU_SUB;                  // cv.subNr
                    3'b101: alu_operator_o = ALU_SUBU;                 // cv.subuNr
                    3'b110: alu_operator_o = ALU_SUBR;                 // cv.subRNr
                    3'b111: alu_operator_o = ALU_SUBUR;                // cv.subuRNr
                    default: alu_operator_o = ALU_ADD;
                  endcase
                end

                7'b1001000, 7'b1001001: begin
                  alu_en          = 1'b0;
                  mult_int_en     = 1'b1;
                  regfile_alu_we  = 1'b1;
                  rega_used_o     = 1'b1;
                  regb_used_o     = 1'b1;
                  regc_used_o     = 1'b1;
                  regc_mux_o      = REGC_RD;

                  if (instr_rdata_i[25] == 1'b0) begin
                    mult_operator_o = MUL_MAC32;                       // cv.mac
                  end else begin
                    mult_operator_o = MUL_MSU32;                       // cv.msu
                  end
                end

                default: illegal_insn_o = 1'b1;
              endcase
            end // Plane A

            ///////////////////////////////////////////////
            //  _   ___        ___     ___   ___  ____   //
            // | | | \ \      / / |   / _ \ / _ \|  _ \  //
            // | |_| |\ \ /\ / /| |  | | | | | | | |_) | //
            // |  _  | \ V  V / | |__| |_| | |_| |  __/  //
            // |_| |_|  \_/\_/  |_____\___/ \___/|_|     //
            //                                           //
            ///////////////////////////////////////////////
            3'b100 : begin // Plane B
              hwlp_target_mux_sel_o = 2'b0;

              unique case (instr_rdata_i[11:8])
                4'b0000: begin
                  // lp.starti: set start address to PC + I-type immediate
                  hwlp_we[0]           = 1'b1;
                  hwlp_start_mux_sel_o = 2'b0;
                  if (instr_rdata_i[19:15] != 5'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0001: begin
                  // lp.start: set start address to rs1 content
                  hwlp_we[0]           = 1'b1;
                  hwlp_start_mux_sel_o = 2'b10;
                  rega_used_o          = 1'b1;
                  if (instr_rdata_i[31:20] != 12'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0010: begin
                  // lp.endi: set end address to PC + I-type immediate - 4
                  hwlp_we[1] = 1'b1;
                  if (instr_rdata_i[19:15] != 5'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0011: begin
                  // lp.end: set end address to (rs1 - 4) content
                  hwlp_we[1]            = 1'b1;
                  hwlp_target_mux_sel_o = 2'b10;
                  rega_used_o           = 1'b1;
                  if (instr_rdata_i[31:20] != 12'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0100: begin
                  // lp.counti: initialize counter from I-type immediate
                  hwlp_we[2]         = 1'b1;
                  hwlp_cnt_mux_sel_o = 1'b0;
                  if (instr_rdata_i[19:15] != 5'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0101: begin
                  // lp.count: initialize counter from rs1
                  hwlp_we[2]         = 1'b1;
                  hwlp_cnt_mux_sel_o = 1'b1;
                  rega_used_o        = 1'b1;
                  if (instr_rdata_i[31:20] != 12'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                4'b0110: begin
                  // lp.setupi: initialize counter from immediate, set start address to
                  // next instruction and end address to PC + I-type immediate - 4
                  hwlp_we               = 3'b111;
                  hwlp_target_mux_sel_o = 2'b01;
                  hwlp_start_mux_sel_o  = 2'b01;
                  hwlp_cnt_mux_sel_o    = 1'b0;
                end
                4'b0111: begin
                  // lp.setup: initialize counter from rs1, set start address to
                  // next instruction and end address to PC + I-type immediate - 4
                  hwlp_we              = 3'b111;
                  hwlp_start_mux_sel_o = 2'b01;
                  hwlp_cnt_mux_sel_o   = 1'b1;
                  rega_used_o          = 1'b1;
                end
                default: begin
                  illegal_insn_o = 1'b1;
                end
              endcase
            end // Plane B

            default: illegal_insn_o = 1'b1;
          endcase

        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_CUSTOM_2: begin  // PULP specific ALU instructions with two source operands and one immediate
        if (COREV_PULP) begin
          regfile_alu_we = 1'b1;
          rega_used_o    = 1'b1;
          regb_used_o    = 1'b1;

          unique case (instr_rdata_i[14:13])
            2'b00: begin
              // Bit Manipulation instructions
              regb_used_o         = 1'b0;
              bmask_a_mux_o       = BMASK_A_S3;
              bmask_b_mux_o       = BMASK_B_S2;
              alu_op_b_mux_sel_o  = OP_B_IMM;
     
              unique case ({instr_rdata_i[31:30], instr_rdata_i[12]})
                {2'b00, 1'b0}: begin                                       // cv.extract
                  alu_operator_o  = ALU_BEXT;
                  imm_b_mux_sel_o = IMMB_S2;
                  bmask_b_mux_o   = BMASK_B_ZERO;
                end
                {2'b01, 1'b0}: begin                                       // cv.extractu
                  alu_operator_o  = ALU_BEXTU;
                  imm_b_mux_sel_o = IMMB_S2;
                  bmask_b_mux_o   = BMASK_B_ZERO;
                end
                {2'b10, 1'b0}: begin                                       // cv.insert
                  alu_operator_o  = ALU_BINS;
                  imm_b_mux_sel_o = IMMB_S2;
                  regc_used_o     = 1'b1;
                  regc_mux_o      = REGC_RD;
                end
                {2'b00, 1'b1}: begin                                       // cv.bclr
                  alu_operator_o = ALU_BCLR;
                end
                {2'b01, 1'b1}: begin                                       // cv.bset
                  alu_operator_o = ALU_BSET;
                end
                {2'b11, 1'b1}: begin                                       // cv.bitrev
                  alu_operator_o        = ALU_BREV;
                  // Enable write back to RD
                  regc_used_o           = 1'b1;
                  regc_mux_o            = REGC_RD;
                  // Extract the source register on operand a
                  imm_b_mux_sel_o       = IMMB_S2;
                  // Map the radix to bmask_a immediate
                  alu_bmask_a_mux_sel_o = BMASK_A_IMM;
                  if (instr_rdata_i[29:27] != 3'b0) begin
                    illegal_insn_o = 1'b1;
                  end
                end
                default: illegal_insn_o = 1'b1;
              endcase
            end

            2'b01: begin
              // ADD/SUB with normalization and rounding
              bmask_a_mux_o  = BMASK_A_ZERO;
              bmask_b_mux_o  = BMASK_B_S3;

              // decide between using unsigned and rounding, and combinations
              unique case ({instr_rdata_i[31:30], instr_rdata_i[12]})
                {2'b00, 1'b0}: alu_operator_o = ALU_ADD;                   // cv.addN
                {2'b01, 1'b0}: alu_operator_o = ALU_ADDU;                  // cv.adduN
                {2'b10, 1'b0}: alu_operator_o = ALU_ADDR;                  // cv.addRN
                {2'b11, 1'b0}: alu_operator_o = ALU_ADDUR;                 // cv.adduRN
                {2'b00, 1'b1}: alu_operator_o = ALU_SUB;                   // cv.subN
                {2'b01, 1'b1}: alu_operator_o = ALU_SUBU;                  // cv.subuN
                {2'b10, 1'b1}: alu_operator_o = ALU_SUBR;                  // cv.subRN
                {2'b11, 1'b1}: alu_operator_o = ALU_SUBUR;                 // cv.subuRN
                default      : alu_operator_o = ALU_ADD;
              endcase

            end

            2'b10, 2'b11: begin
              // MUL/MAC with subword selection
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;

              mult_imm_mux_o     = MIMM_S3;
              mult_sel_subword_o = instr_rdata_i[30];                      // cv.mulhhsN, cv.mulhhsRN, cv.mulhhuN, cv.mulhhuRN
                                                                           // cv.machhsN, cv.machhsRN, cv.machhuN, cv.machhuRN
              mult_signed_mode_o = {2{~instr_rdata_i[12]}};                // cv.mulsN,   cv.mulhhsN,  cv.mulsRN,  cv.mulhhsRN
                                                                           // cv.macsN,   cv.machhsN,  cv.macsRN,  cv.machhsRN

              if (instr_rdata_i[13]) begin                                 // cv.macsN,   cv.machhsN,  cv.macsRN,  cv.machhsRN
                                                                           // cv.macuN,   cv.machhuN,  cv.macuRN,  cv.machhuRN
                regc_used_o = 1'b1;
                regc_mux_o  = REGC_RD;
              end else begin                                               // cv.mulsN,   cv.mulhhsN,  cv.mulsRN,  cv.mulhhsRN
                                                                           // cv.muluN,   cv.mulhhuN,  cv.muluRN,  cv.mulhhuRN
                regc_mux_o  = REGC_ZERO;
              end

              if (instr_rdata_i[31]) begin                                 // cv.mulsRN,  cv.mulhhsRN, cv.muluRN,  cv.mulhhuRN
                                                                           // cv.macsRN,  cv.machhsRN, cv.macuRN,  cv.machhuRN
                mult_operator_o = MUL_IR;
              end else begin                                               // cv.mulsN,   cv.mulhhsN,  cv.muluN,   cv.mulhhuN
                                                                           // cv.macsN,   cv.machhsN,  cv.macuN,   cv.machhuN
                mult_operator_o = MUL_I;
              end
            end
            default: illegal_insn_o = 1'b1;
          endcase
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_CUSTOM_3: begin
        if (COREV_PULP) begin
          regfile_alu_we      = 1'b1;
          rega_used_o         = 1'b1;
          imm_b_mux_sel_o     = IMMB_VS;

          alu_vec_o = 1'b1;
          // vector size
          if (instr_rdata_i[12]) begin
            alu_vec_mode_o  = VEC_MODE8;
            mult_operator_o = MUL_DOT8;
          end else begin
            alu_vec_mode_o  = VEC_MODE16;
            mult_operator_o = MUL_DOT16;
          end

          // distinguish normal vector, sc and sci modes
          if (instr_rdata_i[14]) begin
            scalar_replication_o = 1'b1;

            if (instr_rdata_i[13]) begin
              // immediate scalar replication, .sci
              alu_op_b_mux_sel_o = OP_B_IMM;
            end else begin
              // register scalar replication, .sc
              regb_used_o = 1'b1;
            end
          end else begin
            // normal register use
            regb_used_o = 1'b1;
          end

          // now decode the instruction
          unique case (instr_rdata_i[31:26])
            6'b00000_0: begin // cv.add
              alu_operator_o = ALU_ADD;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00001_0: begin // cv.sub
              alu_operator_o = ALU_SUB;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00010_0: begin // cv.avg
              alu_operator_o = ALU_ADD;
              imm_b_mux_sel_o = IMMB_VS;
              bmask_b_mux_o = BMASK_B_ONE;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00011_0: begin // cv.avgu
             alu_operator_o = ALU_ADDU;
             imm_b_mux_sel_o = IMMB_VU;
             bmask_b_mux_o = BMASK_B_ONE;
             if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
               illegal_insn_o = 1'b1;
             end
             if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                 instr_rdata_i[25] != 1'b0) begin
               illegal_insn_o = 1'b1;
             end
            end
            6'b00100_0: begin // cv.min
             alu_operator_o = ALU_MIN;
             imm_b_mux_sel_o = IMMB_VS;
             if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
               illegal_insn_o = 1'b1;
             end
             if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                 instr_rdata_i[25] != 1'b0) begin
               illegal_insn_o = 1'b1;
             end
            end
            6'b00101_0: begin // cv.minu
              alu_operator_o = ALU_MINU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00110_0: begin // cv.max
              alu_operator_o = ALU_MAX;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00111_0: begin // cv.maxu
              alu_operator_o = ALU_MAXU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01000_0: begin // cv.srl
              alu_operator_o = ALU_SRL;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01001_0: begin // cv.sra
              alu_operator_o = ALU_SRA;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01010_0: begin // cv.sll
              alu_operator_o = ALU_SLL;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01011_0: begin // cv.or
              alu_operator_o = ALU_OR;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01100_0: begin // cv.xor
              alu_operator_o = ALU_XOR;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01101_0: begin // cv.and
              alu_operator_o = ALU_AND;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01110_0: begin // cv.abs
              alu_operator_o = ALU_ABS;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] != 3'b000 && instr_rdata_i[14:12] != 3'b001) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[25:20] != 6'b000000) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10000_0: begin // cv.dotup
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b00;
              imm_b_mux_sel_o   = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10001_0: begin // cv.dotusp
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b01;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10010_0: begin // cv.dotsp
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b11;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10011_0: begin // cv.sdotup
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b00;
              regc_used_o       = 1'b1;
              regc_mux_o        = REGC_RD;
              imm_b_mux_sel_o   = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10100_0: begin // cv.sdotusp
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b01;
              regc_used_o       = 1'b1;
              regc_mux_o        = REGC_RD;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10101_0: begin // cv.sdotsp
              alu_en            = 1'b0;
              mult_dot_en       = 1'b1;
              mult_dot_signed_o = 2'b11;
              regc_used_o       = 1'b1;
              regc_mux_o        = REGC_RD;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b10111_0: begin
              unique case (instr_rdata_i[14:13])
                2'b00: alu_operator_o = ALU_EXTS; // cv.extract
                2'b01: alu_operator_o = ALU_EXT;  // cv.extractu
                2'b10: begin                      // cv.insert
                  alu_operator_o     = ALU_INS;
                  regc_used_o        = 1'b1;
                  regc_mux_o         = REGC_RD;
                  alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                end
                default: illegal_insn_o = 1'b1;
              endcase
            end
            6'b11000_0: begin // cv.shuffle, cv.shuffleI0
              alu_operator_o       = ALU_SHUF;
              imm_b_mux_sel_o      = IMMB_SHUF;
              regb_used_o          = 1'b1;
              scalar_replication_o = 1'b0;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011 ||
                  instr_rdata_i[14:12] == 3'b100 || instr_rdata_i[14:12] == 3'b101) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b11001_0,
            6'b11010_0,
            6'b11011_0: begin // cv.shuffleI1 cv.shuffleI2 cv.shuffleI3
              alu_operator_o       = ALU_SHUF;
              imm_b_mux_sel_o      = IMMB_SHUF;
              regb_used_o          = 1'b1;
              scalar_replication_o = 1'b0;
              if (instr_rdata_i[14:12] != 3'b111) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b11100_0: begin // cv.shuffle2
              alu_operator_o       = ALU_SHUF2;
              regb_used_o          = 1'b1;
              regc_used_o          = 1'b1;
              regc_mux_o           = REGC_RD;
              scalar_replication_o = 1'b0;
              if (instr_rdata_i[14:12] != 3'b000 && instr_rdata_i[14:12] != 3'b001) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b11110_0: begin // cv.pack, cv.pack.h
              alu_operator_o = instr_rdata_i[25] ? ALU_PCKHI : ALU_PCKLO;
              regb_used_o    = 1'b1;
              if (instr_rdata_i[14:12] != 3'b000) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b11111_0: begin // cv.packhi, cv.packlo
              alu_operator_o = instr_rdata_i[25] ? ALU_PCKHI : ALU_PCKLO;
              regb_used_o    = 1'b1;
              regc_used_o    = 1'b1;
              regc_mux_o     = REGC_RD;
              if (instr_rdata_i[14:12] != 3'b001) begin
                illegal_insn_o = 1'b1;
              end
            end

            // Comparisons, always have bit 26 set
            6'b00000_1: begin // cv.cmpeq
              alu_operator_o  = ALU_EQ;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00001_1: begin // cv.cmpne
              alu_operator_o  = ALU_NE;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00010_1: begin // cv.cmpgt
              alu_operator_o  = ALU_GTS;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00011_1: begin // cv.cmpge
              alu_operator_o  = ALU_GES;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00100_1: begin // cv.cmplt
              alu_operator_o  = ALU_LTS;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00101_1: begin // cv.cmple
              alu_operator_o  = ALU_LES;
              imm_b_mux_sel_o = IMMB_VS;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00110_1: begin // cv.cmpgtu
              alu_operator_o  = ALU_GTU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b00111_1: begin // cv.cmpgeu
              alu_operator_o  = ALU_GEU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01000_1: begin // cv.cmpltu
              alu_operator_o  = ALU_LTU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01001_1: begin // cv.cmpleu
              alu_operator_o  = ALU_LEU;
              imm_b_mux_sel_o = IMMB_VU;
              if (instr_rdata_i[14:12] == 3'b010 || instr_rdata_i[14:12] == 3'b011) begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[14:12] != 3'b110 && instr_rdata_i[14:12] != 3'b111 &&
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end

            /*  Complex instructions */
            6'b01010_1: begin // cv.cplxmul.{r,i}.{/,div2,div4,div8}
              alu_en               = 1'b0;
              mult_dot_en          = 1'b1;
              mult_dot_signed_o    = 2'b11;
              is_clpx_o            = 1'b1;
              regc_used_o          = 1'b1;
              regc_mux_o           = REGC_RD;
              scalar_replication_o = 1'b0;
              alu_op_b_mux_sel_o   = OP_B_REGB_OR_FWD;
              regb_used_o          = 1'b1;
              illegal_insn_o       = instr_rdata_i[12];
            end
            6'b01011_1: begin // cv.cplxconj
              alu_operator_o       = ALU_ABS;
              is_clpx_o            = 1'b1;
              scalar_replication_o = 1'b0;
              regb_used_o          = 1'b0;
              if (instr_rdata_i[14:12] != 3'b000 || instr_rdata_i[25:20] != 6'b000000) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01100_1: begin // cv.subrotmj.{/,div2,div4,div8}
              alu_operator_o       = ALU_SUB;
              is_clpx_o            = 1'b1;
              scalar_replication_o = 1'b0;
              alu_op_b_mux_sel_o   = OP_B_REGB_OR_FWD;
              regb_used_o          = 1'b1;
              is_subrot_o          = 1'b1;
              if (instr_rdata_i[12] != 1'b0 || instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01101_1: begin // cv.add.{div2,div4,div8}
              alu_operator_o       = ALU_ADD;
              is_clpx_o            = 1'b1;
              scalar_replication_o = 1'b0;
              alu_op_b_mux_sel_o   = OP_B_REGB_OR_FWD;
              regb_used_o          = 1'b1;
              if (instr_rdata_i[12] != 1'b0 || instr_rdata_i[14:12] == 3'b000 ||
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end
            6'b01110_1: begin // cv.sub.{div2,div4,div8}
              alu_operator_o       = ALU_SUB;
              is_clpx_o            = 1'b1;
              scalar_replication_o = 1'b0;
              alu_op_b_mux_sel_o   = OP_B_REGB_OR_FWD;
              regb_used_o          = 1'b1;
              if (instr_rdata_i[12] != 1'b0 || instr_rdata_i[14:12] == 3'b000 ||
                  instr_rdata_i[25] != 1'b0) begin
                illegal_insn_o = 1'b1;
              end
            end

            default: illegal_insn_o = 1'b1;
          endcase
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      ////////////////////////////////////////////////
      //  ____  ____  _____ ____ ___    _    _      //
      // / ___||  _ \| ____/ ___|_ _|  / \  | |     //
      // \___ \| |_) |  _|| |    | |  / _ \ | |     //
      //  ___) |  __/| |__| |___ | | / ___ \| |___  //
      // |____/|_|   |_____\____|___/_/   \_\_____| //
      //                                            //
      ////////////////////////////////////////////////

      OPCODE_FENCE: begin
        unique case (instr_rdata_i[14:12])
          3'b000: begin // FENCE (FENCE.I instead, a bit more conservative)
            // flush pipeline
            fencei_insn_o = 1'b1;
          end

          3'b001: begin // FENCE.I
            // flush prefetch buffer, flush pipeline
            fencei_insn_o = 1'b1;
          end

          default: illegal_insn_o =  1'b1;
        endcase
      end

      OPCODE_SYSTEM: begin
        if (instr_rdata_i[14:12] == 3'b000)
        begin
          // non CSR related SYSTEM instructions
          if ( {instr_rdata_i[19:15], instr_rdata_i[11:7]} == '0)
          begin
            unique case (instr_rdata_i[31:20])
              12'h000:  // ECALL
              begin
                // environment (system) call
                ecall_insn_o  = 1'b1;
              end

              12'h001:  // ebreak
              begin
                // debugger trap
                ebrk_insn_o = 1'b1;
              end

              12'h302:  // mret
              begin
                illegal_insn_o = (PULP_SECURE) ? current_priv_lvl_i != PRIV_LVL_M : 1'b0;
                mret_insn_o    = ~illegal_insn_o;
                mret_dec_o     = 1'b1;
              end

              12'h002:  // uret
              begin
                illegal_insn_o = (PULP_SECURE) ? 1'b0 : 1'b1;
                uret_insn_o    = ~illegal_insn_o;
                uret_dec_o     = 1'b1;
              end

              12'h7b2:  // dret
              begin
                illegal_insn_o = !debug_mode_i;
                dret_insn_o    =  debug_mode_i;
                dret_dec_o     =  1'b1;
              end

              12'h105:  // wfi
              begin
                wfi_o = 1'b1;
                if (debug_wfi_no_sleep_i) begin
                  // Treat as NOP (do not cause sleep mode entry)
                  // Using decoding similar to ADDI, but without register reads/writes,
                  // i.e. keep regfile_alu_we = 0, rega_used_o = 0
                  alu_op_b_mux_sel_o = OP_B_IMM;
                  imm_b_mux_sel_o = IMMB_I;
                  alu_operator_o = ALU_ADD;
                end
              end

              default: illegal_insn_o = 1'b1;
            endcase
          end else illegal_insn_o = 1'b1;
        end
        else
        begin
          // instruction to read/modify CSR
          csr_access_o        = 1'b1;
          regfile_alu_we      = 1'b1;
          alu_op_b_mux_sel_o  = OP_B_IMM;
          imm_a_mux_sel_o     = IMMA_Z;
          imm_b_mux_sel_o     = IMMB_I;    // CSR address is encoded in I imm

          if (instr_rdata_i[14] == 1'b1) begin
            // rs1 field is used as immediate
            alu_op_a_mux_sel_o = OP_A_IMM;
          end else begin
            rega_used_o        = 1'b1;
            alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;
          end

          // instr_rdata_i[19:14] = rs or immediate value
          //   if set or clear with rs == x0 or imm == 0,
          //   then do not perform a write action
          unique case (instr_rdata_i[13:12])
            2'b01:   csr_op = CSR_OP_WRITE;
            2'b10:   csr_op = instr_rdata_i[19:15] == 5'b0 ? CSR_OP_READ : CSR_OP_SET;
            2'b11:   csr_op = instr_rdata_i[19:15] == 5'b0 ? CSR_OP_READ : CSR_OP_CLEAR;
            default: csr_illegal = 1'b1;
          endcase

          if (instr_rdata_i[29:28] > current_priv_lvl_i) begin
            // No access to higher privilege CSR
            csr_illegal = 1'b1;
          end

          // Determine if CSR access is illegal
          case (instr_rdata_i[31:20])
            // Floating point
            CSR_FFLAGS :
                if (FPU == 0 || fs_off_i == 1'b1) csr_illegal = 1'b1;

            CSR_FRM,
              CSR_FCSR :
                if (FPU == 0 || fs_off_i == 1'b1) begin
                  csr_illegal = 1'b1;
                end else begin
                  // FRM updated value needed by following FPU instruction
                  if (csr_op != CSR_OP_READ) csr_status_o = 1'b1;
                end

            //  Writes to read only CSRs results in illegal instruction
            CSR_MVENDORID,
              CSR_MARCHID,
              CSR_MIMPID,
              CSR_MHARTID :
                if (csr_op != CSR_OP_READ) csr_illegal = 1'b1;

            // These are valid CSR registers
            CSR_MSTATUS,
              CSR_MEPC,
              CSR_MTVEC,
              CSR_MCAUSE :
                // Not illegal, but treat as status CSR for side effect handling
                csr_status_o = 1'b1;

            // These are valid CSR registers
            CSR_MISA,
              CSR_MIE,
              CSR_MSCRATCH,
              CSR_MTVAL,
              CSR_MIP :
                ; // do nothing, not illegal

            // Hardware Performance Monitor
            CSR_MCYCLE,
              CSR_MINSTRET,
              CSR_MHPMCOUNTER3,
              CSR_MHPMCOUNTER4,  CSR_MHPMCOUNTER5,  CSR_MHPMCOUNTER6,  CSR_MHPMCOUNTER7,
              CSR_MHPMCOUNTER8,  CSR_MHPMCOUNTER9,  CSR_MHPMCOUNTER10, CSR_MHPMCOUNTER11,
              CSR_MHPMCOUNTER12, CSR_MHPMCOUNTER13, CSR_MHPMCOUNTER14, CSR_MHPMCOUNTER15,
              CSR_MHPMCOUNTER16, CSR_MHPMCOUNTER17, CSR_MHPMCOUNTER18, CSR_MHPMCOUNTER19,
              CSR_MHPMCOUNTER20, CSR_MHPMCOUNTER21, CSR_MHPMCOUNTER22, CSR_MHPMCOUNTER23,
              CSR_MHPMCOUNTER24, CSR_MHPMCOUNTER25, CSR_MHPMCOUNTER26, CSR_MHPMCOUNTER27,
              CSR_MHPMCOUNTER28, CSR_MHPMCOUNTER29, CSR_MHPMCOUNTER30, CSR_MHPMCOUNTER31,
              CSR_MCYCLEH,
              CSR_MINSTRETH,
              CSR_MHPMCOUNTER3H,
              CSR_MHPMCOUNTER4H,  CSR_MHPMCOUNTER5H,  CSR_MHPMCOUNTER6H,  CSR_MHPMCOUNTER7H,
              CSR_MHPMCOUNTER8H,  CSR_MHPMCOUNTER9H,  CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H,
              CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H, CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H,
              CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H, CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H,
              CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H, CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H,
              CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H,
              CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H,
              CSR_MCOUNTINHIBIT,
              CSR_MHPMEVENT3,
              CSR_MHPMEVENT4,  CSR_MHPMEVENT5,  CSR_MHPMEVENT6,  CSR_MHPMEVENT7,
              CSR_MHPMEVENT8,  CSR_MHPMEVENT9,  CSR_MHPMEVENT10, CSR_MHPMEVENT11,
              CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15,
              CSR_MHPMEVENT16, CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19,
              CSR_MHPMEVENT20, CSR_MHPMEVENT21, CSR_MHPMEVENT22, CSR_MHPMEVENT23,
              CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26, CSR_MHPMEVENT27,
              CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31 :
                // Not illegal, but treat as status CSR to get accurate counts
                csr_status_o = 1'b1;

            // Hardware Performance Monitor (unprivileged read-only mirror CSRs)
            CSR_CYCLE,
              CSR_INSTRET,
              CSR_HPMCOUNTER3,
              CSR_HPMCOUNTER4,  CSR_HPMCOUNTER5,  CSR_HPMCOUNTER6,  CSR_HPMCOUNTER7,
              CSR_HPMCOUNTER8,  CSR_HPMCOUNTER9,  CSR_HPMCOUNTER10, CSR_HPMCOUNTER11,
              CSR_HPMCOUNTER12, CSR_HPMCOUNTER13, CSR_HPMCOUNTER14, CSR_HPMCOUNTER15,
              CSR_HPMCOUNTER16, CSR_HPMCOUNTER17, CSR_HPMCOUNTER18, CSR_HPMCOUNTER19,
              CSR_HPMCOUNTER20, CSR_HPMCOUNTER21, CSR_HPMCOUNTER22, CSR_HPMCOUNTER23,
              CSR_HPMCOUNTER24, CSR_HPMCOUNTER25, CSR_HPMCOUNTER26, CSR_HPMCOUNTER27,
              CSR_HPMCOUNTER28, CSR_HPMCOUNTER29, CSR_HPMCOUNTER30, CSR_HPMCOUNTER31,
              CSR_CYCLEH,
              CSR_INSTRETH,
              CSR_HPMCOUNTER3H,
              CSR_HPMCOUNTER4H,  CSR_HPMCOUNTER5H,  CSR_HPMCOUNTER6H,  CSR_HPMCOUNTER7H,
              CSR_HPMCOUNTER8H,  CSR_HPMCOUNTER9H,  CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H,
              CSR_HPMCOUNTER12H, CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H,
              CSR_HPMCOUNTER16H, CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H,
              CSR_HPMCOUNTER20H, CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_HPMCOUNTER23H,
              CSR_HPMCOUNTER24H, CSR_HPMCOUNTER25H, CSR_HPMCOUNTER26H, CSR_HPMCOUNTER27H,
              CSR_HPMCOUNTER28H, CSR_HPMCOUNTER29H, CSR_HPMCOUNTER30H, CSR_HPMCOUNTER31H :
                // Read-only and readable from user mode only if the bit of mcounteren is set
                if ((csr_op != CSR_OP_READ) ||
                    (PULP_SECURE && (current_priv_lvl_i != PRIV_LVL_M) && !mcounteren_i[instr_rdata_i[24:20]])) begin
                  csr_illegal = 1'b1;
                end else begin
                  csr_status_o = 1'b1;
                end

            // This register only exists in user mode
            CSR_MCOUNTEREN :
                if (!PULP_SECURE) begin
                  csr_illegal = 1'b1;
                end else begin
                  csr_status_o = 1'b1;
                end

            // Debug register access
            CSR_DCSR,
              CSR_DPC,
              CSR_DSCRATCH0,
              CSR_DSCRATCH1 :
                if (!debug_mode_i) begin
                  csr_illegal = 1'b1;
                end else begin
                  csr_status_o = 1'b1;
                end

            // Debug Trigger register access
            CSR_TSELECT,
              CSR_TDATA1,
              CSR_TDATA2,
              CSR_TDATA3,
              CSR_TINFO,
              CSR_MCONTEXT,
              CSR_SCONTEXT :
                if (DEBUG_TRIGGER_EN != 1)
                  csr_illegal = 1'b1;

            // Hardware Loop register
            CSR_LPSTART0,
              CSR_LPEND0,
              CSR_LPCOUNT0,
              CSR_LPSTART1,
              CSR_LPEND1,
              CSR_LPCOUNT1:
                if (!COREV_PULP || csr_op != CSR_OP_READ) csr_illegal = 1'b1;

            // UHARTID access
            CSR_UHARTID :
                if (!COREV_PULP || csr_op != CSR_OP_READ) csr_illegal = 1'b1;

            // PRIVLV access
            CSR_PRIVLV :
                if (!COREV_PULP || csr_op != CSR_OP_READ) begin
                  csr_illegal = 1'b1;
                end else begin
                  csr_status_o = 1'b1;
                end

            // ZFINX
            CSR_ZFINX :
                if (!COREV_PULP || (FPU && !ZFINX) || csr_op != CSR_OP_READ) begin
                  csr_illegal = 1'b1;
                end

            // PMP register access
            CSR_PMPCFG0,
              CSR_PMPCFG1,
              CSR_PMPCFG2,
              CSR_PMPCFG3,
              CSR_PMPADDR0,
              CSR_PMPADDR1,
              CSR_PMPADDR2,
              CSR_PMPADDR3,
              CSR_PMPADDR4,
              CSR_PMPADDR5,
              CSR_PMPADDR6,
              CSR_PMPADDR7,
              CSR_PMPADDR8,
              CSR_PMPADDR9,
              CSR_PMPADDR10,
              CSR_PMPADDR11,
              CSR_PMPADDR12,
              CSR_PMPADDR13,
              CSR_PMPADDR14,
              CSR_PMPADDR15 :
                if (!USE_PMP) csr_illegal = 1'b1;

            // User register access
            CSR_USTATUS,
              CSR_UEPC,
              CSR_UTVEC,
              CSR_UCAUSE :
                if (!PULP_SECURE) begin
                  csr_illegal = 1'b1;
                end else begin
                  csr_status_o = 1'b1;
                end

            default : csr_illegal = 1'b1;

          endcase // case (instr_rdata_i[31:20])

          illegal_insn_o = csr_illegal;

        end
      end
      default: illegal_insn_o = 1'b1;
    endcase

    // make sure invalid compressed instruction causes an exception
    if (illegal_c_insn_i) begin
      illegal_insn_o = 1'b1;
    end

  end

  // deassert we signals (in case of stalls)
  assign alu_en_o                    = (deassert_we_i) ? 1'b0          : alu_en;
  assign mult_int_en_o               = (deassert_we_i) ? 1'b0          : mult_int_en;
  assign mult_dot_en_o               = (deassert_we_i) ? 1'b0          : mult_dot_en;
  assign apu_en_o                    = (deassert_we_i) ? 1'b0          : apu_en;
  assign regfile_mem_we_o            = (deassert_we_i) ? 1'b0          : regfile_mem_we;
  assign regfile_alu_we_o            = (deassert_we_i) ? 1'b0          : regfile_alu_we;
  assign data_req_o                  = (deassert_we_i) ? 1'b0          : data_req;
  assign hwlp_we_o                   = (deassert_we_i) ? 3'b0          : hwlp_we;
  assign csr_op_o                    = (deassert_we_i) ? CSR_OP_READ   : csr_op;
  assign ctrl_transfer_insn_in_id_o  = (deassert_we_i) ? BRANCH_NONE   : ctrl_transfer_insn;

  assign ctrl_transfer_insn_in_dec_o  = ctrl_transfer_insn;
  assign regfile_alu_we_dec_o         = regfile_alu_we;

endmodule // cv32e40p_decoder

// -------------------- END OF rtl/cv32e40p_decoder.sv --------------------

// -------------------- START OF rtl/cv32e40p_ex_stage.sv --------------------
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
// Engineer:       Renzo Andri - andrire@student.ethz.ch                      //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Execute stage                                              //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Execution stage: Hosts ALU and MAC unit                    //
//                 ALU: computes additions/subtractions/comparisons           //
//                 MULT: computes normal multiplications                      //
//                 APU_DISP: offloads instructions to the shared unit.        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_ex_stage
  import cv32e40p_pkg::*;
  import cv32e40p_apu_core_pkg::*;
#(
    parameter COREV_PULP       = 0,
    parameter FPU              = 0,
    parameter APU_NARGS_CPU    = 3,
    parameter APU_WOP_CPU      = 6,
    parameter APU_NDSFLAGS_CPU = 15,
    parameter APU_NUSFLAGS_CPU = 5
) (
    input logic clk,
    input logic rst_n,

    // ALU signals from ID stage
    input alu_opcode_e        alu_operator_i,
    input logic        [31:0] alu_operand_a_i,
    input logic        [31:0] alu_operand_b_i,
    input logic        [31:0] alu_operand_c_i,
    input logic               alu_en_i,
    input logic        [ 4:0] bmask_a_i,
    input logic        [ 4:0] bmask_b_i,
    input logic        [ 1:0] imm_vec_ext_i,
    input logic        [ 1:0] alu_vec_mode_i,
    input logic               alu_is_clpx_i,
    input logic               alu_is_subrot_i,
    input logic        [ 1:0] alu_clpx_shift_i,

    // Multiplier signals
    input mul_opcode_e        mult_operator_i,
    input logic        [31:0] mult_operand_a_i,
    input logic        [31:0] mult_operand_b_i,
    input logic        [31:0] mult_operand_c_i,
    input logic               mult_en_i,
    input logic               mult_sel_subword_i,
    input logic        [ 1:0] mult_signed_mode_i,
    input logic        [ 4:0] mult_imm_i,

    input logic [31:0] mult_dot_op_a_i,
    input logic [31:0] mult_dot_op_b_i,
    input logic [31:0] mult_dot_op_c_i,
    input logic [ 1:0] mult_dot_signed_i,
    input logic        mult_is_clpx_i,
    input logic [ 1:0] mult_clpx_shift_i,
    input logic        mult_clpx_img_i,

    output logic mult_multicycle_o,

    input logic data_req_i,
    input logic data_rvalid_i,
    input logic data_misaligned_ex_i,
    input logic data_misaligned_i,

    input logic [1:0] ctrl_transfer_insn_in_dec_i,

    // FPU signals
    output logic fpu_fflags_we_o,
    output logic [APU_NUSFLAGS_CPU-1:0] fpu_fflags_o,

    // APU signals
    input logic                              apu_en_i,
    input logic [     APU_WOP_CPU-1:0]       apu_op_i,
    input logic [                 1:0]       apu_lat_i,
    input logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_i,
    input logic [                 5:0]       apu_waddr_i,
    input logic [APU_NUSFLAGS_CPU-1:0]       apu_flags_i,

    input  logic [2:0][5:0] apu_read_regs_i,
    input  logic [2:0]      apu_read_regs_valid_i,
    output logic            apu_read_dep_o,
    output logic            apu_read_dep_for_jalr_o,
    input  logic [1:0][5:0] apu_write_regs_i,
    input  logic [1:0]      apu_write_regs_valid_i,
    output logic            apu_write_dep_o,

    output logic apu_perf_type_o,
    output logic apu_perf_cont_o,
    output logic apu_perf_wb_o,

    output logic apu_busy_o,
    output logic apu_ready_wb_o,

    // apu-interconnect
    // handshake signals
    output logic                           apu_req_o,
    input  logic                           apu_gnt_i,
    // request channel
    output logic [APU_NARGS_CPU-1:0][31:0] apu_operands_o,
    output logic [  APU_WOP_CPU-1:0]       apu_op_o,
    // response channel
    input  logic                           apu_rvalid_i,
    input  logic [             31:0]       apu_result_i,

    input logic        lsu_en_i,
    input logic [31:0] lsu_rdata_i,

    // input from ID stage
    input logic       branch_in_ex_i,
    input logic [5:0] regfile_alu_waddr_i,
    input logic       regfile_alu_we_i,

    // directly passed through to WB stage, not used in EX
    input logic       regfile_we_i,
    input logic [5:0] regfile_waddr_i,

    // CSR access
    input logic        csr_access_i,
    input logic [31:0] csr_rdata_i,

    // Output of EX stage pipeline
    output logic [ 5:0] regfile_waddr_wb_o,
    output logic        regfile_we_wb_o,
    output logic        regfile_we_wb_power_o,
    output logic [31:0] regfile_wdata_wb_o,

    // Forwarding ports : to ID stage
    output logic [ 5:0] regfile_alu_waddr_fw_o,
    output logic        regfile_alu_we_fw_o,
    output logic        regfile_alu_we_fw_power_o,
    output logic [31:0] regfile_alu_wdata_fw_o,  // forward to RF and ID/EX pipe, ALU & MUL

    // To IF: Jump and branch target and decision
    output logic [31:0] jump_target_o,
    output logic        branch_decision_o,

    // Stall Control
    input logic is_decoding_i, // Used to mask data Dependency inside the APU dispatcher in case of an istruction non valid
    input logic lsu_ready_ex_i,  // EX part of LSU is done
    input logic lsu_err_i,

    output logic ex_ready_o,  // EX stage ready for new data
    output logic ex_valid_o,  // EX stage gets new data
    input  logic wb_ready_i  // WB stage ready for new data
);

  logic [                31:0] alu_result;
  logic [                31:0] mult_result;
  logic                        alu_cmp_result;

  logic                        regfile_we_lsu;
  logic [                 5:0] regfile_waddr_lsu;

  logic                        wb_contention;
  logic                        wb_contention_lsu;

  logic                        alu_ready;
  logic                        mulh_active;
  logic                        mult_ready;

  // APU signals
  logic                        apu_valid;
  logic [                 5:0] apu_waddr;
  logic [                31:0] apu_result;
  logic                        apu_stall;
  logic                        apu_active;
  logic                        apu_singlecycle;
  logic                        apu_multicycle;
  logic                        apu_req;
  logic                        apu_gnt;

  logic                        apu_rvalid_q;
  logic [                31:0] apu_result_q;
  logic [APU_NUSFLAGS_CPU-1:0] apu_flags_q;

  // ALU write port mux
  always_comb begin
    regfile_alu_wdata_fw_o    = '0;
    regfile_alu_waddr_fw_o    = '0;
    regfile_alu_we_fw_o       = 1'b0;
    regfile_alu_we_fw_power_o = 1'b0;
    wb_contention             = 1'b0;

    // APU single cycle operations, and multicycle operations (> 2cycles) are written back on ALU port
    if (apu_valid & (apu_singlecycle | apu_multicycle)) begin
      regfile_alu_we_fw_o       = 1'b1;
      regfile_alu_we_fw_power_o = 1'b1;
      regfile_alu_waddr_fw_o    = apu_waddr;
      regfile_alu_wdata_fw_o    = apu_result;

      if (regfile_alu_we_i & ~apu_en_i) begin
        wb_contention = 1'b1;
      end
    end else begin
      regfile_alu_we_fw_o = regfile_alu_we_i & ~apu_en_i;
      regfile_alu_we_fw_power_o = !COREV_PULP ? regfile_alu_we_i & ~apu_en_i : 
                                                regfile_alu_we_i & ~apu_en_i &
                                                mult_ready & alu_ready & lsu_ready_ex_i;
      regfile_alu_waddr_fw_o = regfile_alu_waddr_i;
      if (alu_en_i) regfile_alu_wdata_fw_o = alu_result;
      if (mult_en_i) regfile_alu_wdata_fw_o = mult_result;
      if (csr_access_i) regfile_alu_wdata_fw_o = csr_rdata_i;
    end
  end

  // LSU write port mux
  always_comb begin
    regfile_we_wb_o       = 1'b0;
    regfile_we_wb_power_o = 1'b0;
    regfile_waddr_wb_o    = regfile_waddr_lsu;
    regfile_wdata_wb_o    = lsu_rdata_i;
    wb_contention_lsu     = 1'b0;

    if (regfile_we_lsu) begin
      regfile_we_wb_o       = 1'b1;
      regfile_we_wb_power_o = !COREV_PULP ? 1'b1 : ~data_misaligned_ex_i & wb_ready_i;
      if (apu_valid & (!apu_singlecycle & !apu_multicycle)) begin
        wb_contention_lsu = 1'b1;
      end
      // APU two-cycle operations are written back on LSU port
    end else if (apu_valid & (!apu_singlecycle & !apu_multicycle)) begin
      regfile_we_wb_o       = 1'b1;
      regfile_we_wb_power_o = 1'b1;
      regfile_waddr_wb_o    = apu_waddr;
      regfile_wdata_wb_o    = apu_result;
    end
  end

  // branch handling
  assign branch_decision_o = alu_cmp_result;
  assign jump_target_o     = alu_operand_c_i;


  ////////////////////////////
  //     _    _    _   _    //
  //    / \  | |  | | | |   //
  //   / _ \ | |  | | | |   //
  //  / ___ \| |__| |_| |   //
  // /_/   \_\_____\___/    //
  //                        //
  ////////////////////////////

  cv32e40p_alu alu_i (
      .clk        (clk),
      .rst_n      (rst_n),
      .enable_i   (alu_en_i),
      .operator_i (alu_operator_i),
      .operand_a_i(alu_operand_a_i),
      .operand_b_i(alu_operand_b_i),
      .operand_c_i(alu_operand_c_i),

      .vector_mode_i(alu_vec_mode_i),
      .bmask_a_i    (bmask_a_i),
      .bmask_b_i    (bmask_b_i),
      .imm_vec_ext_i(imm_vec_ext_i),

      .is_clpx_i   (alu_is_clpx_i),
      .clpx_shift_i(alu_clpx_shift_i),
      .is_subrot_i (alu_is_subrot_i),

      .result_o           (alu_result),
      .comparison_result_o(alu_cmp_result),

      .ready_o   (alu_ready),
      .ex_ready_i(ex_ready_o)
  );


  ////////////////////////////////////////////////////////////////
  //  __  __ _   _ _   _____ ___ ____  _     ___ _____ ____     //
  // |  \/  | | | | | |_   _|_ _|  _ \| |   |_ _| ____|  _ \    //
  // | |\/| | | | | |   | |  | || |_) | |    | ||  _| | |_) |   //
  // | |  | | |_| | |___| |  | ||  __/| |___ | || |___|  _ <    //
  // |_|  |_|\___/|_____|_| |___|_|   |_____|___|_____|_| \_\   //
  //                                                            //
  ////////////////////////////////////////////////////////////////

  cv32e40p_mult mult_i (
      .clk  (clk),
      .rst_n(rst_n),

      .enable_i  (mult_en_i),
      .operator_i(mult_operator_i),

      .short_subword_i(mult_sel_subword_i),
      .short_signed_i (mult_signed_mode_i),

      .op_a_i(mult_operand_a_i),
      .op_b_i(mult_operand_b_i),
      .op_c_i(mult_operand_c_i),
      .imm_i (mult_imm_i),

      .dot_op_a_i  (mult_dot_op_a_i),
      .dot_op_b_i  (mult_dot_op_b_i),
      .dot_op_c_i  (mult_dot_op_c_i),
      .dot_signed_i(mult_dot_signed_i),
      .is_clpx_i   (mult_is_clpx_i),
      .clpx_shift_i(mult_clpx_shift_i),
      .clpx_img_i  (mult_clpx_img_i),

      .result_o(mult_result),

      .multicycle_o (mult_multicycle_o),
      .mulh_active_o(mulh_active),
      .ready_o      (mult_ready),
      .ex_ready_i   (ex_ready_o)
  );

  generate
    if (FPU == 1) begin : gen_apu
      ////////////////////////////////////////////////////
      //     _    ____  _   _   ____ ___ ____  ____     //
      //    / \  |  _ \| | | | |  _ \_ _/ ___||  _ \    //
      //   / _ \ | |_) | | | | | | | | |\___ \| |_) |   //
      //  / ___ \|  __/| |_| | | |_| | | ___) |  __/    //
      // /_/   \_\_|    \___/  |____/___|____/|_|       //
      //                                                //
      ////////////////////////////////////////////////////

      cv32e40p_apu_disp apu_disp_i (
          .clk_i (clk),
          .rst_ni(rst_n),

          .enable_i   (apu_en_i),
          .apu_lat_i  (apu_lat_i),
          .apu_waddr_i(apu_waddr_i),

          .apu_waddr_o      (apu_waddr),
          .apu_multicycle_o (apu_multicycle),
          .apu_singlecycle_o(apu_singlecycle),

          .active_o(apu_active),
          .stall_o (apu_stall),

          .is_decoding_i      (is_decoding_i),
          .read_regs_i        (apu_read_regs_i),
          .read_regs_valid_i  (apu_read_regs_valid_i),
          .read_dep_o         (apu_read_dep_o),
          .read_dep_for_jalr_o(apu_read_dep_for_jalr_o),
          .write_regs_i       (apu_write_regs_i),
          .write_regs_valid_i (apu_write_regs_valid_i),
          .write_dep_o        (apu_write_dep_o),

          .perf_type_o(apu_perf_type_o),
          .perf_cont_o(apu_perf_cont_o),

          // apu-interconnect
          // handshake signals
          .apu_req_o   (apu_req),
          .apu_gnt_i   (apu_gnt),
          // response channel
          .apu_rvalid_i(apu_valid)
      );

      assign apu_perf_wb_o  = wb_contention | wb_contention_lsu;
      assign apu_ready_wb_o = ~(apu_active | apu_en_i | apu_stall) | apu_valid;

      ///////////////////////////////////////
      // APU result memorization Register  //
      ///////////////////////////////////////
      always_ff @(posedge clk, negedge rst_n) begin : APU_Result_Memorization
        if (~rst_n) begin
          apu_rvalid_q <= 1'b0;
          apu_result_q <= 'b0;
          apu_flags_q  <= 'b0;
        end else begin
          if (apu_rvalid_i && apu_multicycle &&
              (data_misaligned_i || data_misaligned_ex_i ||
               ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
               (mulh_active && (mult_operator_i == MUL_H)) ||
               ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
                regfile_alu_we_i && ~apu_read_dep_for_jalr_o))) begin
            apu_rvalid_q <= 1'b1;
            apu_result_q <= apu_result_i;
            apu_flags_q  <= apu_flags_i;
          end else if (apu_rvalid_q && !(data_misaligned_i || data_misaligned_ex_i ||
                                         ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
                                         (mulh_active && (mult_operator_i == MUL_H)) ||
                                         ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
                                          regfile_alu_we_i && ~apu_read_dep_for_jalr_o))) begin
            apu_rvalid_q <= 1'b0;
          end
        end
      end

      assign apu_req_o = apu_req;
      assign apu_gnt = apu_gnt_i;
      assign apu_valid = (apu_multicycle && (data_misaligned_i || data_misaligned_ex_i ||
                                             ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
                                             (mulh_active && (mult_operator_i == MUL_H)) ||
                                             ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
                                              regfile_alu_we_i && ~apu_read_dep_for_jalr_o)))
                         ? 1'b0 : (apu_rvalid_i || apu_rvalid_q);
      assign apu_operands_o = apu_operands_i;
      assign apu_op_o = apu_op_i;
      assign apu_result = apu_rvalid_q ? apu_result_q : apu_result_i;
      assign fpu_fflags_we_o = apu_valid;
      assign fpu_fflags_o = apu_rvalid_q ? apu_flags_q : apu_flags_i;
    end else begin : gen_no_apu
      // default assignements for the case when no FPU/APU is attached.
      assign apu_req_o               = '0;
      assign apu_operands_o[0]       = '0;
      assign apu_operands_o[1]       = '0;
      assign apu_operands_o[2]       = '0;
      assign apu_op_o                = '0;
      assign apu_req                 = 1'b0;
      assign apu_gnt                 = 1'b0;
      assign apu_result              = 32'b0;
      assign apu_valid               = 1'b0;
      assign apu_waddr               = 6'b0;
      assign apu_stall               = 1'b0;
      assign apu_active              = 1'b0;
      assign apu_ready_wb_o          = 1'b1;
      assign apu_perf_wb_o           = 1'b0;
      assign apu_perf_cont_o         = 1'b0;
      assign apu_perf_type_o         = 1'b0;
      assign apu_singlecycle         = 1'b0;
      assign apu_multicycle          = 1'b0;
      assign apu_read_dep_o          = 1'b0;
      assign apu_read_dep_for_jalr_o = 1'b0;
      assign apu_write_dep_o         = 1'b0;
      assign fpu_fflags_o            = '0;
      assign fpu_fflags_we_o         = '0;
    end
  endgenerate

  assign apu_busy_o = apu_active;

  ///////////////////////////////////////
  // EX/WB Pipeline Register           //
  ///////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin : EX_WB_Pipeline_Register
    if (~rst_n) begin
      regfile_waddr_lsu <= '0;
      regfile_we_lsu    <= 1'b0;
    end else begin
      if (ex_valid_o) // wb_ready_i is implied
      begin
        regfile_we_lsu <= regfile_we_i & ~lsu_err_i;
        if (regfile_we_i & ~lsu_err_i) begin
          regfile_waddr_lsu <= regfile_waddr_i;
        end
      end else if (wb_ready_i) begin
        // we are ready for a new instruction, but there is none available,
        // so we just flush the current one out of the pipe
        regfile_we_lsu <= 1'b0;
      end
    end
  end

  // As valid always goes to the right and ready to the left, and we are able
  // to finish branches without going to the WB stage, ex_valid does not
  // depend on ex_ready.
  assign ex_ready_o = (~apu_stall & alu_ready & mult_ready & lsu_ready_ex_i
                       & wb_ready_i & ~wb_contention) | (branch_in_ex_i);
  assign ex_valid_o = (apu_valid | alu_en_i | mult_en_i | csr_access_i | lsu_en_i)
                       & (alu_ready & mult_ready & lsu_ready_ex_i & wb_ready_i);

endmodule

// -------------------- END OF rtl/cv32e40p_ex_stage.sv --------------------

// -------------------- START OF rtl/cv32e40p_ff_one.sv --------------------
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
// Engineer:       Andreas Traber - atraber@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    cv32e40p_ff_one                                               //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Find First One                                             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_ff_one #(
    parameter LEN = 32
) (
    input logic [LEN-1:0] in_i,

    output logic [$clog2(LEN)-1:0] first_one_o,
    output logic                   no_ones_o
);

  localparam NUM_LEVELS = $clog2(LEN);

  logic [          LEN-1:0][NUM_LEVELS-1:0] index_lut;
  logic [2**NUM_LEVELS-1:0]                 sel_nodes;
  logic [2**NUM_LEVELS-1:0][NUM_LEVELS-1:0] index_nodes;


  //////////////////////////////////////////////////////////////////////////////
  // generate tree structure
  //////////////////////////////////////////////////////////////////////////////

  generate
    genvar j;
    for (j = 0; j < LEN; j++) begin : gen_index_lut
      assign index_lut[j] = $unsigned(j);
    end
  endgenerate

  generate
    genvar k;
    genvar l;
    genvar level;

    assign sel_nodes[2**NUM_LEVELS-1] = 1'b0;

    for (level = 0; level < NUM_LEVELS; level++) begin : gen_tree
      //------------------------------------------------------------
      if (level < NUM_LEVELS - 1) begin : gen_non_root_level
        for (l = 0; l < 2 ** level; l++) begin : gen_node
          assign sel_nodes[2**level-1+l]   = sel_nodes[2**(level+1)-1+l*2] | sel_nodes[2**(level+1)-1+l*2+1];
          assign index_nodes[2**level-1+l] = (sel_nodes[2**(level+1)-1+l*2] == 1'b1) ?
                                           index_nodes[2**(level+1)-1+l*2] : index_nodes[2**(level+1)-1+l*2+1];
        end
      end
      //------------------------------------------------------------
      if (level == NUM_LEVELS - 1) begin : gen_root_level
        for (k = 0; k < 2 ** level; k++) begin : gen_node
          // if two successive indices are still in the vector...
          if (k * 2 < LEN - 1) begin : gen_two
            assign sel_nodes[2**level-1+k] = in_i[k*2] | in_i[k*2+1];
            assign index_nodes[2**level-1+k] = (in_i[k*2] == 1'b1) ? index_lut[k*2] : index_lut[k*2+1];
          end
          // if only the first index is still in the vector...
          if (k * 2 == LEN - 1) begin : gen_one
            assign sel_nodes[2**level-1+k]   = in_i[k*2];
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end
          // if index is out of range
          if (k * 2 > LEN - 1) begin : gen_out_of_range
            assign sel_nodes[2**level-1+k]   = 1'b0;
            assign index_nodes[2**level-1+k] = '0;
          end
        end
      end
      //------------------------------------------------------------
    end
  endgenerate

  //////////////////////////////////////////////////////////////////////////////
  // connect output
  //////////////////////////////////////////////////////////////////////////////

  assign first_one_o = index_nodes[0];
  assign no_ones_o   = ~sel_nodes[0];

endmodule

// -------------------- END OF rtl/cv32e40p_ff_one.sv --------------------

// -------------------- START OF rtl/cv32e40p_fifo.sv --------------------
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

// Copy of fifo_v3 from https://github.com/pulp-platform/common_cells b2a4b2d3decdfc152ad9b4564a48ed3b2649fd6c

module cv32e40p_fifo #(
    parameter bit FALL_THROUGH = 1'b0,  // fifo is in fall-through mode
    parameter int unsigned DATA_WIDTH = 32,  // default data width if the fifo is of type logic
    parameter int unsigned DEPTH = 8,  // depth can be arbitrary from 0 to 2**32
    // DO NOT OVERWRITE THIS PARAMETER
    parameter int unsigned ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    input logic clk_i,  // Clock
    input logic rst_ni,  // Asynchronous reset active low
    input logic flush_i,  // flush the queue
    input logic flush_but_first_i,  // flush the queue except the first instruction
    input logic testmode_i,  // test_mode to bypass clock gating
    // status flags
    output logic full_o,  // queue is full
    output logic empty_o,  // queue is empty
    output logic [ADDR_DEPTH:0] cnt_o,  // FIFO counter
    // as long as the queue is not full we can push new data
    input logic [DATA_WIDTH-1:0] data_i,  // data to push into the queue
    input logic push_i,  // data is valid and can be pushed to the queue
    // as long as the queue is not empty we can pop new elements
    output logic [DATA_WIDTH-1:0] data_o,  // output data
    input logic pop_i  // pop head from queue
);
  // local parameter
  // FIFO depth - handle the case of pass-through, synthesizer will do constant propagation
  localparam int unsigned FIFO_DEPTH = (DEPTH > 0) ? DEPTH : 1;
  // clock gating control
  logic gate_clock;
  // pointer to the read and write section of the queue
  logic [ADDR_DEPTH - 1:0] read_pointer_n, read_pointer_q, write_pointer_n, write_pointer_q;
  // keep a counter to keep track of the current queue status
  logic [ADDR_DEPTH:0]
      status_cnt_n, status_cnt_q;  // this integer will be truncated by the synthesis tool
  // actual memory
  logic [FIFO_DEPTH - 1:0][DATA_WIDTH-1:0] mem_n, mem_q;

  assign cnt_o = status_cnt_q;

  // status flags
  generate
    if (DEPTH == 0) begin : gen_zero_depth
      assign empty_o = ~push_i;
      assign full_o  = ~pop_i;
    end else begin : gen_non_zero_depth
      assign full_o  = (status_cnt_q == FIFO_DEPTH[ADDR_DEPTH:0]);
      assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
    end
  endgenerate

  // read and write queue logic
  always_comb begin : read_write_comb
    // default assignment
    read_pointer_n  = read_pointer_q;
    write_pointer_n = write_pointer_q;
    status_cnt_n    = status_cnt_q;
    data_o          = (DEPTH == 0) ? data_i : mem_q[read_pointer_q];
    mem_n           = mem_q;
    gate_clock      = 1'b1;

    // push a new element to the queue
    if (push_i && ~full_o) begin
      // push the data onto the queue
      mem_n[write_pointer_q] = data_i;
      // un-gate the clock, we want to write something
      gate_clock = 1'b0;
      // increment the write counter
      if (write_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) write_pointer_n = '0;
      else write_pointer_n = write_pointer_q + 1;
      // increment the overall counter
      status_cnt_n = status_cnt_q + 1;
    end

    if (pop_i && ~empty_o) begin
      // read from the queue is a default assignment
      // but increment the read pointer...
      if (read_pointer_n == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) read_pointer_n = '0;
      else read_pointer_n = read_pointer_q + 1;
      // ... and decrement the overall count
      status_cnt_n = status_cnt_q - 1;
    end

    // keep the count pointer stable if we push and pop at the same time
    if (push_i && pop_i && ~full_o && ~empty_o) status_cnt_n = status_cnt_q;

    // FIFO is in pass through mode -> do not change the pointers
    if (FALL_THROUGH && (status_cnt_q == 0) && push_i) begin
      data_o = data_i;
      if (pop_i) begin
        status_cnt_n = status_cnt_q;
        read_pointer_n = read_pointer_q;
        write_pointer_n = write_pointer_q;
      end
    end
  end

  // sequential process
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      read_pointer_q  <= '0;
      write_pointer_q <= '0;
      status_cnt_q    <= '0;
    end else begin
      unique case (1'b1)
        // Flush the FIFO
        flush_i: begin
          read_pointer_q  <= '0;
          write_pointer_q <= '0;
          status_cnt_q    <= '0;
        end
        // Flush the FIFO but keep the first instruction alive if present
        flush_but_first_i: begin
          read_pointer_q  <= (status_cnt_q > 0) ? read_pointer_q : '0;
          write_pointer_q <= (status_cnt_q > 0) ? read_pointer_q + 1 : '0;
          status_cnt_q    <= (status_cnt_q > 0) ? 1'b1 : '0;
        end
        // If we are not flushing, update the pointers
        default: begin
          read_pointer_q  <= read_pointer_n;
          write_pointer_q <= write_pointer_n;
          status_cnt_q    <= status_cnt_n;
        end
      endcase
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      mem_q <= '0;
    end else if (!gate_clock) begin
      mem_q <= mem_n;
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Assertions
  //////////////////////////////////////////////////////////////////////////////

`ifdef CV32E40P_ASSERT_ON

  initial begin
    assert (DEPTH > 0)
    else $error("DEPTH must be greater than 0.");
  end

  full_write :
  assert property (@(posedge clk_i) disable iff (~rst_ni) (full_o |-> ~push_i))
  else $fatal(1, "Trying to push new data although the FIFO is full.");

  empty_read :
  assert property (@(posedge clk_i) disable iff (~rst_ni) (empty_o |-> ~pop_i))
  else $fatal(1, "Trying to pop data although the FIFO is empty.");
`endif

endmodule  // cv32e40p_fifo

// -------------------- END OF rtl/cv32e40p_fifo.sv --------------------

// -------------------- START OF rtl/cv32e40p_hwloop_regs.sv --------------------
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
// Engineer:       Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    hwloop regs                                                //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Hardware loop registers                                    //
//                 a) store start/end address of N=4 hardware loops           //
//                 b) store init value of counter for each hardware loop      //
//                 c) decrement counter if hwloop taken                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_hwloop_regs #(
    parameter N_REGS     = 2,
    parameter N_REG_BITS = $clog2(N_REGS)
) (
    input logic clk,
    input logic rst_n,

    // from ex stage
    input logic [          31:0] hwlp_start_data_i,
    input logic [          31:0] hwlp_end_data_i,
    input logic [          31:0] hwlp_cnt_data_i,
    input logic [           2:0] hwlp_we_i,
    input logic [N_REG_BITS-1:0] hwlp_regid_i,  // selects the register set

    // from controller
    input logic valid_i,

    // from hwloop controller
    input logic [N_REGS-1:0] hwlp_dec_cnt_i,

    // to hwloop controller
    output logic [N_REGS-1:0][31:0] hwlp_start_addr_o,
    output logic [N_REGS-1:0][31:0] hwlp_end_addr_o,
    output logic [N_REGS-1:0][31:0] hwlp_counter_o
);


  logic [N_REGS-1:0][31:0] hwlp_start_q;
  logic [N_REGS-1:0][31:0] hwlp_end_q;
  logic [N_REGS-1:0][31:0] hwlp_counter_q, hwlp_counter_n;

  int unsigned i;


  assign hwlp_start_addr_o = hwlp_start_q;
  assign hwlp_end_addr_o   = hwlp_end_q;
  assign hwlp_counter_o    = hwlp_counter_q;


  /////////////////////////////////////////////////////////////////////////////////
  // HWLOOP start-address register                                               //
  /////////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin : HWLOOP_REGS_START
    if (rst_n == 1'b0) begin
      hwlp_start_q <= '{default: 32'b0};
    end else if (hwlp_we_i[0] == 1'b1) begin
      hwlp_start_q[hwlp_regid_i] <= {hwlp_start_data_i[31:2], 2'b0};
    end
  end


  /////////////////////////////////////////////////////////////////////////////////
  // HWLOOP end-address register                                                 //
  /////////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin : HWLOOP_REGS_END
    if (rst_n == 1'b0) begin
      hwlp_end_q <= '{default: 32'b0};
    end else if (hwlp_we_i[1] == 1'b1) begin
      hwlp_end_q[hwlp_regid_i] <= {hwlp_end_data_i[31:2], 2'b0};
    end
  end


  /////////////////////////////////////////////////////////////////////////////////
  // HWLOOP counter register with decrement logic                                //
  /////////////////////////////////////////////////////////////////////////////////
  genvar k;
  for (k = 0; k < N_REGS; k++) begin
    assign hwlp_counter_n[k] = hwlp_counter_q[k] - 1;
  end

  always_ff @(posedge clk, negedge rst_n) begin : HWLOOP_REGS_COUNTER
    if (rst_n == 1'b0) begin
      hwlp_counter_q <= '{default: 32'b0};
    end else begin
      for (i = 0; i < N_REGS; i++) begin
        if ((hwlp_we_i[2] == 1'b1) && (i == hwlp_regid_i)) begin
          hwlp_counter_q[i] <= hwlp_cnt_data_i;
        end else begin
          if (hwlp_dec_cnt_i[i] && valid_i) hwlp_counter_q[i] <= hwlp_counter_n[i];
        end
      end
    end
  end

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------
`ifdef CV32E40P_ASSERT_ON
  // do not decrement more than one counter at once
  assert property (@(posedge clk) (valid_i) |-> ($countones(hwlp_dec_cnt_i) <= 1));
`endif
endmodule

// -------------------- END OF rtl/cv32e40p_hwloop_regs.sv --------------------

// -------------------- START OF rtl/cv32e40p_id_stage.sv --------------------
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
// Engineer:       Renzo Andri - andrire@student.ethz.ch                      //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Instruction Decode Stage                                   //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decode stage of the core. It decodes the instructions      //
//                 and hosts the register file.                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_id_stage
  import cv32e40p_pkg::*;
  import cv32e40p_apu_core_pkg::*;
#(
    parameter COREV_PULP =  1,  // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding cv.elw)
    parameter COREV_CLUSTER = 0,
    parameter N_HWLP = 2,
    parameter N_HWLP_BITS = $clog2(N_HWLP),
    parameter PULP_SECURE = 0,
    parameter USE_PMP = 0,
    parameter A_EXTENSION = 0,
    parameter APU = 0,
    parameter FPU = 0,
    parameter FPU_ADDMUL_LAT = 0,
    parameter FPU_OTHERS_LAT = 0,
    parameter ZFINX = 0,
    parameter APU_NARGS_CPU = 3,
    parameter APU_WOP_CPU = 6,
    parameter APU_NDSFLAGS_CPU = 15,
    parameter APU_NUSFLAGS_CPU = 5,
    parameter DEBUG_TRIGGER_EN = 1
) (
    input logic clk,  // Gated clock
    input logic clk_ungated_i,  // Ungated clock
    input logic rst_n,

    input logic scan_cg_en_i,

    input  logic fetch_enable_i,
    output logic ctrl_busy_o,
    output logic is_decoding_o,

    // Interface to IF stage
    input  logic        instr_valid_i,
    input  logic [31:0] instr_rdata_i,  // comes from pipeline of IF stage
    output logic        instr_req_o,
    input  logic        is_compressed_i,
    input  logic        illegal_c_insn_i,

    // Jumps and branches
    output logic        branch_in_ex_o,
    input  logic        branch_decision_i,
    output logic [31:0] jump_target_o,
    output logic [ 1:0] ctrl_transfer_insn_in_dec_o,

    // IF and ID stage signals
    output logic       clear_instr_valid_o,
    output logic       pc_set_o,
    output logic [3:0] pc_mux_o,
    output logic [2:0] exc_pc_mux_o,
    output logic [1:0] trap_addr_mux_o,


    input logic is_fetch_failed_i,

    input logic [31:0] pc_id_i,

    // Stalls
    output logic halt_if_o,  // controller requests a halt of the IF stage

    output logic id_ready_o,  // ID stage is ready for the next instruction
    input  logic ex_ready_i,  // EX stage is ready for the next instruction
    input  logic wb_ready_i,  // WB stage is ready for the next instruction

    output logic id_valid_o,  // ID stage is done
    input  logic ex_valid_i,  // EX stage is done

    // Pipeline ID/EX
    output logic [31:0] pc_ex_o,

    output logic [31:0] alu_operand_a_ex_o,
    output logic [31:0] alu_operand_b_ex_o,
    output logic [31:0] alu_operand_c_ex_o,
    output logic [ 4:0] bmask_a_ex_o,
    output logic [ 4:0] bmask_b_ex_o,
    output logic [ 1:0] imm_vec_ext_ex_o,
    output logic [ 1:0] alu_vec_mode_ex_o,

    output logic [5:0] regfile_waddr_ex_o,
    output logic       regfile_we_ex_o,

    output logic [5:0] regfile_alu_waddr_ex_o,
    output logic       regfile_alu_we_ex_o,

    // ALU
    output logic              alu_en_ex_o,
    output alu_opcode_e       alu_operator_ex_o,
    output logic              alu_is_clpx_ex_o,
    output logic              alu_is_subrot_ex_o,
    output logic        [1:0] alu_clpx_shift_ex_o,

    // MUL
    output mul_opcode_e        mult_operator_ex_o,
    output logic        [31:0] mult_operand_a_ex_o,
    output logic        [31:0] mult_operand_b_ex_o,
    output logic        [31:0] mult_operand_c_ex_o,
    output logic               mult_en_ex_o,
    output logic               mult_sel_subword_ex_o,
    output logic        [ 1:0] mult_signed_mode_ex_o,
    output logic        [ 4:0] mult_imm_ex_o,

    output logic [31:0] mult_dot_op_a_ex_o,
    output logic [31:0] mult_dot_op_b_ex_o,
    output logic [31:0] mult_dot_op_c_ex_o,
    output logic [ 1:0] mult_dot_signed_ex_o,
    output logic        mult_is_clpx_ex_o,
    output logic [ 1:0] mult_clpx_shift_ex_o,
    output logic        mult_clpx_img_ex_o,

    // APU
    output logic                              apu_en_ex_o,
    output logic [     APU_WOP_CPU-1:0]       apu_op_ex_o,
    output logic [                 1:0]       apu_lat_ex_o,
    output logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_ex_o,
    output logic [APU_NDSFLAGS_CPU-1:0]       apu_flags_ex_o,
    output logic [                 5:0]       apu_waddr_ex_o,

    output logic [2:0][5:0] apu_read_regs_o,
    output logic [2:0]      apu_read_regs_valid_o,
    input  logic            apu_read_dep_i,
    input  logic            apu_read_dep_for_jalr_i,
    output logic [1:0][5:0] apu_write_regs_o,
    output logic [1:0]      apu_write_regs_valid_o,
    input  logic            apu_write_dep_i,
    output logic            apu_perf_dep_o,
    input  logic            apu_busy_i,

    input logic            fs_off_i,
    input logic [C_RM-1:0] frm_i,

    // CSR ID/EX
    output logic              csr_access_ex_o,
    output csr_opcode_e       csr_op_ex_o,
    input  PrivLvl_t          current_priv_lvl_i,
    output logic              csr_irq_sec_o,
    output logic        [5:0] csr_cause_o,
    output logic              csr_save_if_o,
    output logic              csr_save_id_o,
    output logic              csr_save_ex_o,
    output logic              csr_restore_mret_id_o,
    output logic              csr_restore_uret_id_o,
    output logic              csr_restore_dret_id_o,
    output logic              csr_save_cause_o,

    // hwloop signals
    output logic [N_HWLP-1:0][31:0] hwlp_start_o,
    output logic [N_HWLP-1:0][31:0] hwlp_end_o,
    output logic [N_HWLP-1:0][31:0] hwlp_cnt_o,
    output logic                    hwlp_jump_o,
    output logic [      31:0]       hwlp_target_o,

    // Interface to load store unit
    output logic       data_req_ex_o,
    output logic       data_we_ex_o,
    output logic [1:0] data_type_ex_o,
    output logic [1:0] data_sign_ext_ex_o,
    output logic [1:0] data_reg_offset_ex_o,
    output logic       data_load_event_ex_o,

    output logic data_misaligned_ex_o,

    output logic prepost_useincr_ex_o,
    input  logic data_misaligned_i,
    input  logic data_err_i,
    output logic data_err_ack_o,

    output logic [5:0] atop_ex_o,

    // Interrupt signals
    input  logic [31:0] irq_i,
    input  logic        irq_sec_i,
    input  logic [31:0] mie_bypass_i,  // MIE CSR (bypass)
    output logic [31:0] mip_o,  // MIP CSR
    input  logic        m_irq_enable_i,
    input  logic        u_irq_enable_i,
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o,
    output logic [ 4:0] exc_cause_o,

    // Debug Signal
    output logic       debug_mode_o,
    output logic [2:0] debug_cause_o,
    output logic       debug_csr_save_o,
    input  logic       debug_req_i,
    input  logic       debug_single_step_i,
    input  logic       debug_ebreakm_i,
    input  logic       debug_ebreaku_i,
    input  logic       trigger_match_i,
    output logic       debug_p_elw_no_sleep_o,
    output logic       debug_havereset_o,
    output logic       debug_running_o,
    output logic       debug_halted_o,

    // Wakeup Signal
    output logic wake_from_sleep_o,

    // Forward Signals
    input logic [5:0] regfile_waddr_wb_i,
    input logic regfile_we_wb_i,
    input logic regfile_we_wb_power_i,
    input  logic [31:0] regfile_wdata_wb_i, // From wb_stage: selects data from data memory, ex_stage result and sp rdata

    input logic [ 5:0] regfile_alu_waddr_fw_i,
    input logic        regfile_alu_we_fw_i,
    input logic        regfile_alu_we_fw_power_i,
    input logic [31:0] regfile_alu_wdata_fw_i,

    // from ALU
    input  logic        mult_multicycle_i,    // when we need multiple cycles in the multiplier and use op c as storage

    // Performance Counters
    output logic mhpmevent_minstret_o,
    output logic mhpmevent_load_o,
    output logic mhpmevent_store_o,
    output logic mhpmevent_jump_o,
    output logic mhpmevent_branch_o,
    output logic mhpmevent_branch_taken_o,
    output logic mhpmevent_compressed_o,
    output logic mhpmevent_jr_stall_o,
    output logic mhpmevent_imiss_o,
    output logic mhpmevent_ld_stall_o,
    output logic mhpmevent_pipe_stall_o,

    input logic        perf_imiss_i,
    input logic [31:0] mcounteren_i
);

  // Source/Destination register instruction index
  localparam REG_S1_MSB = 19;
  localparam REG_S1_LSB = 15;

  localparam REG_S2_MSB = 24;
  localparam REG_S2_LSB = 20;

  localparam REG_S4_MSB = 31;
  localparam REG_S4_LSB = 27;

  localparam REG_D_MSB = 11;
  localparam REG_D_LSB = 7;

  logic [31:0] instr;


  // Decoder/Controller ID stage internal signals
  logic        deassert_we;

  logic        illegal_insn_dec;
  logic        ebrk_insn_dec;
  logic        mret_insn_dec;
  logic        uret_insn_dec;

  logic        dret_insn_dec;

  logic        ecall_insn_dec;
  logic        wfi_insn_dec;

  logic        fencei_insn_dec;

  logic        rega_used_dec;
  logic        regb_used_dec;
  logic        regc_used_dec;

  logic        branch_taken_ex;
  logic [ 1:0] ctrl_transfer_insn_in_id;
  logic [ 1:0] ctrl_transfer_insn_in_dec;

  logic        misaligned_stall;
  logic        jr_stall;
  logic        load_stall;
  logic        csr_apu_stall;
  logic        hwlp_mask;
  logic        halt_id;
  logic        halt_if;

  logic        debug_wfi_no_sleep;

  // Immediate decoding and sign extension
  logic [31:0] imm_i_type;
  logic [31:0] imm_iz_type;
  logic [31:0] imm_s_type;
  logic [31:0] imm_sb_type;
  logic [31:0] imm_u_type;
  logic [31:0] imm_uj_type;
  logic [31:0] imm_z_type;
  logic [31:0] imm_s2_type;
  logic [31:0] imm_bi_type;
  logic [31:0] imm_s3_type;
  logic [31:0] imm_vs_type;
  logic [31:0] imm_vu_type;
  logic [31:0] imm_shuffleb_type;
  logic [31:0] imm_shuffleh_type;
  logic [31:0] imm_shuffle_type;
  logic [31:0] imm_clip_type;

  logic [31:0] imm_a;  // contains the immediate for operand b
  logic [31:0] imm_b;  // contains the immediate for operand b

  logic [31:0] jump_target;  // calculated jump target (-> EX -> IF)

  // Signals running between controller and int_controller
  logic        irq_req_ctrl;
  logic        irq_sec_ctrl;
  logic        irq_wu_ctrl;
  logic [ 4:0] irq_id_ctrl;

  // Register file interface
  logic [ 5:0] regfile_addr_ra_id;
  logic [ 5:0] regfile_addr_rb_id;
  logic [ 5:0] regfile_addr_rc_id;

  logic        regfile_fp_a;
  logic        regfile_fp_b;
  logic        regfile_fp_c;
  logic        regfile_fp_d;

  logic [ 5:0] regfile_waddr_id;
  logic [ 5:0] regfile_alu_waddr_id;
  logic regfile_alu_we_id, regfile_alu_we_dec_id;

  logic [31:0] regfile_data_ra_id;
  logic [31:0] regfile_data_rb_id;
  logic [31:0] regfile_data_rc_id;

  // ALU Control
  logic alu_en;
  alu_opcode_e alu_operator;
  logic [2:0] alu_op_a_mux_sel;
  logic [2:0] alu_op_b_mux_sel;
  logic [1:0] alu_op_c_mux_sel;
  logic [1:0] regc_mux;

  logic [0:0] imm_a_mux_sel;
  logic [3:0] imm_b_mux_sel;
  logic [1:0] ctrl_transfer_target_mux_sel;

  // Multiplier Control
  mul_opcode_e mult_operator;  // multiplication operation selection
  logic mult_en;  // multiplication is used instead of ALU
  logic mult_int_en;  // use integer multiplier
  logic mult_sel_subword;  // Select a subword when doing multiplications
  logic [1:0]  mult_signed_mode; // Signed mode multiplication at the output of the controller, and before the pipe registers
  logic mult_dot_en;  // use dot product
  logic [1:0] mult_dot_signed;  // Signed mode dot products (can be mixed types)

  // FPU signals
  logic [cv32e40p_fpu_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt;
  logic [cv32e40p_fpu_pkg::FP_FORMAT_BITS-1:0] fpu_dst_fmt;
  logic [cv32e40p_fpu_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt;

  // APU signals
  logic apu_en;
  logic [APU_WOP_CPU-1:0] apu_op;
  logic [1:0] apu_lat;
  logic [APU_NARGS_CPU-1:0][31:0] apu_operands;
  logic [APU_NDSFLAGS_CPU-1:0] apu_flags;
  logic [5:0] apu_waddr;

  logic [2:0][5:0] apu_read_regs;
  logic [2:0] apu_read_regs_valid;
  logic [1:0][5:0] apu_write_regs;
  logic [1:0] apu_write_regs_valid;

  logic apu_stall;
  logic [2:0] fp_rnd_mode;

  // Register Write Control
  logic regfile_we_id;
  logic regfile_alu_waddr_mux_sel;

  // Data Memory Control
  logic data_we_id;
  logic [1:0] data_type_id;
  logic [1:0] data_sign_ext_id;
  logic [1:0] data_reg_offset_id;
  logic data_req_id;
  logic data_load_event_id;

  // Atomic memory instruction
  logic [5:0] atop_id;

  // hwloop signals
  logic [N_HWLP_BITS-1:0] hwlp_regid;
  logic [2:0] hwlp_we, hwlp_we_masked;
  logic        [       1:0] hwlp_target_mux_sel;
  logic        [       1:0] hwlp_start_mux_sel;
  logic                     hwlp_cnt_mux_sel;

  logic        [      31:0] hwlp_start;
  logic        [      31:0] hwlp_end;
  logic        [      31:0] hwlp_cnt;
  logic        [N_HWLP-1:0] hwlp_dec_cnt;
  logic                     hwlp_valid;

  // CSR control
  logic                     csr_access;
  csr_opcode_e              csr_op;
  logic                     csr_status;

  logic                     prepost_useincr;

  // Forwarding
  logic        [       1:0] operand_a_fw_mux_sel;
  logic        [       1:0] operand_b_fw_mux_sel;
  logic        [       1:0] operand_c_fw_mux_sel;
  logic        [      31:0] operand_a_fw_id;
  logic        [      31:0] operand_b_fw_id;
  logic        [      31:0] operand_c_fw_id;

  logic [31:0] operand_b, operand_b_vec;
  logic [31:0] operand_c, operand_c_vec;

  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;
  logic [31:0] alu_operand_c;

  // Immediates for ID
  logic [ 0:0] bmask_a_mux;
  logic [ 1:0] bmask_b_mux;
  logic        alu_bmask_a_mux_sel;
  logic        alu_bmask_b_mux_sel;
  logic [ 0:0] mult_imm_mux;

  logic [ 4:0] bmask_a_id_imm;
  logic [ 4:0] bmask_b_id_imm;
  logic [ 4:0] bmask_a_id;
  logic [ 4:0] bmask_b_id;
  logic [ 1:0] imm_vec_ext_id;
  logic [ 4:0] mult_imm_id;

  logic        alu_vec;
  logic [ 1:0] alu_vec_mode;
  logic        scalar_replication;
  logic        scalar_replication_c;

  // Forwarding detection signals
  logic        reg_d_ex_is_reg_a_id;
  logic        reg_d_ex_is_reg_b_id;
  logic        reg_d_ex_is_reg_c_id;
  logic        reg_d_wb_is_reg_a_id;
  logic        reg_d_wb_is_reg_b_id;
  logic        reg_d_wb_is_reg_c_id;
  logic        reg_d_alu_is_reg_a_id;
  logic        reg_d_alu_is_reg_b_id;
  logic        reg_d_alu_is_reg_c_id;

  logic is_clpx, is_subrot;

  logic mret_dec;
  logic uret_dec;
  logic dret_dec;

  // Performance counters
  logic id_valid_q;
  logic minstret;
  logic perf_pipeline_stall;

  assign instr = instr_rdata_i;


  // immediate extraction and sign extension
  assign imm_i_type = {{20{instr[31]}}, instr[31:20]};
  assign imm_iz_type = {20'b0, instr[31:20]};
  assign imm_s_type = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  assign imm_sb_type = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_u_type = {instr[31:12], 12'b0};
  assign imm_uj_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  // immediate for CSR manipulatin (zero extended)
  assign imm_z_type = {27'b0, instr[REG_S1_MSB:REG_S1_LSB]};

  assign imm_s2_type = {27'b0, instr[24:20]};
  assign imm_bi_type = {{27{instr[24]}}, instr[24:20]};
  assign imm_s3_type = {27'b0, instr[29:25]};
  assign imm_vs_type = {{26{instr[24]}}, instr[24:20], instr[25]};
  assign imm_vu_type = {26'b0, instr[24:20], instr[25]};

  // same format as rS2 for shuffle needs, expands immediate
  assign imm_shuffleb_type = {
    6'b0, instr[28:27], 6'b0, instr[24:23], 6'b0, instr[22:21], 6'b0, instr[20], instr[25]
  };
  assign imm_shuffleh_type = {15'h0, instr[20], 15'h0, instr[25]};

  // clipping immediate, uses a small barrel shifter to pre-process the
  // immediate and an adder to subtract 1
  // The end result is a mask that has 1's set in the lower part
  assign imm_clip_type = (32'h1 << instr[24:20]) - 1;

  //---------------------------------------------------------------------------
  // source register selection regfile_fp_x=1 <=> CV32E40P_REG_x is a FP-register
  //---------------------------------------------------------------------------
  assign regfile_addr_ra_id = {regfile_fp_a, instr[REG_S1_MSB:REG_S1_LSB]};
  assign regfile_addr_rb_id = {regfile_fp_b, instr[REG_S2_MSB:REG_S2_LSB]};

  // register C mux
  always_comb begin
    unique case (regc_mux)
      REGC_ZERO: regfile_addr_rc_id = '0;
      REGC_RD:   regfile_addr_rc_id = {regfile_fp_c, instr[REG_D_MSB:REG_D_LSB]};
      REGC_S1:   regfile_addr_rc_id = {regfile_fp_c, instr[REG_S1_MSB:REG_S1_LSB]};
      REGC_S4:   regfile_addr_rc_id = {regfile_fp_c, instr[REG_S4_MSB:REG_S4_LSB]};
    endcase
  end

  //---------------------------------------------------------------------------
  // destination registers regfile_fp_d=1 <=> REG_D is a FP-register
  //---------------------------------------------------------------------------
  assign regfile_waddr_id = {regfile_fp_d, instr[REG_D_MSB:REG_D_LSB]};

  // Second Register Write Address Selection
  // Used for prepost load/store and multiplier
  assign regfile_alu_waddr_id = regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id;

  // Forwarding control signals
  assign reg_d_ex_is_reg_a_id  = (regfile_waddr_ex_o     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_ex_is_reg_b_id  = (regfile_waddr_ex_o     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_ex_is_reg_c_id  = (regfile_waddr_ex_o     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_wb_is_reg_a_id  = (regfile_waddr_wb_i     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_wb_is_reg_b_id  = (regfile_waddr_wb_i     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_wb_is_reg_c_id  = (regfile_waddr_wb_i     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_alu_is_reg_a_id = (regfile_alu_waddr_fw_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_alu_is_reg_b_id = (regfile_alu_waddr_fw_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_alu_is_reg_c_id = (regfile_alu_waddr_fw_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);


  // kill instruction in the IF/ID stage by setting the instr_valid_id control
  // signal to 0 for instructions that are done
  assign clear_instr_valid_o = id_ready_o | halt_id | branch_taken_ex;

  assign branch_taken_ex = branch_in_ex_o && branch_decision_i;


  assign mult_en = mult_int_en | mult_dot_en;


  //////////////////////////////////////////////////////////////////
  //      _                         _____                    _    //
  //     | |_   _ _ __ ___  _ __   |_   _|_ _ _ __ __ _  ___| |_  //
  //  _  | | | | | '_ ` _ \| '_ \    | |/ _` | '__/ _` |/ _ \ __| //
  // | |_| | |_| | | | | | | |_) |   | | (_| | | | (_| |  __/ |_  //
  //  \___/ \__,_|_| |_| |_| .__/    |_|\__,_|_|  \__, |\___|\__| //
  //                       |_|                    |___/           //
  //////////////////////////////////////////////////////////////////

  always_comb begin : jump_target_mux
    unique case (ctrl_transfer_target_mux_sel)
      JT_JAL:  jump_target = pc_id_i + imm_uj_type;
      JT_COND: jump_target = pc_id_i + imm_sb_type;

      // JALR: Cannot forward RS1, since the path is too long
      JT_JALR: jump_target = regfile_data_ra_id + imm_i_type;
      default: jump_target = regfile_data_ra_id + imm_i_type;
    endcase
  end

  assign jump_target_o = jump_target;


  ////////////////////////////////////////////////////////
  //   ___                                 _      _     //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| |    / \    //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` |   / _ \   //
  // | |_| | |_) |  __/ | | (_| | | | | (_| |  / ___ \  //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_| /_/   \_\ //
  //       |_|                                          //
  ////////////////////////////////////////////////////////

  // ALU_Op_a Mux
  always_comb begin : alu_operand_a_mux
    case (alu_op_a_mux_sel)
      OP_A_REGA_OR_FWD: alu_operand_a = operand_a_fw_id;
      OP_A_REGB_OR_FWD: alu_operand_a = operand_b_fw_id;
      OP_A_REGC_OR_FWD: alu_operand_a = operand_c_fw_id;
      OP_A_CURRPC:      alu_operand_a = pc_id_i;
      OP_A_IMM:         alu_operand_a = imm_a;
      default:          alu_operand_a = operand_a_fw_id;
    endcase
    ;  // case (alu_op_a_mux_sel)
  end

  always_comb begin : immediate_a_mux
    unique case (imm_a_mux_sel)
      IMMA_Z:    imm_a = imm_z_type;
      IMMA_ZERO: imm_a = '0;
    endcase
  end

  // Operand a forwarding mux
  always_comb begin : operand_a_fw_mux
    case (operand_a_fw_mux_sel)
      SEL_FW_EX:   operand_a_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_a_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_a_fw_id = regfile_data_ra_id;
      default:     operand_a_fw_id = regfile_data_ra_id;
    endcase
    ;  // case (operand_a_fw_mux_sel)
  end

  //////////////////////////////////////////////////////
  //   ___                                 _   ____   //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| | | __ )  //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` | |  _ \  //
  // | |_| | |_) |  __/ | | (_| | | | | (_| | | |_) | //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_| |____/  //
  //       |_|                                        //
  //////////////////////////////////////////////////////

  // Immediate Mux for operand B
  always_comb begin : immediate_b_mux
    unique case (imm_b_mux_sel)
      IMMB_I:      imm_b = imm_i_type;
      IMMB_S:      imm_b = imm_s_type;
      IMMB_U:      imm_b = imm_u_type;
      IMMB_PCINCR: imm_b = is_compressed_i ? 32'h2 : 32'h4;
      IMMB_S2:     imm_b = imm_s2_type;
      IMMB_BI:     imm_b = imm_bi_type;
      IMMB_S3:     imm_b = imm_s3_type;
      IMMB_VS:     imm_b = imm_vs_type;
      IMMB_VU:     imm_b = imm_vu_type;
      IMMB_SHUF:   imm_b = imm_shuffle_type;
      IMMB_CLIP:   imm_b = {1'b0, imm_clip_type[31:1]};
      default:     imm_b = imm_i_type;
    endcase
  end

  // ALU_Op_b Mux
  always_comb begin : alu_operand_b_mux
    case (alu_op_b_mux_sel)
      OP_B_REGA_OR_FWD: operand_b = operand_a_fw_id;
      OP_B_REGB_OR_FWD: operand_b = operand_b_fw_id;
      OP_B_REGC_OR_FWD: operand_b = operand_c_fw_id;
      OP_B_IMM:         operand_b = imm_b;
      OP_B_BMASK:       operand_b = $unsigned(operand_b_fw_id[4:0]);
      default:          operand_b = operand_b_fw_id;
    endcase  // case (alu_op_b_mux_sel)
  end


  // scalar replication for operand B and shuffle type
  always_comb begin
    if (alu_vec_mode == VEC_MODE8) begin
      operand_b_vec    = {4{operand_b[7:0]}};
      imm_shuffle_type = imm_shuffleb_type;
    end else begin
      operand_b_vec    = {2{operand_b[15:0]}};
      imm_shuffle_type = imm_shuffleh_type;
    end
  end

  // choose normal or scalar replicated version of operand b
  assign alu_operand_b = (scalar_replication == 1'b1) ? operand_b_vec : operand_b;


  // Operand b forwarding mux
  always_comb begin : operand_b_fw_mux
    case (operand_b_fw_mux_sel)
      SEL_FW_EX:   operand_b_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_b_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_b_fw_id = regfile_data_rb_id;
      default:     operand_b_fw_id = regfile_data_rb_id;
    endcase
    ;  // case (operand_b_fw_mux_sel)
  end


  //////////////////////////////////////////////////////
  //   ___                                 _    ____  //
  //  / _ \ _ __   ___ _ __ __ _ _ __   __| |  / ___| //
  // | | | | '_ \ / _ \ '__/ _` | '_ \ / _` | | |     //
  // | |_| | |_) |  __/ | | (_| | | | | (_| | | |___  //
  //  \___/| .__/ \___|_|  \__,_|_| |_|\__,_|  \____| //
  //       |_|                                        //
  //////////////////////////////////////////////////////

  // ALU OP C Mux
  always_comb begin : alu_operand_c_mux
    case (alu_op_c_mux_sel)
      OP_C_REGC_OR_FWD: operand_c = operand_c_fw_id;
      OP_C_REGB_OR_FWD: operand_c = operand_b_fw_id;
      OP_C_JT:          operand_c = jump_target;
      default:          operand_c = operand_c_fw_id;
    endcase  // case (alu_op_c_mux_sel)
  end


  // scalar replication for operand C and shuffle type
  always_comb begin
    if (alu_vec_mode == VEC_MODE8) begin
      operand_c_vec = {4{operand_c[7:0]}};
    end else begin
      operand_c_vec = {2{operand_c[15:0]}};
    end
  end

  // choose normal or scalar replicated version of operand b
  assign alu_operand_c = (scalar_replication_c == 1'b1) ? operand_c_vec : operand_c;


  // Operand c forwarding mux
  always_comb begin : operand_c_fw_mux
    case (operand_c_fw_mux_sel)
      SEL_FW_EX:   operand_c_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_c_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_c_fw_id = regfile_data_rc_id;
      default:     operand_c_fw_id = regfile_data_rc_id;
    endcase
    ;  // case (operand_c_fw_mux_sel)
  end


  ///////////////////////////////////////////////////////////////////////////
  //  ___                              _ _       _              ___ ____   //
  // |_ _|_ __ ___  _ __ ___   ___  __| (_) __ _| |_ ___  ___  |_ _|  _ \  //
  //  | || '_ ` _ \| '_ ` _ \ / _ \/ _` | |/ _` | __/ _ \/ __|  | || | | | //
  //  | || | | | | | | | | | |  __/ (_| | | (_| | ||  __/\__ \  | || |_| | //
  // |___|_| |_| |_|_| |_| |_|\___|\__,_|_|\__,_|\__\___||___/ |___|____/  //
  //                                                                       //
  ///////////////////////////////////////////////////////////////////////////

  always_comb begin
    unique case (bmask_a_mux)
      BMASK_A_ZERO: bmask_a_id_imm = '0;
      BMASK_A_S3:   bmask_a_id_imm = imm_s3_type[4:0];
    endcase
  end
  always_comb begin
    unique case (bmask_b_mux)
      BMASK_B_ZERO: bmask_b_id_imm = '0;
      BMASK_B_ONE:  bmask_b_id_imm = 5'd1;
      BMASK_B_S2:   bmask_b_id_imm = imm_s2_type[4:0];
      BMASK_B_S3:   bmask_b_id_imm = imm_s3_type[4:0];
    endcase
  end

  always_comb begin
    unique case (alu_bmask_a_mux_sel)
      BMASK_A_IMM: bmask_a_id = bmask_a_id_imm;
      BMASK_A_REG: bmask_a_id = operand_b_fw_id[9:5];
    endcase
  end
  always_comb begin
    unique case (alu_bmask_b_mux_sel)
      BMASK_B_IMM: bmask_b_id = bmask_b_id_imm;
      BMASK_B_REG: bmask_b_id = operand_b_fw_id[4:0];
    endcase
  end

  generate
    if (!COREV_PULP) begin
      assign imm_vec_ext_id = imm_vu_type[1:0];
    end else begin
      assign imm_vec_ext_id = (alu_vec) ? imm_vu_type[1:0] : 2'b0;
    end
  endgenerate

  always_comb begin
    unique case (mult_imm_mux)
      MIMM_ZERO: mult_imm_id = '0;
      MIMM_S3:   mult_imm_id = imm_s3_type[4:0];
    endcase
  end

  /////////////////////////////
  // APU operand assignment  //
  /////////////////////////////
  // read regs
  generate
    if (APU == 1) begin : gen_apu

      if (APU_NARGS_CPU >= 1) assign apu_operands[0] = alu_operand_a;
      if (APU_NARGS_CPU >= 2) assign apu_operands[1] = alu_operand_b;
      if (APU_NARGS_CPU >= 3) assign apu_operands[2] = alu_operand_c;

      // write reg
      assign apu_waddr = regfile_alu_waddr_id;

      // flags
      assign apu_flags = (FPU == 1) ? {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} : '0;

      // dependency checks
      always_comb begin
        unique case (alu_op_a_mux_sel)
          OP_A_CURRPC: begin
            if (ctrl_transfer_target_mux_sel == JT_JALR) begin
              apu_read_regs[0]       = regfile_addr_ra_id;
              apu_read_regs_valid[0] = 1'b1;
            end else begin
              apu_read_regs[0]       = regfile_addr_ra_id;
              apu_read_regs_valid[0] = 1'b0;
            end
          end  // OP_A_CURRPC:
          OP_A_REGA_OR_FWD: begin
            apu_read_regs[0]       = regfile_addr_ra_id;
            apu_read_regs_valid[0] = 1'b1;
          end  // OP_A_REGA_OR_FWD:
          OP_A_REGB_OR_FWD, OP_A_REGC_OR_FWD: begin
            apu_read_regs[0]       = regfile_addr_rb_id;
            apu_read_regs_valid[0] = 1'b1;
          end
          default: begin
            apu_read_regs[0]       = regfile_addr_ra_id;
            apu_read_regs_valid[0] = 1'b0;
          end
        endcase
      end

      always_comb begin
        unique case (alu_op_b_mux_sel)
          OP_B_REGA_OR_FWD: begin
            apu_read_regs[1]       = regfile_addr_ra_id;
            apu_read_regs_valid[1] = 1'b1;
          end
          OP_B_REGB_OR_FWD, OP_B_BMASK: begin
            apu_read_regs[1]       = regfile_addr_rb_id;
            apu_read_regs_valid[1] = 1'b1;
          end
          OP_B_REGC_OR_FWD: begin
            apu_read_regs[1]       = regfile_addr_rc_id;
            apu_read_regs_valid[1] = 1'b1;
          end
          OP_B_IMM: begin
            if (alu_bmask_b_mux_sel == BMASK_B_REG) begin
              apu_read_regs[1]       = regfile_addr_rb_id;
              apu_read_regs_valid[1] = 1'b1;
            end else begin
              apu_read_regs[1]       = regfile_addr_rb_id;
              apu_read_regs_valid[1] = 1'b0;
            end
          end
          default: begin
            apu_read_regs[1]       = regfile_addr_rb_id;
            apu_read_regs_valid[1] = 1'b0;
          end
        endcase
      end

      always_comb begin
        unique case (alu_op_c_mux_sel)
          OP_C_REGB_OR_FWD: begin
            apu_read_regs[2]       = regfile_addr_rb_id;
            apu_read_regs_valid[2] = 1'b1;
          end
          OP_C_REGC_OR_FWD: begin
            if ((alu_op_a_mux_sel != OP_A_REGC_OR_FWD) && (ctrl_transfer_target_mux_sel != JT_JALR) &&
                !((alu_op_b_mux_sel == OP_B_IMM) && (alu_bmask_b_mux_sel == BMASK_B_REG)) &&
                !(alu_op_b_mux_sel == OP_B_BMASK)) begin
              apu_read_regs[2]       = regfile_addr_rc_id;
              apu_read_regs_valid[2] = 1'b1;
            end else begin
              apu_read_regs[2]       = regfile_addr_rc_id;
              apu_read_regs_valid[2] = 1'b0;
            end
          end
          default: begin
            apu_read_regs[2]       = regfile_addr_rc_id;
            apu_read_regs_valid[2] = 1'b0;
          end
        endcase
      end

      assign apu_write_regs[0]       = regfile_alu_waddr_id;
      assign apu_write_regs_valid[0] = regfile_alu_we_id;

      assign apu_write_regs[1]       = regfile_waddr_id;
      assign apu_write_regs_valid[1] = regfile_we_id;

      assign apu_read_regs_o         = apu_read_regs;
      assign apu_read_regs_valid_o   = apu_read_regs_valid;

      assign apu_write_regs_o        = apu_write_regs;
      assign apu_write_regs_valid_o  = apu_write_regs_valid;
    end else begin : gen_no_apu
      for (genvar i = 0; i < APU_NARGS_CPU; i++) begin : gen_apu_tie_off
        assign apu_operands[i] = '0;
      end

      assign apu_read_regs          = '0;
      assign apu_read_regs_valid    = '0;
      assign apu_write_regs         = '0;
      assign apu_write_regs_valid   = '0;
      assign apu_waddr              = '0;
      assign apu_flags              = '0;
      assign apu_write_regs_o       = '0;
      assign apu_read_regs_o        = '0;
      assign apu_write_regs_valid_o = '0;
      assign apu_read_regs_valid_o  = '0;
    end
  endgenerate

  assign apu_perf_dep_o = apu_stall;
  // stall when we access the CSR after a multicycle APU instruction
  assign csr_apu_stall  = (csr_access & (apu_en_ex_o & (apu_lat_ex_o[1] == 1'b1) | apu_busy_i));

  /////////////////////////////////////////////////////////
  //  ____  _____ ____ ___ ____ _____ _____ ____  ____   //
  // |  _ \| ____/ ___|_ _/ ___|_   _| ____|  _ \/ ___|  //
  // | |_) |  _|| |  _ | |\___ \ | | |  _| | |_) \___ \  //
  // |  _ <| |__| |_| || | ___) || | | |___|  _ < ___) | //
  // |_| \_\_____\____|___|____/ |_| |_____|_| \_\____/  //
  //                                                     //
  /////////////////////////////////////////////////////////

  cv32e40p_register_file #(
      .ADDR_WIDTH(6),
      .DATA_WIDTH(32),
      .FPU       (FPU),
      .ZFINX     (ZFINX)
  ) register_file_i (
      .clk  (clk),
      .rst_n(rst_n),

      .scan_cg_en_i(scan_cg_en_i),

      // Read port a
      .raddr_a_i(regfile_addr_ra_id),
      .rdata_a_o(regfile_data_ra_id),

      // Read port b
      .raddr_b_i(regfile_addr_rb_id),
      .rdata_b_o(regfile_data_rb_id),

      // Read port c
      .raddr_c_i(regfile_addr_rc_id),
      .rdata_c_o(regfile_data_rc_id),

      // Write port a
      .waddr_a_i(regfile_waddr_wb_i),
      .wdata_a_i(regfile_wdata_wb_i),
      .we_a_i   (regfile_we_wb_power_i),

      // Write port b
      .waddr_b_i(regfile_alu_waddr_fw_i),
      .wdata_b_i(regfile_alu_wdata_fw_i),
      .we_b_i   (regfile_alu_we_fw_power_i)
  );


  ///////////////////////////////////////////////
  //  ____  _____ ____ ___  ____  _____ ____   //
  // |  _ \| ____/ ___/ _ \|  _ \| ____|  _ \  //
  // | | | |  _|| |  | | | | | | |  _| | |_) | //
  // | |_| | |__| |__| |_| | |_| | |___|  _ <  //
  // |____/|_____\____\___/|____/|_____|_| \_\ //
  //                                           //
  ///////////////////////////////////////////////

  cv32e40p_decoder #(
      .COREV_PULP      (COREV_PULP),
      .COREV_CLUSTER   (COREV_CLUSTER),
      .A_EXTENSION     (A_EXTENSION),
      .FPU             (FPU),
      .FPU_ADDMUL_LAT  (FPU_ADDMUL_LAT),
      .FPU_OTHERS_LAT  (FPU_OTHERS_LAT),
      .ZFINX           (ZFINX),
      .PULP_SECURE     (PULP_SECURE),
      .USE_PMP         (USE_PMP),
      .APU_WOP_CPU     (APU_WOP_CPU),
      .DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
  ) decoder_i (
      // controller related signals
      .deassert_we_i(deassert_we),

      .illegal_insn_o(illegal_insn_dec),
      .ebrk_insn_o   (ebrk_insn_dec),

      .mret_insn_o(mret_insn_dec),
      .uret_insn_o(uret_insn_dec),
      .dret_insn_o(dret_insn_dec),

      .mret_dec_o(mret_dec),
      .uret_dec_o(uret_dec),
      .dret_dec_o(dret_dec),

      .ecall_insn_o(ecall_insn_dec),
      .wfi_o       (wfi_insn_dec),

      .fencei_insn_o(fencei_insn_dec),

      .rega_used_o(rega_used_dec),
      .regb_used_o(regb_used_dec),
      .regc_used_o(regc_used_dec),

      .reg_fp_a_o(regfile_fp_a),
      .reg_fp_b_o(regfile_fp_b),
      .reg_fp_c_o(regfile_fp_c),
      .reg_fp_d_o(regfile_fp_d),

      .bmask_a_mux_o        (bmask_a_mux),
      .bmask_b_mux_o        (bmask_b_mux),
      .alu_bmask_a_mux_sel_o(alu_bmask_a_mux_sel),
      .alu_bmask_b_mux_sel_o(alu_bmask_b_mux_sel),

      // from IF/ID pipeline
      .instr_rdata_i   (instr),
      .illegal_c_insn_i(illegal_c_insn_i),

      // ALU signals
      .alu_en_o              (alu_en),
      .alu_operator_o        (alu_operator),
      .alu_op_a_mux_sel_o    (alu_op_a_mux_sel),
      .alu_op_b_mux_sel_o    (alu_op_b_mux_sel),
      .alu_op_c_mux_sel_o    (alu_op_c_mux_sel),
      .alu_vec_o             (alu_vec),
      .alu_vec_mode_o        (alu_vec_mode),
      .scalar_replication_o  (scalar_replication),
      .scalar_replication_c_o(scalar_replication_c),
      .imm_a_mux_sel_o       (imm_a_mux_sel),
      .imm_b_mux_sel_o       (imm_b_mux_sel),
      .regc_mux_o            (regc_mux),
      .is_clpx_o             (is_clpx),
      .is_subrot_o           (is_subrot),

      // MUL signals
      .mult_operator_o   (mult_operator),
      .mult_int_en_o     (mult_int_en),
      .mult_sel_subword_o(mult_sel_subword),
      .mult_signed_mode_o(mult_signed_mode),
      .mult_imm_mux_o    (mult_imm_mux),
      .mult_dot_en_o     (mult_dot_en),
      .mult_dot_signed_o (mult_dot_signed),

      // FPU / APU signals
      .fs_off_i     (fs_off_i),
      .frm_i        (frm_i),
      .fpu_src_fmt_o(fpu_src_fmt),
      .fpu_dst_fmt_o(fpu_dst_fmt),
      .fpu_int_fmt_o(fpu_int_fmt),
      .apu_en_o     (apu_en),
      .apu_op_o     (apu_op),
      .apu_lat_o    (apu_lat),
      .fp_rnd_mode_o(fp_rnd_mode),

      // Register file control signals
      .regfile_mem_we_o       (regfile_we_id),
      .regfile_alu_we_o       (regfile_alu_we_id),
      .regfile_alu_we_dec_o   (regfile_alu_we_dec_id),
      .regfile_alu_waddr_sel_o(regfile_alu_waddr_mux_sel),

      // CSR control signals
      .csr_access_o      (csr_access),
      .csr_status_o      (csr_status),
      .csr_op_o          (csr_op),
      .current_priv_lvl_i(current_priv_lvl_i),

      // Data bus interface
      .data_req_o           (data_req_id),
      .data_we_o            (data_we_id),
      .prepost_useincr_o    (prepost_useincr),
      .data_type_o          (data_type_id),
      .data_sign_extension_o(data_sign_ext_id),
      .data_reg_offset_o    (data_reg_offset_id),
      .data_load_event_o    (data_load_event_id),

      // Atomic memory access
      .atop_o(atop_id),

      // hwloop signals
      .hwlp_we_o            (hwlp_we),
      .hwlp_target_mux_sel_o(hwlp_target_mux_sel),
      .hwlp_start_mux_sel_o (hwlp_start_mux_sel),
      .hwlp_cnt_mux_sel_o   (hwlp_cnt_mux_sel),

      // debug mode
      .debug_mode_i        (debug_mode_o),
      .debug_wfi_no_sleep_i(debug_wfi_no_sleep),

      // jump/branches
      .ctrl_transfer_insn_in_dec_o   (ctrl_transfer_insn_in_dec_o),
      .ctrl_transfer_insn_in_id_o    (ctrl_transfer_insn_in_id),
      .ctrl_transfer_target_mux_sel_o(ctrl_transfer_target_mux_sel),

      // HPM related control signals
      .mcounteren_i(mcounteren_i)

  );

  ////////////////////////////////////////////////////////////////////
  //    ____ ___  _   _ _____ ____   ___  _     _     _____ ____    //
  //   / ___/ _ \| \ | |_   _|  _ \ / _ \| |   | |   | ____|  _ \   //
  //  | |  | | | |  \| | | | | |_) | | | | |   | |   |  _| | |_) |  //
  //  | |__| |_| | |\  | | | |  _ <| |_| | |___| |___| |___|  _ <   //
  //   \____\___/|_| \_| |_| |_| \_\\___/|_____|_____|_____|_| \_\  //
  //                                                                //
  ////////////////////////////////////////////////////////////////////

  cv32e40p_controller #(
      .COREV_CLUSTER(COREV_CLUSTER),
      .COREV_PULP   (COREV_PULP),
      .FPU          (FPU)
  ) controller_i (
      .clk          (clk),  // Gated clock
      .clk_ungated_i(clk_ungated_i),  // Ungated clock
      .rst_n        (rst_n),

      .fetch_enable_i   (fetch_enable_i),
      .ctrl_busy_o      (ctrl_busy_o),
      .is_decoding_o    (is_decoding_o),
      .is_fetch_failed_i(is_fetch_failed_i),

      // decoder related signals
      .deassert_we_o(deassert_we),

      .illegal_insn_i(illegal_insn_dec),
      .ecall_insn_i  (ecall_insn_dec),
      .mret_insn_i   (mret_insn_dec),
      .uret_insn_i   (uret_insn_dec),

      .dret_insn_i(dret_insn_dec),

      .mret_dec_i(mret_dec),
      .uret_dec_i(uret_dec),
      .dret_dec_i(dret_dec),


      .wfi_i        (wfi_insn_dec),
      .ebrk_insn_i  (ebrk_insn_dec),
      .fencei_insn_i(fencei_insn_dec),
      .csr_status_i (csr_status),

      .hwlp_mask_o(hwlp_mask),

      // from IF/ID pipeline
      .instr_valid_i(instr_valid_i),

      // from prefetcher
      .instr_req_o(instr_req_o),

      // to prefetcher
      .pc_set_o       (pc_set_o),
      .pc_mux_o       (pc_mux_o),
      .exc_pc_mux_o   (exc_pc_mux_o),
      .exc_cause_o    (exc_cause_o),
      .trap_addr_mux_o(trap_addr_mux_o),

      // HWLoop signls
      .pc_id_i(pc_id_i),

      .hwlp_start_addr_i(hwlp_start_o),
      .hwlp_end_addr_i  (hwlp_end_o),
      .hwlp_counter_i   (hwlp_cnt_o),
      .hwlp_dec_cnt_o   (hwlp_dec_cnt),

      .hwlp_jump_o     (hwlp_jump_o),
      .hwlp_targ_addr_o(hwlp_target_o),

      // LSU
      .data_req_ex_i    (data_req_ex_o),
      .data_we_ex_i     (data_we_ex_o),
      .data_misaligned_i(data_misaligned_i),
      .data_load_event_i(data_load_event_id),
      .data_err_i       (data_err_i),
      .data_err_ack_o   (data_err_ack_o),

      // ALU
      .mult_multicycle_i(mult_multicycle_i),

      // APU
      .apu_en_i               (apu_en),
      .apu_read_dep_i         (apu_read_dep_i),
      .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
      .apu_write_dep_i        (apu_write_dep_i),

      .apu_stall_o(apu_stall),

      // jump/branch control
      .branch_taken_ex_i          (branch_taken_ex),
      .ctrl_transfer_insn_in_id_i (ctrl_transfer_insn_in_id),
      .ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec_o),

      // Interrupt signals
      .irq_wu_ctrl_i     (irq_wu_ctrl),
      .irq_req_ctrl_i    (irq_req_ctrl),
      .irq_sec_ctrl_i    (irq_sec_ctrl),
      .irq_id_ctrl_i     (irq_id_ctrl),
      .current_priv_lvl_i(current_priv_lvl_i),
      .irq_ack_o         (irq_ack_o),
      .irq_id_o          (irq_id_o),

      // Debug Signal
      .debug_mode_o          (debug_mode_o),
      .debug_cause_o         (debug_cause_o),
      .debug_csr_save_o      (debug_csr_save_o),
      .debug_req_i           (debug_req_i),
      .debug_single_step_i   (debug_single_step_i),
      .debug_ebreakm_i       (debug_ebreakm_i),
      .debug_ebreaku_i       (debug_ebreaku_i),
      .trigger_match_i       (trigger_match_i),
      .debug_p_elw_no_sleep_o(debug_p_elw_no_sleep_o),
      .debug_wfi_no_sleep_o  (debug_wfi_no_sleep),
      .debug_havereset_o     (debug_havereset_o),
      .debug_running_o       (debug_running_o),
      .debug_halted_o        (debug_halted_o),

      // Wakeup Signal
      .wake_from_sleep_o(wake_from_sleep_o),

      // CSR Controller Signals
      .csr_save_cause_o     (csr_save_cause_o),
      .csr_cause_o          (csr_cause_o),
      .csr_save_if_o        (csr_save_if_o),
      .csr_save_id_o        (csr_save_id_o),
      .csr_save_ex_o        (csr_save_ex_o),
      .csr_restore_mret_id_o(csr_restore_mret_id_o),
      .csr_restore_uret_id_o(csr_restore_uret_id_o),

      .csr_restore_dret_id_o(csr_restore_dret_id_o),

      .csr_irq_sec_o(csr_irq_sec_o),

      // Write targets from ID
      .regfile_we_id_i       (regfile_alu_we_dec_id),
      .regfile_alu_waddr_id_i(regfile_alu_waddr_id),

      // Forwarding signals from regfile
      .regfile_we_ex_i   (regfile_we_ex_o),
      .regfile_waddr_ex_i(regfile_waddr_ex_o),
      .regfile_we_wb_i   (regfile_we_wb_i),

      // regfile port 2
      .regfile_alu_we_fw_i(regfile_alu_we_fw_i),

      // Forwarding detection signals
      .reg_d_ex_is_reg_a_i (reg_d_ex_is_reg_a_id),
      .reg_d_ex_is_reg_b_i (reg_d_ex_is_reg_b_id),
      .reg_d_ex_is_reg_c_i (reg_d_ex_is_reg_c_id),
      .reg_d_wb_is_reg_a_i (reg_d_wb_is_reg_a_id),
      .reg_d_wb_is_reg_b_i (reg_d_wb_is_reg_b_id),
      .reg_d_wb_is_reg_c_i (reg_d_wb_is_reg_c_id),
      .reg_d_alu_is_reg_a_i(reg_d_alu_is_reg_a_id),
      .reg_d_alu_is_reg_b_i(reg_d_alu_is_reg_b_id),
      .reg_d_alu_is_reg_c_i(reg_d_alu_is_reg_c_id),

      // Forwarding signals
      .operand_a_fw_mux_sel_o(operand_a_fw_mux_sel),
      .operand_b_fw_mux_sel_o(operand_b_fw_mux_sel),
      .operand_c_fw_mux_sel_o(operand_c_fw_mux_sel),

      // Stall signals
      .halt_if_o(halt_if),
      .halt_id_o(halt_id),

      .misaligned_stall_o(misaligned_stall),
      .jr_stall_o        (jr_stall),
      .load_stall_o      (load_stall),

      .id_ready_i(id_ready_o),
      .id_valid_i(id_valid_o),

      .ex_valid_i(ex_valid_i),

      .wb_ready_i(wb_ready_i),

      // Performance Counters
      .perf_pipeline_stall_o(perf_pipeline_stall)
  );


  ////////////////////////////////////////////////////////////////////////
  //  _____      _       _____             _             _ _            //
  // |_   _|    | |     /  __ \           | |           | | |           //
  //   | | _ __ | |_    | /  \/ ___  _ __ | |_ _ __ ___ | | | ___ _ __  //
  //   | || '_ \| __|   | |    / _ \| '_ \| __| '__/ _ \| | |/ _ \ '__| //
  //  _| || | | | |_ _  | \__/\ (_) | | | | |_| | | (_) | | |  __/ |    //
  //  \___/_| |_|\__(_)  \____/\___/|_| |_|\__|_|  \___/|_|_|\___|_|    //
  //                                                                    //
  ////////////////////////////////////////////////////////////////////////

  cv32e40p_int_controller #(
      .PULP_SECURE(PULP_SECURE)
  ) int_controller_i (
      .clk  (clk),
      .rst_n(rst_n),

      // External interrupt lines
      .irq_i    (irq_i),
      .irq_sec_i(irq_sec_i),

      // To cv32e40p_controller
      .irq_req_ctrl_o(irq_req_ctrl),
      .irq_sec_ctrl_o(irq_sec_ctrl),
      .irq_id_ctrl_o (irq_id_ctrl),
      .irq_wu_ctrl_o (irq_wu_ctrl),

      // To/from with cv32e40p_cs_registers
      .mie_bypass_i      (mie_bypass_i),
      .mip_o             (mip_o),
      .m_ie_i            (m_irq_enable_i),
      .u_ie_i            (u_irq_enable_i),
      .current_priv_lvl_i(current_priv_lvl_i)
  );

  generate
    if (COREV_PULP) begin : gen_hwloop_regs

      ///////////////////////////////////////////////
      //  _   ___        ___     ___   ___  ____   //
      // | | | \ \      / / |   / _ \ / _ \|  _ \  //
      // | |_| |\ \ /\ / /| |  | | | | | | | |_) | //
      // |  _  | \ V  V / | |__| |_| | |_| |  __/  //
      // |_| |_|  \_/\_/  |_____\___/ \___/|_|     //
      //                                           //
      ///////////////////////////////////////////////


      cv32e40p_hwloop_regs #(
          .N_REGS(N_HWLP)
      ) hwloop_regs_i (
          .clk  (clk),
          .rst_n(rst_n),

          // from ID
          .hwlp_start_data_i(hwlp_start),
          .hwlp_end_data_i  (hwlp_end),
          .hwlp_cnt_data_i  (hwlp_cnt),
          .hwlp_we_i        (hwlp_we_masked),
          .hwlp_regid_i     (hwlp_regid),

          // from controller
          .valid_i(hwlp_valid),

          // to hwloop controller
          .hwlp_start_addr_o(hwlp_start_o),
          .hwlp_end_addr_o  (hwlp_end_o),
          .hwlp_counter_o   (hwlp_cnt_o),

          // from hwloop controller
          .hwlp_dec_cnt_i(hwlp_dec_cnt)
      );

      assign hwlp_valid = instr_valid_i & clear_instr_valid_o;

      // hwloop register id
      assign hwlp_regid = instr[7];  // rd contains hwloop register id

      // hwloop target mux
      always_comb begin
        case (hwlp_target_mux_sel)
          2'b00:   hwlp_end = pc_id_i + {imm_iz_type[29:0], 2'b0};
          2'b01:   hwlp_end = pc_id_i + {imm_z_type[29:0], 2'b0};
          2'b10:   hwlp_end = operand_a_fw_id;
          default: hwlp_end = operand_a_fw_id;
        endcase
      end

      // hwloop start mux
      always_comb begin
        case (hwlp_start_mux_sel)
          2'b00:   hwlp_start = hwlp_end;  // for PC + I imm
          2'b01:   hwlp_start = pc_id_i + 4;  // for next PC
          2'b10:   hwlp_start = operand_a_fw_id;
          default: hwlp_start = operand_a_fw_id;
        endcase
      end

      // hwloop cnt mux
      always_comb begin : hwlp_cnt_mux
        case (hwlp_cnt_mux_sel)
          1'b0: hwlp_cnt = imm_iz_type;
          1'b1: hwlp_cnt = operand_a_fw_id;
        endcase
        ;
      end

      /*
        when hwlp_mask is 1, the controller is about to take an interrupt
        the xEPC is going to have the hwloop instruction PC, therefore, do not update the
        hwloop registers to make clear that the instruction hasn't been executed.
        Although it may not be a HW bugs causing uninteded behaviours,
        it helps verifications processes when checking the hwloop regs
      */
      assign hwlp_we_masked = hwlp_we & ~{3{hwlp_mask}} & {3{id_ready_o}};

    end else begin : gen_no_hwloop_regs

      assign hwlp_start_o   = 'b0;
      assign hwlp_end_o     = 'b0;
      assign hwlp_cnt_o     = 'b0;
      assign hwlp_valid     = 'b0;
      assign hwlp_we_masked = 'b0;
      assign hwlp_start     = 'b0;
      assign hwlp_end       = 'b0;
      assign hwlp_cnt       = 'b0;
      assign hwlp_regid     = 'b0;

    end
  endgenerate


  /////////////////////////////////////////////////////////////////////////////////
  //   ___ ____        _______  __  ____ ___ ____  _____ _     ___ _   _ _____   //
  //  |_ _|  _ \      | ____\ \/ / |  _ \_ _|  _ \| ____| |   |_ _| \ | | ____|  //
  //   | || | | |_____|  _|  \  /  | |_) | || |_) |  _| | |    | ||  \| |  _|    //
  //   | || |_| |_____| |___ /  \  |  __/| ||  __/| |___| |___ | || |\  | |___   //
  //  |___|____/      |_____/_/\_\ |_|  |___|_|   |_____|_____|___|_| \_|_____|  //
  //                                                                             //
  /////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n) begin : ID_EX_PIPE_REGISTERS
    if (rst_n == 1'b0) begin
      alu_en_ex_o            <= '0;
      alu_operator_ex_o      <= ALU_SLTU;
      alu_operand_a_ex_o     <= '0;
      alu_operand_b_ex_o     <= '0;
      alu_operand_c_ex_o     <= '0;
      bmask_a_ex_o           <= '0;
      bmask_b_ex_o           <= '0;
      imm_vec_ext_ex_o       <= '0;
      alu_vec_mode_ex_o      <= '0;
      alu_clpx_shift_ex_o    <= 2'b0;
      alu_is_clpx_ex_o       <= 1'b0;
      alu_is_subrot_ex_o     <= 1'b0;

      mult_operator_ex_o     <= MUL_MAC32;
      mult_operand_a_ex_o    <= '0;
      mult_operand_b_ex_o    <= '0;
      mult_operand_c_ex_o    <= '0;
      mult_en_ex_o           <= 1'b0;
      mult_sel_subword_ex_o  <= 1'b0;
      mult_signed_mode_ex_o  <= 2'b00;
      mult_imm_ex_o          <= '0;

      mult_dot_op_a_ex_o     <= '0;
      mult_dot_op_b_ex_o     <= '0;
      mult_dot_op_c_ex_o     <= '0;
      mult_dot_signed_ex_o   <= '0;
      mult_is_clpx_ex_o      <= 1'b0;
      mult_clpx_shift_ex_o   <= 2'b0;
      mult_clpx_img_ex_o     <= 1'b0;

      apu_en_ex_o            <= '0;
      apu_op_ex_o            <= '0;
      apu_lat_ex_o           <= '0;
      apu_operands_ex_o[0]   <= '0;
      apu_operands_ex_o[1]   <= '0;
      apu_operands_ex_o[2]   <= '0;
      apu_flags_ex_o         <= '0;
      apu_waddr_ex_o         <= '0;


      regfile_waddr_ex_o     <= 6'b0;
      regfile_we_ex_o        <= 1'b0;

      regfile_alu_waddr_ex_o <= 6'b0;
      regfile_alu_we_ex_o    <= 1'b0;
      prepost_useincr_ex_o   <= 1'b0;

      csr_access_ex_o        <= 1'b0;
      csr_op_ex_o            <= CSR_OP_READ;

      data_we_ex_o           <= 1'b0;
      data_type_ex_o         <= 2'b0;
      data_sign_ext_ex_o     <= 2'b0;
      data_reg_offset_ex_o   <= 2'b0;
      data_req_ex_o          <= 1'b0;
      data_load_event_ex_o   <= 1'b0;
      atop_ex_o              <= 5'b0;

      data_misaligned_ex_o   <= 1'b0;

      pc_ex_o                <= '0;

      branch_in_ex_o         <= 1'b0;

    end else if (data_misaligned_i) begin
      // misaligned data access case
      if (ex_ready_i) begin  // misaligned access case, only unstall alu operands

        // if we are using post increments, then we have to use the
        // original value of the register for the second memory access
        // => keep it stalled
        if (prepost_useincr_ex_o == 1'b1) begin
          alu_operand_a_ex_o <= operand_a_fw_id;
        end

        alu_operand_b_ex_o   <= 32'h4;
        regfile_alu_we_ex_o  <= 1'b0;
        prepost_useincr_ex_o <= 1'b1;

        data_misaligned_ex_o <= 1'b1;
      end
    end else if (mult_multicycle_i) begin
      mult_operand_c_ex_o <= operand_c_fw_id;
    end else begin
      // normal pipeline unstall case

      if (id_valid_o) begin  // unstall the whole pipeline
        alu_en_ex_o <= alu_en;
        if (alu_en) begin
          alu_operator_ex_o   <= alu_operator;
          alu_operand_a_ex_o  <= alu_operand_a;
          alu_operand_b_ex_o  <= alu_operand_b;
          alu_operand_c_ex_o  <= alu_operand_c;
          bmask_a_ex_o        <= bmask_a_id;
          bmask_b_ex_o        <= bmask_b_id;
          imm_vec_ext_ex_o    <= imm_vec_ext_id;
          alu_vec_mode_ex_o   <= alu_vec_mode;
          alu_is_clpx_ex_o    <= is_clpx;
          alu_clpx_shift_ex_o <= instr[14:13];
          alu_is_subrot_ex_o  <= is_subrot;
        end

        mult_en_ex_o <= mult_en;
        if (mult_int_en) begin
          mult_operator_ex_o    <= mult_operator;
          mult_sel_subword_ex_o <= mult_sel_subword;
          mult_signed_mode_ex_o <= mult_signed_mode;
          mult_operand_a_ex_o   <= alu_operand_a;
          mult_operand_b_ex_o   <= alu_operand_b;
          mult_operand_c_ex_o   <= alu_operand_c;
          mult_imm_ex_o         <= mult_imm_id;
        end
        if (mult_dot_en) begin
          mult_operator_ex_o   <= mult_operator;
          mult_dot_signed_ex_o <= mult_dot_signed;
          mult_dot_op_a_ex_o   <= alu_operand_a;
          mult_dot_op_b_ex_o   <= alu_operand_b;
          mult_dot_op_c_ex_o   <= alu_operand_c;
          mult_is_clpx_ex_o    <= is_clpx;
          mult_clpx_shift_ex_o <= instr[14:13];
          mult_clpx_img_ex_o   <= instr[25];
        end

        // APU pipeline
        apu_en_ex_o <= apu_en;
        if (apu_en) begin
          apu_op_ex_o       <= apu_op;
          apu_lat_ex_o      <= apu_lat;
          apu_operands_ex_o <= apu_operands;
          apu_flags_ex_o    <= apu_flags;
          apu_waddr_ex_o    <= apu_waddr;
        end

        regfile_we_ex_o <= regfile_we_id;
        if (regfile_we_id) begin
          regfile_waddr_ex_o <= regfile_waddr_id;
        end

        regfile_alu_we_ex_o <= regfile_alu_we_id;
        if (regfile_alu_we_id) begin
          regfile_alu_waddr_ex_o <= regfile_alu_waddr_id;
        end

        prepost_useincr_ex_o <= prepost_useincr;

        csr_access_ex_o      <= csr_access;
        csr_op_ex_o          <= csr_op;

        data_req_ex_o        <= data_req_id;
        if (data_req_id) begin  // only needed for LSU when there is an active request
          data_we_ex_o         <= data_we_id;
          data_type_ex_o       <= data_type_id;
          data_sign_ext_ex_o   <= data_sign_ext_id;
          data_reg_offset_ex_o <= data_reg_offset_id;
          data_load_event_ex_o <= data_load_event_id;
          atop_ex_o            <= atop_id;
        end else begin
          data_load_event_ex_o <= 1'b0;
        end

        data_misaligned_ex_o <= 1'b0;

        if ((ctrl_transfer_insn_in_id == BRANCH_COND) || data_req_id) begin
          pc_ex_o <= pc_id_i;
        end

        branch_in_ex_o <= ctrl_transfer_insn_in_id == BRANCH_COND;
      end else if (ex_ready_i) begin
        // EX stage is ready but we don't have a new instruction for it,
        // so we set all write enables to 0, but unstall the pipe

        regfile_we_ex_o      <= 1'b0;

        regfile_alu_we_ex_o  <= 1'b0;

        csr_op_ex_o          <= CSR_OP_READ;

        data_req_ex_o        <= 1'b0;

        data_load_event_ex_o <= 1'b0;

        data_misaligned_ex_o <= 1'b0;

        branch_in_ex_o       <= 1'b0;

        apu_en_ex_o          <= 1'b0;

        alu_operator_ex_o    <= ALU_SLTU;

        mult_en_ex_o         <= 1'b0;

        alu_en_ex_o          <= 1'b1;

      end else if (csr_access_ex_o) begin
        //In the EX stage there was a CSR access, to avoid multiple
        //writes to the RF, disable regfile_alu_we_ex_o.
        //Not doing it can overwrite the RF file with the currennt CSR value rather than the old one
        regfile_alu_we_ex_o <= 1'b0;
      end
    end
  end

  // Performance Counter Events

  // Illegal/ebreak/ecall are never counted as retired instructions. Note that actually issued instructions
  // are being counted; the manner in which CSR instructions access the performance counters guarantees
  // that this count will correspond to the retired isntructions count.
  assign minstret = id_valid_o && is_decoding_o && !(illegal_insn_dec || ebrk_insn_dec || ecall_insn_dec);

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      id_valid_q               <= 1'b0;
      mhpmevent_minstret_o     <= 1'b0;
      mhpmevent_load_o         <= 1'b0;
      mhpmevent_store_o        <= 1'b0;
      mhpmevent_jump_o         <= 1'b0;
      mhpmevent_branch_o       <= 1'b0;
      mhpmevent_compressed_o   <= 1'b0;
      mhpmevent_branch_taken_o <= 1'b0;
      mhpmevent_jr_stall_o     <= 1'b0;
      mhpmevent_imiss_o        <= 1'b0;
      mhpmevent_ld_stall_o     <= 1'b0;
      mhpmevent_pipe_stall_o   <= 1'b0;
    end else begin
      // Helper signal
      id_valid_q <= id_valid_o;
      // ID stage counts
      mhpmevent_minstret_o <= minstret;
      mhpmevent_load_o <= minstret && data_req_id && !data_we_id;
      mhpmevent_store_o <= minstret && data_req_id && data_we_id;
      mhpmevent_jump_o           <= minstret && ((ctrl_transfer_insn_in_id == BRANCH_JAL) || (ctrl_transfer_insn_in_id == BRANCH_JALR));
      mhpmevent_branch_o <= minstret && (ctrl_transfer_insn_in_id == BRANCH_COND);
      mhpmevent_compressed_o <= minstret && is_compressed_i;
      // EX stage count
      mhpmevent_branch_taken_o <= mhpmevent_branch_o && branch_decision_i;
      // IF stage count
      mhpmevent_imiss_o <= perf_imiss_i;
      // Jump-register-hazard; do not count stall on flushed instructions (id_valid_q used to only count first cycle)
      mhpmevent_jr_stall_o <= jr_stall && !halt_id && id_valid_q;
      // Load-use-hazard; do not count stall on flushed instructions (id_valid_q used to only count first cycle)
      mhpmevent_ld_stall_o <= load_stall && !halt_id && id_valid_q;
      // ELW
      mhpmevent_pipe_stall_o <= perf_pipeline_stall;
    end
  end

  // stall control
  assign id_ready_o = ((~misaligned_stall) & (~jr_stall) & (~load_stall) & (~apu_stall) & (~csr_apu_stall) & ex_ready_i);
  assign id_valid_o = (~halt_id) & id_ready_o;
  assign halt_if_o = halt_if;


  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------
`ifdef CV32E40P_ASSERT_ON

  always_comb begin
    if (FPU == 1) begin
      assert (APU_NDSFLAGS_CPU >= C_RM+2*cv32e40p_fpu_pkg::FP_FORMAT_BITS+cv32e40p_fpu_pkg::INT_FORMAT_BITS)
      else
        $error("[apu] APU_NDSFLAGS_CPU APU flagbits is smaller than %0d",
               C_RM + 2 * cv32e40p_fpu_pkg::FP_FORMAT_BITS + cv32e40p_fpu_pkg::INT_FORMAT_BITS);
    end
  end

  // make sure that branch decision is valid when jumping
  a_br_decision :
  assert property (@(posedge clk) (branch_in_ex_o) |-> (branch_decision_i !== 1'bx))
  else begin
    $warning("%t, Branch decision is X in module %m", $time);
    $stop;
  end

  // the instruction delivered to the ID stage should always be valid
  a_valid_instr :
  assert property (@(posedge clk) (instr_valid_i & (~illegal_c_insn_i)) |-> (!$isunknown(instr)))
  else $warning("%t, Instruction is valid, but has at least one X", $time);

  // Check that instruction after taken branch is flushed (more should actually be flushed, but that is not checked here)
  // and that EX stage is ready to receive flushed instruction immediately
  property p_branch_taken_ex;
    @(posedge clk) disable iff (!rst_n) (branch_taken_ex == 1'b1) |-> ((ex_ready_i == 1'b1) &&
                                                                          (alu_en == 1'b0) && (apu_en == 1'b0) &&
                                                                          (mult_en == 1'b0) && (mult_int_en == 1'b0) &&
                                                                          (mult_dot_en == 1'b0) && (regfile_we_id == 1'b0) &&
                                                                          (regfile_alu_we_id == 1'b0) && (data_req_id == 1'b0));
  endproperty

  a_branch_taken_ex :
  assert property (p_branch_taken_ex);

  // Check that if IRQ PC update does not coincide with IRQ related CSR write
  // MIE is excluded from the check because it has a bypass.
  property p_irq_csr;
    @(posedge clk) disable iff (!rst_n) (pc_set_o && (pc_mux_o == PC_EXCEPTION) && ((exc_pc_mux_o == EXC_PC_EXCEPTION) || (exc_pc_mux_o == EXC_PC_IRQ)) &&
                                            csr_access_ex_o && (csr_op_ex_o != CSR_OP_READ)) |->
                                           ((alu_operand_b_ex_o[11:0] != CSR_MSTATUS) && (alu_operand_b_ex_o[11:0] != CSR_USTATUS) &&
                                            (alu_operand_b_ex_o[11:0] != CSR_MEPC) && (alu_operand_b_ex_o[11:0] != CSR_UEPC) &&
                                            (alu_operand_b_ex_o[11:0] != CSR_MCAUSE) && (alu_operand_b_ex_o[11:0] != CSR_UCAUSE) &&
                                            (alu_operand_b_ex_o[11:0] != CSR_MTVEC) && (alu_operand_b_ex_o[11:0] != CSR_UTVEC));
  endproperty

  a_irq_csr :
  assert property (p_irq_csr);

  // Check that xret does not coincide with CSR write (to avoid using wrong return address)
  // This check is more strict than really needed; a CSR instruction would be allowed in EX as long
  // as its write action happens before the xret CSR usage
  property p_xret_csr;
    @(posedge clk) disable iff (!rst_n) (pc_set_o && ((pc_mux_o == PC_MRET) || (pc_mux_o == PC_URET) || (pc_mux_o == PC_DRET))) |->
                                           (!(csr_access_ex_o && (csr_op_ex_o != CSR_OP_READ)));
  endproperty

  a_xret_csr :
  assert property (p_xret_csr);

  generate
    if (!A_EXTENSION) begin : gen_no_a_extension_assertions

      // Check that A extension opcodes are decoded as illegal when A extension not enabled
      property p_illegal_0;
        @(posedge clk) disable iff (!rst_n) (instr[6:0] == OPCODE_AMO) |-> (illegal_insn_dec == 'b1);
      endproperty

      a_illegal_0 :
      assert property (p_illegal_0);

    end
  endgenerate

  generate
    if (!COREV_PULP) begin : gen_no_pulp_xpulp_assertions

      // Check that PULP extension opcodes are decoded as illegal when PULP extension is not enabled
      property p_illegal_1;
        @(posedge clk) disable iff (!rst_n) ((instr[6:0] == OPCODE_CUSTOM_0) || (instr[6:0] == OPCODE_CUSTOM_1) ||
                                             (instr[6:0] == OPCODE_CUSTOM_2) || (instr[6:0] == OPCODE_CUSTOM_3))
                                            |-> (illegal_insn_dec == 'b1);
      endproperty

      a_illegal_1 :
      assert property (p_illegal_1);

      // Check that certain ALU operations are not used when PULP extension is not enabled
      property p_alu_op;
        @(posedge clk) disable iff (!rst_n) (1'b1) |-> ( (alu_operator != ALU_ADDU ) && (alu_operator != ALU_SUBU ) &&
                                                           (alu_operator != ALU_ADDR ) && (alu_operator != ALU_SUBR ) &&
                                                           (alu_operator != ALU_ADDUR) && (alu_operator != ALU_SUBUR) &&
                                                           (alu_operator != ALU_ROR) && (alu_operator != ALU_BEXT) &&
                                                           (alu_operator != ALU_BEXTU) && (alu_operator != ALU_BINS) &&
                                                           (alu_operator != ALU_BCLR) && (alu_operator != ALU_BSET) &&
                                                           (alu_operator != ALU_BREV) && (alu_operator != ALU_FF1) &&
                                                           (alu_operator != ALU_FL1) && (alu_operator != ALU_CNT) &&
                                                           (alu_operator != ALU_CLB) && (alu_operator != ALU_EXTS) &&
                                                           (alu_operator != ALU_EXT) && (alu_operator != ALU_LES) &&
                                                           (alu_operator != ALU_LEU) && (alu_operator != ALU_GTS) &&
                                                           (alu_operator != ALU_GTU) && (alu_operator != ALU_SLETS) &&
                                                           (alu_operator != ALU_SLETU) && (alu_operator != ALU_ABS) &&
                                                           (alu_operator != ALU_CLIP) && (alu_operator != ALU_CLIPU) &&
                                                           (alu_operator != ALU_INS) && (alu_operator != ALU_MIN) &&
                                                           (alu_operator != ALU_MINU) && (alu_operator != ALU_MAX) &&
                                                           (alu_operator != ALU_MAXU) && (alu_operator != ALU_SHUF) &&
                                                           (alu_operator != ALU_SHUF2) && (alu_operator != ALU_PCKLO) &&
                                                           (alu_operator != ALU_PCKHI) );
      endproperty

      a_alu_op :
      assert property (p_alu_op);

      // Check that certain vector modes are not used when PULP extension is not enabled
      property p_vector_mode;
        @(posedge clk) disable iff (!rst_n) (1'b1) |-> ( (alu_vec_mode != VEC_MODE8 ) && (alu_vec_mode != VEC_MODE16 ) );
      endproperty

      a_vector_mode :
      assert property (p_vector_mode);

      // Check that certain multiplier operations are not used when PULP extension is not enabled
      property p_mul_op;
        @(posedge clk) disable iff (!rst_n) (mult_int_en == 1'b1) |-> ( (mult_operator != MUL_MSU32) && (mult_operator != MUL_I) &&
                                                                         (mult_operator != MUL_IR) && (mult_operator != MUL_DOT8) &&
                                                                         (mult_operator != MUL_DOT16) );
      endproperty

      a_mul_op :
      assert property (p_mul_op);

    end
  endgenerate

  // Check that illegal instruction has no other side effects
  property p_illegal_2;
    @(posedge clk) disable iff (!rst_n) (illegal_insn_dec == 1'b1) |-> !(ebrk_insn_dec || mret_insn_dec || uret_insn_dec || dret_insn_dec ||
                                                                            ecall_insn_dec || wfi_insn_dec || fencei_insn_dec ||
                                                                            alu_en || mult_int_en || mult_dot_en || apu_en ||
                                                                            regfile_we_id || regfile_alu_we_id ||
                                                                            csr_op != CSR_OP_READ || data_req_id);
  endproperty

  a_illegal_2 :
  assert property (p_illegal_2);

`endif

endmodule  // cv32e40p_id_stage

// -------------------- END OF rtl/cv32e40p_id_stage.sv --------------------

// -------------------- START OF rtl/cv32e40p_if_stage.sv --------------------
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
// Engineer:       Renzo Andri - andrire@student.ethz.ch                      //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
// Design Name:    Instruction Fetch Stage                                    //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Instruction fetch unit: Selection of the next PC, and      //
//                 buffering (sampling) of the read instruction               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_if_stage #(
    parameter COREV_PULP = 0, // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding cv.elw)
    parameter PULP_OBI = 0,  // Legacy PULP OBI behavior
    parameter PULP_SECURE = 0,
    parameter FPU = 0,
    parameter ZFINX = 0
) (
    input logic clk,
    input logic rst_n,

    // Used to calculate the exception offsets
    input logic [23:0] m_trap_base_addr_i,
    input logic [23:0] u_trap_base_addr_i,
    input logic [ 1:0] trap_addr_mux_i,
    // Boot address
    input logic [31:0] boot_addr_i,
    input logic [31:0] dm_exception_addr_i,

    // Debug mode halt address
    input logic [31:0] dm_halt_addr_i,

    // instruction request control
    input logic req_i,

    // instruction cache interface
    output logic instr_req_o,
    output logic [31:0] instr_addr_o,
    input logic instr_gnt_i,
    input logic instr_rvalid_i,
    input logic [31:0] instr_rdata_i,
    input logic instr_err_i,      // External bus error (validity defined by instr_rvalid_i) (not used yet)
    input logic instr_err_pmp_i,  // PMP error (validity defined by instr_gnt_i)

    // Output of IF Pipeline stage
    output logic instr_valid_id_o,  // instruction in IF/ID pipeline is valid
    output logic [31:0] instr_rdata_id_o,      // read instruction is sampled and sent to ID stage for decoding
    output logic is_compressed_id_o,  // compressed decoder thinks this is a compressed instruction
    output logic illegal_c_insn_id_o,  // compressed decoder thinks this is an invalid instruction
    output logic [31:0] pc_if_o,
    output logic [31:0] pc_id_o,
    output logic is_fetch_failed_o,

    // Forwarding ports - control signals
    input logic clear_instr_valid_i,  // clear instruction valid bit in IF/ID pipe
    input logic pc_set_i,  // set the program counter to a new value
    input logic [31:0] mepc_i,  // address used to restore PC when the interrupt/exception is served
    input logic [31:0] uepc_i,  // address used to restore PC when the interrupt/exception is served

    input logic [31:0] depc_i,  // address used to restore PC when the debug is served

    input logic [3:0] pc_mux_i,  // sel for pc multiplexer
    input logic [2:0] exc_pc_mux_i,  // selects ISR address

    input  logic [4:0] m_exc_vec_pc_mux_i,  // selects ISR address for vectorized interrupt lines
    input  logic [4:0] u_exc_vec_pc_mux_i,  // selects ISR address for vectorized interrupt lines
    output logic       csr_mtvec_init_o,  // tell CS regfile to init mtvec

    // jump and branch target and decision
    input logic [31:0] jump_target_id_i,  // jump target address
    input logic [31:0] jump_target_ex_i,  // jump target address

    // from hwloop controller
    input logic        hwlp_jump_i,
    input logic [31:0] hwlp_target_i,

    // pipeline stall
    input logic halt_if_i,
    input logic id_ready_i,

    // misc signals
    output logic if_busy_o,  // is the IF stage busy fetching instructions?
    output logic perf_imiss_o  // Instruction Fetch Miss
);

  import cv32e40p_pkg::*;

  logic if_valid, if_ready;

  // prefetch buffer related signals
  logic        prefetch_busy;
  logic        branch_req;
  logic [31:0] branch_addr_n;

  logic        fetch_valid;
  logic        fetch_ready;
  logic [31:0] fetch_rdata;

  logic [31:0] exc_pc;

  logic [23:0] trap_base_addr;
  logic [ 4:0] exc_vec_pc_mux;
  logic        fetch_failed;

  logic        aligner_ready;
  logic        instr_valid;

  logic        illegal_c_insn;
  logic [31:0] instr_aligned;
  logic [31:0] instr_decompressed;
  logic        instr_compressed_int;


  // exception PC selection mux
  always_comb begin : EXC_PC_MUX
    unique case (trap_addr_mux_i)
      TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;
      TRAP_USER:    trap_base_addr = u_trap_base_addr_i;
      default:      trap_base_addr = m_trap_base_addr_i;
    endcase

    unique case (trap_addr_mux_i)
      TRAP_MACHINE: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
      TRAP_USER:    exc_vec_pc_mux = u_exc_vec_pc_mux_i;
      default:      exc_vec_pc_mux = m_exc_vec_pc_mux_i;
    endcase

    unique case (exc_pc_mux_i)
      EXC_PC_EXCEPTION:
      exc_pc = {trap_base_addr, 8'h0};  //1.10 all the exceptions go to base address
      EXC_PC_IRQ: exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux, 2'b0};  // interrupts are vectored
      EXC_PC_DBD: exc_pc = {dm_halt_addr_i[31:2], 2'b0};
      EXC_PC_DBE: exc_pc = {dm_exception_addr_i[31:2], 2'b0};
      default: exc_pc = {trap_base_addr, 8'h0};
    endcase
  end

  // fetch address selection
  always_comb begin
    // Default assign PC_BOOT (should be overwritten in below case)
    branch_addr_n = {boot_addr_i[31:2], 2'b0};

    unique case (pc_mux_i)
      PC_BOOT: branch_addr_n = {boot_addr_i[31:2], 2'b0};
      PC_JUMP: branch_addr_n = jump_target_id_i;
      PC_BRANCH: branch_addr_n = jump_target_ex_i;
      PC_EXCEPTION: branch_addr_n = exc_pc;  // set PC to exception handler
      PC_MRET: branch_addr_n = mepc_i;  // PC is restored when returning from IRQ/exception
      PC_URET: branch_addr_n = uepc_i;  // PC is restored when returning from IRQ/exception
      PC_DRET: branch_addr_n = depc_i;  //
      PC_FENCEI: branch_addr_n = pc_id_o + 4;  // jump to next instr forces prefetch buffer reload
      PC_HWLOOP: branch_addr_n = hwlp_target_i;
      default: ;
    endcase
  end

  // tell CS register file to initialize mtvec on boot
  assign csr_mtvec_init_o = (pc_mux_i == PC_BOOT) & pc_set_i;

  assign fetch_failed    = 1'b0; // PMP is not supported in CV32E40P

  // prefetch buffer, caches a fixed number of instructions
  cv32e40p_prefetch_buffer #(
      .PULP_OBI  (PULP_OBI),
      .COREV_PULP(COREV_PULP)
  ) prefetch_buffer_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i(req_i),

      .branch_i     (branch_req),
      .branch_addr_i({branch_addr_n[31:1], 1'b0}),

      .hwlp_jump_i  (hwlp_jump_i),
      .hwlp_target_i(hwlp_target_i),

      .fetch_ready_i(fetch_ready),
      .fetch_valid_o(fetch_valid),
      .fetch_rdata_o(fetch_rdata),

      // goes to instruction memory / instruction cache
      .instr_req_o    (instr_req_o),
      .instr_addr_o   (instr_addr_o),
      .instr_gnt_i    (instr_gnt_i),
      .instr_rvalid_i (instr_rvalid_i),
      .instr_err_i    (instr_err_i),  // Not supported (yet)
      .instr_err_pmp_i(instr_err_pmp_i),  // Not supported (yet)
      .instr_rdata_i  (instr_rdata_i),

      // Prefetch Buffer Status
      .busy_o(prefetch_busy)
  );

  // offset FSM state transition logic
  always_comb begin

    fetch_ready = 1'b0;
    branch_req  = 1'b0;
    // take care of jumps and branches
    if (pc_set_i) begin
      branch_req = 1'b1;
    end else if (fetch_valid) begin
      if (req_i && if_valid) begin
        fetch_ready = aligner_ready;
      end
    end
  end

  assign if_busy_o    = prefetch_busy;
  assign perf_imiss_o = !fetch_valid && !branch_req;

  // IF-ID pipeline registers, frozen when the ID stage is stalled
  always_ff @(posedge clk, negedge rst_n) begin : IF_ID_PIPE_REGISTERS
    if (rst_n == 1'b0) begin
      instr_valid_id_o    <= 1'b0;
      instr_rdata_id_o    <= '0;
      is_fetch_failed_o   <= 1'b0;
      pc_id_o             <= '0;
      is_compressed_id_o  <= 1'b0;
      illegal_c_insn_id_o <= 1'b0;
    end else begin

      if (if_valid && instr_valid) begin
        instr_valid_id_o    <= 1'b1;
        instr_rdata_id_o    <= instr_decompressed;
        is_compressed_id_o  <= instr_compressed_int;
        illegal_c_insn_id_o <= illegal_c_insn;
        is_fetch_failed_o   <= 1'b0;
        pc_id_o             <= pc_if_o;
      end else if (clear_instr_valid_i) begin
        instr_valid_id_o  <= 1'b0;
        is_fetch_failed_o <= fetch_failed;
      end
    end
  end

  assign if_ready = fetch_valid & id_ready_i;
  assign if_valid = (~halt_if_i) & if_ready;

  cv32e40p_aligner aligner_i (
      .clk             (clk),
      .rst_n           (rst_n),
      .fetch_valid_i   (fetch_valid),
      .aligner_ready_o (aligner_ready),
      .if_valid_i      (if_valid),
      .fetch_rdata_i   (fetch_rdata),
      .instr_aligned_o (instr_aligned),
      .instr_valid_o   (instr_valid),
      .branch_addr_i   ({branch_addr_n[31:1], 1'b0}),
      .branch_i        (branch_req),
      .hwlp_addr_i     (hwlp_target_i),
      .hwlp_update_pc_i(hwlp_jump_i),
      .pc_o            (pc_if_o)
  );

  cv32e40p_compressed_decoder #(
      .FPU  (FPU),
      .ZFINX(ZFINX)
  ) compressed_decoder_i (
      .instr_i        (instr_aligned),
      .instr_o        (instr_decompressed),
      .is_compressed_o(instr_compressed_int),
      .illegal_instr_o(illegal_c_insn)
  );

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

`ifdef CV32E40P_ASSERT_ON

  generate
    if (!COREV_PULP) begin : gen_no_pulp_xpulp_assertions

      // Check that PC Mux cannot select Hardware Loop address iF PULP extensions are not included
      property p_pc_mux_0;
        @(posedge clk) disable iff (!rst_n) (1'b1) |-> (pc_mux_i != PC_HWLOOP);
      endproperty

      a_pc_mux_0 :
      assert property (p_pc_mux_0);

    end
  endgenerate

  generate
    if (!PULP_SECURE) begin : gen_no_pulp_secure_assertions

      // Check that PC Mux cannot select URET address if User Mode is not included
      property p_pc_mux_1;
        @(posedge clk) disable iff (!rst_n) (1'b1) |-> (pc_mux_i != PC_URET);
      endproperty

      a_pc_mux_1 :
      assert property (p_pc_mux_1);

    end
  endgenerate

`endif

endmodule

// -------------------- END OF rtl/cv32e40p_if_stage.sv --------------------

// -------------------- START OF rtl/cv32e40p_int_controller.sv --------------------
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
// Engineer:       Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
// Design Name:    Interrupt Controller                                       //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Interrupt Controller of the pipelined processor            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_int_controller
  import cv32e40p_pkg::*;
#(
    parameter PULP_SECURE = 0
) (
    input logic clk,
    input logic rst_n,

    // External interrupt lines
    input logic [31:0] irq_i,  // Level-triggered interrupt inputs
    input logic        irq_sec_i,  // Interrupt secure bit from EU

    // To cv32e40p_controller
    output logic       irq_req_ctrl_o,
    output logic       irq_sec_ctrl_o,
    output logic [4:0] irq_id_ctrl_o,
    output logic       irq_wu_ctrl_o,

    // To/from cv32e40p_cs_registers
    input  logic     [31:0] mie_bypass_i,  // MIE CSR (bypass)
    output logic     [31:0] mip_o,  // MIP CSR
    input  logic            m_ie_i,  // Interrupt enable bit from CSR (M mode)
    input  logic            u_ie_i,  // Interrupt enable bit from CSR (U mode)
    input  PrivLvl_t        current_priv_lvl_i
);

  logic        global_irq_enable;
  logic [31:0] irq_local_qual;
  logic [31:0] irq_q;
  logic        irq_sec_q;

  // Register all interrupt inputs (on gated clock). The wake-up logic will
  // observe irq_i as well, but in all other places irq_q will be used to 
  // avoid timing paths from irq_i to instr_*_o

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      irq_q     <= '0;
      irq_sec_q <= 1'b0;
    end else begin
      irq_q     <= irq_i & IRQ_MASK;
      irq_sec_q <= irq_sec_i;
    end
  end

  // MIP CSR
  assign mip_o = irq_q;

  // Qualify registered IRQ with MIE CSR to compute locally enabled IRQs
  assign irq_local_qual = irq_q & mie_bypass_i;

  // Wake-up signal based on unregistered IRQ such that wake-up can be caused if no clock is present
  assign irq_wu_ctrl_o = |(irq_i & mie_bypass_i);

  // Global interrupt enable
  generate
    if (PULP_SECURE) begin : gen_pulp_secure
      assign global_irq_enable = ((u_ie_i || irq_sec_i) && current_priv_lvl_i == PRIV_LVL_U) || (m_ie_i && current_priv_lvl_i == PRIV_LVL_M);
    end else begin : gen_no_pulp_secure
      assign global_irq_enable = m_ie_i;
    end
  endgenerate

  // Request to take interrupt if there is a locally enabled interrupt while interrupts are also enabled globally
  assign irq_req_ctrl_o = (|irq_local_qual) && global_irq_enable;

  // Interrupt Encoder
  //
  // - sets correct id to request to ID
  // - encodes priority order

  always_comb begin
    if (irq_local_qual[31]) irq_id_ctrl_o = 5'd31;  // Custom irq_i[31]
    else if (irq_local_qual[30]) irq_id_ctrl_o = 5'd30;  // Custom irq_i[30]
    else if (irq_local_qual[29]) irq_id_ctrl_o = 5'd29;  // Custom irq_i[29]
    else if (irq_local_qual[28]) irq_id_ctrl_o = 5'd28;  // Custom irq_i[28]
    else if (irq_local_qual[27]) irq_id_ctrl_o = 5'd27;  // Custom irq_i[27]
    else if (irq_local_qual[26]) irq_id_ctrl_o = 5'd26;  // Custom irq_i[26]
    else if (irq_local_qual[25]) irq_id_ctrl_o = 5'd25;  // Custom irq_i[25]
    else if (irq_local_qual[24]) irq_id_ctrl_o = 5'd24;  // Custom irq_i[24]
    else if (irq_local_qual[23]) irq_id_ctrl_o = 5'd23;  // Custom irq_i[23]
    else if (irq_local_qual[22]) irq_id_ctrl_o = 5'd22;  // Custom irq_i[22]
    else if (irq_local_qual[21]) irq_id_ctrl_o = 5'd21;  // Custom irq_i[21]
    else if (irq_local_qual[20]) irq_id_ctrl_o = 5'd20;  // Custom irq_i[20]
    else if (irq_local_qual[19]) irq_id_ctrl_o = 5'd19;  // Custom irq_i[19]
    else if (irq_local_qual[18]) irq_id_ctrl_o = 5'd18;  // Custom irq_i[18]
    else if (irq_local_qual[17]) irq_id_ctrl_o = 5'd17;  // Custom irq_i[17]
    else if (irq_local_qual[16]) irq_id_ctrl_o = 5'd16;  // Custom irq_i[16]

    else if (irq_local_qual[15])
      irq_id_ctrl_o = 5'd15;  // Reserved  (default masked out with IRQ_MASK)
    else if (irq_local_qual[14])
      irq_id_ctrl_o = 5'd14;  // Reserved  (default masked out with IRQ_MASK)
    else if (irq_local_qual[13])
      irq_id_ctrl_o = 5'd13;  // Reserved  (default masked out with IRQ_MASK)
    else if (irq_local_qual[12])
      irq_id_ctrl_o = 5'd12;  // Reserved  (default masked out with IRQ_MASK)

    else if (irq_local_qual[CSR_MEIX_BIT]) irq_id_ctrl_o = CSR_MEIX_BIT;  // MEI, irq_i[11]
    else if (irq_local_qual[CSR_MSIX_BIT]) irq_id_ctrl_o = CSR_MSIX_BIT;  // MSI, irq_i[3]
    else if (irq_local_qual[CSR_MTIX_BIT]) irq_id_ctrl_o = CSR_MTIX_BIT;  // MTI, irq_i[7]

    else if (irq_local_qual[10])
      irq_id_ctrl_o = 5'd10;                         // Reserved (for now assuming EI, SI, TI priority) (default masked out with IRQ_MASK)
    else if (irq_local_qual[2])
      irq_id_ctrl_o = 5'd2;                          // Reserved (for now assuming EI, SI, TI priority) (default masked out with IRQ_MASK)
    else if (irq_local_qual[6])
      irq_id_ctrl_o = 5'd6;                          // Reserved (for now assuming EI, SI, TI priority) (default masked out with IRQ_MASK)

    else if (irq_local_qual[9])
      irq_id_ctrl_o = 5'd9;  // Reserved: SEI (default masked out with IRQ_MASK)
    else if (irq_local_qual[1])
      irq_id_ctrl_o = 5'd1;  // Reserved: SSI (default masked out with IRQ_MASK)
    else if (irq_local_qual[5])
      irq_id_ctrl_o = 5'd5;  // Reserved: STI (default masked out with IRQ_MASK)

    else if (irq_local_qual[8])
      irq_id_ctrl_o = 5'd8;  // Reserved: UEI (default masked out with IRQ_MASK)
    else if (irq_local_qual[0])
      irq_id_ctrl_o = 5'd0;  // Reserved: USI (default masked out with IRQ_MASK)
    else if (irq_local_qual[4])
      irq_id_ctrl_o = 5'd4;  // Reserved: UTI (default masked out with IRQ_MASK)

    else irq_id_ctrl_o = CSR_MTIX_BIT;  // Value not relevant
  end

  assign irq_sec_ctrl_o = irq_sec_q;

endmodule  // cv32e40p_int_controller

// -------------------- END OF rtl/cv32e40p_int_controller.sv --------------------

// -------------------- START OF rtl/cv32e40p_load_store_unit.sv --------------------
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
// Engineer:       Igor Loi - igor.loi@unibo.it                               //
//                                                                            //
// Additional contributions by:                                               //
//                 Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Design Name:    Load Store Unit                                            //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Load Store Unit, used to eliminate multiple access during  //
//                 processor stalls, and to align bytes and halfwords         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_load_store_unit #(
    parameter PULP_OBI = 0  // Legacy PULP OBI behavior
) (
    input logic clk,
    input logic rst_n,

    // output to data memory
    output logic data_req_o,
    input logic data_gnt_i,
    input logic data_rvalid_i,
    input  logic         data_err_i,           // External bus error (validity defined by data_rvalid_i) (not used yet)
    input logic data_err_pmp_i,  // PMP error (validity defined by data_gnt_i)

    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,

    // signals from ex stage
    input logic        data_we_ex_i,  // write enable                      -> from ex stage
    input logic [ 1:0] data_type_ex_i,  // Data type word, halfword, byte    -> from ex stage
    input logic [31:0] data_wdata_ex_i,  // data to write to memory           -> from ex stage
    input logic [ 1:0] data_reg_offset_ex_i,  // offset inside register for stores -> from ex stage
    input logic        data_load_event_ex_i,  // load event                        -> from ex stage
    input logic [ 1:0] data_sign_ext_ex_i,  // sign extension                    -> from ex stage

    output logic [31:0] data_rdata_ex_o,  // requested data                    -> to ex stage
    input  logic        data_req_ex_i,  // data request                      -> from ex stage
    input  logic [31:0] operand_a_ex_i,  // operand a from RF for address     -> from ex stage
    input  logic [31:0] operand_b_ex_i,  // operand b from RF for address     -> from ex stage
    input  logic        addr_useincr_ex_i,  // use a + b or just a for address   -> from ex stage

    input  logic data_misaligned_ex_i,  // misaligned access in last ld/st   -> from ID/EX pipeline
    output logic data_misaligned_o,  // misaligned access was detected    -> to controller

    input  logic [5:0] data_atop_ex_i,  // atomic instructions signal        -> from ex stage
    output logic [5:0] data_atop_o,  // atomic instruction signal         -> core output

    output logic p_elw_start_o,  // load event starts
    output logic p_elw_finish_o,  // load event finishes

    // stall signal
    output logic lsu_ready_ex_o,  // LSU ready for new data in EX stage
    output logic lsu_ready_wb_o,  // LSU ready for new data in WB stage

    output logic busy_o
);

  localparam DEPTH = 2;  // Maximum number of outstanding transactions

  // Transaction request (to cv32e40p_obi_interface)
  logic trans_valid;
  logic trans_ready;
  logic [31:0] trans_addr;
  logic trans_we;
  logic [3:0] trans_be;
  logic [31:0] trans_wdata;
  logic [5:0] trans_atop;

  // Transaction response interface (from cv32e40p_obi_interface)
  logic resp_valid;
  logic [31:0] resp_rdata;
  logic resp_err;  // Unused for now

  // Counter to count maximum number of outstanding transactions
  logic [1:0] cnt_q;  // Transaction counter
  logic [1:0] next_cnt;  // Next value for cnt_q
  logic         count_up;               // Increment outstanding transaction count by 1 (can happen at same time as count_down)
  logic         count_down;             // Decrement outstanding transaction count by 1 (can happen at same time as count_up)

  logic ctrl_update;  // Update load/store control info in WB stage

  logic [31:0] data_addr_int;

  // registers for data_rdata alignment and sign extension
  logic [1:0] data_type_q;
  logic [1:0] rdata_offset_q;
  logic [1:0] data_sign_ext_q;
  logic data_we_q;
  logic data_load_event_q;

  logic [1:0] wdata_offset;  // mux control for data to be written to memory

  logic [3:0] data_be;
  logic [31:0] data_wdata;

  logic misaligned_st;  // high if we are currently performing the second part of a misaligned store
  logic load_err_o, store_err_o;

  logic [31:0] rdata_q;

  ///////////////////////////////// BE generation ////////////////////////////////
  always_comb begin
    case (data_type_ex_i)  // Data type 00 Word, 01 Half word, 11,10 byte
      2'b00: begin  // Writing a word
        if (misaligned_st == 1'b0) begin  // non-misaligned case
          case (data_addr_int[1:0])
            2'b00: data_be = 4'b1111;
            2'b01: data_be = 4'b1110;
            2'b10: data_be = 4'b1100;
            2'b11: data_be = 4'b1000;
          endcase
          ;  // case (data_addr_int[1:0])
        end else begin  // misaligned case
          case (data_addr_int[1:0])
            2'b00: data_be = 4'b0000;  // this is not used, but included for completeness
            2'b01: data_be = 4'b0001;
            2'b10: data_be = 4'b0011;
            2'b11: data_be = 4'b0111;
          endcase
          ;  // case (data_addr_int[1:0])
        end
      end

      2'b01: begin  // Writing a half word
        if (misaligned_st == 1'b0) begin  // non-misaligned case
          case (data_addr_int[1:0])
            2'b00: data_be = 4'b0011;
            2'b01: data_be = 4'b0110;
            2'b10: data_be = 4'b1100;
            2'b11: data_be = 4'b1000;
          endcase
          ;  // case (data_addr_int[1:0])
        end else begin  // misaligned case
          data_be = 4'b0001;
        end
      end

      2'b10, 2'b11: begin  // Writing a byte
        case (data_addr_int[1:0])
          2'b00: data_be = 4'b0001;
          2'b01: data_be = 4'b0010;
          2'b10: data_be = 4'b0100;
          2'b11: data_be = 4'b1000;
        endcase
        ;  // case (data_addr_int[1:0])
      end
    endcase
    ;  // case (data_type_ex_i)
  end

  // prepare data to be written to the memory
  // we handle misaligned accesses, half word and byte accesses and
  // register offsets here
  assign wdata_offset = data_addr_int[1:0] - data_reg_offset_ex_i[1:0];
  always_comb begin
    case (wdata_offset)
      2'b00: data_wdata = data_wdata_ex_i[31:0];
      2'b01: data_wdata = {data_wdata_ex_i[23:0], data_wdata_ex_i[31:24]};
      2'b10: data_wdata = {data_wdata_ex_i[15:0], data_wdata_ex_i[31:16]};
      2'b11: data_wdata = {data_wdata_ex_i[7:0], data_wdata_ex_i[31:8]};
    endcase
    ;  // case (wdata_offset)
  end


  // FF for rdata alignment and sign-extension
  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      data_type_q       <= '0;
      rdata_offset_q    <= '0;
      data_sign_ext_q   <= '0;
      data_we_q         <= 1'b0;
      data_load_event_q <= 1'b0;
    end
    else if (ctrl_update) // request was granted, we wait for rvalid and can continue to WB
    begin
      data_type_q       <= data_type_ex_i;
      rdata_offset_q    <= data_addr_int[1:0];
      data_sign_ext_q   <= data_sign_ext_ex_i;
      data_we_q         <= data_we_ex_i;
      data_load_event_q <= data_load_event_ex_i;
    end
  end

  // Load event starts when request is sent and finishes when (final) rvalid is received
  assign p_elw_start_o  = data_load_event_ex_i && data_req_o;
  assign p_elw_finish_o = data_load_event_q && data_rvalid_i && !data_misaligned_ex_i;

  ////////////////////////////////////////////////////////////////////////
  //  ____  _               _____      _                 _              //
  // / ___|(_) __ _ _ __   | ____|_  _| |_ ___ _ __  ___(_) ___  _ __   //
  // \___ \| |/ _` | '_ \  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \  //
  //  ___) | | (_| | | | | | |___ >  <| ||  __/ | | \__ \ | (_) | | | | //
  // |____/|_|\__, |_| |_| |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_| //
  //          |___/                                                     //
  ////////////////////////////////////////////////////////////////////////

  logic [31:0] data_rdata_ext;

  logic [31:0] rdata_w_ext;  // sign extension for words, actually only misaligned assembly
  logic [31:0] rdata_h_ext;  // sign extension for half words
  logic [31:0] rdata_b_ext;  // sign extension for bytes

  // take care of misaligned words
  always_comb begin
    case (rdata_offset_q)
      2'b00: rdata_w_ext = resp_rdata[31:0];
      2'b01: rdata_w_ext = {resp_rdata[7:0], rdata_q[31:8]};
      2'b10: rdata_w_ext = {resp_rdata[15:0], rdata_q[31:16]};
      2'b11: rdata_w_ext = {resp_rdata[23:0], rdata_q[31:24]};
    endcase
  end

  // sign extension for half words
  always_comb begin
    case (rdata_offset_q)
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[15:0]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[15:0]};
        else rdata_h_ext = {{16{resp_rdata[15]}}, resp_rdata[15:0]};
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[23:8]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[23:8]};
        else rdata_h_ext = {{16{resp_rdata[23]}}, resp_rdata[23:8]};
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[31:16]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[31:16]};
        else rdata_h_ext = {{16{resp_rdata[31]}}, resp_rdata[31:16]};
      end

      2'b11: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[7:0], rdata_q[31:24]};
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[7:0], rdata_q[31:24]};
        else rdata_h_ext = {{16{resp_rdata[7]}}, resp_rdata[7:0], rdata_q[31:24]};
      end
    endcase  // case (rdata_offset_q)
  end

  // sign extension for bytes
  always_comb begin
    case (rdata_offset_q)
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[7:0]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[7:0]};
        else rdata_b_ext = {{24{resp_rdata[7]}}, resp_rdata[7:0]};
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[15:8]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[15:8]};
        else rdata_b_ext = {{24{resp_rdata[15]}}, resp_rdata[15:8]};
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[23:16]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[23:16]};
        else rdata_b_ext = {{24{resp_rdata[23]}}, resp_rdata[23:16]};
      end

      2'b11: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[31:24]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[31:24]};
        else rdata_b_ext = {{24{resp_rdata[31]}}, resp_rdata[31:24]};
      end
    endcase  // case (rdata_offset_q)
  end

  // select word, half word or byte sign extended version
  always_comb begin
    case (data_type_q)
      2'b00:        data_rdata_ext = rdata_w_ext;
      2'b01:        data_rdata_ext = rdata_h_ext;
      2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
    endcase  //~case(rdata_type_q)
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      rdata_q <= '0;
    end else begin
      if (resp_valid && (~data_we_q)) begin
        // if we have detected a misaligned access, and we are
        // currently doing the first part of this access, then
        // store the data coming from memory in rdata_q.
        // In all other cases, rdata_q gets the value that we are
        // writing to the register file
        if ((data_misaligned_ex_i == 1'b1) || (data_misaligned_o == 1'b1)) rdata_q <= resp_rdata;
        else rdata_q <= data_rdata_ext;
      end
    end
  end

  // output to register file
  assign data_rdata_ex_o = (resp_valid == 1'b1) ? data_rdata_ext : rdata_q;

  assign misaligned_st   = data_misaligned_ex_i;

  // Note: PMP is not fully supported at the moment (not even if USE_PMP = 1)
  assign load_err_o      = data_gnt_i && data_err_pmp_i && ~data_we_o;  // Not currently used
  assign store_err_o     = data_gnt_i && data_err_pmp_i && data_we_o;  // Not currently used


  // check for misaligned accesses that need a second memory access
  // If one is detected, this is signaled with data_misaligned_o to
  // the controller which selectively stalls the pipeline
  always_comb begin
    data_misaligned_o = 1'b0;

    if ((data_req_ex_i == 1'b1) && (data_misaligned_ex_i == 1'b0)) begin
      case (data_type_ex_i)
        2'b00: // word
        begin
          if (data_addr_int[1:0] != 2'b00) data_misaligned_o = 1'b1;
        end
        2'b01: // half word
        begin
          if (data_addr_int[1:0] == 2'b11) data_misaligned_o = 1'b1;
        end
      endcase  // case (data_type_ex_i)
    end
  end

  // generate address from operands
  assign data_addr_int = (addr_useincr_ex_i) ? (operand_a_ex_i + operand_b_ex_i) : operand_a_ex_i;

  // Busy if there are ongoing (or potentially outstanding) transfers
  assign busy_o = (cnt_q != 2'b00) || trans_valid;

  //////////////////////////////////////////////////////////////////////////////
  // Transaction request generation
  //
  // Assumes that corresponding response is at least 1 cycle after request
  //
  // - Only request transaction when EX stage requires data transfer (data_req_ex_i), and
  // - maximum number of outstanding transactions will not be exceeded (cnt_q < DEPTH)
  //////////////////////////////////////////////////////////////////////////////

  // For last phase of misaligned transfer the address needs to be word aligned (as LSB of data_be will be set)
  assign trans_addr = data_misaligned_ex_i ? {data_addr_int[31:2], 2'b00} : data_addr_int;
  assign trans_we = data_we_ex_i;
  assign trans_be = data_be;
  assign trans_wdata = data_wdata;
  assign trans_atop = data_atop_ex_i;

  // Transaction request generation
  generate
    if (PULP_OBI == 0) begin : gen_no_pulp_obi
      // OBI compatible (avoids combinatorial path from data_rvalid_i to data_req_o).
      // Multiple trans_* transactions can be issued (and accepted) before a response
      // (resp_*) is received.
      assign trans_valid = data_req_ex_i && (cnt_q < DEPTH);
    end else begin : gen_pulp_obi
      // Legacy PULP OBI behavior, i.e. only issue subsequent transaction if preceding transfer
      // is about to finish (re-introducing timing critical path from data_rvalid_i to data_req_o)
      assign trans_valid = (cnt_q == 2'b00) ? data_req_ex_i && (cnt_q < DEPTH) :
                                              data_req_ex_i && (cnt_q < DEPTH) && resp_valid;
    end
  endgenerate

  // LSU WB stage is ready if it is not being used (i.e. no outstanding transfers, cnt_q = 0),
  // or if it WB stage is being used and the awaited response arrives (resp_rvalid).
  assign lsu_ready_wb_o = (cnt_q == 2'b00) ? 1'b1 : resp_valid;

  // LSU EX stage readyness requires two criteria to be met:
  // 
  // - A data request (data_req_ex_i) has been forwarded/accepted (trans_valid && trans_ready)
  // - The LSU WB stage is available such that EX and WB can be updated in lock step
  //
  // Default (if there is not even a data request) LSU EX is signaled to be ready, else
  // if there are no outstanding transactions the EX stage is ready again once the transaction
  // request is accepted (at which time this load/store will move to the WB stage), else
  // in case there is already at least one outstanding transaction (so WB is full) the EX 
  // and WB stage can only signal readiness in lock step (so resp_valid is used as well).

  assign lsu_ready_ex_o = (data_req_ex_i == 1'b0) ? 1'b1 :
                          (cnt_q == 2'b00) ? (              trans_valid && trans_ready) : 
                          (cnt_q == 2'b01) ? (resp_valid && trans_valid && trans_ready) : 
                                              resp_valid;

  // Update signals for EX/WB registers (when EX has valid data itself and is ready for next)
  assign ctrl_update = lsu_ready_ex_o && data_req_ex_i;


  //////////////////////////////////////////////////////////////////////////////
  // Counter (cnt_q, next_cnt) to count number of outstanding OBI transactions 
  // (maximum = DEPTH)
  // 
  // Counter overflow is prevented by limiting the number of outstanding transactions
  // to DEPTH. Counter underflow is prevented by the assumption that resp_valid = 1 
  // will only occur in response to accepted transfer request (as per the OBI protocol).
  //////////////////////////////////////////////////////////////////////////////

  assign count_up = trans_valid && trans_ready;  // Increment upon accepted transfer request
  assign count_down = resp_valid;  // Decrement upon accepted transfer response

  always_comb begin
    unique case ({
      count_up, count_down
    })
      2'b00: begin
        next_cnt = cnt_q;
      end
      2'b01: begin
        next_cnt = cnt_q - 1'b1;
      end
      2'b10: begin
        next_cnt = cnt_q + 1'b1;
      end
      2'b11: begin
        next_cnt = cnt_q;
      end
    endcase
  end


  //////////////////////////////////////////////////////////////////////////////
  // Registers
  //////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      cnt_q <= '0;
    end else begin
      cnt_q <= next_cnt;
    end
  end


  //////////////////////////////////////////////////////////////////////////////
  // OBI interface
  //////////////////////////////////////////////////////////////////////////////

  cv32e40p_obi_interface #(
      .TRANS_STABLE(1)
  ) data_obi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i (trans_addr),
      .trans_we_i   (trans_we),
      .trans_be_i   (trans_be),
      .trans_wdata_i(trans_wdata),
      .trans_atop_i (trans_atop),

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),  // Unused for now

      .obi_req_o   (data_req_o),
      .obi_gnt_i   (data_gnt_i),
      .obi_addr_o  (data_addr_o),
      .obi_we_o    (data_we_o),
      .obi_be_o    (data_be_o),
      .obi_wdata_o (data_wdata_o),
      .obi_atop_o  (data_atop_o),  // Not (yet) defined in OBI 1.0 spec
      .obi_rdata_i (data_rdata_i),
      .obi_rvalid_i(data_rvalid_i),
      .obi_err_i   (data_err_i)  // External bus error (validity defined by obi_rvalid_i)
  );


  //////////////////////////////////////////////////////////////////////////////
  // Assertions
  //////////////////////////////////////////////////////////////////////////////

`ifdef CV32E40P_ASSERT_ON

  // External data bus errors are not supported yet. PMP errors are not supported yet.
  // 
  // Note: Once PMP is re-introduced please consider to make data_err_pmp_i a 'data' signal
  // that is qualified with data_req_o && data_gnt_i (instead of suppressing data_gnt_i 
  // as is currently done. This will keep the data_req_o/data_gnt_i protocol intact.
  //
  // JUST RE-ENABLING the PMP VIA ITS USE_PMP LOCALPARAM WILL NOT WORK AS DATA_ERR_PMP_I 
  // NO LONGER FEEDS INTO LSU_READY_EX_O.

  property p_no_error;
    @(posedge clk) (1'b1) |-> ((data_err_i == 1'b0) && (data_err_pmp_i == 1'b0));
  endproperty

  a_no_error :
  assert property (p_no_error);

  // Check that outstanding transaction count will not overflow DEPTH
  property p_no_transaction_count_overflow_0;
    @(posedge clk) (1'b1) |-> (cnt_q <= DEPTH);
  endproperty

  a_no_transaction_count_overflow_0 :
  assert property (p_no_transaction_count_overflow_0);

  property p_no_transaction_count_overflow_1;
    @(posedge clk) (cnt_q == DEPTH) |-> (!count_up || count_down);
  endproperty

  a_no_transaction_count_overflow_1 :
  assert property (p_no_transaction_count_overflow_1);

  // Check that an rvalid only occurs when there are outstanding transaction(s)
  property p_no_spurious_rvalid;
    @(posedge clk) (data_rvalid_i == 1'b1) |-> (cnt_q > 0);
  endproperty

  a_no_spurious_rvalid :
  assert property (p_no_spurious_rvalid);

  // Check that the address/we/be/atop does not contain X when request is sent
  property p_address_phase_signals_defined;
    @(posedge clk) (data_req_o == 1'b1) |-> (!($isunknown(
        data_addr_o
    ) || $isunknown(
        data_we_o
    ) || $isunknown(
        data_be_o
    ) || $isunknown(
        data_atop_o
    )));
  endproperty

  a_address_phase_signals_defined :
  assert property (p_address_phase_signals_defined);

`endif

endmodule

// -------------------- END OF rtl/cv32e40p_load_store_unit.sv --------------------

// -------------------- START OF rtl/cv32e40p_mult.sv --------------------
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
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Subword multiplier and MAC                                 //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Advanced MAC unit for PULP.                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_mult
  import cv32e40p_pkg::*;
(
    input logic clk,
    input logic rst_n,

    input logic        enable_i,
    input mul_opcode_e operator_i,

    // integer and short multiplier
    input logic       short_subword_i,
    input logic [1:0] short_signed_i,

    input logic [31:0] op_a_i,
    input logic [31:0] op_b_i,
    input logic [31:0] op_c_i,

    input logic [4:0] imm_i,


    // dot multiplier
    input logic [ 1:0] dot_signed_i,
    input logic [31:0] dot_op_a_i,
    input logic [31:0] dot_op_b_i,
    input logic [31:0] dot_op_c_i,
    input logic        is_clpx_i,
    input logic [ 1:0] clpx_shift_i,
    input logic        clpx_img_i,

    output logic [31:0] result_o,

    output logic multicycle_o,
    output logic mulh_active_o,
    output logic ready_o,
    input  logic ex_ready_i
);

  ///////////////////////////////////////////////////////////////
  //  ___ _  _ _____ ___ ___ ___ ___   __  __ _   _ _  _____   //
  // |_ _| \| |_   _| __/ __| __| _ \ |  \/  | | | | ||_   _|  //
  //  | || .  | | | | _| (_ | _||   / | |\/| | |_| | |__| |    //
  // |___|_|\_| |_| |___\___|___|_|_\ |_|  |_|\___/|____|_|    //
  //                                                           //
  ///////////////////////////////////////////////////////////////

  logic [16:0] short_op_a;
  logic [16:0] short_op_b;
  logic [32:0] short_op_c;
  logic [33:0] short_mul;
  logic [33:0] short_mac;
  logic [31:0] short_round, short_round_tmp;
  logic [33:0] short_result;

  logic        short_mac_msb1;
  logic        short_mac_msb0;

  logic [ 4:0] short_imm;
  logic [ 1:0] short_subword;
  logic [ 1:0] short_signed;
  logic        short_shift_arith;
  logic [ 4:0] mulh_imm;
  logic [ 1:0] mulh_subword;
  logic [ 1:0] mulh_signed;
  logic        mulh_shift_arith;
  logic        mulh_carry_q;
  logic        mulh_save;
  logic        mulh_clearcarry;
  logic        mulh_ready;

  mult_state_e mulh_CS, mulh_NS;

  // prepare the rounding value
  assign short_round_tmp = (32'h00000001) << imm_i;
  assign short_round = (operator_i == MUL_IR) ? {1'b0, short_round_tmp[31:1]} : '0;

  // perform subword selection and sign extensions
  assign short_op_a[15:0] = short_subword[0] ? op_a_i[31:16] : op_a_i[15:0];
  assign short_op_b[15:0] = short_subword[1] ? op_b_i[31:16] : op_b_i[15:0];

  assign short_op_a[16] = short_signed[0] & short_op_a[15];
  assign short_op_b[16] = short_signed[1] & short_op_b[15];

  assign short_op_c = mulh_active_o ? $signed({mulh_carry_q, op_c_i}) : $signed(op_c_i);

  assign short_mul = $signed(short_op_a) * $signed(short_op_b);
  assign short_mac = $signed(short_op_c) + $signed(short_mul) + $signed(short_round);

  //we use only short_signed_i[0] as it cannot be short_signed_i[1] 1 and short_signed_i[0] 0
  assign short_result = $signed(
      {short_shift_arith & short_mac_msb1, short_shift_arith & short_mac_msb0, short_mac[31:0]}
  ) >>> short_imm;

  // choose between normal short multiplication operation and mulh operation
  assign short_imm = mulh_active_o ? mulh_imm : imm_i;
  assign short_subword = mulh_active_o ? mulh_subword : {2{short_subword_i}};
  assign short_signed = mulh_active_o ? mulh_signed : short_signed_i;
  assign short_shift_arith = mulh_active_o ? mulh_shift_arith : short_signed_i[0];

  assign short_mac_msb1 = mulh_active_o ? short_mac[33] : short_mac[31];
  assign short_mac_msb0 = mulh_active_o ? short_mac[32] : short_mac[31];


  always_comb begin
    mulh_NS          = mulh_CS;
    mulh_imm         = 5'd0;
    mulh_subword     = 2'b00;
    mulh_signed      = 2'b00;
    mulh_shift_arith = 1'b0;
    mulh_ready       = 1'b0;
    mulh_active_o    = 1'b1;
    mulh_save        = 1'b0;
    mulh_clearcarry  = 1'b0;
    multicycle_o     = 1'b0;

    case (mulh_CS)
      IDLE_MULT: begin
        mulh_active_o = 1'b0;
        mulh_ready    = 1'b1;
        mulh_save     = 1'b0;
        if ((operator_i == MUL_H) && enable_i) begin
          mulh_ready = 1'b0;
          mulh_NS    = STEP0;
        end
      end

      STEP0: begin
        multicycle_o  = 1'b1;
        mulh_imm      = 5'd16;
        mulh_active_o = 1'b1;
        //AL*BL never overflows
        mulh_save     = 1'b0;
        mulh_NS       = STEP1;
        //Here always a 32'b unsigned result (no carry)
      end

      STEP1: begin
        multicycle_o     = 1'b1;
        //AL*BH is signed iff B is signed
        mulh_signed      = {short_signed_i[1], 1'b0};
        mulh_subword     = 2'b10;
        mulh_save        = 1'b1;
        mulh_shift_arith = 1'b1;
        mulh_NS          = STEP2;
        //Here signed 32'b + unsigned 32'b result.
        //Result is a signed 33'b
        //Store the carry as it will be used as sign extension, we do
        //not shift
      end

      STEP2: begin
        multicycle_o     = 1'b1;
        //AH*BL is signed iff A is signed
        mulh_signed      = {1'b0, short_signed_i[0]};
        mulh_subword     = 2'b01;
        mulh_imm         = 5'd16;
        mulh_save        = 1'b1;
        mulh_clearcarry  = 1'b1;
        mulh_shift_arith = 1'b1;
        mulh_NS          = FINISH;
        //Here signed 32'b + signed 33'b result.
        //Result is a signed 34'b
        //We do not store the carries as the bits 34:33 are shifted back, so we clear it
      end

      FINISH: begin
        mulh_signed  = short_signed_i;
        mulh_subword = 2'b11;
        mulh_ready   = 1'b1;
        if (ex_ready_i) mulh_NS = IDLE_MULT;
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mulh_CS      <= IDLE_MULT;
      mulh_carry_q <= 1'b0;
    end else begin
      mulh_CS <= mulh_NS;

      if (mulh_save) mulh_carry_q <= ~mulh_clearcarry & short_mac[32];
      else if (ex_ready_i)  // clear carry when we are going to the next instruction
        mulh_carry_q <= 1'b0;
    end
  end

  // 32x32 = 32-bit multiplier
  logic [31:0] int_op_a_msu;
  logic [31:0] int_op_b_msu;
  logic [31:0] int_result;

  logic        int_is_msu;

  assign int_is_msu = (operator_i == MUL_MSU32);

  assign int_op_a_msu = op_a_i ^ {32{int_is_msu}};
  assign int_op_b_msu = op_b_i & {32{int_is_msu}};

  assign int_result = $signed(
      op_c_i
  ) + $signed(
      int_op_b_msu
  ) + $signed(
      int_op_a_msu
  ) * $signed(
      op_b_i
  );

  ///////////////////////////////////////////////
  //  ___   ___ _____   __  __ _   _ _  _____  //
  // |   \ / _ \_   _| |  \/  | | | | ||_   _| //
  // | |) | (_) || |   | |\/| | |_| | |__| |   //
  // |___/ \___/ |_|   |_|  |_|\___/|____|_|   //
  //                                           //
  ///////////////////////////////////////////////

  logic [31:0] dot_char_result;
  logic [32:0] dot_short_result;
  logic [31:0] accumulator;
  logic [15:0] clpx_shift_result;
  logic [3:0][8:0] dot_char_op_a;
  logic [3:0][8:0] dot_char_op_b;
  logic [3:0][17:0] dot_char_mul;

  logic [1:0][16:0] dot_short_op_a;
  logic [1:0][16:0] dot_short_op_b;
  logic [1:0][33:0] dot_short_mul;
  logic      [16:0] dot_short_op_a_1_neg; //to compute -rA[31:16]*rB[31:16] -> (!rA[31:16] + 1)*rB[31:16] = !rA[31:16]*rB[31:16] + rB[31:16]
  logic [31:0] dot_short_op_b_ext;

  assign dot_char_op_a[0] = {dot_signed_i[1] & dot_op_a_i[7], dot_op_a_i[7:0]};
  assign dot_char_op_a[1] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:8]};
  assign dot_char_op_a[2] = {dot_signed_i[1] & dot_op_a_i[23], dot_op_a_i[23:16]};
  assign dot_char_op_a[3] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:24]};

  assign dot_char_op_b[0] = {dot_signed_i[0] & dot_op_b_i[7], dot_op_b_i[7:0]};
  assign dot_char_op_b[1] = {dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:8]};
  assign dot_char_op_b[2] = {dot_signed_i[0] & dot_op_b_i[23], dot_op_b_i[23:16]};
  assign dot_char_op_b[3] = {dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:24]};

  assign dot_char_mul[0] = $signed(dot_char_op_a[0]) * $signed(dot_char_op_b[0]);
  assign dot_char_mul[1] = $signed(dot_char_op_a[1]) * $signed(dot_char_op_b[1]);
  assign dot_char_mul[2] = $signed(dot_char_op_a[2]) * $signed(dot_char_op_b[2]);
  assign dot_char_mul[3] = $signed(dot_char_op_a[3]) * $signed(dot_char_op_b[3]);

  assign dot_char_result = $signed(
      dot_char_mul[0]
  ) + $signed(
      dot_char_mul[1]
  ) + $signed(
      dot_char_mul[2]
  ) + $signed(
      dot_char_mul[3]
  ) + $signed(
      dot_op_c_i
  );


  assign dot_short_op_a[0] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:0]};
  assign dot_short_op_a[1] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:16]};
  assign dot_short_op_a_1_neg = dot_short_op_a[1] ^ {17{(is_clpx_i & ~clpx_img_i)}}; //negates whether clpx_img_i is 0 or 1, only REAL PART needs to be negated

  assign dot_short_op_b[0] = (is_clpx_i & clpx_img_i) ? {
    dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]
  } : {
    dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]
  };
  assign dot_short_op_b[1] = (is_clpx_i & clpx_img_i) ? {
    dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]
  } : {
    dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]
  };

  assign dot_short_mul[0] = $signed(dot_short_op_a[0]) * $signed(dot_short_op_b[0]);
  assign dot_short_mul[1] = $signed(dot_short_op_a_1_neg) * $signed(dot_short_op_b[1]);

  assign dot_short_op_b_ext = $signed(dot_short_op_b[1]);
  assign accumulator = is_clpx_i ? dot_short_op_b_ext & {32{~clpx_img_i}} : $signed(dot_op_c_i);

  assign dot_short_result = $signed(
      dot_short_mul[0][31:0]
  ) + $signed(
      dot_short_mul[1][31:0]
  ) + $signed(
      accumulator
  );
  assign clpx_shift_result = $signed(dot_short_result[31:15]) >>> clpx_shift_i;

  ////////////////////////////////////////////////////////
  //   ____                 _ _     __  __              //
  //  |  _ \ ___  ___ _   _| | |_  |  \/  |_   ___  __  //
  //  | |_) / _ \/ __| | | | | __| | |\/| | | | \ \/ /  //
  //  |  _ <  __/\__ \ |_| | | |_  | |  | | |_| |>  <   //
  //  |_| \_\___||___/\__,_|_|\__| |_|  |_|\__,_/_/\_\  //
  //                                                    //
  ////////////////////////////////////////////////////////

  always_comb begin
    result_o = '0;

    unique case (operator_i)
      MUL_MAC32, MUL_MSU32: result_o = int_result[31:0];

      MUL_I, MUL_IR, MUL_H: result_o = short_result[31:0];

      MUL_DOT8: result_o = dot_char_result[31:0];
      MUL_DOT16: begin
        if (is_clpx_i) begin
          if (clpx_img_i) begin
            result_o[31:16] = clpx_shift_result;
            result_o[15:0]  = dot_op_c_i[15:0];
          end else begin
            result_o[15:0]  = clpx_shift_result;
            result_o[31:16] = dot_op_c_i[31:16];
          end
        end else begin
          result_o = dot_short_result[31:0];
        end
      end

      default: ;  // default case to suppress unique warning
    endcase
  end

  assign ready_o = mulh_ready;

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

  // check multiplication result for mulh
`ifdef CV32E40P_ASSERT_ON
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b11))
    |->
    (result_o == (($signed(
      {{32{op_a_i[31]}}, op_a_i}
  ) * $signed(
      {{32{op_b_i[31]}}, op_b_i}
  )) >>> 32)));

  // check multiplication result for mulhsu
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b01))
    |->
    (result_o == (($signed(
      {{32{op_a_i[31]}}, op_a_i}
  ) * {
    32'b0, op_b_i
  }) >> 32)));

  // check multiplication result for mulhu
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b00))
    |->
    (result_o == (({
    32'b0, op_a_i
  } * {
    32'b0, op_b_i
  }) >> 32)));
`endif
endmodule

// -------------------- END OF rtl/cv32e40p_mult.sv --------------------

// -------------------- START OF rtl/cv32e40p_obi_interface.sv --------------------
// Copyright 2020 Silicon Labs, Inc.
//
// This file, and derivatives thereof are licensed under the
// Solderpad License, Version 2.0 (the "License").
//
// Use of this file means you agree to the terms and conditions
// of the license and are in full compliance with the License.
//
// You may obtain a copy of the License at:
//
//     https://solderpad.org/licenses/SHL-2.0/
//
// Unless required by applicable law or agreed to in writing, software
// and hardware implementations thereof distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
//
// See the License for the specific language governing permissions and
// limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Arjan Bink - arjan.bink@silabs.com                         //
//                                                                            //
// Design Name:    OBI (Open Bus Interface)                                   //
// Project Name:   CV32E40P                                                   //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Open Bus Interface adapter. Translates transaction request //
//                 on the trans_* interface into an OBI A channel transfer.   //
//                 The OBI R channel transfer translated (i.e. passed on) as  //
//                 a transaction response on the resp_* interface.            //
//                                                                            //
//                 This adapter does not limit the number of outstanding      //
//                 OBI transactions in any way.                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_obi_interface #(
    parameter TRANS_STABLE =  0                   // Are trans_addr_i, trans_we_i, trans_be_i, trans_wdata_i, trans_atop_i signals stable during a non-accepted transaction?
) (
    input logic clk,
    input logic rst_n,

    // Transaction request interface
    input logic trans_valid_i,
    output logic trans_ready_o,
    input logic [31:0] trans_addr_i,
    input logic trans_we_i,
    input logic [3:0] trans_be_i,
    input logic [31:0] trans_wdata_i,
    input  logic  [5:0] trans_atop_i,             // Future proof addition (not part of OBI 1.0 spec; not used in CV32E40P)

    // Transaction response interface
    output logic resp_valid_o,  // Note: Consumer is assumed to be 'ready' whenever resp_valid_o = 1
    output logic [31:0] resp_rdata_o,
    output logic resp_err_o,

    // OBI interface
    output logic        obi_req_o,
    input  logic        obi_gnt_i,
    output logic [31:0] obi_addr_o,
    output logic        obi_we_o,
    output logic [ 3:0] obi_be_o,
    output logic [31:0] obi_wdata_o,
    output logic [ 5:0] obi_atop_o,
    input  logic [31:0] obi_rdata_i,
    input  logic        obi_rvalid_i,
    input  logic        obi_err_i
);

  enum logic {
    TRANSPARENT,
    REGISTERED
  }
      state_q, next_state;

  //////////////////////////////////////////////////////////////////////////////
  // OBI R Channel
  //////////////////////////////////////////////////////////////////////////////

  // The OBI R channel signals are passed on directly on the transaction response
  // interface (resp_*). It is assumed that the consumer of the transaction response
  // is always receptive when resp_valid_o = 1 (otherwise a response would get dropped)

  assign resp_valid_o = obi_rvalid_i;
  assign resp_rdata_o = obi_rdata_i;
  assign resp_err_o   = obi_err_i;


  //////////////////////////////////////////////////////////////////////////////
  // OBI A Channel
  //////////////////////////////////////////////////////////////////////////////

  generate
    if (TRANS_STABLE) begin : gen_trans_stable

      // If the incoming transaction itself is stable, then it satisfies the OBI protocol
      // and signals can be passed to/from OBI directly.
      assign obi_req_o     = trans_valid_i;
      assign obi_addr_o    = trans_addr_i;
      assign obi_we_o      = trans_we_i;
      assign obi_be_o      = trans_be_i;
      assign obi_wdata_o   = trans_wdata_i;
      assign obi_atop_o    = trans_atop_i;

      assign trans_ready_o = obi_gnt_i;

      // FSM not used
      assign state_q       = TRANSPARENT;
      assign next_state    = TRANSPARENT;
    end else begin : gen_no_trans_stable

      // OBI A channel registers (to keep A channel stable)
      logic [31:0] obi_addr_q;
      logic        obi_we_q;
      logic [ 3:0] obi_be_q;
      logic [31:0] obi_wdata_q;
      logic [ 5:0] obi_atop_q;

      // If the incoming transaction itself is not stable; use an FSM to make sure that
      // the OBI address phase signals are kept stable during non-granted requests.

      //////////////////////////////////////////////////////////////////////////////
      // OBI FSM
      //////////////////////////////////////////////////////////////////////////////

      // FSM (state_q, next_state) to control OBI A channel signals.

      always_comb begin
        next_state = state_q;

        case (state_q)

          // Default (transparent) state. Transaction requests are passed directly onto the OBI A channel.
          TRANSPARENT: begin
            if (obi_req_o && !obi_gnt_i) begin
              // OBI request not immediately granted. Move to REGISTERED state such that OBI address phase
              // signals can be kept stable while the transaction request (trans_*) can possibly change.
              next_state = REGISTERED;
            end
          end  // case: TRANSPARENT

          // Registered state. OBI address phase signals are kept stable (driven from registers).
          REGISTERED: begin
            if (obi_gnt_i) begin
              // Received grant. Move back to TRANSPARENT state such that next transaction request can be passed on.
              next_state = TRANSPARENT;
            end
          end  // case: REGISTERED

        endcase
      end

      always_comb begin
        if (state_q == TRANSPARENT) begin
          obi_req_o   = trans_valid_i;  // Do not limit number of outstanding transactions
          obi_addr_o  = trans_addr_i;
          obi_we_o    = trans_we_i;
          obi_be_o    = trans_be_i;
          obi_wdata_o = trans_wdata_i;
          obi_atop_o  = trans_atop_i;
        end else begin
          // state_q == REGISTERED
          obi_req_o   = 1'b1;  // Never retract request
          obi_addr_o  = obi_addr_q;
          obi_we_o    = obi_we_q;
          obi_be_o    = obi_be_q;
          obi_wdata_o = obi_wdata_q;
          obi_atop_o  = obi_atop_q;
        end
      end

      //////////////////////////////////////////////////////////////////////////////
      // Registers
      //////////////////////////////////////////////////////////////////////////////

      always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
          state_q     <= TRANSPARENT;
          obi_addr_q  <= 32'b0;
          obi_we_q    <= 1'b0;
          obi_be_q    <= 4'b0;
          obi_wdata_q <= 32'b0;
          obi_atop_q  <= 6'b0;
        end else begin
          state_q <= next_state;
          if ((state_q == TRANSPARENT) && (next_state == REGISTERED)) begin
            // Keep OBI A channel signals stable throughout REGISTERED state
            obi_addr_q  <= obi_addr_o;
            obi_we_q    <= obi_we_o;
            obi_be_q    <= obi_be_o;
            obi_wdata_q <= obi_wdata_o;
            obi_atop_q  <= obi_atop_o;
          end
        end
      end

      // Always ready to accept a new transfer requests when previous A channel
      // transfer has been granted. Note that cv32e40p_obi_interface does not limit
      // the number of outstanding transactions in any way.
      assign trans_ready_o = (state_q == TRANSPARENT);

    end
  endgenerate

endmodule  // cv32e40p_obi_interface

// -------------------- END OF rtl/cv32e40p_obi_interface.sv --------------------

// -------------------- START OF rtl/cv32e40p_popcnt.sv --------------------
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
// Engineer:       Andreas Traber - atraber@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    cv32e40p_popcnt                                               //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Count the number of '1's in a word                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_popcnt (
    input  logic [31:0] in_i,
    output logic [ 5:0] result_o
);

  logic [15:0][1:0] cnt_l1;
  logic [ 7:0][2:0] cnt_l2;
  logic [ 3:0][3:0] cnt_l3;
  logic [ 1:0][4:0] cnt_l4;

  genvar l, m, n, p;
  generate
    for (l = 0; l < 16; l++) begin : gen_cnt_l1
      assign cnt_l1[l] = {1'b0, in_i[2*l]} + {1'b0, in_i[2*l+1]};
    end
  endgenerate

  generate
    for (m = 0; m < 8; m++) begin : gen_cnt_l2
      assign cnt_l2[m] = {1'b0, cnt_l1[2*m]} + {1'b0, cnt_l1[2*m+1]};
    end
  endgenerate

  generate
    for (n = 0; n < 4; n++) begin : gen_cnt_l3
      assign cnt_l3[n] = {1'b0, cnt_l2[2*n]} + {1'b0, cnt_l2[2*n+1]};
    end
  endgenerate

  generate
    for (p = 0; p < 2; p++) begin : gen_cnt_l4
      assign cnt_l4[p] = {1'b0, cnt_l3[2*p]} + {1'b0, cnt_l3[2*p+1]};
    end
  endgenerate

  assign result_o = {1'b0, cnt_l4[0]} + {1'b0, cnt_l4[1]};

endmodule

// -------------------- END OF rtl/cv32e40p_popcnt.sv --------------------

// -------------------- START OF rtl/cv32e40p_prefetch_buffer.sv --------------------
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
// Engineer:       Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Design Name:    Prefetcher Buffer for 32 bit memory interface              //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Prefetch Buffer that caches instructions. This cuts overly //
//                 long critical paths to the instruction cache               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

// input port: send address one cycle before the data
// clear_i clears the FIFO for the following cycle. in_addr_i can be sent in
// this cycle already

module cv32e40p_prefetch_buffer #(
    parameter PULP_OBI = 0,  // Legacy PULP OBI behavior
    parameter COREV_PULP = 1  // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding p.elw)
) (
    input logic clk,
    input logic rst_n,

    input logic        req_i,
    input logic        branch_i,
    input logic [31:0] branch_addr_i,

    input logic        hwlp_jump_i,
    input logic [31:0] hwlp_target_i,

    input  logic        fetch_ready_i,
    output logic        fetch_valid_o,
    output logic [31:0] fetch_rdata_o,

    // goes to instruction memory / instruction cache
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,
    input  logic        instr_rvalid_i,
    input  logic        instr_err_i,  // Not used yet (future addition)
    input  logic        instr_err_pmp_i,  // Not used yet (future addition)

    // Prefetch Buffer Status
    output logic busy_o
);
  // FIFO_DEPTH controls also the number of outstanding memory requests
  // FIFO_DEPTH must be greater than 1 to respect assertion in prefetch controller
  // FIFO_DEPTH must be a power of 2 (because of the FIFO implementation)
  localparam FIFO_DEPTH                     = 2; //must be greater or equal to 2 //Set at least to 3 to avoid stalls compared to the master branch
  localparam int unsigned FIFO_ADDR_DEPTH = $clog2(FIFO_DEPTH);

  // Transaction request (between cv32e40p_prefetch_controller and cv32e40p_obi_interface)
  logic                     trans_valid;
  logic                     trans_ready;
  logic [             31:0] trans_addr;

  logic                     fifo_flush;
  logic                     fifo_flush_but_first;
  logic [FIFO_ADDR_DEPTH:0] fifo_cnt;  // fifo_cnt should count from 0 to FIFO_DEPTH!

  logic [             31:0] fifo_rdata;
  logic                     fifo_push;
  logic                     fifo_pop;
  logic                     fifo_empty;

  // Transaction response interface (between cv32e40p_obi_interface and cv32e40p_fetch_fifo)
  logic                     resp_valid;
  logic [             31:0] resp_rdata;
  logic                     resp_err;  // Unused for now

  //////////////////////////////////////////////////////////////////////////////
  // Prefetch Controller
  //////////////////////////////////////////////////////////////////////////////

  cv32e40p_prefetch_controller #(
      .DEPTH     (FIFO_DEPTH),
      .PULP_OBI  (PULP_OBI),
      .COREV_PULP(COREV_PULP)
  ) prefetch_controller_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i        (req_i),
      .branch_i     (branch_i),
      .branch_addr_i(branch_addr_i),
      .busy_o       (busy_o),

      .hwlp_jump_i  (hwlp_jump_i),
      .hwlp_target_i(hwlp_target_i),

      .trans_valid_o(trans_valid),
      .trans_ready_i(trans_ready),
      .trans_addr_o (trans_addr),

      .resp_valid_i(resp_valid),

      .fetch_ready_i(fetch_ready_i),
      .fetch_valid_o(fetch_valid_o),

      .fifo_push_o           (fifo_push),
      .fifo_pop_o            (fifo_pop),
      .fifo_flush_o          (fifo_flush),
      .fifo_flush_but_first_o(fifo_flush_but_first),
      .fifo_cnt_i            (fifo_cnt),
      .fifo_empty_i          (fifo_empty)
  );

  //////////////////////////////////////////////////////////////////////////////
  // Fetch FIFO && fall-through path
  //////////////////////////////////////////////////////////////////////////////

  cv32e40p_fifo #(
      .FALL_THROUGH(1'b0),
      .DATA_WIDTH  (32),
      .DEPTH       (FIFO_DEPTH)
  ) fifo_i (
      .clk_i            (clk),
      .rst_ni           (rst_n),
      .flush_i          (fifo_flush),
      .flush_but_first_i(fifo_flush_but_first),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (fifo_empty),
      .cnt_o            (fifo_cnt),
      .data_i           (resp_rdata),
      .push_i           (fifo_push),
      .data_o           (fifo_rdata),
      .pop_i            (fifo_pop)
  );

  // First POP from the FIFO if it is not empty.
  // Otherwise, try to fall-through it.
  assign fetch_rdata_o = fifo_empty ? resp_rdata : fifo_rdata;

  //////////////////////////////////////////////////////////////////////////////
  // OBI interface
  //////////////////////////////////////////////////////////////////////////////

  cv32e40p_obi_interface #(
      .TRANS_STABLE(0)  // trans_* is NOT guaranteed stable during waited transfers;
      // this is ignored for legacy PULP behavior (not compliant to OBI)
  )                                                     // Keep this parameter stuck to 0 to make HWLP work

  instruction_obi_i
  (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i ({trans_addr[31:2], 2'b00}),
      .trans_we_i   (1'b0),  // Instruction interface (never write)
      .trans_be_i   (4'b1111),  // Corresponding obi_be_o not used
      .trans_wdata_i(32'b0),  // Corresponding obi_wdata_o not used
      .trans_atop_i (6'b0),  // Atomics not used on instruction bus

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),  // Unused for now

      .obi_req_o   (instr_req_o),
      .obi_gnt_i   (instr_gnt_i),
      .obi_addr_o  (instr_addr_o),
      .obi_we_o    (),  // Left unconnected on purpose
      .obi_be_o    (),  // Left unconnected on purpose
      .obi_wdata_o (),  // Left unconnected on purpose
      .obi_atop_o  (),  // Left unconnected on purpose
      .obi_rdata_i (instr_rdata_i),
      .obi_rvalid_i(instr_rvalid_i),
      .obi_err_i   (instr_err_i)
  );

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

`ifdef CV32E40P_ASSERT_ON

  // FIFO_DEPTH must be greater than 1. Otherwise, the property
  // p_hwlp_end_already_gnt_when_hwlp_branch in cv32e40p_prefetch_controller
  // is not verified, since the prefetcher cannot ask for HWLP_END the cycle
  // in which HWLP_END-4 is being absorbed by ID.
  property p_fifo_depth_gt_1;
    @(posedge clk) (FIFO_DEPTH > 1);
  endproperty

  a_fifo_depth_gt_1 :
  assert property (p_fifo_depth_gt_1);

  // Check that branch target address is half-word aligned (RV32-C)
  property p_branch_halfword_aligned;
    @(posedge clk) (branch_i) |-> (branch_addr_i[0] == 1'b0);
  endproperty

  a_branch_halfword_aligned :
  assert property (p_branch_halfword_aligned);

  // Check that bus interface transactions are word aligned
  property p_instr_addr_word_aligned;
    @(posedge clk) (1'b1) |-> (instr_addr_o[1:0] == 2'b00);
  endproperty

  a_instr_addr_word_aligned :
  assert property (p_instr_addr_word_aligned);

  // Check that a taken branch can only occur if fetching is requested
  property p_branch_implies_req;
    @(posedge clk) (branch_i) |-> (req_i);
  endproperty

  a_branch_implies_req :
  assert property (p_branch_implies_req);

  // Check that after a taken branch the initial FIFO output is not accepted
  property p_branch_invalidates_fifo;
    @(posedge clk) (branch_i) |-> (!(fetch_valid_o && fetch_ready_i));
  endproperty

  a_branch_invalidates_fifo :
  assert property (p_branch_invalidates_fifo);

  // External instruction bus errors are not supported yet. PMP errors are not supported yet.
  //
  // Note: Once PMP is re-introduced please consider to make instr_err_pmp_i a 'data' signal
  // that is qualified with instr_req_o && instr_gnt_i (instead of suppressing instr_gnt_i
  // as is currently done. This will keep the instr_req_o/instr_gnt_i protocol intact.
  //
  // JUST RE-ENABLING the PMP VIA ITS USE_PMP LOCALPARAM WILL NOT WORK BECAUSE OF THE
  // GRANT SUPPRESSION IN THE PMP.

  property p_no_error;
    @(posedge clk) (1'b1) |-> ((instr_err_i == 1'b0) && (instr_err_pmp_i == 1'b0));
  endproperty

  a_no_error :
  assert property (p_no_error);




`endif

endmodule  // cv32e40p_prefetch_buffer

// -------------------- END OF rtl/cv32e40p_prefetch_buffer.sv --------------------

// -------------------- START OF rtl/cv32e40p_prefetch_controller.sv --------------------
// Copyright 2020 Silicon Labs, Inc.
//
// This file, and derivatives thereof are licensed under the
// Solderpad License, Version 2.0 (the "License").
//
// Use of this file means you agree to the terms and conditions
// of the license and are in full compliance with the License.
//
// You may obtain a copy of the License at:
//
//     https://solderpad.org/licenses/SHL-2.0/
//
// Unless required by applicable law or agreed to in writing, software
// and hardware implementations thereof distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
//
// See the License for the specific language governing permissions and
// limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Arjan Bink - arjan.bink@silabs.com                         //
//                                                                            //
// Design Name:    Prefetcher Controller                                      //
// Project Name:   CV32E40P                                                   //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Prefetch Controller which receives control flow            //
//                 information (req_i, branch_*) from the Fetch stage         //
//                 and based on that performs transactions requests to the    //
//                 bus interface adapter instructions. Prefetching based on   //
//                 incrementing addressed is performed when no new control    //
//                 flow change is requested. New transaction requests are     //
//                 only performed if it can be guaranteed that the fetch FIFO //
//                 will not overflow (resulting in a maximum of DEPTH         //
//                 outstanding transactions.                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_prefetch_controller #(
    parameter PULP_OBI = 0,  // Legacy PULP OBI behavior
    parameter COREV_PULP = 1,  // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding cv.elw)
    parameter DEPTH = 4,  // Prefetch FIFO Depth
    parameter FIFO_ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1  // Do not override this parameter
) (
    input logic clk,
    input logic rst_n,

    // Fetch stage interface
    input  logic        req_i,  // Fetch stage requests instructions
    input  logic        branch_i,  // Taken branch
    input  logic [31:0] branch_addr_i,  // Taken branch address (only valid when branch_i = 1)
    output logic        busy_o,  // Prefetcher busy

    // HW loop signals
    input logic        hwlp_jump_i,
    input logic [31:0] hwlp_target_i,

    // Transaction request interface
    output logic trans_valid_o,  // Transaction request valid (to bus interface adapter)
    input  logic                     trans_ready_i,           // Transaction request ready (transaction gets accepted when trans_valid_o and trans_ready_i are both 1)
    output logic [31:0]              trans_addr_o,            // Transaction address (only valid when trans_valid_o = 1). No stability requirements.

    // Transaction response interface
    input logic resp_valid_i,  // Note: Consumer is assumed to be 'ready' whenever resp_valid_i = 1

    // Fetch interface is ready/valid
    input  logic fetch_ready_i,
    output logic fetch_valid_o,

    // FIFO interface
    output logic fifo_push_o,  // PUSH an instruction into the FIFO
    output logic fifo_pop_o,  // POP an instruction from the FIFO
    output logic fifo_flush_o,  // Flush the FIFO
    output logic                     fifo_flush_but_first_o,  // Flush the FIFO, but keep the first instruction if present
    input logic [FIFO_ADDR_DEPTH:0] fifo_cnt_i,  // Number of valid items/words in the prefetch FIFO
    input logic fifo_empty_i  // FIFO is empty
);

  import cv32e40p_pkg::*;

  prefetch_state_e state_q, next_state;

  logic [FIFO_ADDR_DEPTH:0] cnt_q;  // Transaction counter
  logic [FIFO_ADDR_DEPTH:0] next_cnt;  // Next value for cnt_q
  logic                          count_up;                        // Increment outstanding transaction count by 1 (can happen at same time as count_down)
  logic                          count_down;                      // Decrement outstanding transaction count by 1 (can happen at same time as count_up)

  logic  [FIFO_ADDR_DEPTH:0]     flush_cnt_q;                     // Response flush counter (to flush speculative responses after branch)
  logic [FIFO_ADDR_DEPTH:0] next_flush_cnt;  // Next value for flush_cnt_q

  // Transaction address
  logic [31:0] trans_addr_q, trans_addr_incr;

  // Word-aligned branch target address
  logic [31:0] aligned_branch_addr;  // Word aligned branch target address

  // FIFO auxiliary signal
  logic fifo_valid;  // FIFO output valid (if !fifo_empty)
  logic [FIFO_ADDR_DEPTH:0]      fifo_cnt_masked;                 // FIFO_cnt signal, masked when we are branching to allow a new memory request in that cycle

  // HW loop support signals
  logic hwlp_wait_resp_flush;  // Trigger for the delayed flush
  logic hwlp_flush_after_resp;  // Wait for HWLP_END and then flush the wrong granted requests
  logic [FIFO_ADDR_DEPTH:0]      hwlp_flush_cnt_delayed_q;        // The number of outstanding requests to flush when HWLP_END is returned
  logic hwlp_flush_resp_delayed;  // Actual delayed flush
  logic hwlp_flush_resp;  // Response flush counter when hwlp occurs

  //////////////////////////////////////////////////////////////////////////////
  // Prefetch buffer status
  //////////////////////////////////////////////////////////////////////////////

  // Busy if there are ongoing (or potentially outstanding) transfers
  assign busy_o = (cnt_q != 3'b000) || trans_valid_o;

  //////////////////////////////////////////////////////////////////////////////
  // IF/ID interface
  //////////////////////////////////////////////////////////////////////////////

  // Fectch valid control. Fetch never valid if jumping or flushing responses.
  // Fetch valid if there are instructions in FIFO or there is an incoming
  // instruction from memory.
  assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > 0));

  //////////////////////////////////////////////////////////////////////////////
  // Transaction request generation
  //
  // Assumes that corresponding response is at least 1 cycle after request
  //
  // - Only request transaction when fetch stage requires fetch (req_i), and
  // - make sure that FIFO (cv32e40p_fetch_fifo) never overflows (fifo_cnt_i + cnt_q < DEPTH)
  //////////////////////////////////////////////////////////////////////////////

  // Prefetcher will only perform word fetches
  assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};

  // Increment address (always word fetch)
  assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;

  // Transaction request generation
  generate
    if (PULP_OBI == 0) begin : gen_no_pulp_obi
      // OBI compatible (avoids combinatorial path from instr_rvalid_i to instr_req_o).
      // Multiple trans_* transactions can be issued (and accepted) before a response
      // (resp_*) is received.
      assign trans_valid_o = req_i && (fifo_cnt_masked + cnt_q < DEPTH);
    end else begin : gen_pulp_obi
      // Legacy PULP OBI behavior, i.e. only issue subsequent transaction if preceding transfer
      // is about to finish (re-introducing timing critical path from instr_rvalid_i to instr_req_o)
      assign trans_valid_o = (cnt_q == 3'b000) ? req_i && (fifo_cnt_masked + cnt_q < DEPTH) :
                                                 req_i && (fifo_cnt_masked + cnt_q < DEPTH) && resp_valid_i;
    end
  endgenerate

  // Optimization:
  // fifo_cnt is used to understand if we can perform new memory requests
  // When branching, we flush both the FIFO and the outstanding requests. Therefore,
  // there is surely space for a new request.
  // Masking fifo_cnt in this case allows for making a new request when the FIFO
  // is not empty and we are jumping, and (fifo_cnt_i + cnt_q == DEPTH)
  assign fifo_cnt_masked = (branch_i || hwlp_jump_i) ? '0 : fifo_cnt_i;

  // FSM (state_q, next_state) to control OBI A channel signals.
  always_comb begin
    next_state   = state_q;
    trans_addr_o = trans_addr_q;

    case (state_q)
      // Default state (pass on branch target address or transaction with incremented address)
      IDLE: begin
        begin
          if (branch_i) begin
            // Jumps must have the highest priority (e.g. an interrupt must
            // have higher priority than a HW-loop branch)
            trans_addr_o = aligned_branch_addr;
          end else if (hwlp_jump_i) begin
            trans_addr_o = hwlp_target_i;
          end else begin
            trans_addr_o = trans_addr_incr;
          end
        end
        if ((branch_i || hwlp_jump_i) && !(trans_valid_o && trans_ready_i)) begin
          // Taken branch, but transaction not yet accepted by bus interface adapter.
          next_state = BRANCH_WAIT;
        end
      end  // case: IDLE

      BRANCH_WAIT: begin
        // Replay previous branch target address (trans_addr_q) or new branch address (this can
        // occur if for example an interrupt is taken right after a taken jump which did not
        // yet have its target address accepted by the bus interface adapter.
        trans_addr_o = branch_i ? aligned_branch_addr : trans_addr_q;
        if (trans_valid_o && trans_ready_i) begin
          // Transaction with branch target address has been accepted. Start regular prefetch again.
          next_state = IDLE;
        end
      end  // case: BRANCH_WAIT
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////
  // FIFO management
  //////////////////////////////////////////////////////////////////////////////

  // Pass on response transfer directly to FIFO (which should be ready, otherwise
  // the corresponding transfer would not have been requested via trans_valid_o).
  // Upon a branch (branch_i) all incoming responses (resp_valid_i) are flushed
  // until the flush count is 0 again. (The flush count is initialized with the
  // number of outstanding transactions at the time of the branch).
  assign fifo_valid = !fifo_empty_i;
  assign fifo_push_o = resp_valid_i && (fifo_valid || !fetch_ready_i) && !(branch_i || (flush_cnt_q > 0));
  assign fifo_pop_o = fifo_valid && fetch_ready_i;

  //////////////////////////////////////////////////////////////////////////////
  // Counter (cnt_q, next_cnt) to count number of outstanding OBI transactions
  // (maximum = DEPTH)
  //
  // Counter overflow is prevented by limiting the number of outstanding transactions
  // to DEPTH. Counter underflow is prevented by the assumption that resp_valid_i = 1
  // will only occur in response to accepted transfer request (as per the OBI protocol).
  //////////////////////////////////////////////////////////////////////////////

  assign count_up = trans_valid_o && trans_ready_i;  // Increment upon accepted transfer request
  assign count_down = resp_valid_i;  // Decrement upon accepted transfer response

  always_comb begin
    case ({
      count_up, count_down
    })
      2'b00: begin
        next_cnt = cnt_q;
      end
      2'b01: begin
        next_cnt = cnt_q - 1'b1;
      end
      2'b10: begin
        next_cnt = cnt_q + 1'b1;
      end
      2'b11: begin
        next_cnt = cnt_q;
      end
    endcase
  end

  generate
    if (COREV_PULP) begin : gen_hwlp

      // Flush the FIFO if it is not empty and we are hwlp branching.
      // If HWLP_END is not going to ID, save it from the flush.
      // Don't flush the FIFO if it is empty (maybe we must accept
      // HWLP_end from the memory in this cycle)
      assign fifo_flush_o           = branch_i || (hwlp_jump_i && !fifo_empty_i && fifo_pop_o);
      assign fifo_flush_but_first_o = (hwlp_jump_i && !fifo_empty_i && !fifo_pop_o);

      //////////////////////////////////////////////////////////////////////////////
      // HWLP main resp flush controller
      //////////////////////////////////////////////////////////////////////////////

      // If HWLP_END-4 is in ID and HWLP_END is being/was returned by the memory
      // we can flush all the eventual outstanding requests up to now
      assign hwlp_flush_resp        = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);

      //////////////////////////////////////////////////////////////////////////////
      // HWLP delayed flush controller
      //////////////////////////////////////////////////////////////////////////////

      // If HWLP_END-4 is in ID and HWLP_END has not been returned yet,
      // save the present number of outstanding requests (subtract the HWLP_END one).
      // Wait for HWLP_END then flush the saved number of (wrong) outstanding requests
      assign hwlp_wait_resp_flush   = hwlp_jump_i && (fifo_empty_i && !resp_valid_i);

      always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
          hwlp_flush_after_resp    <= 1'b0;
          hwlp_flush_cnt_delayed_q <= 2'b00;
        end else begin
          if (branch_i) begin
            // Reset the flush request if an interrupt is taken
            hwlp_flush_after_resp    <= 1'b0;
            hwlp_flush_cnt_delayed_q <= 2'b00;
          end else begin
            if (hwlp_wait_resp_flush) begin
              hwlp_flush_after_resp    <= 1'b1;
              // cnt_q > 0 checked by an assertion
              hwlp_flush_cnt_delayed_q <= cnt_q - 1'b1;
            end else begin
              // Reset the delayed flush request when it's completed
              if (hwlp_flush_resp_delayed) begin
                hwlp_flush_after_resp    <= 1'b0;
                hwlp_flush_cnt_delayed_q <= 2'b00;
              end
            end
          end
        end
      end

      // This signal is masked by branch_i in the flush counter process,
      // because if an interrupt occurs during a delayed flush, the interrupt
      // is served first so the flush should be normal (caused by branch_i)
      assign hwlp_flush_resp_delayed = hwlp_flush_after_resp && resp_valid_i;

    end else begin : gen_no_hwlp

      // Flush the FIFO if it is not empty
      assign fifo_flush_o             = branch_i;
      assign fifo_flush_but_first_o   = 1'b0;
      assign hwlp_flush_resp          = 1'b0;
      assign hwlp_wait_resp_flush     = 1'b0;

      assign hwlp_flush_after_resp    = 1'b0;
      assign hwlp_flush_cnt_delayed_q = 2'b00;
      assign hwlp_flush_resp_delayed  = 1'b0;


    end
  endgenerate

  //////////////////////////////////////////////////////////////////////////////
  // Counter (flush_cnt_q, next_flush_cnt) to count reseponses to be flushed.
  //////////////////////////////////////////////////////////////////////////////

  always_comb begin
    next_flush_cnt = flush_cnt_q;

    // Number of outstanding transfers at time of branch equals the number of
    // responses that will need to be flushed (responses already in the FIFO will
    // be flushed there)
    if (branch_i || hwlp_flush_resp) begin
      next_flush_cnt = cnt_q;
      if (resp_valid_i && (cnt_q > 0)) begin
        next_flush_cnt = cnt_q - 1'b1;
      end
    end else if (hwlp_flush_resp_delayed) begin
      // Delayed flush has a lower priority than the normal flush,
      // because HW loops branches have lower priority than
      // taken interrupts
      next_flush_cnt = hwlp_flush_cnt_delayed_q;
    end else if (resp_valid_i && (flush_cnt_q > 0)) begin
      next_flush_cnt = flush_cnt_q - 1'b1;
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Registers
  //////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      state_q      <= IDLE;
      cnt_q        <= '0;
      flush_cnt_q  <= '0;
      trans_addr_q <= '0;
    end else begin
      state_q     <= next_state;
      cnt_q       <= next_cnt;
      flush_cnt_q <= next_flush_cnt;
      if (branch_i || hwlp_jump_i || (trans_valid_o && trans_ready_i)) begin
        trans_addr_q <= trans_addr_o;
      end
    end
  end

endmodule  // cv32e40p_prefetch_controller

// -------------------- END OF rtl/cv32e40p_prefetch_controller.sv --------------------

// -------------------- START OF rtl/cv32e40p_register_file_ff.sv --------------------
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
// Engineer:       Francesco Conti - f.conti@unibo.it                         //
//                                                                            //
// Additional contributions by:                                               //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    RISC-V register file                                       //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Register file with 31x 32 bit wide registers. Register 0   //
//                 is fixed to 0. This register file is based on flip-flops.  //
//                 Also supports the fp-register file now if FPU=1            //
//                 If ZFINX is 1, floating point operations take values       //
//                 from the X register file                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_register_file #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter FPU        = 0,
    parameter ZFINX      = 0
) (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    input logic scan_cg_en_i,

    //Read port R1
    input  logic [ADDR_WIDTH-1:0] raddr_a_i,
    output logic [DATA_WIDTH-1:0] rdata_a_o,

    //Read port R2
    input  logic [ADDR_WIDTH-1:0] raddr_b_i,
    output logic [DATA_WIDTH-1:0] rdata_b_o,

    //Read port R3
    input  logic [ADDR_WIDTH-1:0] raddr_c_i,
    output logic [DATA_WIDTH-1:0] rdata_c_o,

    // Write port W1
    input logic [ADDR_WIDTH-1:0] waddr_a_i,
    input logic [DATA_WIDTH-1:0] wdata_a_i,
    input logic                  we_a_i,

    // Write port W2
    input logic [ADDR_WIDTH-1:0] waddr_b_i,
    input logic [DATA_WIDTH-1:0] wdata_b_i,
    input logic                  we_b_i
);

  // number of integer registers
  localparam NUM_WORDS = 2 ** (ADDR_WIDTH - 1);
  // number of floating point registers
  localparam NUM_FP_WORDS = 2 ** (ADDR_WIDTH - 1);
  localparam NUM_TOT_WORDS = FPU ? (ZFINX ? NUM_WORDS : NUM_WORDS + NUM_FP_WORDS) : NUM_WORDS;

  // integer register file
  logic [    NUM_WORDS-1:0][DATA_WIDTH-1:0] mem;

  // fp register file
  logic [ NUM_FP_WORDS-1:0][DATA_WIDTH-1:0] mem_fp;

  // masked write addresses
  logic [   ADDR_WIDTH-1:0]                 waddr_a;
  logic [   ADDR_WIDTH-1:0]                 waddr_b;

  // write enable signals for all registers
  logic [NUM_TOT_WORDS-1:0]                 we_a_dec;
  logic [NUM_TOT_WORDS-1:0]                 we_b_dec;


  //-----------------------------------------------------------------------------
  //-- READ : Read address decoder RAD
  //-----------------------------------------------------------------------------
  assign rdata_a_o = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
  assign rdata_b_o = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
  assign rdata_c_o = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];

  //-----------------------------------------------------------------------------
  //-- WRITE : Write Address Decoder (WAD), combinatorial process
  //-----------------------------------------------------------------------------

  // Mask top bit of write address to disable fp regfile
  assign waddr_a   = waddr_a_i;
  assign waddr_b   = waddr_b_i;

  genvar gidx;
  generate
    for (gidx = 0; gidx < NUM_TOT_WORDS; gidx++) begin : gen_we_decoder
      assign we_a_dec[gidx] = (waddr_a == gidx) ? we_a_i : 1'b0;
      assign we_b_dec[gidx] = (waddr_b == gidx) ? we_b_i : 1'b0;
    end
  endgenerate

  genvar i, l;
  generate

    //-----------------------------------------------------------------------------
    //-- WRITE : Write operation
    //-----------------------------------------------------------------------------
    // R0 is nil
    always_ff @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
        // R0 is nil
        mem[0] <= 32'b0;
      end else begin
        // R0 is nil
        mem[0] <= 32'b0;
      end
    end

    // loop from 1 to NUM_WORDS-1 as R0 is nil
    for (i = 1; i < NUM_WORDS; i++) begin : gen_rf

      always_ff @(posedge clk, negedge rst_n) begin : register_write_behavioral
        if (rst_n == 1'b0) begin
          mem[i] <= 32'b0;
        end else begin
          if (we_b_dec[i] == 1'b1) mem[i] <= wdata_b_i;
          else if (we_a_dec[i] == 1'b1) mem[i] <= wdata_a_i;
        end
      end

    end

    if (FPU == 1 && ZFINX == 0) begin : gen_mem_fp_write
      // Floating point registers
      for (l = 0; l < NUM_FP_WORDS; l++) begin
        always_ff @(posedge clk, negedge rst_n) begin : fp_regs
          if (rst_n == 1'b0) mem_fp[l] <= '0;
          else if (we_b_dec[l+NUM_WORDS] == 1'b1) mem_fp[l] <= wdata_b_i;
          else if (we_a_dec[l+NUM_WORDS] == 1'b1) mem_fp[l] <= wdata_a_i;
        end
      end
    end else begin : gen_no_mem_fp_write
      assign mem_fp = 'b0;
    end

  endgenerate

endmodule

// -------------------- END OF rtl/cv32e40p_register_file_ff.sv --------------------

// -------------------- START OF rtl/cv32e40p_sim_clock_gate.sv --------------------
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// !!! cv32e40p_sim_clock_gate file is meant for simulation only !!!
// !!! It must not be used for ASIC synthesis                    !!!
// !!! It must not be used for FPGA synthesis                    !!!

module cv32e40p_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  logic clk_en;

  always_latch begin
    if (clk_i == 1'b0) clk_en <= en_i | scan_cg_en_i;
  end

  assign clk_o = clk_i & clk_en;

endmodule  // cv32e40p_clock_gate

// -------------------- END OF rtl/cv32e40p_sim_clock_gate.sv --------------------

// -------------------- START OF rtl/cv32e40p_sleep_unit.sv --------------------
// Copyright 2020 Silicon Labs, Inc.
//
// This file, and derivatives thereof are licensed under the
// Solderpad License, Version 2.0 (the "License").
//
// Use of this file means you agree to the terms and conditions
// of the license and are in full compliance with the License.
//
// You may obtain a copy of the License at:
//
//     https://solderpad.org/licenses/SHL-2.0/
//
// Unless required by applicable law or agreed to in writing, software
// and hardware implementations thereof distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
//
// See the License for the specific language governing permissions and
// limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Arjan Bink - arjan.bink@silabs.com                         //
//                                                                            //
// Design Name:    Sleep Unit                                                 //
// Project Name:   CV32E40P                                                   //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Sleep unit containing the instantiated clock gate which    //
//                 provides the gated clock (clk_gated_o) for the rest        //
//                 of the design.                                             //
//                                                                            //
//                 The clock is gated for the following scenarios:            //
//                                                                            //
//                 - While waiting for fetch to become enabled                //
//                 - While blocked on a WFI (COREV_CLUSTER = 0)               //
//                 - While clock_en_i = 0 during a cv.elw (COREV_CLUSTER = 1) //
//                                                                            //
//                 Sleep is signaled via core_sleep_o when:                   //
//                                                                            //
//                 - During a cv.elw (except in debug (i.e. pending debug     //
//                   request, debug mode, single stepping, trigger match)     //
//                 - During a WFI (except in debug)                           //
//                                                                            //
// Requirements:   If COREV_CLUSTER = 1 the environment must guarantee:       //
//                                                                            //
//                 - If core_sleep_o    == 1'b0, then pulp_clock_en_i == 1'b1 //
//                 - If pulp_clock_en_i == 1'b0, then irq_i == 'b0            //
//                 - If pulp_clock_en_i == 1'b0, then debug_req_i == 1'b0     //
//                 - If pulp_clock_en_i == 1'b0, then instr_rvalid_i == 1'b0  //
//                 - If pulp_clock_en_i == 1'b0, then instr_gnt_i == 1'b0     //
//                 - If pulp_clock_en_i == 1'b0, then data_rvalid_i == 1'b0   //
//                 - If pulp_clock_en_i == 1'b0, then data_gnt_i == 1'b1      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40p_sleep_unit #(
    parameter COREV_CLUSTER = 0
) (
    // Clock, reset interface
    input  logic clk_ungated_i,  // Free running clock
    input  logic rst_n,
    output logic clk_gated_o,  // Gated clock
    input  logic scan_cg_en_i,  // Enable all clock gates for testing

    // Core sleep
    output logic core_sleep_o,

    // Fetch enable
    input  logic fetch_enable_i,
    output logic fetch_enable_o,

    // Core status
    input logic if_busy_i,
    input logic ctrl_busy_i,
    input logic lsu_busy_i,
    input logic apu_busy_i,

    // PULP Cluster interface
    input logic pulp_clock_en_i,  // PULP clock enable (only used if COREV_CLUSTER = 1)
    input logic p_elw_start_i,
    input logic p_elw_finish_i,
    input logic debug_p_elw_no_sleep_i,

    // WFI wake
    input logic wake_from_sleep_i
);

  import cv32e40p_pkg::*;

  logic fetch_enable_q;  // Sticky version of fetch_enable_i
  logic fetch_enable_d;
  logic              core_busy_q;               // Is core still busy (and requires a clock) with what needs to finish before entering sleep?
  logic core_busy_d;
  logic p_elw_busy_q;  // Busy with cv.elw (transaction in progress)?
  logic p_elw_busy_d;
  logic clock_en;  // Final clock enable

  //////////////////////////////////////////////////////////////////////////////
  // Sleep FSM
  //////////////////////////////////////////////////////////////////////////////

  // Make sticky version of fetch_enable_i
  assign fetch_enable_d = fetch_enable_i ? 1'b1 : fetch_enable_q;

  generate
    if (COREV_CLUSTER) begin : g_pulp_sleep

      // Busy unless in a cv.elw and IF/APU are no longer busy
      assign core_busy_d = p_elw_busy_d ? (if_busy_i || apu_busy_i) : 1'b1;

      // Enable the clock only after the initial fetch enable while busy or instructed so by PULP Cluster's pulp_clock_en_i
      assign clock_en = fetch_enable_q && (pulp_clock_en_i || core_busy_q);

      // Sleep only in response to cv.elw onec no longer busy (but not during various debug scenarios)
      assign core_sleep_o = p_elw_busy_d && !core_busy_q && !debug_p_elw_no_sleep_i;

      // cv.elw is busy between load start and load finish (data_req_o / data_rvalid_i)
      assign p_elw_busy_d = p_elw_start_i ? 1'b1 : (p_elw_finish_i ? 1'b0 : p_elw_busy_q);

    end else begin : g_no_pulp_sleep

      // Busy when any of the sub units is busy (typically wait for the instruction buffer to fill up)
      assign core_busy_d = if_busy_i || ctrl_busy_i || lsu_busy_i || apu_busy_i;

      // Enable the clock only after the initial fetch enable while busy or waking up to become busy
      assign clock_en = fetch_enable_q && (wake_from_sleep_i || core_busy_q);

      // Sleep only in response to WFI which leads to clock disable; debug_wfi_no_sleep_o in
      // cv32e40p_controller determines the scenarios for which WFI can(not) cause sleep.
      assign core_sleep_o = fetch_enable_q && !clock_en;

      // cv.elw does not exist for COREV_CLUSTER = 0
      assign p_elw_busy_d = 1'b0;

    end
  endgenerate

  always_ff @(posedge clk_ungated_i, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      core_busy_q    <= 1'b0;
      p_elw_busy_q   <= 1'b0;
      fetch_enable_q <= 1'b0;
    end else begin
      core_busy_q    <= core_busy_d;
      p_elw_busy_q   <= p_elw_busy_d;
      fetch_enable_q <= fetch_enable_d;
    end
  end

  // Fetch enable for Controller
  assign fetch_enable_o = fetch_enable_q;

  // Main clock gate of CV32E40P
  cv32e40p_clock_gate core_clock_gate_i (
      .clk_i       (clk_ungated_i),
      .en_i        (clock_en),
      .scan_cg_en_i(scan_cg_en_i),
      .clk_o       (clk_gated_o)
  );

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

`ifdef CV32E40P_ASSERT_ON

  // Clock gate is disabled during RESET state of the controller
  property p_clock_en_0;
    @(posedge clk_ungated_i) disable iff (!rst_n) ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::RESET) && (id_stage_i.controller_i.ctrl_fsm_ns == cv32e40p_pkg::RESET)) |-> (clock_en == 1'b0);
  endproperty

  a_clock_en_0 :
  assert property (p_clock_en_0);

  // Clock gate is enabled when exit from RESET state is required
  property p_clock_en_1;
    @(posedge clk_ungated_i) disable iff (!rst_n) ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::RESET) && (id_stage_i.controller_i.ctrl_fsm_ns != cv32e40p_pkg::RESET)) |-> (clock_en == 1'b1);
  endproperty

  a_clock_en_1 :
  assert property (p_clock_en_1);

  // Clock gate is not enabled before receiving fetch_enable_i pulse
  property p_clock_en_2;
    @(posedge clk_ungated_i) disable iff (!rst_n) (fetch_enable_q == 1'b0) |-> (clock_en == 1'b0);
  endproperty

  a_clock_en_2 :
  assert property (p_clock_en_2);

  generate
    if (COREV_CLUSTER) begin : g_pulp_cluster_assertions

      // Clock gate is only possibly disabled in RESET or when COREV_CLUSTER disables clock
      property p_clock_en_3;
        @(posedge clk_ungated_i) disable iff (!rst_n) (clock_en == 1'b0) -> ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::RESET) || (COREV_CLUSTER && !pulp_clock_en_i));
      endproperty

      a_clock_en_3 :
      assert property (p_clock_en_3);

      // Core can only sleep in response to cv.elw
      property p_only_sleep_during_p_elw;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> (p_elw_busy_d == 1'b1);
      endproperty

      a_only_sleep_during_p_elw :
      assert property (p_only_sleep_during_p_elw);


      // Environment fully controls clock_en during sleep
      property p_full_clock_en_control;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> (pulp_clock_en_i == clock_en);
      endproperty

      a_full_clock_en_control :
      assert property (p_full_clock_en_control);

    end else begin : g_no_pulp_cluster_assertions

      // Clock gate is only possibly disabled in RESET or SLEEP
      property p_clock_en_4;
        @(posedge clk_ungated_i) disable iff (!rst_n) (clock_en == 1'b0) -> ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::RESET) || (id_stage_i.controller_i.ctrl_fsm_ns == cv32e40p_pkg::SLEEP));
      endproperty

      a_clock_en_4 :
      assert property (p_clock_en_4);

      // Clock gate is enabled when exit from SLEEP state is required
      property p_clock_en_5;
        @(posedge clk_ungated_i) disable iff (!rst_n)  ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::SLEEP) && (id_stage_i.controller_i.ctrl_fsm_ns != cv32e40p_pkg::SLEEP)) |-> (clock_en == 1'b1);
      endproperty

      a_clock_en_5 :
      assert property (p_clock_en_5);

      // Core sleep is only signaled in SLEEP state
      property p_core_sleep;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) -> ((id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::SLEEP));
      endproperty

      a_core_sleep :
      assert property (p_core_sleep);

      // Core can only become non-busy due to SLEEP entry
      property p_non_busy;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_busy_d == 1'b0) |-> (id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::WAIT_SLEEP) || (id_stage_i.controller_i.ctrl_fsm_cs == cv32e40p_pkg::SLEEP);
      endproperty

      a_non_busy :
      assert property (p_non_busy);

      // During (COREV_CLUSTER = 0) sleep it should be allowed to externally gate clk_i
      property p_gate_clk_i;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> (core_busy_q == core_busy_d) && (p_elw_busy_q == p_elw_busy_d) && (fetch_enable_q == fetch_enable_d);
      endproperty

      a_gate_clk_i :
      assert property (p_gate_clk_i);

      // During sleep the internal clock is gated
      property p_gate_clock_during_sleep;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> (clock_en == 1'b0);
      endproperty

      a_gate_clock_during_sleep :
      assert property (p_gate_clock_during_sleep);

      // Sleep mode can only be entered in response to a WFI instruction
      property p_only_sleep_for_wfi;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> (id_stage_i.instr == {
          12'b000100000101, 13'b0, OPCODE_SYSTEM
        });
      endproperty

      a_only_sleep_for_wfi :
      assert property (p_only_sleep_for_wfi);

      // In sleep mode the core will not be busy (e.g. no ongoing/outstanding instruction or data transactions)
      property p_not_busy_during_sleep;
        @(posedge clk_ungated_i) disable iff (!rst_n) (core_sleep_o == 1'b1) |-> ((core_busy_q == 1'b0) && (core_busy_d == 1'b0));
      endproperty

      a_not_busy_during_sleep :
      assert property (p_not_busy_during_sleep);

    end
  endgenerate

`endif

endmodule  // cv32e40p_sleep_unit

// -------------------- END OF rtl/cv32e40p_sleep_unit.sv --------------------

// -------------------- START OF rtl/cv32e40p_top.sv --------------------
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Top file instantiating a CV32E40P core and an optional FPU
// Contributor: Davide Schiavone <davide@openhwgroup.org>

module cv32e40p_top #(
    parameter COREV_PULP = 0, // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
    parameter COREV_CLUSTER = 0,  // PULP Cluster interface (incl. cv.elw)
    parameter FPU = 0,  // Floating Point Unit (interfaced via APU interface)
    parameter FPU_ADDMUL_LAT = 0,  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
    parameter FPU_OTHERS_LAT = 0,  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
    parameter ZFINX = 0,  // Float-in-General Purpose registers
    parameter NUM_MHPMCOUNTERS = 1
) (
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    input logic pulp_clock_en_i,  // PULP clock enable (only used if COREV_CLUSTER = 1)
    input logic scan_cg_en_i,  // Enable all clock gates for testing

    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    input logic [31:0] boot_addr_i,
    input logic [31:0] mtvec_addr_i,
    input logic [31:0] dm_halt_addr_i,
    input logic [31:0] hart_id_i,
    input logic [31:0] dm_exception_addr_i,

    // Instruction memory interface
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,

    // Data memory interface
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,

    // Interrupt inputs
    input  logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o,

    // Debug Interface
    input  logic debug_req_i,
    output logic debug_havereset_o,
    output logic debug_running_o,
    output logic debug_halted_o,

    // CPU Control Signals
    input  logic fetch_enable_i,
    output logic core_sleep_o
);

  import cv32e40p_apu_core_pkg::*;

  // Core to FPU
  logic                              clk;
  logic                              apu_req;
  logic [   APU_NARGS_CPU-1:0][31:0] apu_operands;
  logic [     APU_WOP_CPU-1:0]       apu_op;
  logic [APU_NDSFLAGS_CPU-1:0]       apu_flags;

  // FPU to Core
  logic                              apu_gnt;
  logic                              apu_rvalid;
  logic [                31:0]       apu_rdata;
  logic [APU_NUSFLAGS_CPU-1:0]       apu_rflags;

  // Instantiate the Core
  cv32e40p_core #(
      .COREV_PULP      (COREV_PULP),
      .COREV_CLUSTER   (COREV_CLUSTER),
      .FPU             (FPU),
      .FPU_ADDMUL_LAT  (FPU_ADDMUL_LAT),
      .FPU_OTHERS_LAT  (FPU_OTHERS_LAT),
      .ZFINX           (ZFINX),
      .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
  ) core_i (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .pulp_clock_en_i(pulp_clock_en_i),
      .scan_cg_en_i   (scan_cg_en_i),

      .boot_addr_i        (boot_addr_i),
      .mtvec_addr_i       (mtvec_addr_i),
      .dm_halt_addr_i     (dm_halt_addr_i),
      .hart_id_i          (hart_id_i),
      .dm_exception_addr_i(dm_exception_addr_i),

      .instr_req_o   (instr_req_o),
      .instr_gnt_i   (instr_gnt_i),
      .instr_rvalid_i(instr_rvalid_i),
      .instr_addr_o  (instr_addr_o),
      .instr_rdata_i (instr_rdata_i),

      .data_req_o   (data_req_o),
      .data_gnt_i   (data_gnt_i),
      .data_rvalid_i(data_rvalid_i),
      .data_we_o    (data_we_o),
      .data_be_o    (data_be_o),
      .data_addr_o  (data_addr_o),
      .data_wdata_o (data_wdata_o),
      .data_rdata_i (data_rdata_i),

      .apu_req_o     (apu_req),
      .apu_gnt_i     (apu_gnt),
      .apu_operands_o(apu_operands),
      .apu_op_o      (apu_op),
      .apu_flags_o   (apu_flags),
      .apu_rvalid_i  (apu_rvalid),
      .apu_result_i  (apu_rdata),
      .apu_flags_i   (apu_rflags),

      .irq_i    (irq_i),
      .irq_ack_o(irq_ack_o),
      .irq_id_o (irq_id_o),

      .debug_req_i      (debug_req_i),
      .debug_havereset_o(debug_havereset_o),
      .debug_running_o  (debug_running_o),
      .debug_halted_o   (debug_halted_o),

      .fetch_enable_i(fetch_enable_i),
      .core_sleep_o  (core_sleep_o)
  );

  generate
    if (FPU) begin : fpu_gen
      // FPU clock gate
      cv32e40p_clock_gate core_clock_gate_i (
          .clk_i       (clk_i),
          .en_i        (!core_sleep_o),
          .scan_cg_en_i(scan_cg_en_i),
          .clk_o       (clk)
      );

      // Instantiate the FPU wrapper
      cv32e40p_fp_wrapper #(
          .FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
          .FPU_OTHERS_LAT(FPU_OTHERS_LAT)
      ) fp_wrapper_i (
          .clk_i         (clk),
          .rst_ni        (rst_ni),
          .apu_req_i     (apu_req),
          .apu_gnt_o     (apu_gnt),
          .apu_operands_i(apu_operands),
          .apu_op_i      (apu_op),
          .apu_flags_i   (apu_flags),
          .apu_rvalid_o  (apu_rvalid),
          .apu_rdata_o   (apu_rdata),
          .apu_rflags_o  (apu_rflags)
      );
    end else begin : no_fpu_gen
      // Drive FPU output signals to 0
      assign apu_gnt    = '0;
      assign apu_rvalid = '0;
      assign apu_rdata  = '0;
      assign apu_rflags = '0;
    end
  endgenerate

endmodule

// -------------------- END OF rtl/cv32e40p_top.sv --------------------

