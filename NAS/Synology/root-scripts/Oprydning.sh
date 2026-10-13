#!/bin/bash
# Version:      1.3
# Date:         2026-10-13
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Oprydning i Dragic - én gennemsøgning af sharet pr. kørsel
# Samme fil til begge DSM-opgaver - MODE sættes i opgaven:
#   Oprydning - Find:    MODE=find  bash /volume1/root-scripts/Oprydning.sh
#   Oprydning - Delete:  MODE=clean bash /volume1/root-scripts/Oprydning.sh
#
#   MODE=find   viser fund og diskforbrug pr. mappe, ændrer intet (standard)
#   MODE=clean  sletter junk-filer og retter dobbelte mellemrum
# Uden MODE køres find, så en glemt MODE aldrig sletter noget.
MODE=${MODE:-find}
ROOT=/volume1/Dragic
MIN_AGE_MIN=1440   # clean rører kun filer, der ikke er ændret de sidste 24 timer
SIZE_SKIP=Log      # diskforbrug: mapper/filer med dette navn tælles ikke med (som i det gamle du-job)

case $MODE in find|clean) ;; *) echo "FEJL: ukendt MODE '$MODE'"; exit 1 ;; esac
[[ -d $ROOT ]] || { echo "FEJL: $ROOT findes ikke"; exit 1; }
echo "MODE=$MODE  ROOT=$ROOT"
echo

T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT

age=()
[[ $MODE == clean ]] && age=(-mmin +"$MIN_AGE_MIN")

# Diskforbrug beregnes kun i find-mode - i samme gennemsøgning (erstatter "Disk Used size - Dragic")
size=()
# shellcheck disable=SC2054  # kommaet er finds komma-operator, ikke en array-separator
[[ $MODE == find ]] && size=(, \( -printf '%b\t%P\n' \))

# Lægger diskforbruget sammen pr. mappe i roden af ROOT. %b = 512-byte blokke, som du bruger.
sum_sizes() {
    awk -F'\t' -v skip="$SIZE_SKIP" '
        function h(b,  u, i) { split("B KB MB GB TB", u, " "); i = 1
                               while (b >= 1024 && i < 5) { b /= 1024; i++ }
                               return sprintf(i == 1 ? "%d %s" : "%.1f %s", b, u[i]) }
        $2 == "" { next }
        { n = split($2, p, "/"); for (i = 1; i <= n; i++) if (p[i] == skip) next
          s[p[1]] += $1 * 512; tot += $1 * 512 }
        END { for (k in s) printf "%10s  %s\n", h(s[k]), k | "sort -f -k3"
              close("sort -f -k3"); printf "%10s  %s\n", h(tot), "I alt" }'
}

# Én gennemsøgning (uden om #recycle og @eaDir) - hvert fund skrives til sin egen liste
find "$ROOT" \( -path "$ROOT/#recycle" -o -name '@eaDir' \) -prune -o \( \
      \( -type f -iname '*.bak'      "${age[@]}" -fprint0 "$T/bak"     \) , \
      \( -type f -iname '*.tmp'      "${age[@]}" -fprint0 "$T/tmp"     \) , \
      \( -type f -iname 'Thumbs.db'  "${age[@]}" -fprint0 "$T/thumbs"  \) , \
      \( -type f -name  '~*.*'       "${age[@]}" -fprint0 "$T/tilde"   \) , \
      \( -type f -name  '*CORRUPT*.*'            -fprint0 "$T/corrupt" \) , \
      \( -type f -name  '*INVALID*.*'            -fprint0 "$T/invalid" \) , \
      \(         -name  '*  *'                   -fprint0 "$T/spaces"  \) \
      "${size[@]}" \) | sum_sizes > "$T/sizes"

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
    echo "== Diskforbrug pr. mappe (uden #recycle, @eaDir og $SIZE_SKIP) =="
    cat "$T/sizes"
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
