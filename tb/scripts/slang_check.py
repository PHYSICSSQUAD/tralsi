#!/usr/bin/env python3
"""Thin wrapper around pyslang's Driver that behaves like the `slang` CLI.

Usage:   python3 tb/scripts/slang_check.py <slang args ...>
Example: python3 tb/scripts/slang_check.py -f tb/scripts/rtl.f --top cv32e40p_top

Runs parse + elaboration (+ analysis) and prints the diagnostics.
Exit code 0 when the compilation has no errors, 1 otherwise.
"""
import sys
import pyslang


def main(argv):
    drv = pyslang.driver.Driver()
    drv.addStandardArgs()
    if not drv.parseCommandLine("slang " + " ".join(argv)):
        return 2
    if not drv.processOptions():
        return 2
    ok = drv.parseAllSources()
    comp = drv.createCompilation()
    drv.reportCompilation(comp, False)
    try:
        drv.runAnalysis(comp)
    except Exception:  # analysis is optional (older pyslang builds)
        pass
    ok = drv.reportDiagnostics(False) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
