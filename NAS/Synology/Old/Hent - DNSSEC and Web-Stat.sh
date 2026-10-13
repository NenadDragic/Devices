#!/bin/bash
# Version:      1.0
# Date:         2026-10-07
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Hent - DNSSEC og Web-Stat: henter rapporter fra 10.0.0.214 og viser dagens DNS-sundhedstjek
# Erstatter "DNSSEC - StatusFile" og "Web-Stat".
# Kun nye og ændrede filer overføres. Begge dele hentes, selvom den ene fejler.
# Afslutter med exit 1, hvis noget fejlede, eller dagens sundhedstjek mangler.
# Køres som ElBosso (bruger ElBossos SSH-nøgle til admina@10.0.0.214).
SRV='admina@10.0.0.214:/home/admina'
RAP=/volume1/Dragic/Rap
SSH='ssh -o BatchMode=yes -o ConnectTimeout=15'   # fejl i stedet for at hænge på en prompt
TODAY="$RAP/DNS_Status/Sundhedscheck-$(date +%F).txt"

[[ -d $RAP ]] || { echo "FEJL: $RAP findes ikke"; exit 1; }

fejl=0
report=

# Hent én del. $1 = navn, $2 = kilde, $3 = mål, resten = rsync-filtre
hent() {
    local name=$1 src=$2 dst=$3 out rc files; shift 3
    report+="=== $name: hentet ==="$'\n'
    if ! mkdir -p "$dst"; then
        report+="FEJL: kan ikke oprette $dst"$'\n\n'; fejl=1; return
    fi
    # -rt: indhold og tidsstempler. Ikke -a, så filerne arver sharets rettigheder. -8: æøå vises korrekt.
    out=$(rsync -rt8 --timeout=300 -e "$SSH" --out-format='%n' "$@" "$src" "$dst/" 2>&1)
    rc=$?
    case $rc in
        0|24) files=$(grep -v '/$' <<< "$out")
              report+="${files:-(ingen nye eller ændrede filer)}"$'\n'
              (( rc == 24 )) && report+="ADVARSEL: nogle filer forsvandt under overførslen"$'\n' ;;
        *)    report+="FEJL: rsync stoppede med kode $rc"$'\n'"$out"$'\n'; fejl=1 ;;
    esac
    report+=$'\n'
}

# DNSSEC: *.txt i DNSSEC/ og DNSSEC/Old/ - som før
hent "DNSSEC" "$SRV/DNSSEC/" "$RAP/DNS_Status" \
     --include='/Old/' --include='/*.txt' --include='/Old/*.txt' --exclude='*'
# Web-Stat: *.html i reports/
hent "Web-Stat" "$SRV/Web-Stat/reports/" "$RAP/Web_Status" \
     --include='/*.html' --exclude='*'

echo "=== DNS-sundhedstjek $(date +%F) ==="
if [[ -f $TODAY ]]; then
    cat -- "$TODAY"
    # Dagens fil slettes på NAS'en igen, som i det gamle job. Når serveren har flyttet den
    # til Old/, hentes den derfra - så ligger den kun ét sted. Bliver den i stedet liggende
    # i DNSSEC/, hentes den igen i morgen og beholdes, fordi den så ikke længere er dagens.
    rm -f -- "$TODAY"
else
    echo "FEJL: ingen rapport for i dag ($TODAY)"
    fejl=1
fi
echo
printf '%s' "$report"
exit $fejl