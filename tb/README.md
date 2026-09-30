# tb/ - MUL + ALU/DIV verification components for the CV32E40P testbench

```
tb/
├── common/rv32m_ref_pkg.sv          RV32M reference functions (MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU),
│                                    instruction decode helpers, operand classes   [shared with the Predictor]
├── common/rv32m_ref_selftest.sv     60-vector self-test module
├── common/alu_ref_pkg.sv            ALU reference: operator classes, alu_ref / alu_cmp_ref (all 20 RV32IM
│                                    alu_opcode_e), divider latency model div_latency_ref (3..35),
│                                    decoder expectations alu_expect_of_instr (op / we / rd / lui / auipc / jump / lsu)
├── interfaces/alu_mul_if.sv         passive ALU_MUL interface (EX-stage ALU + MUL signals, LSU flags, RF ALU write port, ID tags)
├── interfaces/alu_mul_bind.sv       bind into cv32e40p_core + config_db registrar ("alu_mul_vif")
├── agents/mul_agent/                mul_txn, mul_agent_cfg, mul_monitor, mul_agent (passive), mul_agent_pkg
├── agents/alu_agent/                alu_txn, alu_agent_cfg, alu_monitor, alu_agent (passive), alu_agent_pkg
├── env/alu_mul_scoreboard.sv        ALU_MUL Scoreboard - mul_imp (MUL side) + alu_imp (ALU/DIV side), alu_mul_sb_pkg.sv
├── fcov/mul_cov.sv                  MUL functional coverage subscriber (6 covergroups)
├── fcov/alu_cov.sv                  ALU/DIV functional coverage subscriber (8 covergroups), alu_mul_cov_pkg.sv
├── assertions/mul_sva.sv            MUL SVA module bound next to the interface (17 assertions, 8 covers)
├── assertions/alu_sva.sv            ALU/DIV SVA module, same bind (22 assertions incl. exact divider latency, 12 covers)
├── sequences/mul_program_pkg.sv     program generator (plain SV, RTL-validated): MUL blocks + div_mix / div_corners /
│                                    alu_mix / lsu_mix (misaligned) blocks for the ALU path
├── sequences/mul_program_seq.sv     V_Sequence wrapper + mul_program container (mul_seq_pkg.sv); focus knobs incl. div/alu
├── tests/README_mul_tests.md        test definitions (MUL tests + risc_div_test / risc_alu_test)
├── mini/                            MINI environments (block-level, pre-integration): mini_dut.sv (negedge
│                                    scenario driver + 3-instr simple program, no RTL), mini_tb.sv (UVM top),
│                                    mini_plain_tb.sv (NO-UVM twin: same smoke checkers + VCD), cb_probe.sv
├── sim/smoke/                       Verilator smoke bench (tb_smoke, OBI memory models, mul/alu checker twins, directed program)
└── scripts/                         rtl.f, tb_mul.f, slang_check.py, check_bind.py, rv32_asm.py, run_smoke.sh,
                                     run_selftest.sh, run_mini_uvm.sh, run_mini_plain.sh, mini_uvm.f, mini_plain.f,
                                     mini_group_mk.py, vcd_to_html.py, setup_tools.sh
```

NOTE: the coverage directory is named `fcov/` on purpose - a directory literally named
`coverage` is dropped by the Arena workspace snapshot (it happened once; the files were rewritten).

Compile order (team simulator): RTL packages + RTL, `uvm_pkg`, then `-f tb/scripts/tb_mul.f`
(paths relative to the repo root; the .f file is comment-free on purpose). The bind files need the
RTL module `cv32e40p_core` to be compiled in the same design; the registrar in `alu_mul_bind.sv`
needs `uvm_pkg` (compile with `-DALU_MUL_NO_UVM` in a non-UVM bench). `-DMUL_SVA_NO_BIND` /
`-DALU_SVA_NO_BIND` disable the SVA binds.

Environment hook-up:
```
mul_agent m_mul_agent;  alu_agent m_alu_agent;  alu_mul_scoreboard m_alu_mul_sb;   // env
mul_cov   m_mul_cov;    alu_cov   m_alu_cov;                                       // inside coverage_collector
m_mul_agent.ap.connect(m_alu_mul_sb.mul_imp);   m_mul_agent.ap.connect(m_mul_cov.analysis_export);
m_alu_agent.ap.connect(m_alu_mul_sb.alu_imp);   m_alu_agent.ap.connect(m_alu_cov.analysis_export);
```
Both agents are passive and share the single `alu_mul_if` instance bound into `cv32e40p_core`
(config_db key `"alu_mul_vif"`). Agent knobs: `mul_agent_cfg` / `alu_agent_cfg` via config_db `"cfg"`
(check_protocol, max_cycles_in_ex, tag_enable, verbose). Scoreboard knobs via `uvm_config_db#(bit)`:
`check_result`, `check_latency`, `check_wb_port`, `check_tag` (shared by both sides).

How the ALU monitor tells instructions apart (validated on the RTL, see `sim/smoke/alu_smoke_checker.sv`):
* an instruction is in EX in cycle N+1 iff `id_valid && is_decoding` in cycle N (tag pc/instr);
* `alu_en` without that pulse is a **pipeline bubble** (`ALU_SLTU`, `we=0`, loaded by the ID stage whenever EX
  is ready and ID has nothing) - counted, not published;
* `alu_en` with `data_misaligned_ex` is the **second pass of a misaligned load/store** (`ADD(addr, 4)`, `we=0`,
  no pulse) - published with `misaligned_2nd=1` and the tag of the first pass;
* completion is `ex_ready` (not `ex_valid`): a branch leaves EX with `ex_valid=0` when WB is busy.

Checks:
* tools after a sandbox restart: `tb/scripts/setup_tools.sh` (pyslang, Verilator, uvm-core in /home/user/tools)
* elaboration (full UVM stack): `python3 tb/scripts/slang_check.py -f tb/scripts/rtl.f <uvm>/src/uvm_pkg.sv -I<uvm>/src -f tb/scripts/tb_mul.f --top cv32e40p_top -Wno-unused`
* bind ports: `python3 tb/scripts/check_bind.py tb/interfaces/alu_mul_bind.sv cv32e40p_top.core_i -f tb/scripts/rtl.f tb/common/rv32m_ref_pkg.sv tb/interfaces/alu_mul_if.sv tb/interfaces/alu_mul_bind.sv -DALU_MUL_NO_UVM --top cv32e40p_top`
  (same for `tb/assertions/mul_sva.sv` and `tb/assertions/alu_sva.sv`, adding `tb/common/alu_ref_pkg.sv` and the sva file to the list)
* RTL simulation (Verilator, both checker twins + both SVA modules bound): `tb/scripts/run_smoke.sh +dgw=2 +drw=6`,
  `GEN=60 SEEDS="1 2 3" tb/scripts/run_smoke.sh +dgw=2 +drw=6`, `+reset_at=<cycle>`, `+verbose` / `+verbose_alu` / `+trace_alu`;
  `REBUILD=1` after any source change.
* reference-model self-test (60 vectors, no UVM): `tb/scripts/run_selftest.sh` → greps `rv32m_ref_selftest: PASS`.
* **mini UVM environment** (real agents + scoreboard + coverage + `mul_smoke_test`, free tools only):
  `tb/scripts/run_mini_uvm.sh` → PASS/FAIL from the UVM report (all `errors=0`, no UVM_ERROR/FATAL).
  `REBUILD=1` after any source change; `SIM=questa|vcs|xcelium` selects a vendor simulator
  (those branches need the vendor's UVM or `UVM_SRC`; they are compile-ready but untested in this sandbox).
* **mini plain bench (NO UVM)** — same checkers as the smoke bench, 3-instruction program:
  `tb/scripts/run_mini_plain.sh` → `MINI_PLAIN TEST PASSED`, per-instruction prints, `mini_plain.vcd`
  waveform (render: `tb/scripts/vcd_to_html.py <in.vcd> <out.html>`); `+mini_prog=full` for the
  whole scenario, `+novcd` to skip the dump.

Mini environments (tb/mini/) — why they exist — TWO runnable copies of the same checking logic:
* **UVM version** (`run_mini_uvm.sh`): the REAL UVM stack (interface, both passive agents,
  scoreboard, covergroups, test + phases) against `mini_dut.sv`, a small negedge-driven scenario
  driver (MUL/ALU/branch/DIV/misaligned/reset sequences with native golden results) — no RTL,
  so it validates the bench before integration.
* **Plain (no-UVM) version** (`run_mini_plain.sh`): `mini_plain_tb.sv` — identical wiring, but the
  checking is done by the SAME plain-SV checkers the big RTL smoke bench uses
  (`mul_smoke_checker` + `alu_smoke_checker`). Defaults to the **3-instruction program**
  (`+mini_prog=simple`: MUL, MULH, ALU_ADD — edit them in `mini_dut.sv`), prints every instruction
  (`+verbose`/`+verbose_alu`) and dumps a waveform (`+vcd` → `mini_plain.vcd`; render with
  `tb/scripts/vcd_to_html.py in.vcd out.html` and open the HTML). `+mini_prog=full` runs the whole
  directed scenario plain as well.
* `+UVM_NO_DPI` everywhere → pure-SV UVM → any IEEE-1800 tool with a SystemVerilog compiler;
* Verilator build note: the front end aggregates all UVM classes into ONE generated TU that needs
  >3 GB to compile. `mini_group_mk.py` rewrites `V*_classes.mk` into ~100-file group objects first
  (serial build ≈ 4 min, peak RSS ≈ 1.2 GB). The plain bench has no UVM, so it builds directly
  (≈ 20 s). Covergroups are parsed but ignored by Verilator (`COVERIGN`); the 13 cross
  `ignore_bins` selects in `tb/fcov/*` are `ifdef VERILATOR`-guarded.
* results: UVM full → MUL 8/8 txns, ALU 31/31 txns, errors=0 → PASS (it also caught a real AUIPC
  operand bug in the scenario driver while being brought up); plain simple → 3 instrs, 0 errors
  → MINI_PLAIN TEST PASSED.
