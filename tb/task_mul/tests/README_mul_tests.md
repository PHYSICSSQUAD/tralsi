# MUL / ALU-DIV directed tests (what the test layer has to provide)

The MUL and ALU agents / scoreboard / coverage / assertions are all passive:
they only need programs that put the two EX units into the interesting
situations, plus the Data-agent wait states and the Reset agent for two of the
scenarios. The programs come from `mul_seq_pkg::mul_program_seq` (V_Sequence
layer), whose generator was validated on the RTL with `tb/scripts/run_smoke.sh GEN=..`
(both checker twins, both SVA modules, register-file compare against the Python ISS).

## Common set-up (all MUL tests)

| item | value |
|---|---|
| boot / program | `boot_addr_i = 0x80`, program image loaded at `0x80` (Instructions agent memory model) |
| data window | `0x0001_0000 .. 0x0001_0FFF` (byte-enable aware OBI slave, Data agent) |
| end of test | store to `0x0001_0FFC` (program then spins with `jal x0,0`) - or replace the end block (`emit_end_block = 0`) with the team's sentinel |
| tie-offs | `irq_i = 0`, `debug_req_i = 0`, `pulp_clock_en_i = 0`, `scan_cg_en_i = 0`, `mtvec_addr_i` = any 256-B aligned address outside the program |
| env components | `mul_agent` (passive) -> `alu_mul_scoreboard.mul_imp` and `coverage_collector.mul_cov.analysis_export`; `alu_agent` (passive) -> `alu_mul_scoreboard.alu_imp` and `coverage_collector.alu_cov.analysis_export`; `mul_sva` + `alu_sva` bound automatically (`alu_mul_bind.sv`, `mul_sva.sv`, `alu_sva.sv`) |
| pass criteria | 0 `SB_MUL_*` / `SB_MULH_*` / `SB_ALU_*` / `SB_DIV_*` errors, 0 assertion failures, MUL monitor transaction count == `mul_program.n_mul_if_expected` (no reset injected), Predictor / reg_file scoreboard clean |

Sequence hand-over: `mul_program_seq::deliver()` publishes the `mul_program`
object in the config_db (`"mul_program"`); the Instructions agent memory
sequence loads `words[i]` at `base_addr + 4*i`. Override `deliver()` if the
agent wants per-instruction items.

## Tests

### `risc_mul_test`  (exists in the test list - keep the name)
* sequence: `mul_program_seq` with default focus (`stall_focus = dep_focus = corner_focus = 0`), `n_blocks` 60..150.
* buses: instruction gnt 0..1 wait states, data gnt/rvalid 0..2 wait states (light).
* goal: all `cg_op_operands` bins/crosses (op x class x sign), `cg_result`, `cg_regs`
  (rd = x0, rs1 == rs2, rd == rs1/rs2) - ~1500 M ops per seed as in the test list; 10+ seeds.
* also covers risc_dec_01 (all four multiplier mnemonics) and the MUL part of risc_haz_00.

### `risc_mulh_stall_test`  (new)
* sequence: `mul_program_seq` with `stall_focus = 1` (60-80 % `after_load` blocks: `LW` then an
  independent `MULH*`/`MUL`, then a load-use `MUL`).
* buses: data `max_rvalid_wait >= 3` (long stalls), random gnt delays; instruction wait states random.
* goal: `cg_timing.x_op_stall` bins `one`, `two_three`, `many` for both `mul` and `mulh`
  (MULH held in FINISH by `wb_ready = 0`, MUL held in its only cycle) while `cp_mult_cycles`
  stays `one` / `five` - this is vplan row **risc_m_05**. Scoreboard check `SB_MUL_LATENCY`
  (net multiplier cycles), `SB_MUL_WB` (exactly one write-back, in the `ex_valid` cycle).

### `risc_mul_dep_test`  (new)
* sequence: `mul_program_seq` with `dep_focus = 1` (dependency + back-to-back blocks dominate).
* buses: zero or light wait states (so the gaps are really 1).
* goal: `cg_sequence.x_b2b` (MULH->MULH FSM re-entry, MULH->MUL, MUL->MULH, MUL->MUL with gap 1),
  `cg_sequence.x_dep_gap` (MUL-unit result consumed by a MUL-unit op at distance 1 / 2),
  DIV->MUL, MUL->store data / address, MUL->branch condition. Checks: result compare through the
  forwarding path (Predictor + `SB_MUL_RESULT` on the raw operands), `SB_MUL_TAG` (rd of the write
  port == rd of the tagged instruction).

### Reset injection (existing `risc_rst_02`, Reset agent)
* any of the three sequences in the background; the Reset agent re-asserts `rst_ni` while
  `mulh_active = 1` (STEP0..FINISH) and while a MUL is stalled.
* MUL monitor publishes the in-flight transaction with `killed_by_reset = 1`; scoreboard skips
  result/latency checks for it and counts it; `cg_reset.x_op_stage` covers the FSM stage hit;
  `A_RESET_IDLE` (mul_sva) checks the FSM is back in IDLE after reset. After the re-boot the
  program restarts from `boot_addr`, so the final architectural state is still the reference state.

### Multicycle + taken branch (existing `risc_multicycle_branch_test`)
* the `before_branch` blocks of `mul_program_seq` (also present in the default mix) put a MULH/MUL
  right before an always-taken branch and an M op in the shadow. Expected: the older M op completes
  and writes back once; the shadow M op never appears on the MUL interface
  (`n_shadow_ops` is excluded from `n_mul_if_expected`). Covered by the transaction-count check.

### `risc_div_test` / `risc_div_corner_test`  (exist in the test list - keep the names; vplan risc_m_02 / risc_m_03, ALU agent path)
* sequence: `mul_program_seq` with `div_focus = 1` (50-70 % `div_corners` blocks: divisor classes
  0 / 1 / -1 / INT_MIN / INT_MAX / single-bit / all-but-one-bit / small / large, dividend INT_MIN / 0 / -1 /
  INT_MAX / 1 / random; plus `div_mix` and `after_load` blocks).
* buses: data rvalid 0..6 wait states in half of the seeds (holds the divider in FINISH: `cg_div_timing.x_lat_stall`).
* goal: `cg_div` (op x dividend class, op x divisor class, divide by zero, INT_MIN / -1, sign quadrants),
  `cg_div_timing.x_op_lat` - every latency bin 3 / 4..10 / 11..30 / 31..33 / 34 / 35 for the four ops,
  `cg_seq.x_div_then*` (DIV followed by a dependent consumer / branch at gap 1..3). Checks: `SB_DIV_RESULT`
  (spec table 7.1 special cases), `SB_DIV_LATENCY` (exact `div_latency_ref`: 3 for a divisor with no leading
  zero - 0x80000000 unsigned as well as signed -, n+3 for n leading zeros, 34 for divisor 1 / -1, 35 for 0),
  `A_DIV_LATENCY_EXACT` / `A_DIV_LATENCY_CNT`, `A_DIV_BUSY_BLOCKS_EX`, `SB_ALU_WB` (single write-back in the
  `ex_valid` cycle, rd from the tag).
  NOTE for the vplan text of risc_m_02: "35 cycles when the divisor is 0, 3 when the divisor has no leading
  zeros" - the RTL takes 3 cycles for **any** divisor >= 0x80000000 in DIVU/REMU too (6-bit `clb_result`
  wrap in cv32e40p_alu.sv), not 35; the reference model and the smoke run agree.

### ALU-path passive checks for the existing `risc_alu_r_type_test` / `risc_alu_i_type_test` / `risc_shift_test` / `risc_upper_test` / `risc_branch_test` / `risc_jump_test` / `risc_misaligned_test`  (ALU agent path)
* those tests use the team's `riscv_alu_sequence` / `riscv_shift_sequence` / ... ; the ALU agent, `alu_imp`
  scoreboard side, `alu_cov` and `alu_sva` are passive and simply run underneath. To get the same coverage
  from the generator delivered here: `mul_program_seq` with `alu_focus = 1` (60-80 % `alu_mix` blocks: every
  RV32I register / immediate ALU instruction, LUI / AUIPC, the AUIPC + JALR pattern, plus `before_branch`,
  `after_load`, `lsu_mix` blocks with misaligned loads/stores).
* buses: light random wait states; a few seeds with `+drw`-style long data waits to get branches that
  leave EX without `ex_valid` (`cg_branch.x_op_valid`).
* goal: `cg_op` (all 20 operators, `x_op_we`, LUI / AUIPC / jump / LSU sourcing), `cg_alu_operands`
  (class x operand class x sign), `cg_shift` (op x shamt 0 / 1 / mid / 31 x MSB), `cg_branch`
  (op x taken x sign quadrant), `cp_lsu` bins `lsu_addr` / `lsu_misaligned2`. Checks: `SB_ALU_RESULT`,
  `SB_ALU_TAG` (decoder mapping instruction -> operator / we / rd / lsu_en, LUI = imm_u, AUIPC = pc + imm_u,
  JAL/JALR link = pc + 4), `A_NO_ISSUE_IS_BUBBLE`, `A_MISALIGNED_2ND_PASS`, `A_BRANCH_*`.

## Knob reference (`mul_program_seq` / `mul_program_gen`)

| knob | meaning | default |
|---|---|---|
| `n_blocks` | number of scenario blocks | rand 10..150 |
| `w_single`, `w_sign_matrix`, `w_special_regs`, `w_back_to_back`, `w_dependency`, `w_after_load`, `w_before_branch`, `w_div_mix`, `w_alu_mix`, `w_div_corners`, `w_lsu_mix` | block-type weights | see constraints (`stall_focus` / `dep_focus` / `corner_focus` / `div_focus` / `alu_focus`) |
| `pct_misaligned` | % of `lsu_mix` accesses that are misaligned (2 ALU passes in EX) | 40 |
| `pct_rd_x0` | % of M ops with rd = x0 | 0..10 |
| `pct_mulh` | % of MUL-family picks that are MULH/MULHSU/MULHU | 30..80 |
| `w_opclass[12]` | operand class weights (`operand_class_e` order: 0, 1, -1, INT_MAX, INT_MIN, 0xAA.., 0x55.., pow2, pos_small, pos_large, neg_small, neg_large) | corner-heavy |
| `boot_addr`, `data_base`, `end_store_addr`, `emit_end_block`, `init_all_regs` | environment parameters | 0x80 / 0x10000 / 0x10FFC / 1 / 1 |
| `dump_prefix` | write `<prefix>.mem` + `<prefix>.lst` for debug / re-run in the smoke test | "" |

Re-running a program from a UVM test in the Verilator smoke bench (for debug without UVM):
`tb/scripts/run_smoke.sh +prog=<prefix>.mem +exp=` (or produce `exp_regs.txt` with
`python3 tb/scripts/rv32_asm.py <prefix>.mem - exp.txt --exec-mem --end-addr 0x10FFC`).
