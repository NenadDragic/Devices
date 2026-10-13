#!/bin/bash
# Version:      1.2
# Date:         2026-10-07
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Copy GPS log files - henter logs fra gps_monitor med rsync
# Kun nye og ændrede filer overføres. Filer, der slettes på kilden, bliver liggende på NAS'en.
# Afslutter med exit 1 ved fejl, så DSM kan sende fejlmail.
# Køres som ElBosso (bruger ElBossos SSH-nøgle til admina@10.0.0.149).
SRC='admina@10.0.0.149:/home/admina/gps_monitor/logs'   # uden / til sidst: mappen logs lægges i DST, som før
DST=/volume1/Dragic/Rap/GPS_log

[[ -d ${DST%/*} ]] || { echo "FEJL: ${DST%/*} findes ikke"; exit 1; }
mkdir -p "$DST" || { echo "FEJL: kan ikke oprette $DST"; exit 1; }

# -rt: indhold og tidsstempler. Ikke -a, så filerne arver sharets rettigheder i stedet for serverens.
# BatchMode: fejl i stedet for at hænge på en password- eller host key-prompt.
out=$(rsync -8 -rt --timeout=300 \
            -e 'ssh -o BatchMode=yes -o ConnectTimeout=15' \
            --out-format='%n' \
            "$SRC" "$DST/" 2>&1)
rc=$?

echo "=== Hentet ==="
files=$(grep -v '/$' <<< "$out")
if [[ -n $files ]]; then echo "$files"; else echo "(ingen nye eller ændrede filer)"; fi
echo

case $rc in
    0)  ;;
    24) echo "ADVARSEL: nogle filer forsvandt under overførslen (fx logrotation) - resten er hentet"; echo ;;
    *)  echo "FEJL: rsync stoppede med kode $rc"; exit 1 ;;
esac

echo "=== $DST/logs/csv ==="
ls -alh "$DST/logs/csv/"