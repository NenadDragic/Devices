#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools "scp:openssh-client"
# Version:      1.1
# Date:         2026-04-10
# Test Run:     2026-04-10
# Developper:   Nenad(a)dragic(.)com

scp -r admina@10.0.0.149:/home/admina/gps_monitor/logs/ /volume1/Dragic/Rap/GPS_log

ls -alh /volume1/Dragic/Rap/GPS_log/logs/csv/