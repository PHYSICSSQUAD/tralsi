#!/usr/bin/env bash
# =============================================================================
# run_mini_uvm.sh — build & run the MINI UVM environment (tb/mini/) so the
# REAL UVM stack (agents + scoreboard + coverage + mul_smoke_test) can be
# validated on a free simulator BEFORE it is integrated with the big RTL.
#
# Usage:
#   tb/scripts/run_mini_uvm.sh [sim-plusargs...]     # SIM=verilator (default)
#   SIM=questa   tb/scripts/run_mini_uvm.sh          # ModelSim/Questa (vlog/vsim)
#   SIM=vcs      tb/scripts/run_mini_uvm.sh          # Synopsys VCS
#   SIM=xcelium  tb/scripts/run_mini_uvm.sh          # Cadence Xcelium
#   REBUILD=1    ...                                  # force recompile
#
# Notes for the non-Verilator flows:
#   * They need UVM from the tool vendor (or set UVM_SRC to a uvm_pkg.sv
#     tree).  Everything else comes from this repo via tb/scripts/mini_uvm.f.
#   * +incdir+ requirements (same as tb_mul.f):
#       tb/agents/mul_agent  tb/agents/alu_agent  tb/env  tb/fcov
#   * +define+UVM_NO_DPI is used everywhere: the environment only needs
#     glob matching for config_db, so the pure-SV UVM fallback is enough
#     and no DPI C code has to be compiled/linked on any tool.
#   * These three flows are NOT runnable in this sandbox (no license) — the
#     command lines are provided ready for a machine that has them.
#
# Env: UVM_SRC   = dir containing uvm_pkg.sv (default: /home/user/tools/uvm-core/src)
#      MINI_OUT  = work directory        (default: /tmp/mini_uvm)
#      REBUILD=1 = force rebuild
# Exit code 0 = PASS (based on the UVM report, not just the process status).
# =============================================================================
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UVM_SRC="${UVM_SRC:-/home/user/tools/uvm-core/src}"
OUT="${MINI_OUT:-/tmp/mini_uvm}"
SIM="${SIM:-verilator}"
mkdir -p "$OUT"
export PATH="/home/user/tools/bin:$PATH"

INC=(
  "+incdir+$UVM_SRC"
  "+incdir+$ROOT/tb/agents/mul_agent"
  "+incdir+$ROOT/tb/agents/alu_agent"
  "+incdir+$ROOT/tb/env"
  "+incdir+$ROOT/tb/fcov"
)
# repo files in dependency order (plain paths; uvm_pkg.sv is prepended per tool)
mapfile -t REPO_FILES < <(sed "s#^#$ROOT/#" "$ROOT/tb/scripts/mini_uvm.f")
RUN_ARGS=("+UVM_TESTNAME=mul_smoke_test" "+UVM_NO_RELNOTES")

case "$SIM" in
  # -------------------------------------------------------------------------
  verilator)
    if [ ! -x "$OUT/obj_dir/Vmini_uvm" ] || [ -n "$REBUILD" ]; then
      # 1/3 generate C++ (no compile yet)
      echo "[mini_uvm] 1/3: Verilator generate (UVM_NO_DPI, -O0)..."
      ( cd "$OUT" && rm -rf obj_dir &&
        verilator --cc --timing --main --exe --assert -j 1 \
          --output-split 2000 --output-split-cfuncs 500 \
          -CFLAGS "-std=gnu++20 -O0 -fcoroutines" \
          -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD \
          +define+UVM_NO_DPI \
          "${INC[@]}" \
          --top-module mini_tb -o Vmini_uvm \
          "$UVM_SRC/uvm_pkg.sv" "${REPO_FILES[@]}" \
          > "$OUT/build.log" 2>&1 ) || {
            echo "[mini_uvm] GENERATE FAILED — last lines of $OUT/build.log:"
            tail -30 "$OUT/build.log"; exit 1; }
      # 2/3 split Verilator's single aggregated UVM TU into ~100-file groups
      #     (one giant TU needs >3 GB of RAM and dies; groups need ~1 GB)
      echo "[mini_uvm] 2/3: splitting the aggregated UVM classes TU..."
      python3 "$ROOT/tb/scripts/mini_group_mk.py" "$OUT/obj_dir" \
          >> "$OUT/build.log" 2>&1 || {
        echo "[mini_uvm] GROUP SPLIT FAILED — tail of $OUT/build.log:"
        tail -20 "$OUT/build.log"; exit 1; }
      # 3/3 compile serially with the precompiled header
      echo "[mini_uvm] 3/3: compiling (serial, PCH)..."
      ( cd "$OUT/obj_dir" &&
        make -f Vmini_tb.mk -j1 CFG_CXXFLAGS_PCH_I=-include Vmini_uvm \
        >> "$OUT/build.log" 2>&1 ) || {
          echo "[mini_uvm] BUILD FAILED — last lines of $OUT/build.log:"
          tail -30 "$OUT/build.log"; exit 1; }
      echo "[mini_uvm] build OK"
    fi
    ( cd "$OUT" && ./obj_dir/Vmini_uvm "${RUN_ARGS[@]}" "$@" > "$OUT/sim.log" 2>&1 ) || true
    SIM_LOG="$OUT/sim.log"
    ;;
  # -------------------------------------------------------------------------
  questa)
    ( cd "$OUT" &&
      vlib work &&
      vlog -sv +define+UVM_NO_DPI "${INC[@]}" \
           "$UVM_SRC/uvm_pkg.sv" "${REPO_FILES[@]}" &&
      vsim -c -voptargs=+acc mini_tb -do "run -all; quit -f" \
           "${RUN_ARGS[@]}" "$@" | tee "$OUT/sim.log" ) || true
    SIM_LOG="$OUT/sim.log"
    ;;
  # -------------------------------------------------------------------------
  vcs)
    ( cd "$OUT" &&
      vcs -full64 -sverilog -timescale=1ns/1ps +define+UVM_NO_DPI \
          "${INC[@]}" --top_module mini_tb \
          "$UVM_SRC/uvm_pkg.sv" "${REPO_FILES[@]}" -o Vmini_uvm &&
      ./Vmini_uvm "${RUN_ARGS[@]}" "$@" > "$OUT/sim.log" 2>&1 ) || true
    SIM_LOG="$OUT/sim.log"
    ;;
  # -------------------------------------------------------------------------
  xcelium)
    ( cd "$OUT" &&
      xrun -sv -timescale 1ns/1ps +define+UVM_NO_DPI "${INC[@]}" \
           -top mini_tb "$UVM_SRC/uvm_pkg.sv" "${REPO_FILES[@]}" \
           "${RUN_ARGS[@]}" "$@" | tee "$OUT/sim.log" ) || true
    SIM_LOG="$OUT/sim.log"
    ;;
  # -------------------------------------------------------------------------
  *)
    echo "unknown SIM=$SIM (use verilator|questa|vcs|xcelium)"; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# PASS/FAIL evaluation from the UVM report (works for every SIM=...).
# ---------------------------------------------------------------------------
echo "[mini_uvm] log: $SIM_LOG"
pass=1
if ! grep -q "UVM stack summary" "$SIM_LOG"; then
  echo "[mini_uvm] FAIL: the UVM test never reached report_phase"
  pass=0
fi
if grep -qE "UVM_ERROR[[:space:]]*:[[:space:]]*[1-9]" "$SIM_LOG" ||
   grep -qE "UVM_FATAL[[:space:]]*:[[:space:]]*[1-9]" "$SIM_LOG"; then
  echo "[mini_uvm] FAIL: UVM_ERROR/UVM_FATAL reported"
  pass=0
fi
# the test's own summary prints 'errors=N' for the scoreboard — all must be 0
if grep -o 'errors=[0-9]*' "$SIM_LOG" | grep -qv 'errors=0'; then
  echo "[mini_uvm] FAIL: scoreboard reported errors"
  pass=0
fi
if grep -q "MINI_UVM_WATCHDOG" "$SIM_LOG" && ! grep -q "smoke_done triggered" "$SIM_LOG"; then
  echo "[mini_uvm] FAIL: watchdog fired before the scenario finished"
  pass=0
fi

# show the interesting report lines
grep -E "MUL-unit instructions observed|ALU instructions observed|MUL side:|ALU side:|coverage:|UVM stack summary|smoke_done triggered" "$SIM_LOG" | sed 's/^.*: //' || true

if [ "$pass" -eq 1 ]; then
  echo "[mini_uvm] PASS — the UVM stack ran clean on SIM=$SIM"
  exit 0
else
  echo "[mini_uvm] FAILED — see $SIM_LOG"
  exit 1
fi
