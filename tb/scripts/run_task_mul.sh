#!/usr/bin/env bash
# =============================================================================
# run_task_mul.sh — build & run the MUL-ONLY working environment (folder
# tb/task_mul_env/): the tb/task_mul/ deliverable (mul_agent + mul_scoreboard +
# mul_cov + interface) on the behavioural mini core, free tools only.
#
#   tb/scripts/run_task_mul.sh                 # default: short program
#   tb/scripts/run_task_mul.sh +mini_prog=full # whole directed scenario
#   REBUILD=1 ...                              # force recompile
#
# Flow (same proven recipe as run_mini_uvm.sh): Verilator generate ->
# mini_group_mk.py splits the aggregated UVM TU -> serial make -> run.
# Exit 0 = PASS (parsed from the UVM report, not the process exit code).
# =============================================================================
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UVM_SRC="${UVM_SRC:-/home/user/tools/uvm-core/src}"
OUT="${TASK_MUL_OUT:-/tmp/task_mul_env}"
SIM="${SIM:-verilator}"
mkdir -p "$OUT"
export PATH="/home/user/tools/bin:$PATH"

INC=(
  "+incdir+$UVM_SRC"
  "+incdir+$ROOT/tb/task_mul/agents/mul_agent"
  "+incdir+$ROOT/tb/task_mul/env"
  "+incdir+$ROOT/tb/task_mul/fcov"
  "+incdir+$ROOT/tb/task_mul/sequences"
)
mapfile -t REPO_FILES < <(sed "s#^#$ROOT/#" "$ROOT/tb/scripts/task_mul.f")
# short program: a few instructions incl. MUL + MULH (fast, easy to read)
RUN_ARGS=("+mini_prog=simple" "+UVM_NO_RELNOTES")

case "$SIM" in
  verilator)
    if [ ! -x "$OUT/obj_dir/Vtask_mul_env" ] || [ -n "$REBUILD" ]; then
      echo "[task_mul] 1/3: Verilator generate (UVM_NO_DPI, -O0)..."
      ( cd "$OUT" && rm -rf obj_dir &&
        verilator --cc --timing --main --exe --assert -j 1 \
          --output-split 2000 --output-split-cfuncs 500 \
          -CFLAGS "-std=gnu++20 -O0 -fcoroutines" \
          -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD \
          +define+UVM_NO_DPI \
          "${INC[@]}" \
          --top-module task_mul_env_tb -o Vtask_mul_env \
          "$UVM_SRC/uvm_pkg.sv" "${REPO_FILES[@]}" \
          > "$OUT/build.log" 2>&1 ) || {
            echo "[task_mul] GENERATE FAILED — tail of $OUT/build.log:"
            tail -30 "$OUT/build.log"; exit 1; }
      echo "[task_mul] 2/3: splitting the aggregated UVM classes TU..."
      python3 "$ROOT/tb/scripts/mini_group_mk.py" "$OUT/obj_dir" \
          >> "$OUT/build.log" 2>&1 || {
        echo "[task_mul] GROUP SPLIT FAILED — tail of $OUT/build.log:"
        tail -20 "$OUT/build.log"; exit 1; }
      echo "[task_mul] 3/3: compiling (serial, PCH)..."
      ( cd "$OUT/obj_dir" &&
        make -f Vtask_mul_env_tb.mk -j1 CFG_CXXFLAGS_PCH_I=-include Vtask_mul_env \
        >> "$OUT/build.log" 2>&1 ) || {
          echo "[task_mul] BUILD FAILED — tail of $OUT/build.log:"
          tail -30 "$OUT/build.log"; exit 1; }
      echo "[task_mul] build OK"
    fi
    ( cd "$OUT" && ./obj_dir/Vtask_mul_env "${RUN_ARGS[@]}" "$@" > "$OUT/sim.log" 2>&1 ) || true
    SIM_LOG="$OUT/sim.log"
    ;;
  *)
    echo "SIM=$SIM not wired for task_mul (only verilator so far)"; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# PASS/FAIL from the UVM report.
# ---------------------------------------------------------------------------
echo "[task_mul] log: $SIM_LOG"
pass=1
if ! grep -q "TASK_MUL SUMMARY" "$SIM_LOG"; then
  echo "[task_mul] FAIL: the UVM test never reached report_phase"
  pass=0
fi
if grep -qE "UVM_ERROR[[:space:]]*:[[:space:]]*[1-9]" "$SIM_LOG" ||
   grep -qE "UVM_FATAL[[:space:]]*:[[:space:]]*[1-9]" "$SIM_LOG"; then
  echo "[task_mul] FAIL: UVM_ERROR/UVM_FATAL reported"
  pass=0
fi
if grep -o 'errors=[0-9]*' "$SIM_LOG" | grep -qv 'errors=0'; then
  echo "[task_mul] FAIL: scoreboard reported errors"
  pass=0
fi
if grep -q "TASK_MUL_WATCHDOG" "$SIM_LOG" && ! grep -q "smoke_done triggered" "$SIM_LOG"; then
  echo "[task_mul] FAIL: watchdog fired before the scenario finished"
  pass=0
fi

grep -E "TASK_MUL SUMMARY|MUL side:|coverage:|smoke_done triggered|program =" "$SIM_LOG" | sed 's/^.*: //' || true

if [ "$pass" -eq 1 ]; then
  echo "[task_mul] PASS — the MUL task environment ran clean on SIM=$SIM"
  exit 0
else
  echo "[task_mul] FAILED — see $SIM_LOG"
  exit 1
fi
