#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="/home/yokemikal/eda/designs/projects/Jam_Digital"
mkdir -p "$PROJ_DIR/sim/results"
cd "$PROJ_DIR/tb"

echo "=== Running cocotb 2.1.0 Verification Suite ==="
source /home/yokemikal/eda/venvs/ic-env/bin/activate
PYTHONPATH="$PROJ_DIR/tb:${PYTHONPATH:-}" python3 "$PROJ_DIR/tb/test_jam_digital_cocotb.py" 2>&1 | tee "$PROJ_DIR/sim/results/cocotb.log"

echo "[COCOTB_PASS] cocotb suite completed."
