#!/bin/bash
# Version:      1.0
# Date:         2026-10-06
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# DashCam - ugentlig oprydning og rapport (erstatter 6 jobs)
# 1. Sletter optagelser ældre end KEEP_DAYS
# 2. Viser antal filer og størrelse pr. mappe + total
# 3. Viser routerens rapporter fra de sidste REPORT_DAYS dage
# Køres som brugeren DashCam.
ROOT=/volume1/DashCam
KEEP_DAYS=30                                      # slet filer ældre end dette
REPORT_DAYS=7                                     # jobbet kører ugentligt -> vis en uges rapporter
FOLDERS=(Photo Movie Movie/RO Movie/Parking)      # mapper der tælles
REPORTS=(File-Count-DashCam File-Delete File-Count-SD)
PROTECT=()                                        # mapper der aldrig slettes i, fx (Movie/RO)

[[ -d $ROOT ]] || { echo "FEJL: $ROOT findes ikke"; exit 1; }

human() { awk -v b="$1" 'BEGIN { split("B KB MB GB TB", u); i = 1
          while (b >= 1024 && i < 5) { b /= 1024; i++ }
          printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i] }'; }

# --- 1. Slet gamle filer -----------------------------------------------------
prune=(-path "$ROOT/#recycle")
for p in "${PROTECT[@]}"; do prune+=(-o -path "$ROOT/$p"); done

read -r n bytes < <(
    find "$ROOT" \( "${prune[@]}" \) -prune -o \
         -type f -mmin +$((KEEP_DAYS * 1440)) -exec rm -- {} \; -printf '%s\n' |
    awk '{ n++; s += $1 } END { print n + 0, s + 0 }'
)
echo "=== Slettet (ældre end $KEEP_DAYS dage) ==="
echo "$n filer, $(human "$bytes")"
(( ${#PROTECT[@]} )) && echo "Beskyttet: ${PROTECT[*]}"
echo

# --- 2. Filer og størrelse pr. mappe ----------------------------------------
echo "=== Indhold ==="
printf '%-15s %7s %10s\n' "Mappe" "Filer" "Størrelse"
for f in "${FOLDERS[@]}"; do
    if [[ -d $ROOT/$f ]]; then
        cnt=$(find "$ROOT/$f" -maxdepth 1 -type f | wc -l)
        size=$(du -shS "$ROOT/$f" | cut -f1)        # -S: kun mappens egne filer
        printf '%-15s %7s %10s\n' "$f" "$cnt" "$size"
    else
        printf '%-15s %7s\n' "$f" "mangler"
    fi
done
echo "Hele DashCam: $(du -sh --exclude='#recycle' --exclude='@eaDir' "$ROOT" | cut -f1)"
echo

# --- 3. Router-rapporter -----------------------------------------------------
for r in "${REPORTS[@]}"; do
    echo "=== $r (sidste $REPORT_DAYS dage) ==="
    mapfile -d '' files < <(find "$ROOT/$r" -maxdepth 1 -type f -mtime -"$REPORT_DAYS" -print0 2>/dev/null | sort -z)
    if (( ${#files[@]} == 0 )); then
        echo "ADVARSEL: ingen rapporter fra routeren"
    else
        for file in "${files[@]}"; do
            echo "--- ${file##*/}"
            cat -- "$file"
        done
    fi
    echo
done
