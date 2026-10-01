# =====================================================================
# run_standalone.do - Non-UVM Pure SystemVerilog Simulation in ModelSim
# =====================================================================

if {[file exists work]} {vdel -lib work -all}
vlib work

# 1. Compile Packages
vlog -sv ../rtl/package/cv32e40p_apu_core_pkg.sv \
         ../rtl/package/cv32e40p_fpu_pkg.sv \
         ../rtl/package/cv32e40p_pkg.sv

# 2. Compile Core RTL Files (excluding latch register file)
set RTL_FILES {}
foreach f [lsort [glob ../rtl/*.sv]] {
    if {![string match *register_file_latch* $f]} {
        lappend RTL_FILES $f
    }
}
eval vlog -sv $RTL_FILES

# 3. Compile Standalone Testbench
vlog -sv mul_standalone_tb.sv

# 4. Run Simulation
# To run basic test: vsim -c work.mul_standalone_tb +TESTNAME=mul_basic_test
# To run all ops test: vsim -c work.mul_standalone_tb +TESTNAME=mul_all_ops_test
vsim -c work.mul_standalone_tb +TESTNAME=mul_all_ops_test
run -all
quit -f
