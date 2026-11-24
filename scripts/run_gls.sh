#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="/home/yokemikal/eda/designs/projects/Jam_Digital"
SKY130_VERILOG="/home/yokemikal/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A/libs.ref/sky130_fd_sc_hd/verilog"
NETLIST="$PROJ_DIR/pnr/runs/jam_digital_sky130/final/nl/jam_digital_top.nl.v"

mkdir -p "$PROJ_DIR/sim/results"
cd "$PROJ_DIR/sim"

echo "=== Compiling Post-P&R Sky130 Gate-Level Netlist + GLS Testbench ==="
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY="#1" \
    -o results/jam_digital_gls.vvp \
    "$SKY130_VERILOG/primitives.v" \
    "$SKY130_VERILOG/sky130_fd_sc_hd.v" \
    "$NETLIST" \
    "$PROJ_DIR/tb/tb_jam_digital_gls.v" 2>&1 | tee results/gls_compile.log

echo "=== Running Post-P&R Gate-Level Simulation ==="
vvp results/jam_digital_gls.vvp 2>&1 | tee results/gls_sim.log

if grep -q "\[TB_ERROR\]" results/gls_sim.log; then
    echo "FAIL: [TB_ERROR] detected in gls_sim.log"
    exit 1
fi

if ! grep -q "\[TB_INFO\] Simulation Finished!" results/gls_sim.log; then
    echo "FAIL: Missing completion marker in gls_sim.log"
    exit 1
fi

echo "[GLS_PASS] Post-P&R Sky130 Gate-Level Simulation passed cleanly."
