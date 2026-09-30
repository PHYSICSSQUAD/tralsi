# MUL (RV32M multiplier) verification – work plan

Owner scope: everything that touches the multiplier of the CV32E40P in the RV32IM configuration:
`ALU_MUL` interface, `MUL agent` (passive), `ALU_MUL Scoreboard` (MUL side), reference functions,
MUL coverage (in `coverage_collector`), MUL assertions (in `Assertions`), MUL stimulus (V_Sequences side),
and the MUL rows of the verification plan (`risc_dec_01`, `risc_m_00`, `risc_m_01`, `risc_m_04`, parts of `risc_haz_*`).

---

## 0. Facts that shape the design (from the RTL)

### 0.1 MUL is *not* the same block as DIV
| | MUL / MULH / MULHSU / MULHU | DIV / DIVU / REM / REMU |
|---|---|---|
| RTL block | `cv32e40p_mult.sv` (`ex_stage_i.mult_i`) | `cv32e40p_alu.sv` → `cv32e40p_alu_div.sv` (`ex_stage_i.alu_i.alu_div_i`) |
| Decoder enables | `mult_int_en=1`, `alu_en=0` | `alu_en=1`, `alu_operator=ALU_DIV/DIVU/REM/REMU` |
| Operator field | `mult_operator_ex` = `MUL_MAC32` (MUL) / `MUL_H` (MULH*) + `mult_signed_mode_ex` = 11 (MULH), 01 (MULHSU), 00 (MULHU) | `alu_operator_ex`; operands swapped: `alu_operand_a = rs2 (divisor)`, `alu_operand_b = rs1 (dividend)` |
| Ready | `mult_ready` (0 while MULH FSM busy) | `alu_ready` (0 while the divider runs) |
| Latency | MUL 1, MULH* 5 | 3..35 |
| Result mux in EX | `if (mult_en_i) regfile_alu_wdata_fw_o = mult_result` | `if (alu_en_i) regfile_alu_wdata_fw_o = alu_result` |

Shared by both: the EX stage handshake (`ex_ready`, `ex_valid`), the ALU write port of the register file
(`regfile_alu_we_fw`, `regfile_alu_waddr_fw`, `regfile_alu_wdata_fw`) and the EX→ID forwarding path.
Therefore: **one `alu_mul_if`** (as in the architecture drawing), **two passive agents** (MUL agent decodes `mult_*`,
ALU agent decodes `alu_*` including DIV/REM), **one `ALU_MUL Scoreboard`** with two analysis imports,
**one reference package** (`rv32m_ref_pkg`) holding all 8 M-extension functions so the ISA-level Predictor reuses them.

### 0.2 Cycle-by-cycle behaviour the monitor must follow
Sampling convention: clocking block, values of cycle *k* are observed at the posedge that ends cycle *k*.

**MUL rd, rs1, rs2** (no stalls)
| cycle | stage | what the interface shows |
|---|---|---|
| N | ID | `id_valid && is_decoding` = 1 (issue pulse) with `pc_id`, `instr_rdata_id` → tag |
| N+1 | EX | `mult_en=1`, `mult_operator=MUL_MAC32`, `mult_operand_a=rs1`, `mult_operand_b=rs2`, `mult_operand_c=0`, `mult_ready=1`, `mult_multicycle=0`, `mult_result=low32`, `regfile_alu_we_fw=1`, `waddr=rd`, `wdata=mult_result`, `ex_valid=1` → RF written at end of N+1, forwarded to ID in N+1 |

**MULH/MULHSU/MULHU rd, rs1, rs2** (no stalls)
| cycle | `mulh_CS` | `mult_ready` | `mult_multicycle` | `mulh_active` | `mult_operand_c` | `ex_valid` | note |
|---|---|---|---|---|---|---|---|
| N+1 | IDLE | 0 | 0 | 0 | 0 (REGC_ZERO) | 0 | FSM leaves IDLE unconditionally |
| N+2 | STEP0 | 0 | 1 | 1 | 0 | 0 | end of cycle: op_c ← `regfile_alu_wdata_fw` (ID forwards `SEL_FW_EX`) |
| N+3 | STEP1 | 0 | 1 | 1 | partial | 0 | carry saved |
| N+4 | STEP2 | 0 | 1 | 1 | partial | 0 | |
| N+5 | FINISH | 1 | 0 | 1 | partial | 1 | `mult_result` = upper 32 bits; FSM → IDLE when `ex_ready` |
`regfile_alu_we_fw` = 1 in **all five** cycles (intermediate values in the first four) – architecturally harmless,
but it means "no write during the stall" can only be checked at the `ex_valid` level, never at the RF-port level.
If `wb_ready`/`lsu_ready_ex` is low in FINISH, the FSM stays in FINISH (`mult_ready=1`, `ex_valid=0`) – external stall.

Definitions used everywhere below:
* `total_cycles` = cycles from the first cycle with `mult_en` (new instruction) to the cycle with `ex_valid` (inclusive)
* `stall_cycles` = cycles in that window with `mult_ready && !ex_valid` (EX held by LSU/WB, not by the multiplier)
* `mult_cycles` = `total_cycles - stall_cycles` → expected **1** (MUL) / **5** (MULH*)

### 0.3 Other facts to keep in mind
* Nothing in EX is ever killed in this scope (branches kill IF/ID; the illegal-instruction flush waits for `ex_valid`),
  so every started EX operation completes – except on reset (the monitor must drop the in-flight item on `!rst_n`).
* After `ex_valid`, the next cycle is either a new instruction (`mult_en/alu_en` = 1 again) or a bubble (`mult_en=alu_en=0`)
  because the ID/EX register is cleared when `ex_ready && !id_valid` → "`mult_en && !in_flight`" is a safe start condition.
* `regfile_alu_waddr_fw` is 6 bits; bit 5 selects the FP register file (FPU/Zfinx) → must be 0 in our configuration.
* In RV32IM only `MUL_MAC32` and `MUL_H` can appear on `mult_operator`; `mult_sel_subword=0`, `mult_imm=0`, `mult_dot_*` unused.
* There is no general "PC of the instruction in EX" signal (`pc_ex` in the core is only updated for branches) → tag from the ID issue pulse.
* Enabling `CV32E40P_ASSERT_ON` at compile time turns on the RTL's own MULH/MULHSU/MULHU result assertions (free extra checks).
* MUL with `rd = x0` still asserts `regfile_alu_we_fw` with `waddr = 0`; the RF drops it. Treat as legal, cover it.

---

## 1. Decision: MUL first, ALU right after, on a shared skeleton

Do together **now** (they cannot be changed later without touching both agents):
1. `alu_mul_if` with the complete signal list (ALU group + MUL group + shared EX/WB group + tag group) and the `bind`.
2. The transaction base / monitor base ("instruction in EX" tracker: start, cycle counting, stall accounting, completion on `ex_valid`, reset handling, tag attach).
3. `rv32m_ref_pkg` (8 functions + operand classifiers) and the `ALU_MUL Scoreboard` skeleton with two imports (`_mul`, `_alu`).

Then implement/debug **MUL end-to-end** (monitor → scoreboard → coverage → SVA → stimulus → vplan rows),
then **ALU** as a clone of the MUL path (bigger op table, comparisons for branches, DIV latency 3..35).
If a teammate owns the ALU, hand over items 1-3 as the frozen contract.

---

## 2. Deliverables and file layout (proposed `tb/` tree, nothing exists yet in the repo)

```
tb/
├── common/
│   └── rv32m_ref_pkg.sv          # pure functions: mul, mulh, mulhsu, mulhu, div, divu, rem, remu + classifiers
├── interfaces/
│   ├── alu_mul_if.sv             # shared passive interface (clocking block, modport MON)
│   └── alu_mul_bind.sv           # bind into cv32e40p_core (+ uvm_config_db set)
├── agents/mul_agent/
│   ├── mul_agent_pkg.sv          # package + includes
│   ├── mul_txn.sv                # uvm_sequence_item
│   ├── mul_agent_cfg.sv          # uvm_object: vif, has_coverage, check_latency, ...
│   ├── mul_monitor.sv            # passive monitor
│   └── mul_agent.sv              # agent (UVM_PASSIVE: monitor only)
├── env/
│   └── alu_mul_scoreboard.sv     # imports _mul / _alu, result + latency + write-port checks
├── fcov/                         # (not "coverage": that directory name is dropped by the workspace snapshot)
│   ├── mul_cov.sv                # covergroups, lives inside coverage_collector (uvm_subscriber style)
│   └── alu_cov.sv                # ALU/DIV covergroups (step 9)
├── assertions/
│   └── mul_sva.sv                # MUL property group of the Assertions module
└── sequences/
    └── mul_program_seq.sv        # V_Sequence that builds MUL-directed programs (needs Instructions agent API)
```

### 2.1 `alu_mul_if` – signal list and where it comes from (`cv32e40p_top.core_i.*`)
| interface signal | source in `cv32e40p_core` | group |
|---|---|---|
| `clk`, `rst_n` | `clk_i`, `rst_ni` | – |
| `ex_ready`, `ex_valid` | `ex_ready`, `ex_valid` | shared |
| `lsu_ready_ex`, `wb_ready` | `lsu_ready_ex`, `lsu_ready_wb` | shared (why EX is stalled) |
| `branch_in_ex` | `branch_in_ex` | shared/ALU |
| `alu_en`, `alu_operator`, `alu_operand_a/b/c` | `alu_en_ex`, `alu_operator_ex`, `alu_operand_*_ex` | ALU |
| `alu_result`, `alu_cmp_result`, `alu_ready` | `ex_stage_i.alu_result`, `ex_stage_i.alu_cmp_result`, `ex_stage_i.alu_ready` | ALU |
| `mult_en`, `mult_operator`, `mult_signed_mode`, `mult_operand_a/b/c` | `mult_en_ex`, `mult_operator_ex`, `mult_signed_mode_ex`, `mult_operand_*_ex` | MUL |
| `mult_result`, `mult_ready`, `mulh_active`, `mult_multicycle` | `ex_stage_i.mult_result`, `ex_stage_i.mult_ready`, `ex_stage_i.mulh_active`, `mult_multicycle` | MUL |
| `rf_alu_we`, `rf_alu_waddr[5:0]`, `rf_alu_wdata` | `regfile_alu_we_fw`, `regfile_alu_waddr_fw`, `regfile_alu_wdata_fw` | write-back |
| `id_valid`, `is_decoding`, `pc_id`, `instr_id` | `id_valid`, `is_decoding`, `pc_id`, `instr_rdata_id` | tag (debug + rs1/rs2/rd fields) |

`bind cv32e40p_core alu_mul_if alu_mul_if_i (.clk(clk_i), ... , .alu_result(ex_stage_i.alu_result), ...);`
The interface registers itself: `initial uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", <self>);`
so `top_tb` never needs the hierarchical path.

### 2.2 `mul_txn`
```
mul_op_e   op;              // MUL, MULH, MULHSU, MULHU (decoded from mult_operator + mult_signed_mode)
bit [31:0] rs1_val, rs2_val;// mult_operand_a / _b at start
bit [31:0] result;          // mult_result at ex_valid
bit [4:0]  rd;  bit rd_we;  // rf_alu_waddr[4:0], rf_alu_we at ex_valid
bit [31:0] wdata;           // rf_alu_wdata at ex_valid (mux check)
int        total_cycles, stall_cycles, mult_cycles;
bit        multicycle_seen; int multicycle_len;   // mult_multicycle pulse length (expect 0 / 3)
bit [31:0] pc, instr;       // tag; rs1/rs2/rd fields from instr for coverage
time       t_start, t_end;
function bit [31:0] exp_result();  // -> rv32m_ref_pkg
```

### 2.3 `mul_monitor` algorithm (one process on `vif.mon_cb`)
```
forever @(cb):
  if (!rst_n)            : drop in-flight item, clear tag
  if (cb.id_valid && cb.is_decoding) pending_tag = {cb.pc_id, cb.instr_id}
  if (!in_flight && cb.mult_en):
       new item; decode op; capture a/b; item.tag = pending_tag; in_flight = 1; counters = 0
  if (in_flight):
       total++; if (cb.mult_ready && !cb.ex_valid) stall++; if (cb.mult_multicycle) mc_len++
       if (cb.ex_valid): capture result/rd/we/wdata; mult_cycles = total - stall; ap.write(item); in_flight = 0
       guard: total > cfg.max_cycles (e.g. 64) -> uvm_error (hung multiplier / lost ex_valid)
```
Start and finish may happen in the same cycle (MUL) – handle the "start" block before the "in_flight" block.

### 2.4 `ALU_MUL Scoreboard` – MUL checks (block level, self-checking on DUT operands)
| id | check | plan ref |
|---|---|---|
| `sb_mul_result_match` | `result == mul_ref(rs1_val, rs2_val)` | risc_m_00 |
| `sb_mulh_result_match` | `result == mulh/mulhsu/mulhu_ref(...)` per op | risc_m_01 |
| `sb_mul_latency` | `mult_cycles == 1` (MUL) / `== 5` (MULH*); `multicycle_len == 0 / 3` | risc_m_00/01 |
| `sb_mul_wb_port` | `rd_we == 1`, `wdata == result`, `rf_alu_waddr[5] == 0`, `rd == instr[11:7]` | risc_m_00/01, risc_rf_01 |
| `sb_mul_single_completion` | exactly one `ex_valid` per started item (the monitor structure guarantees it; the SB counts items vs. issue tags) | replaces `sb_no_spurious_wb` |
| stats | per-op counters, max stall seen, printed in `report_phase` | – |
Architectural correctness of the operands and of the final rd value is the job of `Predictor` + `Scoreboard` + `reg_file Scoreboard` (not duplicated here).

### 2.5 Coverage (`mul_cov`, sampled per `mul_txn`)
* `cp_op`: MUL, MULH, MULHSU, MULHU
* `cp_a_class`, `cp_b_class`: zero, one, minus_one, int_max, int_min, pow2, pos_small(<2^16), pos_large, neg_small, neg_large, alt_pattern (0xAAAAAAAA/0x55555555)
* `cp_sign_pair`: sign(a) × sign(b) (4 cells) × op
* `cp_result_class`: zero, all_ones, msb_set, low32_overflow (product does not fit 32 bits – interesting for MUL), high_zero/high_nonzero (MULH*)
* `cp_rd`: x0, x1..x31 ; `cp_reg_overlap`: rs1==rs2, rd==rs1, rd==rs2 (from instr fields)
* `cp_latency`: `mult_cycles` {1,5} × `stall_cycles` {0, 1, 2-3, ≥4}  → MULH held in FINISH by a slow data response
* `cp_seq`: previous op → current op transitions (MUL→MULH, MULH→MULH back-to-back, MULH→MUL, ...), with/without a bubble in between
* `cp_dep`: consumer of the previous MUL/MULH at distance 1/2 (RAW through forwarding, needs the tag fields) and MULH followed by a dependent MUL (accumulator/forward path)
* cross `cp_op × cp_a_class × cp_b_class` (reduced with ignore_bins to the corner classes)

### 2.6 Assertions (MUL group of the `Assertions` module, same bind)
1. `mult_en |-> mult_operator inside {MUL_MAC32, MUL_H}` (RV32IM only)
2. `mult_en && mult_operator==MUL_MAC32 |-> mult_ready && !mult_multicycle && mult_operand_c==0`
3. `$rose(mulh_active) |-> mult_multicycle[*3] ##1 (!mult_multicycle && mult_ready)` (FSM shape)
4. `!mult_ready |-> !ex_ready && !ex_valid` (EX held while the multiplier is busy)
5. `mulh_active |-> mult_en && $stable(mult_operand_a) && $stable(mult_operand_b) && $stable(mult_operator) && $stable(mult_signed_mode)`
6. `mult_en |-> !alu_en` ; `mult_en && ex_valid |-> rf_alu_we && rf_alu_wdata == mult_result && rf_alu_waddr[5]==0`
7. `mult_en |-> !mult_sel_subword && mult_imm == 0` (no PULP modes)
8. reset: `!rst_n |=> !mulh_active` (FSM back to IDLE)

### 2.7 Stimulus that closes the MUL coverage (built on the Instructions agent / V_Sequences)
* `mul_program_seq`: blocks of {operand set-up (LUI/ADDI/XORI, or LW from a constant table) → M op → optional consumer}.
  Operand pools weighted to the classes in 2.5; sign-mode matrix for MULH*; `rd=x0`; `rs1==rs2`; `rd==rs1`.
* Patterns: back-to-back MULH×MULH, MULH→MUL, MUL→dependent ALU (distance 1/2), MULH→dependent MUL,
  MULH right after a load (needs Data-agent wait states to hit `stall_cycles>0`), MULH followed by a taken branch (risc_m_04),
  MULH/MUL with reset in the middle (risc_rst_02, Reset agent).
* Tests: `risc_mul_test` (exists), add `risc_mulh_stall_test` (data wait states), `risc_mul_dep_test` (dependency patterns).

### 2.8 Verification-plan rows to fix (MUL part)
* `risc_dec_01`, `risc_m_00`, `risc_m_01`, `risc_m_04`: components → `MUL agent (passive monitor)`, `ALU_MUL Scoreboard`, `Predictor + Scoreboard`, `coverage_collector`, `Assertions`; remove `uvm_scoreboard`, `rvfi_monitor`, `lsu_passive_agent` (in risc_m_02).
* `risc_m_01` checking: replace `sb_no_spurious_wb` by `sb_mul_single_completion` + note that the RF ALU write port toggles every cycle during the FSM and the reg_file monitor must qualify with `ex_valid`.
* `risc_m_00/01` add checking `sb_mul_latency` (1 / 5 cycles net of external stalls) and coverage `mul_latency_stall_cg`, `mul_seq_cg`, `mul_dep_cg`.
* `risc_haz_03` text (WAW mechanism) as noted in `study_notes.md`; `risc_rst_02` uses the Reset agent.
* Add a row: `risc_m_05` – MULH held in FINISH by a pending data response (external stall) completes with the correct result and exactly one write-back.

---

## 3. Order of work (each step ends with a compile/elaboration check)

| step | output | done when |
|---|---|---|
| 1 | `rv32m_ref_pkg.sv` | all 8 functions + self-test vectors (spec corner cases) pass |
| 2 | `alu_mul_if.sv` + `alu_mul_bind.sv` | elaborates against `rtl/` (bind resolves every hierarchical name) |
| 3 | `mul_txn.sv`, `mul_agent_cfg.sv`, `mul_monitor.sv`, `mul_agent.sv`, `mul_agent_pkg.sv` | compiles with UVM; monitor logic reviewed against §0.2 tables |
| 4 | `alu_mul_scoreboard.sv` (MUL side) | checks of §2.4 implemented, report summary |
| 5 | `mul_cov.sv` | covergroups of §2.5, hooked to the MUL analysis port |
| 6 | `mul_sva.sv` | properties of §2.6 |
| 7 | `mul_program_seq.sv` + test descriptions | depends on the Instructions agent API (may be a stub first) |
| 8 | vplan MUL rows updated (§2.8) | text ready to paste into the sheets |
| 9 | ALU agent path (clone) | after MUL is stable |

Tooling note: no commercial simulator in the sandbox. Elaboration checks of the UVM stack are done with `slang`
(`python3 tb/scripts/slang_check.py -f tb/scripts/rtl.f <uvm_pkg.sv> -I<uvm src> -f tb/scripts/tb_mul.f --top cv32e40p_top -Wno-unused`).
Real simulation evidence comes from **Verilator 5.48** (`tb/scripts/run_smoke.sh`, non-UVM): RTL + `alu_mul_if` bind + `mul_sva`
+ a plain-SV twin of the monitor/scoreboard algorithm (`tb/sim/smoke/mul_smoke_checker.sv`) + OBI memory models with wait states,
programs from `tb/sim/smoke/mul_smoke.s` (directed) or `mul_program_gen` (random), reference = independent Python executor
(`tb/scripts/rv32_asm.py`). UVM itself does not build under Verilator in this sandbox (4 GB RAM) - `UVM=1` mode of the script is
kept for a bigger machine / the team's simulator.

## 4. Status (2026-09-29)

| step | status | evidence |
|---|---|---|
| 1 rv32m_ref_pkg | done | 60-vector self-test; agrees with the Python reference on ~4700 random MUL-family ops + all DIV/REM in the programs |
| 2 alu_mul_if + bind | done | slang + `check_bind.py`; elaborates and simulates in Verilator (bound into `cv32e40p_core`) |
| 3 mul agent | done | slang; algorithm twin (`mul_smoke_checker`) validated on RTL: results, latency 1/5, multicycle 3, tags, write port, reset kill |
| 4 ALU_MUL scoreboard (MUL side) | done | slang; same checks as the twin (negative test: wrong latency constant -> flagged) |
| 5 mul_cov | done | slang (covergroups not executed - needs a UVM simulator) |
| 6 mul_sva | done | Verilator `--assert`: silent on 26+ programs incl. wait states and resets; negative tests (`A_MUL_RESULT`, `A_MULH_FSM_SHAPE` mutated) fire |
| 7 mul_program_gen / mul_program_seq / tests | done | 30+ random programs x wait-state settings x reset injection: RTL final RF == Python reference, MUL-interface transaction count == generator expectation |
| 8 vplan rows | done | `notes/mul_vplan_rows.md` |
| 9 ALU agent path | done (2026-09-30) | `alu_ref_pkg` (unit-tested + RTL-confirmed latency model), `alu_agent/*`, scoreboard `alu_imp`, `fcov/alu_cov.sv` (8 covergroups), `assertions/alu_sva.sv` (22 assertions, 12 covers; negative tests `A_DIV_LATENCY_CNT`, `A_NO_ISSUE_IS_BUBBLE` fire); twin `alu_smoke_checker` silent on the directed program + 50 random programs x wait states x resets, divider latency histogram covers 3..35; generator blocks `alu_mix`, `div_corners`, `lsu_mix`; full UVM stack + UVM smoke top elaborate with slang (0 errors); `check_bind.py` 37/37 + sva binds |

### 4.1 RTL facts learned in step 9 (all confirmed on the RTL, not only by reading)
* **Pipeline bubbles**: whenever EX is ready and ID has nothing valid, `cv32e40p_id_stage.sv` loads
  `alu_en_ex=1, alu_operator=ALU_SLTU, regfile_alu_we=0, branch_in_ex=0, data_req=0`. So `alu_en` is NOT
  "an instruction is in EX". The ALU monitor starts an item only when the previous cycle had the issue pulse
  (`id_valid && is_decoding`); everything else must match the bubble signature (checked, counted).
* **Misaligned load/store** (LSU splits it in two): the ID stage re-loads the ALU for a second EX pass with
  `a = first address (EX forward), b = 4, we = 0, data_misaligned_ex = 1` and no issue pulse; the first pass
  already had `ex_valid = 1`. The monitor publishes the second pass as `misaligned_2nd = 1` with the tag of
  the first pass. `lsu_en` (`data_req_ex`) and `data_misaligned_ex` were added to `alu_mul_if` for this.
* **Divider latency** = `div_shift + 3` with `div_shift` from `cv32e40p_alu.sv` (6-bit arithmetic!):
  35 for divisor 0; n + 3 for n = 1..31 leading zeros; **3 for n = 0, i.e. every divisor >= 0x80000000 in
  DIVU/REMU** (`clb_result = ff1 - 1` wraps to 63, `+1` wraps to 0) - the first version of the model said
  35 here and the smoke run caught it; 34 for signed -1; n + 2 for a negative signed divisor with n leading
  ones. No early termination. The vplan text of risc_m_02 needs the correction (see mul_vplan_rows.md).
* **Branches** leave EX with `ex_ready = 1` even when `ex_valid = 0` (`branch_in_ex` term in `ex_ready`),
  e.g. a branch right after a load whose rvalid is pending. Completion in the ALU monitor is `ex_ready`.
* The operand swap for DIV: `alu_operand_a` = divisor (rs2), `alu_operand_b` = dividend (rs1).

Smoke commands: `tb/scripts/run_smoke.sh [+dgw=N +drw=N +igw=N +irw=N] [+reset_at=C] [+verbose] [+verbose_alu] [+trace_alu]`,
`GEN=<blocks> SEEDS="1 2 3" tb/scripts/run_smoke.sh [+dgw=..]` (random programs), `REBUILD=1` after RTL/TB edits.
Tooling: after a sandbox restart run `tb/scripts/setup_tools.sh` (pyslang, Verilator, uvm-core) and rebuild with `REBUILD=1`.
Directory naming: functional coverage lives in `tb/fcov/` - a directory named `coverage` is not persisted by the workspace.

## 5. Post-delivery validation (2026-09-30)

| item | status | evidence |
|---|---|---|
| plan audit (steps 1-9) | all done | §4; zero TODO/FIXME/TBD in `tb/`; sole gap was the selftest not wired to a script -> closed below |
| compile checks | 5/5 pass | full slang UVM stack, smoke-UVM top, 2 binds + sva, mini-env slang (`--timescale 1ns/1ps`), all 0 errors |
| logic review | 1 bug found+fixed | `alu_mul_scoreboard.sv` build_phase was missing `alu_imp = new(...)`; post-fix re-checks PASS |
| reference selftest wired | done | `tb/scripts/run_selftest.sh` (Verilator, PASS = 60 vectors) |
| **mini UVM environment** | done | `tb/mini/{mini_dut.sv,mini_tb.sv}` + `tb/scripts/{mini_uvm.f,run_mini_uvm.sh}` - see below |

### 5.1 Mini UVM environment (validate the TB on a free tool BEFORE integrating the big RTL)

`tb/mini/` runs the REAL UVM stack (mul_smoke_test -> mul_agent + alu_agent + alu_mul_scoreboard +
mul_cov + alu_cov, connected exactly like the team env) against a small behavioural core instead of
`cv32e40p`:

* `mini_dut.sv` drives `alu_mul_if` (negedge-driven, so the `mon_cb @(posedge)` `input #1step` sampling
  is race-free) through a directed scenario covering: MUL/MULH/MULHU/MULHSU (1/5 cycles), external
  stalls, DIV/REM latency corners (3, 32, 34, 35), branches incl. one leaving with `ex_valid=0`,
  LUI/AUIPC/JAL/JALR operand conventions, aligned + misaligned ld/st (2-pass shape), RTL-style bubbles,
  and reset-kills mid-DIV/MULH. Results are computed with native SV operators (independent of the ref
  packages); DIV timing follows `div_latency_ref` (the documented RTL model).
* `mini_tb.sv` publishes the vif under the SAME config_db key (`"alu_mul_vif"`), starts
  `run_test("mul_smoke_test")` and triggers the global `smoke_done` event when the scenario ends
  (same end-of-test contract as `tb_smoke`: fail unless txns>0 on both sides and 0 errors).
* Run: `tb/scripts/run_mini_uvm.sh` (SIM=verilator default; SIM=questa|vcs|xcelium command lines
  provided in the script header for machines with those tools). PASS/FAIL is parsed from the UVM
  report, not the process exit code. slang elaboration: `run_mini_uvm.sh` file list via
  `slang_check.py ... -f tb/scripts/mini_uvm.f --top mini_tb --timescale 1ns/1ps`.
* Tool notes: built with `+define+UVM_NO_DPI` (pure-SV glob matching — no DPI C anywhere), so the
  same file list works on any IEEE-1800 tool with a UVM library. Verilator parses but does not
  implement covergroups (`COVERIGN`, coverage % = 0 there) and its parser rejects `with (...)`
  cross-selects — the 13 `ignore_bins ... with` statements in `tb/fcov/*` are therefore wrapped in
  `` `ifdef VERILATOR `` (plain cross kept; full syntax unchanged for every other tool).
* **First full run (2026-09-30): PASS.** build ≈ 4 min (generate 10 s + group split + serial make),
  simulation 0.05 s: MUL side 8 txns (MUL 4, MULH 2, MULHSU 1, MULHU 1) errors=0; ALU side 31 txns
  (arith 14, logic 3, shift 3, slt 2, branch 2, div 7 with latency histogram 3/30/32/34/35,
  misaligned 2nd passes 2, bubbles 7) errors=0; both reset-kills published and ignored by the SB;
  coverage samples 8+31 (0% only because Verilator ignores covergroups); watchdog never fired.
  While being brought up the env caught a real bug — `mini_dut` drove the AUIPC operand
  `b=0x0000_A000` while the encoded instruction carried `imm_u=0x000AB000` — the scoreboard flagged
  `AUIPC result 0xa0cc != pc + imm_u 0xab0cc` and the scenario was corrected. This is exactly the
  class of error the bench must catch before the big-RTL integration.
* Verilator memory workaround (built into `run_mini_uvm.sh`): the front end aggregates every
  generated class .cpp into ONE `V<top>_vm_classes_0.cpp`; compiling that single TU needs >3 GB RSS
  (observed 3.27 GB and climbing, killed). `tb/scripts/mini_group_mk.py` rewrites `V<top>_classes.mk`
  into ~100-file group objects (11 fast + 16 slow groups here) — serial make with the PCH then peaks
  at ≈1.2 GB and finishes in ≈3.3 min. Flow: generate → split → make → run.
