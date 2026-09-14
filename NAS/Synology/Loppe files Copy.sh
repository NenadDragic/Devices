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
# Date:         2026-03-26
# Test Run:     2026-03-29
# Developper:   Nenad(a)dragic(.)com
scp -r admina@10.0.0.215:/home/admina/Loppe/ /volume1/Dragic/Rap

ls -al /volume1/Dragic/Rap/Loppe
