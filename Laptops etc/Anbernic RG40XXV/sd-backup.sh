#!/usr/bin/env bash
# sd-backup.sh – tager et komplet, komprimeret image af et SD-kort (alle partitioner).
#
# Brug:  sudo ./sd-backup.sh /dev/sdX [mål-mappe] [navn]
#
#   /dev/sdX    hele kortet – ikke en partition (/dev/sdb, ikke /dev/sdb6)
#   mål-mappe   standard: ~/sd-backups (hjemmemappen for brugeren, der kører sudo)
#   navn        standard: sd  ->  filerne hedder <navn>-ÅÅÅÅ-MM-DD_TTMM.*
#
# Laver tre filer:
#   <base>.img.zst          komprimeret image af hele kortet (zstd)
#   <base>.img.zst.sha256   checksum af .zst-filen (kan tjekkes med sha256sum -c)
#   <base>.info             metadata: størrelse, sha256 af rå data, partitionstabel
#
# Kortet bliver kun læst. Dets partitioner afmonteres før læsning.
# Tjek bagefter med:  ./sd-validate.sh <base>.img.zst [/dev/sdX]

# Version:      1.0
# Date:         2026-10-25
# Test Run:
# Developper:   Nenad(a)dragic(.)com

set -Eeuo pipefail

die()     { printf '\e[31mFEJL:\e[0m %s\n' "$*" >&2; exit 1; }
info()    { printf '\e[36m==>\e[0m %s\n' "$*"; }
ok()      { printf '\e[32mOK:\e[0m %s\n' "$*"; }
warn()    { printf '\e[33mADVARSEL:\e[0m %s\n' "$*" >&2; }
usage()   { sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit "${1:-0}"; }
confirm() { local a; read -r -p "$1 [j/N] " a </dev/tty || return 1; [[ $a == [jJyY] ]]; }
human()   { numfmt --to=iec --suffix=B "$1"; }
elapsed() { local s=$(( SECONDS - START )); printf "%d:%02d min" $(( s / 60 )) $(( s % 60 )); }

declare -A PKG=([zstd]=zstd [sfdisk]=fdisk [cmp]=diffutils)
need_cmds() {
    local c
    for c; do
        command -v "$c" >/dev/null || die "Mangler '$c'. Installer med: sudo apt install ${PKG[$c]:-$c}"
    done
}

# Diske som bærer /, /boot, /boot/efi, /home, /usr, /var eller swap. Returnerer altid 0.
system_disks() {
    local mp src
    {
        for mp in / /boot /boot/efi /home /usr /var; do
            src=$(findmnt -nro SOURCE --target "$mp" 2>/dev/null) || continue
            src=${src%%\[*}                        # btrfs: /dev/x[/@] -> /dev/x
            if [[ -b $src ]]; then lsblk -nrpso NAME,TYPE "$src" 2>/dev/null || true; fi
        done
        while read -r src; do
            if [[ -b $src ]]; then lsblk -nrpso NAME,TYPE "$src" 2>/dev/null || true; fi
        done < <(swapon --show=NAME --noheadings 2>/dev/null || true)
    } | awk '$2=="disk"{print $1}' | sort -u
    return 0
}

# Sikkerhedstjek af målenheden: hel disk og ikke systemdisken.
check_disk() {
    local dev=$1 sys
    [[ -b $dev ]] || die "$dev findes ikke eller er ikke en blokenhed."
    [[ $(lsblk -dno TYPE "$dev") == disk ]] || die "$dev er ikke en hel disk. Brug fx /dev/sdb – ikke /dev/sdb1."
    sys=$(system_disks)
    if [[ -z $sys ]]; then
        warn "Kunne ikke finde ud af, hvilken disk systemet kører fra."
        confirm "Er du HELT sikker på, at $dev er SD-kortet?" || exit 1
    elif grep -qxF -- "$dev" <<<"$sys"; then
        die "$dev er en systemdisk (bruges af /, /boot, swap el.lign.). Afbryder."
    fi
}

show_disk() { lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,MODEL,TRAN "$1"; echo; }

list_disks() {
    echo "Tilgængelige diske:"
    lsblk -dpo NAME,SIZE,MODEL,TRAN,RM -e7
}

unmount_all() {
    local part
    while read -r part; do
        while findmnt -rn --source "$part" >/dev/null 2>&1; do
            info "Afmonterer $part"
            umount "$part" || die "Kunne ikke afmontere $part. Er den i brug (står du fx i mappen)?"
        done
    done < <(lsblk -nrpo NAME "$1")
}

# ---------------------------------------------------------------------------

[[ ${1:-} == -h || ${1:-} == --help ]] && usage
[[ $# -ge 1 && $# -le 3 ]] || { usage 1 >&2; }
(( EUID == 0 )) || { list_disks; echo; die "Skal køres med sudo."; }
need_cmds dd zstd sha256sum lsblk findmnt blockdev sfdisk mkfifo numfmt tee

DEV=$(readlink -f -- "$1")
check_disk "$DEV"

USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
DEST=${2:-$USER_HOME/sd-backups}
NAME=${3:-sd}
[[ $NAME =~ ^[A-Za-z0-9._-]+$ ]] || die "Navnet må kun indeholde A-Z a-z 0-9 . _ -"

CREATED_DEST=
if [[ ! -d $DEST ]]; then mkdir -p -- "$DEST"; CREATED_DEST=1; fi
DEST=$(readlink -f -- "$DEST")

BASE="$DEST/$NAME-$(date +%F_%H%M)"
IMG="$BASE.img.zst"
SUM="$IMG.sha256"
INFO="$BASE.info"
[[ -e $IMG || -e $INFO ]] && die "$BASE.* findes allerede."

SIZE=$(blockdev --getsize64 "$DEV")
AVAIL=$(df --output=avail -B1 -- "$DEST" | tail -n 1)

show_disk "$DEV"
info "Kort: $DEV, $(human "$SIZE")"
info "Mål:  $IMG ($(human "$AVAIL") ledig)"
if (( AVAIL < SIZE )); then
    warn "Der er mindre ledig plads end kortets størrelse. Komprimering hjælper som regel, men det er ikke garanteret."
    confirm "Fortsæt alligevel?" || exit 1
fi
confirm "Tag backup af $DEV?" || exit 1

unmount_all "$DEV"

WORK=$(mktemp -d)
FIFO="$WORK/raw.fifo"
mkfifo "$FIFO"
SUMPID=
DONE=
cleanup() {
    [[ -n $SUMPID ]] && kill "$SUMPID" 2>/dev/null || true
    rm -rf -- "$WORK"
    [[ -n $DONE ]] || rm -f -- "$IMG.partial"
}
trap cleanup EXIT

# sha256 af de rå data beregnes samtidig med læsningen (ingen ekstra læsning af kortet).
sha256sum <"$FIFO" | cut -d' ' -f1 >"$WORK/raw.sha256" &
SUMPID=$!

info "Læser $DEV – det tager et stykke tid …"
START=$SECONDS
dd if="$DEV" bs=4M iflag=fullblock status=progress \
    | tee "$FIFO" \
    | zstd -T0 -q -f -o "$IMG.partial"
wait "$SUMPID"
SUMPID=

RAW_SHA=$(<"$WORK/raw.sha256")
[[ $RAW_SHA =~ ^[0-9a-f]{64}$ ]] || die "Kunne ikke beregne checksum af de rå data."
mv -- "$IMG.partial" "$IMG"
DONE=1

info "Beregner checksum af imagefilen …"
(cd -- "$DEST" && sha256sum -- "$(basename -- "$IMG")") >"$SUM"

{
    echo "# SD-kort-backup lavet af sd-backup.sh – nøgle=værdi-linjer læses af sd-validate.sh og sd-restore.sh"
    echo "DATE=$(date -Iseconds)"
    echo "SOURCE_DEVICE=$DEV"
    echo "SOURCE_MODEL=$(lsblk -dno MODEL "$DEV" | xargs)"
    echo "SOURCE_SERIAL=$(lsblk -dno SERIAL "$DEV" | xargs)"
    echo "SIZE_BYTES=$SIZE"
    echo "RAW_SHA256=$RAW_SHA"
    echo "IMAGE_FILE=$(basename -- "$IMG")"
    echo "IMAGE_BYTES=$(stat -c %s -- "$IMG")"
    echo
    echo "# Partitioner (lsblk):"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID "$DEV" | sed 's/^/#   /'
    echo
    echo "# Partitionstabel (sfdisk -d):"
    { sfdisk -d "$DEV" 2>/dev/null || echo "(kunne ikke læses)"; } | sed 's/^/#   /'
} >"$INFO"

if [[ -n ${SUDO_UID:-} ]]; then
    chown "$SUDO_UID:${SUDO_GID:-}" -- "$IMG" "$SUM" "$INFO"
    if [[ -n $CREATED_DEST ]]; then chown "$SUDO_UID:${SUDO_GID:-}" -- "$DEST"; fi
fi

IMG_BYTES=$(stat -c %s -- "$IMG")
echo
ok "Backup færdig på $(elapsed)."
echo "   Image:    $IMG ($(human "$IMG_BYTES") – $(( IMG_BYTES * 100 / SIZE ))% af $(human "$SIZE"))"
echo "   Checksum: $SUM"
echo "   Info:     $INFO"
echo
echo "Kortets partitioner er afmonteret, så det kan tages ud nu."
echo "Valider imaget (læser kortet igen og sammenligner):"
echo "   sudo $(dirname -- "$0")/sd-validate.sh '$IMG' $DEV"
