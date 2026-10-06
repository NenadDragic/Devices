#!/bin/bash
# Version:      1.0
# Date:         2026-10-06
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Copy USB - flyt alle mapper fra USB-disken til NetBackup (usbshare/<mappe>/ -> NetBackup/<mappe>/)
# 1. Kopierer alt. Fejler noget, stopper scriptet, og intet slettes.
# 2. Sletter fra USB kun de filer, der nu ligger identisk i NetBackup.
# 3. Kontrollerer, at USB er tom, og melder fejl, hvis noget er blevet tilbage.
# Køres som root (ingen sudo).
USB=/volumeUSB1/usbshare
DST=/volume1/NetBackup

# Mapper i roden af USB, der aldrig flyttes (system- og papirkurvsmapper)
SKIP=('#recycle' '@eaDir' 'System Volume Information' '$RECYCLE.BIN' 'lost+found')

# -u: overskriv aldrig en nyere fil i NetBackup - den bliver liggende på USB og meldes i trin 3
OPTS=(-a -u --exclude='@eaDir' --exclude='#recycle')

grep -qs " $USB " /proc/mounts || { echo "USB-disken er ikke monteret ($USB) - intet at gøre"; exit 0; }
[[ -d $DST ]] || { echo "FEJL: $DST findes ikke"; exit 1; }

# Find mapperne i roden af USB (skjulte mapper og SKIP-listen udelades)
shopt -s nullglob
dirs=()
for d in "$USB"/*/; do
    name=${d%/}; name=${name##*/}
    for s in "${SKIP[@]}"; do [[ $name == "$s" ]] && continue 2; done
    dirs+=("$name")
done
(( ${#dirs[@]} )) || { echo "Ingen mapper på USB - intet at flytte"; exit 0; }
echo "Mapper på USB: ${dirs[*]}"

echo
echo "=== 1. Kopierer ==="
for name in "${dirs[@]}"; do
    echo "--- $name"
    rsync "${OPTS[@]}" --stats -h "$USB/$name/" "$DST/$name/" \
        || { echo "FEJL under kopiering af $name - intet er slettet fra USB"; exit 1; }
done

echo
echo "=== 2. Sletter fra USB ==="
for name in "${dirs[@]}"; do
    # Kopierer evt. nye filer og sletter kun filer, der er bekræftet identiske i NetBackup
    rsync "${OPTS[@]}" --remove-source-files "$USB/$name/" "$DST/$name/" \
        || { echo "FEJL i slettefasen for $name"; exit 1; }
    # Tomme undermapper fjernes - selve mappen (Log, <enhed>) beholdes
    find "$USB/$name" -mindepth 1 -depth -type d -empty -delete
    echo "$name: færdig"
done

echo
echo "=== 3. Kontrol ==="
left=$(for name in "${dirs[@]}"; do
           find "$USB/$name" ! -type d ! -path '*/@eaDir/*' ! -path '*/#recycle/*'
       done)
loose=$(find "$USB" -mindepth 1 -maxdepth 1 -type f ! -name '.*')
[[ -n $loose ]] && { echo "Løse filer i roden af USB (flyttes ikke):"; echo "$loose"; echo; }
if [[ -n $left ]]; then
    echo "Disse filer ligger stadig på USB:"
    echo "$left"
    exit 1
fi
echo "Alle mapper er flyttet - de er tomme for data."
