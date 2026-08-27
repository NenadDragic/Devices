#!/bin/sh
#
# crontab_backup.sh — gemmer hver brugers crontab i sin egen fil.
#
#   Filnavn:  crontab_<brugernavn>_<YYYY-MM-DD>.txt
#   Indhold:  rå crontab, kan gendannes med:
#             crontab -u <bruger> crontab_<bruger>_<dato>.txt
#
# Ren POSIX sh — kører på BusyBox ash (router/OpenWrt), dash og bash.
# Kræver root for at kunne læse andre brugeres crontabs.
#
set -eu

OUTDIR="/root/Scripts/Crontab"
KEEP_DAYS=0          # 0 = ryd ikke op
INCLUDE_SYSTEM=0     # -s: tag også /etc/crontab og /etc/cron.d/*
DRY_RUN=0
QUIET=0
USERS=""             # mellemrumssepareret liste (ingen arrays i POSIX sh)
DATE="$(date +%Y-%m-%d)"
CRONDIR=""

usage() {
    cat <<EOF
Brug: ${0##*/} [-d katalog] [-u bruger]... [-k dage] [-s] [-n] [-q] [-h]

  -d KATALOG   Output-katalog (standard: $OUTDIR)
  -u BRUGER    Kun denne bruger (kan gentages). Standard: alle i passwd
  -k DAGE      Slet backupfiler ældre end DAGE dage i output-kataloget
  -s           Gem også system-cron (/etc/crontab + /etc/cron.d/*)
  -n           Dry-run: vis hvad der ville ske, skriv ingenting
  -q           Stille (kun fejl)
  -h           Denne hjælp
EOF
}

log()  { [ "$QUIET" = 1 ] || printf '%s\n' "$*"; }
err()  { printf '%s: FEJL: %s\n' "${0##*/}" "$*" >&2; }
warn() { printf '%s: ADVARSEL: %s\n' "${0##*/}" "$*" >&2; }

while getopts d:u:k:snqh opt; do
    case "$opt" in
        d) OUTDIR="$OPTARG" ;;
        u) USERS="$USERS $OPTARG" ;;
        k) KEEP_DAYS="$OPTARG" ;;
        s) INCLUDE_SYSTEM=1 ;;
        n) DRY_RUN=1 ;;
        q) QUIET=1 ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

case "$KEEP_DAYS" in
    ''|*[!0-9]*) err "-k skal være et helt tal"; exit 2 ;;
esac

# Cron-spool: BusyBox/OpenWrt bruger /etc/crontabs, Debian/Ubuntu /var/spool/cron/crontabs
for d in /etc/crontabs /var/spool/cron/crontabs /var/spool/cron; do
    if [ -d "$d" ]; then CRONDIR="$d"; break; fi
done

if ! command -v crontab >/dev/null 2>&1 && [ -z "$CRONDIR" ]; then
    err "hverken crontab-kommandoen eller en cron-spool blev fundet"
    exit 3
fi

# Brugerliste
if [ -z "$USERS" ]; then
    if command -v getent >/dev/null 2>&1; then
        USERS="$(getent passwd | cut -d: -f1 | sort -u)"
    else
        USERS="$(cut -d: -f1 /etc/passwd | sort -u)"
    fi
    # tag også brugere der kun findes som spool-fil (fx på OpenWrt)
    if [ -n "$CRONDIR" ]; then
        for f in "$CRONDIR"/*; do
            [ -f "$f" ] && USERS="$USERS
${f##*/}"
        done
        USERS="$(printf '%s\n' "$USERS" | sort -u)"
    fi
fi

# Uden root kan man kun læse sin egen crontab
if [ "$(id -u)" -ne 0 ]; then
    warn "kører ikke som root — begrænser til brugeren $(id -un)"
    USERS="$(id -un)"
    INCLUDE_SYSTEM=0
fi

umask 077
if [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$OUTDIR"
    chmod 700 "$OUTDIR"
fi

written=0
skipped=0

# Læs én brugers crontab: først via kommandoen, ellers direkte fra spool
read_crontab() {
    if command -v crontab >/dev/null 2>&1; then
        if crontab -l -u "$1" 2>/dev/null; then return 0; fi
    fi
    if [ -n "$CRONDIR" ] && [ -f "$CRONDIR/$1" ]; then
        cat "$CRONDIR/$1"
        return 0
    fi
    return 1
}

save() {   # save <navn> <indhold>
    # gør navnet filnavns-sikkert (fx DOMAIN\bruger)
    _name="$(printf '%s' "$1" | tr -c 'A-Za-z0-9._@-' '_')"
    _out="$OUTDIR/crontab_${_name}_${DATE}.txt"
    if [ "$DRY_RUN" = 1 ]; then
        log "[dry-run] ville skrive $_out"
    else
        printf '%s\n' "$2" > "$_out"
        chmod 600 "$_out"
        log "Skrev $_out"
    fi
    written=$((written + 1))
}

for user in $USERS; do
    if ! content="$(read_crontab "$user")"; then
        skipped=$((skipped + 1))
        continue
    fi
    # spring over crontabs der kun er tomme linjer/kommentarer
    if ! printf '%s\n' "$content" | grep -qv '^[ 	]*\(#\|$\)'; then
        skipped=$((skipped + 1))
        continue
    fi
    save "$user" "$content"
done

if [ "$INCLUDE_SYSTEM" = 1 ]; then
    sys=""
    for f in /etc/crontab /etc/cron.d/*; do
        [ -f "$f" ] || continue
        sys="$sys### $f
$(cat "$f")

"
    done
    [ -n "$sys" ] && save "system" "$sys"
fi

if [ "$KEEP_DAYS" -gt 0 ] && [ "$DRY_RUN" != 1 ]; then
    find "$OUTDIR" -maxdepth 1 -type f \
         -name 'crontab_*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].txt' \
         -mtime +"$KEEP_DAYS" -exec rm -f {} + 2>/dev/null || true
fi

if [ "$DRY_RUN" = 1 ]; then
    log "Færdig (dry-run): $written fil(er) ville blive skrevet, $skipped uden crontab."
else
    log "Færdig: $written fil(er) skrevet, $skipped bruger(e) uden crontab sprunget over."
fi