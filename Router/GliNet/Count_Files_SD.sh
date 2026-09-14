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
require_tools "uptime:procps" "ip:iproute2"

files_count=0

echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
echo ""
echo "Uptime: $(uptime)"
echo ""

files_count=$(ls -l /mnt/sda1/DCIM/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie/RO | wc -l)
echo "Movie RO: $files_count" 

files_count=$(ls -l /mnt/sda1/DCIM/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"

echo ""
echo "Disk Info:"
echo $(df -h)
echo ""
echo "WWAN0:"
echo $(ip address show wwan0 | grep 'inet')
echo ""
echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
