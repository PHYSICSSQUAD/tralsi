# CV32E40P (RV32IM scope) – Study Notes

Notes taken while studying `guidelines/`, `tb_architecture/arch.jpg`, `verification_plan/`, `databook/` and `rtl/`.
Purpose: single reference for (a) what must be verified, (b) what the TB architecture actually contains,
(c) where the verification plan disagrees with the architecture / RTL.

---

## 1. Scope (from `guidelines/Team *.html`)

| Topic | Decision (from the Q&A sheets) |
|---|---|
| ISA | **Vanilla RV32I + RV32M only**. No C, F, Zfinx, Zicsr, Zicntr, Zifencei, no CORE-V custom (Xcv / Xcvelw). |
| Level | **Top-level (core) verification** of `cv32e40p_top`, with scoreboards per *major group of blocks* (register file, ALU/MUL...), not one per module. |
| Exceptions | Simple exceptions (e.g. misaligned memory operations – which the LSU handles in HW) are "good to verify". ECALL / EBREAK / HINTs **not required**. |
| CSR / interrupts | **Not** a concern (no CSR instructions, no IRQ). |
| Fetch path | Aligner + compressed decoder are part of the C extension → out of the verification goal (exercised only as pass-through with 32-bit word-aligned code). |
| Memories | Nothing outside the core RTL is delivered → **the TB owns the instruction + data memory models** (OBI slaves) if the team decides it needs them. |
| OBI | Must know enough OBI to build the drivers and the interface checkers. |
| Reference model | **Build everything yourself** (no open-source ISS / reference model). |
| Other inputs | Debug / IRQ / sleep inputs must be driven to values that keep the core in normal operation (do not ignore them). |
| Deliverables | Verification plan (excel) + presentation; the databook *is* the design spec. |
| Unanswered | Team 4 Q3 (multi-cycle op in EX + taken branch/jump). RTL answer in §4.7. |

---

## 2. TB architecture (as drawn in `tb_architecture/arch.jpg`)

```
Test
 └── V_Sequences ──► V_SQR
Env
 ├── Scoreboard (main)          ├── Predictor            ├── coverage_collector
 ├── reg_file Scoreboard        └── ALU_MUL Scoreboard
 ├── Instructions agent  (active)   : SQR + Driver + Monitor  → Instruction interface (instr_* OBI)
 ├── Data agent          (reactive) : SQR + Driver + Monitor  → Data interface (data_* OBI)  [Monitor→SQR arrow = reactive slave]
 ├── Interrupt_Debug agent (active) : Driver only             → irq_i / debug_req_i (tie-off / quiet driver)
 ├── Reset agent         (active)   : SQR + Driver + Monitor  → rst_ni (+ fetch_enable_i, boot_addr_i, mtvec_addr_i, ... static cfg)
 ├── reg_file agent      (passive)  : Monitor                 → Reg_file interface (internal RF ports)
 ├── MUL agent           (passive)  : Monitor                 → ALU_MUL interface (internal EX signals)
 └── ALU agent           (passive)  : Monitor                 → ALU_MUL interface (internal EX signals)
Assertions (SVA module bound to the DUT)
```

Notes:
* 4 agents have drivers (Instructions, Data, Interrupt_Debug, Reset); 3 are passive (reg_file, MUL, ALU).
* Internal-signal agents (reg_file / ALU / MUL) need `bind` or hierarchical references into `cv32e40p_top.core_i.*`.
* There is **no RVFI tracer** in `rtl/` (no `cv32e40p_rvfi.sv`), so any "rvfi_monitor" must be replaced by reg_file/instruction monitors.

---

## 3. Verification plan review (`verification_plan/*.html`)

### 3.1 Component names used in the plan vs. the architecture

| Name used in the plan | Where | What the architecture actually has |
|---|---|---|
| `sys_ctrl_agent`, `sys_ctrl_init_sequence`, `sys_ctrl_reset_inject_sequence` | System / Generation / Test list | **Reset agent** (rst_ni, fetch_enable_i, boot_addr_i, mtvec_addr_i, hart_id_i, dm_*_addr_i) + **Interrupt_Debug agent** (irq_i=0, debug_req_i=0, pulp_clock_en_i=0, scan_cg_en_i=0) |
| `if_agent`, `if_passive_agent`, `if_passive_agent.output_monitor`, `instr_mem_model` | everywhere | **Instructions agent** (one active agent: driver = OBI instruction slave/memory model, monitor = protocol checks + coverage). No separate passive IF agent exists. |
| `lsu_agent`, `lsu_passive_agent`, `lsu_passive_agent.output_monitor`, `data_mem_model` | everywhere | **Data agent (reactive)**: monitor sees the request → sequencer → driver responds (OBI data slave/memory model). |
| `uvm_scoreboard` (single) | everywhere | **Scoreboard** (architectural compare) + **Predictor** (own RV32IM model) + **reg_file Scoreboard** + **ALU_MUL Scoreboard** |
| `ref_model` | System / Checking | **Predictor** |
| `rvfi_monitor` | Checking (haz_01, rf_00, dec_00, m_01) | Does not exist (no RVFI in RTL). Use **reg_file agent monitor** (RF write ports) + Instructions agent monitor / ID-stage issue pulse. |
| `riscv_program`, `generation constraint` | System / Generation | **V_Sequences** on **V_SQR** → Instructions agent SQR (program builder lives in the sequence layer) |
| `obi_memory_sequence` | Generation / Test list | Instructions-agent sequence (memory/wait-state policy) and Data-agent reactive sequence – should be split per agent |
| `top_tb`, `interfaces` | System | OK (top_tb, virtual interfaces) |
| covergroups (Coverage sheet) | Coverage | Should be located in **coverage_collector** (fed by monitors) |
| SVA property names | Checking | Should be located in the **Assertions** block bound to the DUT (or inside interfaces) |

### 3.2 ID / sheet consistency problems

* IDs present only in *System*: `risc_sys_00`, `risc_sys_01`, `risc_if_04`, `risc_lsu_02`, `risc_lsu_09`, `risc_env_00`, `risc_scope_00`.
* `risc_if_07` does not exist at all (06 → 08).
* `risc_if_09`, `risc_haz_04`, `risc_rf_00`, `risc_env_02` missing from *Generation* (and some from *Coverage*).
* Reviewer notes left inside cells: `risc_sys_01` ("what about boot address and mtvec address?"), `risc_env_00` ("the need for instruction mem or just use the sequences").
* Sheet headers: "Design Requirement Description" column repeats the whole requirement text 4 times (System / Generation / Checking / Coverage) – fine, but any correction must be applied in all 4 sheets.

### 3.3 Technical inaccuracies vs. the RTL

1. **`risc_haz_03` (WAW) – wrong mechanism.** The controller already stalls the younger writer:
   `load_stall` fires when a load is in EX (or in WB waiting for rvalid) **and** the instruction in ID writes the same rd through the ALU port
   (`regfile_waddr_ex == regfile_alu_waddr_id`, `cv32e40p_controller.sv` ~l.1338-1349). So `LW x5 ; ADD x5,...` costs a 1-cycle stall
   and the two writes never land in the same cycle. The register-file "port-b (EX) over port-a (WB)" priority exists but is not the
   mechanism that resolves architectural WAW. Expected observable: 1 stall cycle (zero wait states) – coverable.
2. **`risc_haz_02` (JALR hazard) – incomplete.** JALR reads rs1 straight from the RF (no forwarding: "path too long").
   `jr_stall` is asserted while rs1 has a pending write in EX (ALU port), in EX (load) or in WB (load).
   → ALU producer at distance 1: **1** stall cycle; **load producer at distance 1: 2 stall cycles** (EX + WB), load at distance 2: 1 stall cycle
   (zero wait states). Multicycle producer: JALR waits for the whole DIV/MULH.
3. **`risc_lsu_04` checking text – "first beat address == original *aligned* address"** is wrong. RTL (`trans_addr`):
   first beat carries the **original (unaligned) EA** with the partial byte-enable; second beat carries `(EA+4) & ~3` with the complementary BE.
   Memory model must therefore index by `addr[31:2]` and apply `data_be_o` lanes.
4. **"no spurious write-back during the stall window" (`sb_no_spurious_wb`, `risc_haz_01`, `risc_m_01`) – not true at the RF-port level.**
   With `COREV_PULP=0`, `regfile_alu_we_fw_power = regfile_alu_we & ~apu_en` (not gated by `alu_ready`/`mult_ready`, `cv32e40p_ex_stage.sv`),
   so during a DIV/REM/MULH the ALU write port is enabled **every cycle** with intermediate values of the same rd.
   Likewise a misaligned load writes rd **twice** on the LSU port (first rvalid → partial/garbage, second rvalid → merged value),
   because `regfile_we_wb_power = 1` when `COREV_PULP=0`. Architecturally harmless (final value is correct, dependants are stalled),
   but the **reg_file passive monitor must qualify writes**:
   * ALU/EX port (`we_b`): sample on `ex_valid` (= last cycle of the instruction in EX), or `we_b && alu_ready && mult_ready && lsu_ready_ex && wb_ready`.
   * LSU/WB port (`we_a`): sample on `we_a && lsu_ready_wb && !data_misaligned_ex` (exactly the `COREV_PULP=1` power gating condition).
   Otherwise the "one write per retired instruction" checks and the reg_file scoreboard will fail on a correct design.
5. **`risc_dec_02(c)` – shift encodings.** For funct3=001 (SLLI/SLL) only funct7=0000000 is legal (0100000 is illegal too);
   for funct3=101 both 0000000 (SRLI/SRL) and 0100000 (SRAI/SRA) are legal. Also the `OP` opcode: any funct7 with bit31:30 = 11, or 10 with
   funct7[4:0]==0, or an undefined {funct7[5:0],funct3} → illegal (decoder l.514-995).
6. **Illegal-instruction tests need a strategy without CSRs.** A trap jumps to `{mtvec_addr_i[31:8],8'h0}`; there is no `csrr mepc`/`mret`
   in scope, so the "handler" cannot return. Either (a) the program at mtvec is simply the continuation of the test (the predictor follows PC→mtvec),
   or (b) accept a very small number of illegals per program and end the test from the handler. The "~2 % illegals" inside
   `risc_random_mix_test` is not workable without one of these decisions.
7. **Register-file description** (`risc_rf_01`): RTL writes from EX (ALU port b) and WB (LSU port a); databook text says "writes in WB" – RTL is right.
8. **DIV operands are swapped inside the ALU** (decoder: `alu_op_a = rs2 (divisor)`, `alu_op_b = rs1 (dividend)`). Relevant to the passive ALU monitor / ALU_MUL scoreboard.
9. **MULH/MULHSU/MULHU** use `mult_operator = MUL_H`, `mult_signed_mode = 11/01/00`, 5-cycle FSM `IDLE→STEP0→STEP1→STEP2→FINISH`,
   accumulating through operand C (`regc = x0` initially, then forwarded from EX). `MUL` = `MUL_MAC32` with op_c = 0.
10. `risc_sys_02` generation: de-asserting an async reset at a random clock phase is a sim race; release synchronously (e.g. on negedge).
11. `risc_if_02` checking "rdata stable during its rvalid cycle" is vacuous (rvalid is a single cycle).

### 3.4 Things the plan does not cover (candidates)

* Taken branch / jump while 1 or 2 fetches are outstanding → prefetch `flush_cnt` path (responses dropped); cross with instr wait states.
* Prefetch FIFO full (2 words) while ID is stalled (load-use / multicycle) → back-pressure on the instruction bus (`instr_req_o` held low).
* x0 as rd for loads that are misaligned; x0 as rd for DIV (multicycle, still no write).
* Both buses stalled simultaneously while a misaligned store pair is in flight.
* `fetch_enable_i` glitch (pulse of exactly 1 cycle) → must still start; `fetch_enable_i` toggling after start → ignored.

---

## 4. RTL facts relevant to the TB (`rtl/`, config = all parameters default: FPU=0, COREV_PULP=0, COREV_CLUSTER=0, ZFINX=0, NUM_MHPMCOUNTERS=1)

### 4.1 Top / clock / reset / start-up
* DUT = `cv32e40p_top` → `cv32e40p_core` (+ no FPU). Ports: clk_i, rst_ni, pulp_clock_en_i, scan_cg_en_i, boot_addr_i, mtvec_addr_i, dm_halt_addr_i, hart_id_i, dm_exception_addr_i, instr_* (5), data_* (8), irq_i[31:0], irq_ack_o, irq_id_o[4:0], debug_req_i, debug_havereset_o, debug_running_o, debug_halted_o, fetch_enable_i, core_sleep_o.
* Quiet inputs for normal operation: `irq_i = 0`, `debug_req_i = 0`, `pulp_clock_en_i = 0`, `scan_cg_en_i = 0`; `boot_addr_i` word-aligned (RTL uses `[31:2]`), `mtvec_addr_i` 256-B aligned (RTL uses `[31:8]`), dm_* word aligned, all static after fetch_enable.
* Sleep unit: `fetch_enable_q` is sticky; internal clock gated while `rst_ni=0` and until `fetch_enable_q=1`. Controller: `RESET → BOOT_SET (pc_set=PC_BOOT, instr_req) → FIRST_FETCH → DECODE`. First `instr_req_o` ≈ 2 cycles after `fetch_enable_i` is sampled high.
* Trap vector: exceptions always go to `{mtvec[31:8], 8'h0}`; `mtvec` is loaded from `mtvec_addr_i` at boot (`csr_mtvec_init`).

### 4.2 Instruction side (IF)
* `prefetch_buffer` (FIFO DEPTH=2) + `prefetch_controller` + `obi_interface(TRANS_STABLE=0)` → registered A-channel, request never retracted, address word-aligned.
* `trans_valid = req && (fifo_cnt + outstanding < 2)` → max 2 outstanding, no combinational rvalid→req path.
* On `pc_set` (branch/jump/exception/boot): FIFO flushed, `flush_cnt ← outstanding` (those responses are dropped), new address requested in the same cycle (`BRANCH_WAIT` if not granted).
* Response must arrive ≥1 cycle after the grant (RTL comment; databook waveforms). `instr_gnt_i` may be high without a request.
* Aligner/compressed decoder: pure pass-through for word-aligned 32-bit code (`ALIGNED32`, pc += 4).

### 4.3 Pipeline / control
* Jumps (JAL/JALR) taken in ID (`jump_in_dec`, `pc_set`, `PC_JUMP`); JALR target = `rs1 + imm` from RF read data (no forwarding), LSB cleared in IF.
  Cost 2 cycles (zero wait).
* Branches resolved in EX (`branch_taken_ex = branch_in_ex && branch_decision`) → `PC_BRANCH`, IF **and** ID killed (`clear_instr_valid`). Taken 3 cycles, not taken 1.
* Forwarding: EX→ID (`regfile_alu_we_fw`/`regfile_alu_wdata_fw`, ports a/b/c) and WB→ID (`regfile_we_wb`/`regfile_wdata_wb`), x0 excluded.
* `load_stall` (1 cycle @0-ws): load in EX and ID instruction reads its rd (a/b/c) **or** writes the same rd via the ALU port (WAW). Extends while WB waits for rvalid.
* `jr_stall`: JALR with rs1 pending in EX (ALU or load) or WB (load).
* `misaligned_stall`: ID re-issues the LSU op once with `operand_b = 4`, `operand_a = forwarded EX result (EA)`, `regfile_alu_we = 0`, `data_misaligned_ex = 1`.
* Illegal instruction: `DECODE → FLUSH_EX → FLUSH_WB → pc_set(PC_EXCEPTION)`; mcause = 2; the illegal instruction produces no rd write / no data request.
* Commit point usable by the TB: `id_valid && is_decoding` (== `mhpmevent_minstret` source, excludes illegal/ecall/ebreak) with `pc_id`, `instr_rdata_id`.
  In this scope (no IRQ/debug) an instruction that leaves ID always completes.

### 4.4 EX: ALU / MUL / DIV
* ALU single-cycle: ADD/SUB/SLL/SRL/SRA/SLT(S)/SLTU/XOR/OR/AND, LUI (= 0 + imm_u), AUIPC (= pc + imm_u), JAL/JALR link (= pc + 4), branch compare (`comparison_result_o` → `branch_decision`), LSU address (= rs1 + imm), store data through operand C.
* DIV/DIVU/REM/REMU: `cv32e40p_alu_div` serial divider, `IDLE → DIVIDE (Cnt from leading-zero count) → FINISH`; latency 3..35 cycles as a function of the **divisor**; `ex_ready=0` meanwhile. Special cases per RISC-V spec are implemented via `ResInv/RemSel/OpBIsZero`.
* MUL: 32x32 → low 32 in 1 cycle. MULH*: 5 cycles, `mult_multicycle` stalls ID; partial products go through `mult_operand_c_ex` (forwarded).
* `ex_ready = alu_ready & mult_ready & lsu_ready_ex & wb_ready | branch_in_ex`; `ex_valid` = last cycle of a valid instruction in EX.
* RF write port b (EX) is enabled on **every** stalled cycle of a multicycle op (see §3.3-4).

### 4.5 LSU / data side
* `obi_interface(TRANS_STABLE=1)` → transparent; stability guaranteed by the EX stall. Max 2 outstanding (`cnt_q`), `lsu_ready_wb = (cnt==0) ? 1 : rvalid`.
* BE table (data_type 00=W, 01=H, 10/11=B), `wdata` rotated by `addr[1:0] - reg_offset`, `rdata` extraction by `rdata_offset_q` + sign/zero extension (`data_sign_ext`), misaligned merge with `rdata_q`.
* Misaligned = word with `addr[1:0]!=0` or half with `addr[1:0]==11` → 2 transactions: (EA, partial BE) then ((EA+4)&~3, complementary BE). No exception ever.
* `data_rvalid_i` terminates stores too; `data_rdata_i` ignored for stores. No error signal. Response ≥1 cycle after grant.

### 4.6 Register file (`cv32e40p_register_file_ff`)
* 31 x 32-bit FFs, reset to 0, `mem[0]` forced to 0. 3 read ports (a=rs1, b=rs2, c=rs2-for-store / x0 for MULH), 2 write ports:
  port a = WB/LSU (`regfile_waddr_wb`, `regfile_wdata_wb`, `regfile_we_wb_power`), port b = EX/ALU (`regfile_alu_waddr_fw`, `regfile_alu_wdata_fw`, `regfile_alu_we_fw_power`). Port b has priority when both hit the same address.

### 4.7 Answer to Team 4 Q3 (multicycle op + flush)
* There is a single EX stage: a taken **branch** can only be evaluated when the branch itself is in EX, i.e. after any older MULH/DIV has left EX → the older multicycle op always completes and writes back; a younger one is still in ID and is killed before it starts.
* A **jump** (resolved in ID) that sits in ID while an older DIV/MULH stalls EX: the jump redirects IF immediately (`pc_set`, `jump_done_q` prevents re-issuing) and the multicycle op completes normally. Only IF (and ID for branches) are ever flushed.

---

## 5. Recommendations for the coming work

1. Rename every component in the 5 sheets to the architecture names (table §3.1) and drop `rvfi_monitor`/`ref_model`/`*_passive_agent`.
2. Fix items §3.3-1..6 in the requirement text (they change expected timings and checker design).
3. Predictor = own RV32IM ISA model that executes from the TB program image starting at `boot_addr_i` (do **not** execute raw fetched words – they include speculative prefetches that get flushed). Scoreboard compares: RF write stream (qualified, §3.3-4), data-bus transaction stream, final RF/memory state.
4. End-of-test: a store to a magic address (seen by the Data agent monitor) or a `j .` at a sentinel PC.
5. Data-memory model: byte-enable aware, word indexed (`addr[31:2]`), in-order responses, per-transaction gnt/rvalid delays, rvalid never in the grant cycle.
