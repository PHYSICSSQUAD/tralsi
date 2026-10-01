# tb/task_mul_env/ — runnable MUL-only environment (folder 2)

The **working environment** for the MUL task: it builds only the deliverable
in `tb/task_mul/` (mul_agent + mul_scoreboard + mul_cov + interface) on the
behavioural `tb/mini/mini_dut.sv` core — no RTL, no ALU components.

```
mini_dut  ──drives──►  alu_mul_if  ──sensed by──►  mul_agent (passive)
                                                      │ ap
                      ┌───────────────────────────────┼────────────────┐
                      ▼                               ▼                ▼
               mul_scoreboard (4 check groups)   mul_cov (6 covergroups)
```

Files:
* `mul_demo_pkg.sv` — `mul_demo_env` + `mul_demo_test` (report contract: ≥1 MUL
  transaction and 0 errors, same end-of-test event as the integrated bench)
* `task_mul_env_tb.sv` — top: clock, wires, interface instance, mini_dut,
  config_db `"alu_mul_vif"`, `run_test("mul_demo_test")`, watchdog
* `task_mul.f` — file list (uvm_pkg is prepended by the runner)

Run (free tools):
```
tb/scripts/run_task_mul.sh                 # short program (MUL + MULH + ...), PASS/FAIL
tb/scripts/run_task_mul.sh +mini_prog=full # whole directed scenario
REBUILD=1 tb/scripts/run_task_mul.sh       # after any source change
```
Expected output: `TASK_MUL SUMMARY: monitor txns=2 scoreboard txns=2 errors=0 ...`
then `PASS`. Log: `$TASK_MUL_OUT/sim.log` (default `/tmp/task_mul_env/sim.log`).
