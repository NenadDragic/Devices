#!/usr/bin/env bash
# sd-validate.sh – kontrollerer et image lavet med sd-backup.sh.
#
# Brug:  ./sd-validate.sh BILLEDE.img.zst              (filtjek, kræver ikke sudo)
#        sudo ./sd-validate.sh BILLEDE.img.zst /dev/sdX (filtjek + sammenligning med kortet)
#
# Tjek:
#   1. sha256 af .zst-filen mod .img.zst.sha256  – fanger fejl ved kopiering, fx til NAS
#   2. Udpakker hele imaget og tjekker antal bytes og sha256 af de rå data mod .info.
#      zstd's egne blok-checksums bliver tjekket undervejs.
#   3. Kun hvis /dev/sdX er angivet: sammenligner imaget byte for byte med kortet.
#      Brug det lige efter en backup eller efter en restore.
#
# Exit-kode 0 = alt OK, 1 = mindst ét tjek fejlede.

# Version:      1.0
# Date:         2026-10-25
# Test Run:
# Developper:   Nenad(a)dragic(.)com

set -Eeuo pipefail

die()     { printf '\e[31mFEJL:\e[0m %s\n' "$*" >&2; exit 1; }
info()    { printf '\e[36m==>\e[0m %s\n' "$*"; }
ok()      { printf '\e[32mOK:\e[0m %s\n' "$*"; }
bad()     { printf '\e[31mFEJLET:\e[0m %s\n' "$*" >&2; FAILED=1; }
warn()    { printf '\e[33mADVARSEL:\e[0m %s\n' "$*" >&2; }
usage()   { sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit "${1:-0}"; }
confirm() { local a; read -r -p "$1 [j/N] " a </dev/tty || return 1; [[ $a == [jJyY] ]]; }
human()   { numfmt --to=iec --suffix=B "$1"; }

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
            info "Afmonterer $part (en monteret partition kan ændre sig og give falsk afvigelse)"
            umount "$part" || die "Kunne ikke afmontere $part. Er den i brug (står du fx i mappen)?"
        done
    done < <(lsblk -nrpo NAME "$1")
}

getkey() { grep -m1 "^$1=" -- "$INFO" | cut -d= -f2- || true; }
# "… differ: char 123, line 4" -> " (første forskel ved byte 123)"
first_diff() { local n; n=$(sed -n 's/.*char \([0-9]*\).*/\1/p' <<<"$1"); [[ -n $n ]] && echo " (første forskel ved byte $n)" || true; }

# ---------------------------------------------------------------------------

[[ ${1:-} == -h || ${1:-} == --help ]] && usage
[[ $# -ge 1 && $# -le 2 ]] || usage 1 >&2
need_cmds zstd sha256sum cmp dd numfmt tee wc mkfifo

IMG=$(readlink -f -- "$1")
DEV=${2:+$(readlink -f -- "$2")}
[[ -f $IMG ]] || die "Imagefilen $1 findes ikke."
[[ $IMG == *.img.zst ]] || die "Forventer en .img.zst-fil lavet af sd-backup.sh."
SUM="$IMG.sha256"
INFO="${IMG%.img.zst}.info"
FAILED=

if [[ -n $DEV ]]; then
    (( EUID == 0 )) || die "Sammenligning med kortet kræver sudo."
    need_cmds lsblk findmnt blockdev
    check_disk "$DEV"
fi

EXP_SIZE=
EXP_SHA=
if [[ -f $INFO ]]; then
    EXP_SIZE=$(getkey SIZE_BYTES)
    EXP_SHA=$(getkey RAW_SHA256)
    [[ $EXP_SIZE =~ ^[0-9]+$ && $EXP_SHA =~ ^[0-9a-f]{64}$ ]] || { warn "$INFO mangler SIZE_BYTES/RAW_SHA256."; EXP_SIZE=; EXP_SHA=; }
else
    warn "Ingen .info-fil ($INFO) – kan ikke tjekke de rå data mod en kendt checksum."
fi

# --- 1. checksum af .zst-filen ----------------------------------------------
echo
info "1/3  Checksum af imagefilen"
if [[ -f $SUM ]]; then
    if (cd -- "$(dirname -- "$IMG")" && sha256sum -c --quiet -- "$(basename -- "$SUM")"); then
        ok "$(basename -- "$IMG") matcher $(basename -- "$SUM")"
    else
        bad "Filen matcher ikke sin checksum. Den er beskadiget, ændret eller omdøbt."
    fi
else
    warn "Ingen $(basename -- "$SUM") – springer over."
fi

# --- 2. udpak og tjek de rå data ----------------------------------------------
echo
info "2/3  Udpakker imaget og tjekker indholdet"
WORK=$(mktemp -d)
WCPID=
cleanup() { [[ -n $WCPID ]] && kill "$WCPID" 2>/dev/null || true; rm -rf -- "$WORK"; }
trap cleanup EXIT
FIFO="$WORK/raw.fifo"
mkfifo "$FIFO"
wc -c <"$FIFO" >"$WORK/bytes" &
WCPID=$!

RAW_OK=1
if ! zstd -dc -q -- "$IMG" \
        | dd bs=4M iflag=fullblock status=progress \
        | tee "$FIFO" \
        | sha256sum | cut -d' ' -f1 >"$WORK/sha"; then
    RAW_OK=
fi
wait "$WCPID" || true
WCPID=
GOT_SIZE=$(tr -d ' ' <"$WORK/bytes")
GOT_SHA=$(<"$WORK/sha")

if [[ -z $RAW_OK ]]; then
    bad "Udpakningen fejlede – imaget er beskadiget."
else
    ok "Udpakning uden fejl: $(human "$GOT_SIZE")"
    if [[ -n $EXP_SIZE ]]; then
        if [[ $GOT_SIZE == "$EXP_SIZE" ]]; then ok "Størrelse matcher .info ($GOT_SIZE bytes)"
        else bad "Størrelse $GOT_SIZE bytes, men .info siger $EXP_SIZE"; fi
        if [[ $GOT_SHA == "$EXP_SHA" ]]; then ok "sha256 af de rå data matcher .info"
        else bad "sha256 af de rå data matcher IKKE .info"; fi
    fi
fi

# --- 3. sammenlign med kortet --------------------------------------------------
echo
info "3/3  Sammenligning med kortet"
if [[ -z $DEV ]]; then
    echo "     Springes over (ingen enhed angivet)."
elif [[ -z $RAW_OK ]]; then
    bad "Springes over, fordi imaget ikke kunne udpakkes."
else
    DEV_SIZE=$(blockdev --getsize64 "$DEV")
    if (( DEV_SIZE < GOT_SIZE )); then
        bad "$DEV ($(human "$DEV_SIZE")) er mindre end imaget ($(human "$GOT_SIZE"))."
    else
        (( DEV_SIZE > GOT_SIZE )) && info "Kortet er større end imaget – sammenligner de første $(human "$GOT_SIZE")."
        unmount_all "$DEV"
        blockdev --flushbufs "$DEV"         # læs fra kortet, ikke fra cache
        info "Læser $DEV og sammenligner …"
        if DIFF=$(cmp -n "$GOT_SIZE" -- \
                <(zstd -dc -q -- "$IMG") \
                <(dd if="$DEV" bs=4M iflag=fullblock,count_bytes count="$GOT_SIZE" status=progress)); then
            ok "Kortet er identisk med imaget."
        else
            bad "Kortet og imaget er forskellige$(first_diff "$DIFF")."
        fi
    fi
fi

echo
if [[ -n $FAILED ]]; then
    printf '\e[31mRESULTAT: Mindst ét tjek fejlede.\e[0m\n'
    exit 1
fi
printf '\e[32mRESULTAT: Alle udførte tjek er OK.\e[0m\n'
