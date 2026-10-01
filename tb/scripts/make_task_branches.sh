#!/usr/bin/env bash
# =============================================================================
# make_task_branches.sh — ينشئ ويدفع التلات برانشات بتوع الفريق
# -----------------------------------------------------------------------------
# السبب إن السكربت ده موجود: جلسة الـ agent (Arena) مقيدة ببرانش واحد بس
# (arena/01a0e699-tralsi) — عشان كده الانقسام نفسه بتشغّله إنت بأمر واحد:
#
#     bash tb/scripts/make_task_branches.sh
#
# الناتج (ترقيم زي ما طلبت — بعد main=1 و arena=2):
#   #3  task/mul   = فولدر التاسك (tb/task_mul) + البيئة الشغالة + الراينر
#   #4  task/uvm   = بيئة الـ UVM المتكاملة (agents/env/fcov/assertions/
#                    sequences/smoke + run_smoke / run_mini_uvm / selftest)
#   #5  task/mini  = الميني تاسك (tb/mini + موجات sim/mini + run_mini_plain)
#
# كل برانش:
#   * بيتبني من تيب الجلسة (origin/arena/01a0e699-tralsi) — يعني كل ملفاته
#     نسخة شغالة من نفس الكود، بس بنمسح منه حتت البرانشات التانية، و
#   * بيفضل معاه الـ deps اللي محتاجها يشتغل (مثلاً task/mul ماسك
#     mini_dut + mul_program_pkg عشان run_task_mul.sh يفضل يشتغل)، و
#   * بيتعمله ملف BRANCH_*.md بيشرح محتواه، و
#   * بيتدفع لـ origin باسمه.
#
# الملفات المشتركة اللي موجودة في أكتر من برانش بتفضل متطابقة بالبايت →
# دمج التلاتة بعدين بيركّبهم من غير conflicts.
#
# السكربت مبيمسّحش ويورك ستاورك الحالي: بيشتغل في worktree مؤقتة ويمسحها.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/../.."

SRC_REF="origin/arena/01a0e699-tralsi"
echo "[branches] fetching session tip ${SRC_REF} ..."
git fetch -q origin arena/01a0e699-tralsi
SRC=$(git rev-parse FETCH_HEAD)
echo "[branches] source commit: $(git log --oneline -1 "$SRC")"

WT="$(mktemp -d)"
KEEP="$(mktemp)"
trap 'rm -rf "$WT"; rm -f "$KEEP"' EXIT

# build_branch <branch-name> <marker-file> <commit-subject> <keep-regex>...
#   الـ keep-regex بتتطبق على مسارات git ls-files؛ أي ملف مش مطابق بيتمسح.
build_branch() {
  local name="$1" marker="$2" subject="$3"; shift 3
  echo
  echo "[branches] === building ${name} ==="
  git worktree add -q --detach "$WT" "$SRC"
  (
    cd "$WT"
    # ONLY files under tb/ are candidates for deletion — everything else
    # (rtl/, databook/, guidelines/, ... = main's content, plus notes/) is
    # NEVER touched, so merging these branches later cannot destroy main.
    git ls-files -- tb/ > "$KEEP/all.txt"
    : > "$KEEP/keep.txt"
    local re
    for re in "$@"; do
      grep -E "$re" "$KEEP/all.txt" >> "$KEEP/keep.txt" || true
    done
    sort -u "$KEEP/keep.txt" -o "$KEEP/keep.txt"
    comm -23 <(sort "$KEEP/all.txt") "$KEEP/keep.txt" > "$KEEP/delete.txt"

    local n_keep n_del
    n_keep=$(wc -l < "$KEEP/keep.txt")
    n_del=$(wc -l < "$KEEP/delete.txt")
    echo "[branches]   keeping ${n_keep} files, removing ${n_del}"

    # --- sanity: critical files MUST exist on this branch -------------------
    local must
    for must in "${BRANCH_MUST[@]}"; do
      if ! grep -qxF "$must" "$KEEP/keep.txt"; then
        echo "[branches] ERROR: '${must}' is not kept on ${name} — bad keep list" >&2
        exit 1
      fi
    done
    # --- sanity: nothing from the keep list may be missing on disk ----------
    xargs -r git rm -q --ignore-unmatch -- < "$KEEP/delete.txt"

    {
      echo "# ${subject}"
      echo
      echo "- branch: \`${name}\`"
      echo "- built from: \`${SRC}\` ($(git log --format=%s -1))"
      echo "- kept files: ${n_keep} (this branch's slice + its run dependencies)"
      echo "- created by: tb/scripts/make_task_branches.sh"
      echo
      echo "## run"
      echo '```'
      case "$name" in
        task/mul)  echo "tb/scripts/run_task_mul.sh" ;;
        task/uvm)  echo "tb/scripts/run_smoke.sh          # RTL smoke (UVM checkers)"
                   echo "tb/scripts/run_mini_uvm.sh       # UVM env on mini_dut"
                   echo "tb/scripts/run_selftest.sh       # reference-model selftest" ;;
        task/mini) echo "tb/scripts/run_mini_plain.sh     # no-UVM mini run + VCD"
                   echo "python3 tb/scripts/vcd_to_html.py tb/sim/mini/mini_plain.vcd out.html" ;;
      esac
      echo '```'
    } > "$marker"
    git add -A
    git commit -q -m "$subject"
  )
  local tip
  tip=$(git -C "$WT" rev-parse HEAD)
  git branch -f "$name" "$tip"
  git worktree remove --force "$WT"
  git push origin "$name"
  echo "[branches] pushed ${name} -> $(git log --oneline -1 "$name")"
}

# ---------------------------------------------------------------- branch #3
BRANCH_MUST=(
  "tb/task_mul/README.md"
  "tb/task_mul/env/mul_scoreboard_pkg.sv"
  "tb/task_mul_env/mul_demo_pkg.sv"
  "tb/scripts/run_task_mul.sh"
  "tb/scripts/task_mul.f"
  "tb/mini/mini_dut.sv"
  "tb/sequences/mul_program_pkg.sv"
  "tb/common/alu_ref_pkg.sv"
)
build_branch "task/mul" "BRANCH_task_mul.md" \
  "task/mul: MUL task deliverable + runnable demo environment" \
  '^tb/task_mul/' \
  '^tb/task_mul_env/' \
  '^tb/README\.md$' \
  '^tb/common/alu_ref_pkg\.sv$' \
  '^tb/sequences/mul_program_pkg\.sv$' \
  '^tb/mini/mini_dut\.sv$' \
  '^tb/scripts/(task_mul\.f|run_task_mul\.sh|sync_task_mul\.sh|slang_check\.py|setup_tools\.sh|mini_group_mk\.py)$' \

# ---------------------------------------------------------------- branch #4
BRANCH_MUST=(
  "tb/interfaces/alu_mul_if.sv"
  "tb/agents/mul_agent/mul_agent_pkg.sv"
  "tb/env/alu_mul_sb_pkg.sv"
  "tb/fcov/alu_mul_cov_pkg.sv"
  "tb/sequences/mul_seq_pkg.sv"
  "tb/sim/smoke/tb_smoke.sv"
  "tb/scripts/run_smoke.sh"
  "tb/scripts/run_mini_uvm.sh"
  "tb/mini/mini_tb.sv"
)
build_branch "task/uvm" "BRANCH_uvm.md" \
  "task/uvm: integrated UVM environment (bench, smoke, mini_uvm, selftest)" \
  '^tb/(interfaces|agents|env|fcov|assertions|sequences|tests|common)/' \
  '^tb/sim/smoke/' \
  '^tb/mini/(mini_dut|mini_tb|cb_probe)\.sv$' \
  '^tb/README\.md$' \
  '^tb/scripts/(rtl\.f|tb_mul\.f|run_smoke\.sh|run_selftest\.sh|run_mini_uvm\.sh|mini_uvm\.f|mini_group_mk\.py|slang_check\.py|check_bind\.py|rv32_asm\.py|setup_tools\.sh)$' \

# ---------------------------------------------------------------- branch #5
BRANCH_MUST=(
  "tb/mini/mini_plain_tb.sv"
  "tb/mini/mini_plain_playground.sv"
  "tb/sim/mini/mini_plain.vcd"
  "tb/scripts/run_mini_plain.sh"
  "tb/scripts/mini_plain.f"
  "tb/interfaces/alu_mul_if.sv"
  "tb/sim/smoke/mul_smoke_checker.sv"
  "tb/common/alu_ref_pkg.sv"
)
build_branch "task/mini" "BRANCH_mini.md" \
  "task/mini: mini/plain task (tb/mini + wave artifacts + run_mini_plain)" \
  '^tb/mini/' \
  '^tb/sim/mini/' \
  '^tb/README\.md$' \
  '^tb/common/' \
  '^tb/sequences/mul_program_pkg\.sv$' \
  '^tb/interfaces/alu_mul_if\.sv$' \
  '^tb/sim/smoke/(mul_smoke_checker|alu_smoke_checker)\.sv$' \
  '^tb/scripts/(run_mini_plain\.sh|mini_plain\.f|vcd_to_html\.py|make_plain_bundle\.sh|slang_check\.py|setup_tools\.sh)$' \

echo
echo "[branches] DONE — created and pushed:"
git ls-remote --heads origin 'refs/heads/task/*' | awk '{print "  " $2}'
