#!/bin/bash
# Version:      1.0
# Date:         2026-10-07
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Hent - Loppe: henter Loppe-filerne fra 10.0.0.215 og viser status.txt
# Erstatter "Loppe files Copy" og "Loppe Status".
# Kun nye og ændrede filer overføres. Filer, der slettes på serveren, bliver liggende på NAS'en.
# Afslutter med exit 1 ved fejl, så DSM kan sende fejlmail.
# Køres som ElBosso (bruger ElBossos SSH-nøgle til admina@10.0.0.215).
SRC='admina@10.0.0.215:/home/admina/Loppe'   # uden / til sidst: mappen Loppe lægges i DST, som før
DST=/volume1/Dragic/Rap
STATUS=$DST/Loppe/status.txt
SSH='ssh -o BatchMode=yes -o ConnectTimeout=15'   # fejl i stedet for at hænge på en prompt

[[ -d $DST ]] || { echo "FEJL: $DST findes ikke"; exit 1; }

# -rt: indhold og tidsstempler. Ikke -a, så filerne arver sharets rettigheder. -8: æøå vises korrekt i mailen.
out=$(rsync -rt8 --timeout=300 -e "$SSH" --out-format='%n' "$SRC" "$DST/" 2>&1)
rc=$?
case $rc in
    0|24) ;;
    *)    echo "FEJL: rsync stoppede med kode $rc"; echo "$out"; exit 1 ;;
esac

echo "=== Status ==="
if [[ -f $STATUS ]]; then
    cat -- "$STATUS"
else
    echo "FEJL: $STATUS findes ikke"; exit 1
fi
echo

echo "=== Hentet ==="
files=$(grep -v '/$' <<< "$out")
if [[ -n $files ]]; then echo "$files"; else echo "(ingen nye eller ændrede filer)"; fi
(( rc == 24 )) && echo "ADVARSEL: nogle filer forsvandt under overførslen - resten er hentet"
exit 0