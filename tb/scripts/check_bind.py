#!/usr/bin/env python3
"""Verify that every signal used in a bind file's port connections exists in
the target scope of the elaborated design (implicit nets would otherwise hide
typos, because port connections may create nets silently).

Usage: python3 tb/scripts/check_bind.py <bind_file.sv> <scope_path> <slang args...>
Example:
  python3 tb/scripts/check_bind.py tb/interfaces/alu_mul_bind.sv cv32e40p_top.core_i \
      -f tb/scripts/rtl.f tb/interfaces/alu_mul_if.sv tb/interfaces/alu_mul_bind.sv \
      --top cv32e40p_top -DALU_MUL_NO_UVM
"""
import re
import sys
import pyslang


def main(argv):
    bind_file, scope = argv[0], argv[1]
    drv = pyslang.driver.Driver()
    drv.addStandardArgs()
    if not drv.parseCommandLine("slang " + " ".join(argv[2:])):
        return 2
    drv.processOptions()
    drv.parseAllSources()
    comp = drv.createCompilation()
    drv.reportCompilation(comp, True)
    root = comp.getRoot()

    text = open(bind_file).read()
    text = re.sub(r"//.*", "", text)
    names = set()
    for m in re.finditer(r"\.\s*\w+\s*\(\s*([A-Za-z_][\w\.]*)\s*\)", text):
        names.add(m.group(1))
    bad = []
    for n in sorted(names):
        if n in ("clk_i", "rst_ni"):
            continue
        sym = root.lookupName(scope + "." + n)
        if sym is None:
            bad.append(n)
        else:
            print(f"  ok   {scope}.{n:<28} -> {sym.kind}")
    if bad:
        for n in bad:
            print(f"  MISSING {scope}.{n}")
        print(f"check_bind: {len(bad)} unresolved name(s)")
        return 1
    print(f"check_bind: all {len(names)} connections resolve in {scope}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
