# tb/task_mul/ — MUL task deliverable (one of 5 team tasks)

This folder is **the MUL slice only** — the code the MUL owner contributes to
the team's single environment. Everything here compiles stand-alone; the other
tasks (ALU, sequences, predictor, ...) live with their owners and get merged
later into one environment.

| Piece | File(s) | What it is |
|---|---|---|
| Interface | `interfaces/alu_mul_if.sv` | shared EX-stage probe interface (#6 of `tb_architecture/arch.jpg`), 46 input signals + `mon_cb` |
| Agent + monitor | `agents/mul_agent/*.sv` | `mul_txn`, `mul_agent_cfg`, `mul_monitor` (the brain), passive `mul_agent`, `mul_agent_pkg` |
| Scoreboard part | `env/mul_scoreboard_pkg.sv` | MUL-only scoreboard (result / latency / write-port / tag checks) — extracted from `tb/env/alu_mul_scoreboard.sv` |
| Reference model | `common/rv32m_ref_pkg.sv` + `common/rv32m_ref_selftest.sv` | golden RV32M functions (`rv32m_ref`, decode helpers) + 60-vector self-test |
| Covergroups | `fcov/mul_cov.sv` + `fcov/mul_cov_pkg.sv` | the 6 MUL covergroups (op/operands, result, timing, regs, sequence, reset) |
| Assertions | `assertions/mul_sva.sv` | 17 MUL SVA + 8 covers (bind into the core during integration) |
| Sequences | `sequences/*.sv` | `mul_program_pkg` (plain-SV program generator: MUL blocks + corners), `mul_program_seq` (V_Sequence wrapper), `mul_seq_pkg` |
| Tests doc | `tests/README_mul_tests.md` | MUL test definitions for the team env |

**Not in this folder (on purpose):** `alu_mul_bind.sv` (integration glue, added
when merging with the real RTL), the plain smoke checkers (RTL-bench only),
and every ALU/DIV piece (other task).

## Run it (the working environment)
```
tb/scripts/run_task_mul.sh          # Verilator: build (~4 min first time) + run -> PASS
```
The runner uses `tb/task_mul_env/` (demo env + top + `.f`), which compiles the
files **of this folder** directly — so what runs is exactly what you submit.

## Source of truth / sync
`interfaces/`, `agents/`, `common/`, `fcov/mul_cov.sv`, `assertions/`,
`sequences/`, `tests/` are kept byte-identical to the integrated tree
(`tb/interfaces`, `tb/agents/mul_agent`, ...). Refresh them any time with:
```
tb/scripts/sync_task_mul.sh
```
(`env/mul_scoreboard_pkg.sv` and `fcov/mul_cov_pkg.sv` are deliverable-only
extractions — keep them in sync with the MUL half of `tb/env/alu_mul_scoreboard.sv`
by hand; the checks are documented in the file header.)
