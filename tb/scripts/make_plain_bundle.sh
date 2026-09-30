#!/usr/bin/env bash
# Regenerate tb/mini/mini_plain_playground.sv (single-file plain bench for
# EDA Playground / ModelSim). Run from the repo root.
set -e
cd "$(dirname "$0")/../.."
python3 - <<'EOF'
files = [l.strip() for l in open('tb/scripts/mini_plain.f') if l.strip()]
out = ['`timescale 1ns/1ps\n',
       '// =============================================================\n',
       '// GENERATED FILE - do not edit by hand.\n',
       '// Single-file version of the PLAIN mini bench (no UVM, no SVA,\n',
       '// no covergroups) for EDA Playground / ModelSim / any SV sim.\n',
       '// Regenerate: see tb/scripts/make_plain_bundle.sh\n',
       '// Top module: mini_plain_tb  (prints 3 instructions + mini_plain.vcd)\n',
       '// =============================================================\n']
for f in files:
    out.append(f'\n// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> {f}\n')
    out.append(open(f).read())
bundle = ''.join(out)
reps = [
  ('    verbose     = $test$plusargs("verbose");\n    verbose_alu = $test$plusargs("verbose_alu");',
   "    verbose     = 1'b1;   // per-instruction print always on\n    verbose_alu = 1'b1;"),
  ('    if ($test$plusargs("vcd")) begin',
   "    if (1'b1) begin       // always dump mini_plain.vcd"),
  ("prog_simple = 1'b0;", "prog_simple = 1'b1; // bundle: always the 3-instruction program"),
]
for a, b in reps:
    assert a in b or a in bundle, a
    bundle = bundle.replace(a, b)
open('tb/mini/mini_plain_playground.sv', 'w').write(bundle)
print("bundle written:", len(bundle.splitlines()), "lines")
EOF
