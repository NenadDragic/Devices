#!/bin/bash
# Version:      1.0
# Date:         2026-10-06
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Oprydning i Dragic - én gennemsøgning af sharet pr. kørsel
# Samme script i begge jobs - kun MODE er forskellig:
#   MODE=find   viser fund, ændrer intet
#   MODE=clean  sletter junk-filer og retter dobbelte mellemrum
MODE=find
ROOT=/volume1/Dragic
MIN_AGE_MIN=1440   # clean rører kun filer, der ikke er ændret de sidste 24 timer

case $MODE in find|clean) ;; *) echo "FEJL: ukendt MODE '$MODE'"; exit 1 ;; esac
[[ -d $ROOT ]] || { echo "FEJL: $ROOT findes ikke"; exit 1; }

T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT

age=()
[[ $MODE == clean ]] && age=(-mmin +"$MIN_AGE_MIN")

# Én gennemsøgning (uden om #recycle og @eaDir) - hvert fund skrives til sin egen liste
find "$ROOT" \( -path "$ROOT/#recycle" -o -name '@eaDir' \) -prune -o \( \
      \( -type f -iname '*.bak'      "${age[@]}" -fprint0 "$T/bak"     \) , \
      \( -type f -iname '*.tmp'      "${age[@]}" -fprint0 "$T/tmp"     \) , \
      \( -type f -iname 'Thumbs.db'  "${age[@]}" -fprint0 "$T/thumbs"  \) , \
      \( -type f -name  '~*.*'       "${age[@]}" -fprint0 "$T/tilde"   \) , \
      \( -type f -name  '*CORRUPT*.*'            -fprint0 "$T/corrupt" \) , \
      \( -type f -name  '*INVALID*.*'            -fprint0 "$T/invalid" \) , \
      \(         -name  '*  *'                   -fprint0 "$T/spaces"  \) \)

# Vis en liste. $1 = liste, $2 = overskrift
show() {
    local L; mapfile -d '' L < "$T/$1"
    echo "== $2: ${#L[@]} =="
    (( ${#L[@]} )) && printf '%s\n' "${L[@]}"
    echo
}

# Slet filerne i en liste. $1 = liste, $2 = overskrift
delete() {
    local L p n=0 out=
    mapfile -d '' L < "$T/$1"
    for p in "${L[@]}"; do
        [[ -e $p ]] || continue      # kan være slettet via en anden liste (fx ~WRL1.tmp)
        rm -- "$p" && out+="$p"$'\n' && ((++n))
    done
    echo "== $2: $n slettet =="
    printf '%s' "$out"
    echo
}

if [[ $MODE == find ]]; then
    show bak     ".bak-filer"
    show tmp     ".tmp-filer"
    show thumbs  "Thumbs.db"
    show tilde   "~-filer"
    show corrupt "CORRUPT (kun rapport)"
    show invalid "INVALID (kun rapport)"
    show spaces  "Dobbelte mellemrum"
    exit 0
fi

delete bak    ".bak-filer"
delete tmp    ".tmp-filer"
delete thumbs "Thumbs.db"
delete tilde  "~-filer"

# Dobbelte mellemrum: baglæns, så indhold omdøbes før mappen selv
mapfile -d '' L < "$T/spaces"
echo "== Dobbelte mellemrum =="
for (( i=${#L[@]}-1; i>=0; i-- )); do
    p=${L[i]}
    [[ -e $p ]] || continue          # slettet ovenfor
    new="${p%/*}/$(tr -s ' ' <<< "${p##*/}")"
    if [[ -e $new ]]; then
        echo "SPRUNGET OVER, findes allerede: $new"
    else
        mv -n -- "$p" "$new" && echo "$p  ->  ${new##*/}"
    fi
done
