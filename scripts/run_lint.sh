#!/usr/bin/env bash
set -euo pipefail

export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    set +u
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    set -u
fi

PROJ_DIR="/home/yokemikal/eda/designs/projects/Jam_Digital"
LIBRELANE_DIR="/home/yokemikal/eda/tools/librelane"

echo "=== Running Verilator Lint (-Wall) on Jam_Digital RTL ==="
cd "$LIBRELANE_DIR"
nix-shell --run "verilator --lint-only -Wall --top-module jam_digital_top $PROJ_DIR/rtl/clock_divider.v $PROJ_DIR/rtl/edge_pulse_sync.v $PROJ_DIR/rtl/bcd_mod60_counter.v $PROJ_DIR/rtl/bcd_mod12_counter.v $PROJ_DIR/rtl/bcd_to_7seg.v $PROJ_DIR/rtl/seven_seg_mux6.v $PROJ_DIR/rtl/jam_digital_top.v"

echo "[LINT_PASS] Verilator --lint-only -Wall passed with 0 errors and 0 warnings."
