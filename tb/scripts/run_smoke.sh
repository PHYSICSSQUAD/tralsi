#!/usr/bin/env bash
# Build and run the multiplier smoke test with Verilator.
#   plain : tb/scripts/run_smoke.sh [plusargs...]              (checker only, -DALU_MUL_NO_UVM)
#   UVM   : UVM=1 tb/scripts/run_smoke.sh [plusargs...]        (+ real mul_agent/scoreboard/coverage)
# Env: REBUILD=1 forces a rebuild, SMOKE_OUT=<dir> selects the work directory.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UVM_SRC="${UVM_SRC:-/home/user/tools/uvm-core/src}"
if [ -n "$UVM" ]; then OUT="${SMOKE_OUT:-/tmp/smoke_uvm}"; else OUT="${SMOKE_OUT:-/tmp/smoke}"; fi
mkdir -p "$OUT"
export PATH="/home/user/tools/bin:$PATH"

python3 "$ROOT/tb/scripts/rv32_asm.py" "$ROOT/tb/sim/smoke/mul_smoke.s" "$OUT/prog.mem" "$OUT/exp_regs.txt" \
        --base 0x80 --end-addr 0x10FFC

if [ -n "$UVM" ]; then
  MODE_ARGS="-DSMOKE_UVM +incdir+$UVM_SRC $UVM_SRC/uvm_pkg.sv \
    +incdir+$ROOT/tb/env +incdir+$ROOT/tb/fcov +incdir+$ROOT/tb/agents/alu_agent \
    $ROOT/tb/agents/mul_agent/mul_agent_pkg.sv $ROOT/tb/agents/alu_agent/alu_agent_pkg.sv $ROOT/tb/env/alu_mul_sb_pkg.sv $ROOT/tb/fcov/alu_mul_cov_pkg.sv"
  UVM_PKG_FILE="$ROOT/tb/sim/smoke/mul_smoke_uvm_pkg.sv"
  RUN_ARGS="+UVM_TESTNAME=mul_smoke_test +UVM_NO_RELNOTES"
else
  MODE_ARGS="-DALU_MUL_NO_UVM"
  UVM_PKG_FILE=""
  RUN_ARGS=""
fi

if [ ! -x "$OUT/obj_dir/Vtb_smoke" ] || [ -n "$REBUILD" ]; then
  cd "$OUT"
  verilator --binary --timing --assert -j 2 -CFLAGS "-std=gnu++20 -fcoroutines" -MAKEFLAGS "CFG_CXXFLAGS_PCH_I=-include" \
    -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN \
    --top-module tb_smoke \
    +incdir+"$ROOT/tb/agents/mul_agent" \
    $(sed "s#^#$ROOT/#" "$ROOT/tb/scripts/rtl.f") \
    "$ROOT/tb/common/rv32m_ref_pkg.sv" \
    "$ROOT/tb/common/alu_ref_pkg.sv" \
    "$ROOT/tb/sequences/mul_program_pkg.sv" \
    "$ROOT/tb/interfaces/alu_mul_if.sv" \
    $MODE_ARGS \
    "$ROOT/tb/interfaces/alu_mul_bind.sv" \
    "$ROOT/tb/assertions/mul_sva.sv" \
    "$ROOT/tb/assertions/alu_sva.sv" \
    "$ROOT/tb/sim/smoke/obi_mem_model.sv" \
    "$ROOT/tb/sim/smoke/mul_smoke_checker.sv" \
    "$ROOT/tb/sim/smoke/alu_smoke_checker.sv" \
    $UVM_PKG_FILE \
    "$ROOT/tb/sim/smoke/tb_smoke.sv" \
    -o Vtb_smoke 2>&1 | grep -v "^%Warning" | grep -v "^\s*$" || true
fi
cd "$OUT"
if [ -n "$GEN" ]; then
  # random MUL-directed programs from mul_program_gen, checked against the Python reference executor
  FAIL=0
  for SEED in ${SEEDS:-1 2 3 4 5}; do
    mkdir -p "$OUT/gen_$SEED"
    ./obj_dir/Vtb_smoke +gen="$GEN" +gen_dir="$OUT/gen_$SEED" +exp= +rf_dump="$OUT/gen_$SEED/rf_rtl.txt" \
        +verilator+seed+$SEED $RUN_ARGS "$@" > "$OUT/gen_$SEED/sim.log" 2>&1
    python3 "$ROOT/tb/scripts/rv32_asm.py" "$OUT/gen_$SEED/gen.mem" - "$OUT/gen_$SEED/exp_regs.txt" --exec-mem --end-addr 0x10FFC > "$OUT/gen_$SEED/ref.log"
    if grep -q "SMOKE TEST PASSED" "$OUT/gen_$SEED/sim.log" && python3 "$ROOT/tb/scripts/rv32_asm.py" --compare "$OUT/gen_$SEED/exp_regs.txt" "$OUT/gen_$SEED/rf_rtl.txt" > "$OUT/gen_$SEED/cmp.log"; then
      echo "seed $SEED: PASS  $(grep -o 'generated program: .*' "$OUT/gen_$SEED/sim.log" | cut -c20-140)  | $(grep 'MUL checker' "$OUT/gen_$SEED/sim.log" | cut -c14-90)"
    else
      echo "seed $SEED: FAIL  (see $OUT/gen_$SEED/{sim,ref,cmp}.log)"; FAIL=1
    fi
  done
  exit $FAIL
fi
./obj_dir/Vtb_smoke +prog="$OUT/prog.mem" +exp="$OUT/exp_regs.txt" $RUN_ARGS "$@"
