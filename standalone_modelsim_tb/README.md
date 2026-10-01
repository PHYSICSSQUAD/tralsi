# Standalone Pure SystemVerilog Testbench for CV32E40P Multiplier

This folder provides a clean, **Non-UVM** SystemVerilog testbench (`mul_standalone_tb.sv`) that implements the **exact same logic** as the UVM verification environment:

1. **Stimulus Generation**: Hand-written instruction programs for `mul_basic_test` and `mul_all_ops_test` (MUL, MULH, MULHSU, MULHU, signed/unsigned extremes, corner cases, and back-to-back forwarding).
2. **OBI Memory**: 4 KB instruction and data memory model.
3. **Reference Model**: 64-bit independent mathematical golden model for all 4 multiply instructions.
4. **Scoreboard**: Automatic comparison of actual result vs reference model, write-enable (`wb_we`), and destination register address (`wb_waddr`).
5. **Hand-computed Checker**: Cross-checks results against independent pre-computed golden values.

---

## How to Run in ModelSim / QuestaSim

Open your terminal or ModelSim console, navigate into this directory, and run:

```bash
cd standalone_modelsim_tb
vsim -c -do run_standalone.do
```

Or run interactively inside ModelSim GUI:
```tcl
cd <path_to_repo>/standalone_modelsim_tb
do run_standalone.do
```
