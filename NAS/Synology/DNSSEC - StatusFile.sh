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
# Version:      1.0
# Date:         2026-08-24
# Test Run:     2026-04-24
# Developper:   Nenad(a)dragic(.)com

scp -r admina@10.0.0.214:/home/admina/DNSSEC/*.txt /volume1/Dragic/Rap/DNS_Status

scp -r admina@10.0.0.214:/home/admina/DNSSEC/Old/*.txt /volume1/Dragic/Rap/DNS_Status/Old

more  "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"

rm "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"