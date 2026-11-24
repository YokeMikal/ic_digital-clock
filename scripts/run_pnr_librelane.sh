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

echo "=== Running LibreLane v3.0.17 RTL-to-GDSII (Sky130A) ==="
cd "$LIBRELANE_DIR"
nix-shell --run "librelane --run-tag jam_digital_sky130 --overwrite $PROJ_DIR/pnr/config.json"

echo "[PNR_DONE] LibreLane RTL-to-GDSII completed."
