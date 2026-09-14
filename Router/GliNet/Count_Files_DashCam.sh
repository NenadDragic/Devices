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
require_tools wget

echo '************************************'
echo '** DashCam kort ** DashCam kort **'
echo '************************************'

echo ""
count=$(wget -qO- http://192.168.1.254/DCIM/Photo | grep -o 'JPG' | wc -l)
result=$((count / 2))
echo Photos: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie/RO | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie RO: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie/Parking | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie Parking: $result
echo ""
echo '************************************'
echo '** DashCam kort ** DashCam kort **'
echo '************************************'
