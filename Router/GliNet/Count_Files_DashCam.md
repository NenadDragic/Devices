# DashCam File Count - Count_Files_DashCam.sh

This script queries the DashCam device's web file listing directly (over HTTP) and prints a count of photos and videos in each folder.

## How it works

Before anything else, the script sources the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `wget`. It also stops if `lib/require_tools.sh` itself is not found.

1. Fetches the HTML directory listing at `http://192.168.1.254/DCIM/Photo` via `wget`, counts the occurrences of `JPG`, and divides by 2 (each file typically appears twice in the listing — as a link and as text) to get the photo count.
2. Repeats the same approach for `Movie`, `Movie/RO`, and `Movie/Parking`, counting `MP4` occurrences.
3. Prints each count with a header/footer banner.

## Usage

Run this script to get a quick photo/video count directly from the DashCam's web interface, without mounting the SD card.

```shell
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
```
