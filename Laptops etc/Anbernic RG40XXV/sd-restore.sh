#!/usr/bin/env bash
# sd-restore.sh – skriver et image lavet med sd-backup.sh tilbage på et SD-kort.
#
# Brug:  sudo ./sd-restore.sh BILLEDE.img.zst /dev/sdX
#
#   ADVARSEL: ALT på /dev/sdX bliver overskrevet.
#
# Forløb:
#   1. Tjekker imagefilens checksum, før der skrives noget
#   2. Sikkerhedstjek af kortet: hel disk, ikke systemdisken, stor nok,
#      og imaget må ikke ligge på selve kortet
#   3. Du bekræfter ved at skrive enhedens navn (fx sdb)
#   4. Afmonterer kortets partitioner og skriver imaget
#   5. Læser kortet igen og sammenligner byte for byte med imaget
#
# Kortet skal være mindst lige så stort som det oprindelige.

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
            src=${src%%\[*}
            if [[ -b $src ]]; then lsblk -nrpso NAME,TYPE "$src" 2>/dev/null || true; fi
        done
        while read -r src; do
            if [[ -b $src ]]; then lsblk -nrpso NAME,TYPE "$src" 2>/dev/null || true; fi
        done < <(swapon --show=NAME --noheadings 2>/dev/null || true)
    } | awk '$2=="disk"{print $1}' | sort -u
    return 0
}

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

unmount_all() {
    local part
    while read -r part; do
        while findmnt -rn --source "$part" >/dev/null 2>&1; do
            info "Afmonterer $part"
            umount "$part" || die "Kunne ikke afmontere $part. Er den i brug (står du fx i mappen)?"
        done
    done < <(lsblk -nrpo NAME "$1")
}

getkey() { grep -m1 "^$1=" -- "$INFO" | cut -d= -f2- || true; }
# "… differ: char 123, line 4" -> " (første forskel ved byte 123)"
first_diff() { local n; n=$(sed -n 's/.*char \([0-9]*\).*/\1/p' <<<"$1"); [[ -n $n ]] && echo " (første forskel ved byte $n)" || true; }

# ---------------------------------------------------------------------------

[[ ${1:-} == -h || ${1:-} == --help ]] && usage
[[ $# -eq 2 ]] || usage 1 >&2
(( EUID == 0 )) || die "Skal køres med sudo."
need_cmds zstd sha256sum cmp dd lsblk findmnt blockdev numfmt wc

IMG=$(readlink -f -- "$1")
DEV=$(readlink -f -- "$2")
[[ -f $IMG ]] || die "Imagefilen $1 findes ikke."
[[ $IMG == *.img.zst ]] || die "Forventer en .img.zst-fil lavet af sd-backup.sh."
SUM="$IMG.sha256"
INFO="${IMG%.img.zst}.info"

check_disk "$DEV"

# Imaget må ikke ligge på det kort, der skal overskrives.
IMG_SRC=$(findmnt -nro SOURCE --target "$IMG" 2>/dev/null || true)
IMG_SRC=${IMG_SRC%%\[*}
if [[ -b $IMG_SRC ]]; then
    IMG_DISKS=$(lsblk -nrpso NAME,TYPE "$IMG_SRC" 2>/dev/null | awk '$2=="disk"{print $1}' || true)
    if grep -qxF -- "$DEV" <<<"$IMG_DISKS"; then
        die "Imaget ligger på $DEV selv. Kopiér det et andet sted hen først."
    fi
fi

# --- 1. tjek imaget før der skrives ------------------------------------------
if [[ -f $SUM ]]; then
    info "Tjekker imagefilens checksum, før der skrives noget …"
    (cd -- "$(dirname -- "$IMG")" && sha256sum -c --quiet -- "$(basename -- "$SUM")") \
        || die "Imagefilen matcher ikke sin checksum. Intet er skrevet til kortet."
    ok "Imagefilen er intakt."
else
    warn "Ingen $(basename -- "$SUM") – kan ikke tjekke imaget på forhånd."
    confirm "Fortsæt uden forhåndstjek?" || exit 1
fi

SIZE=
[[ -f $INFO ]] && SIZE=$(getkey SIZE_BYTES)
if [[ ! $SIZE =~ ^[0-9]+$ ]]; then
    info "Ingen størrelse i .info – udpakker for at måle imaget …"
    SIZE=$(zstd -dc -q -- "$IMG" | wc -c) || die "Imaget kunne ikke udpakkes."
fi

# --- 2. tjek kortet --------------------------------------------------------------
DEV_SIZE=$(blockdev --getsize64 "$DEV")
(( DEV_SIZE >= SIZE )) || die "$DEV er for lille: $(human "$DEV_SIZE"), imaget kræver $(human "$SIZE")."

# --- 3. bekræftelse -------------------------------------------------------------
echo
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,MODEL,TRAN "$DEV"
echo
if [[ -f $INFO ]]; then
    MODEL=$(getkey SOURCE_MODEL)
    echo "Image: $(basename -- "$IMG")  (taget $(getkey DATE)${MODEL:+ fra $MODEL})"
fi
printf '\e[31;1mALT på %s (%s) bliver slettet og erstattet med imaget.\e[0m\n' "$DEV" "$(human "$DEV_SIZE")"
NAME=$(basename -- "$DEV")
read -r -p "Skriv '$NAME' for at fortsætte: " ANSWER </dev/tty
[[ $ANSWER == "$NAME" ]] || die "Afbrudt – intet er skrevet."

# --- 4. skriv --------------------------------------------------------------------
unmount_all "$DEV"
info "Skriver imaget til $DEV …"
START=$SECONDS
zstd -dc -q -- "$IMG" | dd of="$DEV" bs=4M iflag=fullblock conv=fsync status=progress \
    || die "Skrivningen fejlede. Kortet er nu i en ukendt tilstand – prøv igen eller med et andet kort."
sync
ok "Skrevet på $(elapsed)."

# --- 5. verificér ----------------------------------------------------------------
blockdev --flushbufs "$DEV"                 # læs fra kortet, ikke fra cache
info "Læser kortet igen og sammenligner med imaget …"
if DIFF=$(cmp -n "$SIZE" -- \
        <(zstd -dc -q -- "$IMG") \
        <(dd if="$DEV" bs=4M iflag=fullblock,count_bytes count="$SIZE" status=progress)); then
    ok "Kortet er identisk med imaget."
else
    die "Kortet matcher IKKE imaget$(first_diff "$DIFF"). Kortet eller kortlæseren kan være defekt."
fi

# Lad kernen læse den nye partitionstabel.
blockdev --rereadpt "$DEV" 2>/dev/null || partx -u "$DEV" 2>/dev/null || true

PTTYPE=$(blkid -p -o value -s PTTYPE "$DEV" 2>/dev/null || true)
if [[ $PTTYPE == gpt ]] && (( DEV_SIZE > SIZE )); then
    warn "Kortet bruger GPT og er større end imaget. Flyt backup-GPT'en til slutningen med:"
    echo "   sudo sfdisk --relocate gpt-bak-std $DEV"
fi

echo
ok "Restore færdig. Kortet kan tages ud."
