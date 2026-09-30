#!/usr/bin/env python3
"""mini_group_mk.py — split Verilator's aggregated UVM classes TU.

Verilator emits ONE aggregator file (V<top>_vm_classes_0.cpp) that
#includes every generated class .cpp.  Compiling that single translation
unit with a full UVM testbench exhausts RAM (>3 GB at -O0).  This script
rewrites V<top>_classes.mk so each ~100-file group compiles as its own
object: same symbols, ~10x less memory, parallel-safe.

Usage:  python3 mini_group_mk.py <obj_dir> [--group-size N]
Exit 0 on success; prints a one-line summary.
"""
import re
import sys
import os


def includes_of(path):
    with open(path) as fh:
        return re.findall(r'#include "([^"]+)"', fh.read())


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    objdir = sys.argv[1]
    group_size = 100
    if "--group-size" in sys.argv:
        group_size = int(sys.argv[sys.argv.index("--group-size") + 1])

    fast_agg = os.path.join(objdir, "V*_vm_classes_0.cpp")  # glob below
    import glob
    fast = glob.glob(fast_agg)
    if not fast:
        print("mini_group_mk: no V*_vm_classes_0.cpp found in " + objdir,
              file=sys.stderr)
        return 1
    fast = fast[0]
    prefix = os.path.basename(fast).split("_vm_classes_0")[0]  # e.g. Vmini_tb
    slow = os.path.join(objdir, prefix + "_vm_classes_Slow_0.cpp")
    mkpath = os.path.join(objdir, prefix + "_classes.mk")

    fast_files = includes_of(fast)
    slow_files = includes_of(slow)
    # the aggregators must not be members of their own include list
    assert os.path.basename(fast) not in fast_files
    assert os.path.basename(slow) not in slow_files

    def write_groups(files, tag):
        names = []
        for gi in range(0, len(files), group_size):
            name = f"{prefix}__grp{tag}{gi // group_size}"
            with open(os.path.join(objdir, name + ".cpp"), "w") as fh:
                fh.write("// Verilated -*- C++ -*-\n")
                for f in files[gi:gi + group_size]:
                    fh.write(f'#include "{f}"\n')
            names.append(name)
        return names

    groups_fast = write_groups(fast_files, "F")
    groups_slow = write_groups(slow_files, "S")

    with open(mkpath) as fh:
        mk = fh.read()

    def replace(mkey, names):
        nonlocal mk
        pat = re.compile(rf"({mkey} \+= \\\n)(?:  \S+ \\\n)+")
        body = "".join(f"  {n} \\\n" for n in names)
        mk, n = pat.subn(r"\g<1>" + body, mk, count=1)
        if n != 1:
            raise SystemExit(f"mini_group_mk: pattern for {mkey} not found")

    replace("VM_CLASSES_FAST", groups_fast)
    replace("VM_CLASSES_SLOW", groups_slow)
    with open(mkpath, "w") as fh:
        fh.write(mk)

    # sanity: every design .cpp covered exactly once (by a group or by the
    # support lists that classes.mk already had)
    import collections
    import glob as g2
    covered = collections.Counter()
    for f in g2.glob(os.path.join(objdir, prefix + "__grp*.cpp")):
        for inc in includes_of(f):
            covered[inc] += 1
    dups = [k for k, v in covered.items() if v > 1]
    supports = set()
    for block in re.findall(
            r"VM_SUPPORT_(?:FAST|SLOW) \+= \\\n((?:  \S+ \\\n)+)", mk):
        for name in re.findall(r"  (\S+) \\\n", block):
            supports.add(name + ".cpp")
    allcpp = {os.path.basename(p)
              for p in g2.glob(os.path.join(objdir, "*.cpp"))
              if "__grp" not in os.path.basename(p)}
    allcpp -= {os.path.basename(fast), os.path.basename(slow)}
    missing = allcpp - set(covered) - supports
    if dups or missing:
        raise SystemExit(
            f"mini_group_mk: coverage broken dups={dups[:3]} missing={missing[:5]}")

    print(f"mini_group_mk: {len(fast_files)} fast + {len(slow_files)} slow "
          f"files -> {len(groups_fast)} + {len(groups_slow)} groups "
          f"(size<={group_size})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
