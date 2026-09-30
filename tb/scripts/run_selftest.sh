#!/usr/bin/env bash
# =============================================================================
# run_selftest.sh — compile and run the RV32M reference self-test.
#
# tb/common/rv32m_ref_selftest.sv checks rv32m_ref_pkg against hand-verified
# vectors (elaboration-time generate checks + a runtime loop).  It is
# standalone (no UVM, no RTL), so any SV simulator can run it — this wrapper
# makes it a one-liner and greps for the PASS banner:
#
#   tb/scripts/run_selftest.sh          # build + run + PASS/FAIL
#   REBUILD=1 tb/scripts/run_selftest.sh
#
# Exit code 0 = PASS ("rv32m_ref_selftest: PASS (N vectors)").
# =============================================================================
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${SELFTEST_OUT:-/tmp/rv32m_selftest}"
mkdir -p "$OUT"
export PATH="/home/user/tools/bin:$PATH"

if [ ! -x "$OUT/rv32m_selftest" ] || [ -n "$REBUILD" ]; then
  echo "[selftest] building with Verilator..."
  verilator --binary --timing -Wno-WIDTH -Wno-UNOPTFLAT -j 1 \
    --top-module rv32m_ref_selftest -o rv32m_selftest --Mdir "$OUT" \
    "$ROOT/tb/common/rv32m_ref_pkg.sv" \
    "$ROOT/tb/common/rv32m_ref_selftest.sv" \
    > "$OUT/build.log" 2>&1 || {
      echo "[selftest] BUILD FAILED — last lines of $OUT/build.log:"
      tail -20 "$OUT/build.log"; exit 1; }
fi

"$OUT/rv32m_selftest" | tee "$OUT/selftest.log"
grep "rv32m_ref_selftest: PASS" "$OUT/selftest.log" > /dev/null
echo "[selftest] PASS"
