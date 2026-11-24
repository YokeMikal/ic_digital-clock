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
GDS_FILE="$PROJ_DIR/pnr/runs/jam_digital_sky130/final/gds/jam_digital_top.gds"
LYT_FILE="/home/yokemikal/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A/libs.tech/klayout/tech/sky130A.lyt"
LYR_FILE="/home/yokemikal/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130A/libs.tech/klayout/tech/sky130A.lyp"

if [ ! -f "$GDS_FILE" ]; then
    echo "GDS file not found: $GDS_FILE"
    exit 1
fi

echo "Opening KLayout on $GDS_FILE ..."
cd "$LIBRELANE_DIR"
nix-shell --run "klayout -l $LYR_FILE $GDS_FILE"
