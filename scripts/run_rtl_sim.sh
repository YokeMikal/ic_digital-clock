#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="/home/yokemikal/eda/designs/projects/Jam_Digital"
mkdir -p "$PROJ_DIR/sim/results"
cd "$PROJ_DIR/sim"

echo "=== Compiling RTL + Testbench with Icarus Verilog ==="
iverilog -g2012 -Wall -o results/jam_digital_rtl.vvp -f filelist.f ../tb/tb_jam_digital_top.v 2>&1 | tee results/compile.log

echo "=== Running RTL Simulation ==="
vvp results/jam_digital_rtl.vvp 2>&1 | tee results/rtl_sim.log

if grep -q "\[TB_ERROR\]" results/rtl_sim.log; then
    echo "FAIL: [TB_ERROR] detected in rtl_sim.log"
    exit 1
fi

if ! grep -q "\[TB_INFO\] Simulation Finished!" results/rtl_sim.log; then
    echo "FAIL: Missing completion marker in rtl_sim.log"
    exit 1
fi

echo "[RTL_SIM_PASS] All RTL checks passed cleanly."
