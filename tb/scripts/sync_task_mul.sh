#!/usr/bin/env bash
# sync_task_mul.sh — refresh the copied files of tb/task_mul/ from their
# source of truth in the integrated tree (the extracted env/fcov packages are
# deliverable-only and are NOT touched). Run from anywhere; repo auto-detected.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

cp tb/interfaces/alu_mul_if.sv                  tb/task_mul/interfaces/
cp tb/agents/mul_agent/mul_txn.sv tb/agents/mul_agent/mul_agent_cfg.sv \
   tb/agents/mul_agent/mul_monitor.sv tb/agents/mul_agent/mul_agent.sv \
   tb/agents/mul_agent/mul_agent_pkg.sv         tb/task_mul/agents/mul_agent/
cp tb/common/rv32m_ref_pkg.sv tb/common/rv32m_ref_selftest.sv tb/task_mul/common/
cp tb/fcov/mul_cov.sv                           tb/task_mul/fcov/
cp tb/assertions/mul_sva.sv                     tb/task_mul/assertions/
# sequences are NOT part of this task (owner = sequence team). They stay
# available OUTSIDE the task folder, in tb/sequences/ — remove any stale copy.
rm -rf "$ROOT/tb/task_mul/sequences"
cp tb/tests/README_mul_tests.md                 tb/task_mul/tests/

echo "[sync_task_mul] copied files refreshed. Verify with:"
echo "  python3 tb/scripts/slang_check.py +incdir files --top task_mul_env_tb (see run_task_mul.sh)"
git -C "$ROOT" status --short tb/task_mul | sed 's/^/  /' || true
