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

echo "=== Running Yosys Sky130 Synthesis Check ==="
cd "$LIBRELANE_DIR"
nix-shell --run "yosys -s $PROJ_DIR/synth/synth_yosys.ys -l $PROJ_DIR/synth/yosys_run.log"

echo "[YOSYS_PASS] Yosys synthesis completed."
