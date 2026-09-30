#!/usr/bin/env bash
# =============================================================================
# run_mini_plain.sh — build & run the PLAIN (NO UVM) mini bench.
#
#   tb/scripts/run_mini_plain.sh                # 3 instructions, verbose on, VCD on
#   tb/scripts/run_mini_plain.sh +mini_prog=full  # the whole directed scenario
#   tb/scripts/run_mini_plain.sh +novcd          # skip the VCD dump
#   REBUILD=1 ...                               # force recompile
#
# What it runs: mini_plain_tb (tb/mini/) = clock + alu_mul_if + mini_dut +
# the SAME plain-SV checkers the big RTL smoke bench uses.  No UVM anywhere —
# this is the no-UVM twin of run_mini_uvm.sh: same logic, second copy.
#
# Outputs (in $PLAIN_OUT, default /tmp/mini_plain):
#   sim.log        console: per-instruction checker prints + summary + verdict
#   mini_plain.vcd waveform (unless +novcd) — open with any VCD viewer
# Exit 0 = PASS (based on the printed verdict).
# =============================================================================
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${PLAIN_OUT:-/tmp/mini_plain}"
mkdir -p "$OUT"
export PATH="/home/user/tools/bin:$PATH"

# defaults for the "watch it" run: short program, per-instruction prints, VCD
ARGS=("+mini_prog=simple" "+verbose" "+verbose_alu" "+vcd")
# user plusargs win (they come later on the command line)
mapfile -t FILES < <(sed "s#^#$ROOT/#" "$ROOT/tb/scripts/mini_plain.f")

if [ ! -x "$OUT/obj_dir/Vmini_plain" ] || [ -n "$REBUILD" ]; then
  echo "[mini_plain] building (no UVM, --trace)..."
  ( cd "$OUT" &&
    verilator --binary --timing --assert --trace -j 2 \
      --timescale 1ns/1ps \
      -CFLAGS "-std=gnu++20 -O0 -fcoroutines" \
      -MAKEFLAGS "CFG_CXXFLAGS_PCH_I=-include" \
      -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD \
      +incdir+"$ROOT/tb/agents/mul_agent" \
      --top-module mini_plain_tb -o Vmini_plain \
      "${FILES[@]}" \
      > "$OUT/build.log" 2>&1 ) || {
        echo "[mini_plain] BUILD FAILED — last lines of $OUT/build.log:"
        tail -30 "$OUT/build.log"; exit 1; }
  echo "[mini_plain] build OK"
fi

echo "[mini_plain] running: Vmini_plain ${ARGS[*]} $*"
( cd "$OUT" && ./obj_dir/Vmini_plain "${ARGS[@]}" "$@" > sim.log 2>&1 ) || true
SIM_LOG="$OUT/sim.log"
echo "[mini_plain] log: $SIM_LOG"
[ -f "$OUT/mini_plain.vcd" ] && echo "[mini_plain] vcd: $OUT/mini_plain.vcd ($(wc -c < "$OUT/mini_plain.vcd") bytes)"

# show the interesting lines (per-instruction prints + summary + verdict)
grep -E "MUL_CHECK|ALU_CHECK|MINI_PLAIN|program =" "$SIM_LOG" || true

if grep -q "MINI_PLAIN TEST PASSED" "$SIM_LOG"; then
  echo "[mini_plain] PASS — plain (no-UVM) bench ran clean"
  exit 0
else
  echo "[mini_plain] FAILED — see $SIM_LOG"
  exit 1
fi
