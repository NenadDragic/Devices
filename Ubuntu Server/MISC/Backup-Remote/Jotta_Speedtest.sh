#!/usr/bin/env bash
# Version:      1.0
# Date:         2026-10-01
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Jotta_Speedtest.sh — test af upload-hastighed til Jottacloud med ét NAS-share
#
# Kør som brugeren misc (IKKE med sudo), gerne i tmux:
#   tmux new -s jottatest
#   bash ~/scripts/Jotta_Speedtest.sh [minutter] [mappe]
#   Ctrl-b d                    frakobl – testen kører videre
#   tmux attach -t jottatest    kobl på igen
#
# Standard: 15 minutter på /mnt/nas/DashCam. Stop før tid med Ctrl-C.
# Hastigheden måles på netkortet (upload = sendt mod internettet,
# NAS-læsning = modtaget fra NAS'en). Andet trafik tæller også med.
# Et CSV-log gemmes i ~/jotta-speedtest-<tidspunkt>.csv.
#
# Til sidst spørger scriptet, om mappen skal fjernes fra backup igen
# (jotta-cli rem) – det sletter test-uploaden i Jottacloud.

set -uo pipefail

# ── Konfiguration ───────────────────────────────────────────────────────────
MINUTES="${1:-15}"
SRC="${2:-/mnt/nas/DashCam}"
NAS_HOST="192.168.1.50"               # Skal svare til NAS_HOST i Nas_Mount.sh
INTERVAL="${INTERVAL:-30}"           # sekunder mellem målinger
LOG="$HOME/jotta-speedtest-$(date +%Y%m%d-%H%M).csv"
# ────────────────────────────────────────────────────────────────────────────

SRC="${SRC%/}"
STOP=0
ADDED_BY_US=0

die() { echo "FEJL: $*" >&2; exit 1; }

iface_for() {
  ip route get "$1" 2>/dev/null \
    | awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i+1); exit } }'
}

nic_bytes() {  # $1 = netkort, $2 = tx|rx
  cat "/sys/class/net/$1/statistics/$2_bytes" 2>/dev/null || echo 0
}

mbit() {       # $1 = bytes, $2 = sekunder
  awk -v b="$1" -v s="$2" 'BEGIN { printf "%.1f", (s > 0 ? b * 8 / s / 1e6 : 0) }'
}

mbyte() {      # $1 = bytes, $2 = sekunder
  awk -v b="$1" -v s="$2" 'BEGIN { printf "%.1f", (s > 0 ? b / s / 1e6 : 0) }'
}

gbyte() {      # $1 = bytes
  awk -v b="$1" 'BEGIN { printf "%.2f", b / 1e9 }'
}

mmss() { printf '%02d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

usage_now() {  # "Usage : 1.2GiB / 4.66GiB" -> "1.2GiB / 4.66GiB"
  timeout 20 jotta-cli status 2>/dev/null \
    | awk -F': *' '/^ *Usage/ { print $2; exit }'
}

# ── Forudsætninger ──────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || die "Kør som misc, ikke med sudo – jotta-cli skal tale med din egen jottad."
[[ $MINUTES =~ ^[1-9][0-9]*$ ]] || die "Minutter skal være et helt tal, fx 15."
command -v jotta-cli >/dev/null 2>&1 || die "jotta-cli er ikke installeret."

# Adgang til mappen udløser automount; derefter skal der ligge et cifs-mount
timeout 15 stat -t -- "$SRC/." >/dev/null 2>&1 \
  || die "$SRC svarer ikke eller kan ikke læses af $(id -un). Tjek: bash ~/scripts/Nas_Mount.sh status"
timeout 10 findmnt -rn -M "$SRC" -t cifs >/dev/null 2>&1 \
  || die "$SRC er ikke et monteret NAS-share. Tjek: bash ~/scripts/Nas_Mount.sh status"

status_before="$(timeout 20 jotta-cli status 2>&1)" \
  || die "jottad svarer ikke. Start den med: run_jottad"

WAN_IF="$(iface_for 1.1.1.1)"
NAS_IF="$(iface_for "$NAS_HOST")"
[[ -n $WAN_IF && -r /sys/class/net/$WAN_IF/statistics/tx_bytes ]] \
  || die "Kunne ikke finde netkortet mod internettet."
[[ -n $NAS_IF ]] || NAS_IF="$WAN_IF"

# ── Tilføj mappen ───────────────────────────────────────────────────────────
echo "== Jottacloud hastighedstest: $SRC i $MINUTES min (måling hvert ${INTERVAL}s)"
echo "   Netkort: upload via $WAN_IF, NAS-læsning via $NAS_IF"
echo "   Log:     $LOG"
echo

if grep -qF -- "$SRC" <<<"$status_before"; then
  echo "$SRC er allerede tilføjet til backup – måler videre på den."
else
  echo "Tilføjer $SRC til backup (svar på eventuel advarsel om netværksmount):"
  jotta-cli add "$SRC" || die "jotta-cli add fejlede."
  ADDED_BY_US=1
fi
echo

# ── Måling ──────────────────────────────────────────────────────────────────
trap 'STOP=1' INT TERM

start=$(date +%s)
end=$(( start + MINUTES * 60 ))
tx0=$(nic_bytes "$WAN_IF" tx);  rx0=$(nic_bytes "$NAS_IF" rx)
prev_t=$start; prev_tx=$tx0; prev_rx=$rx0

echo "tid,sekunder,upload_mbit_s,nas_laesning_mbit_s,jottacloud_usage" > "$LOG"
printf '%-8s  %-6s  %16s  %16s  %s\n' "Tid" "Gået" "Upload" "NAS-læsning" "Jottacloud"
printf '%-8s  %-6s  %16s  %16s  %s\n' "--------" "------" "----------------" "----------------" "----------"

while (( ! STOP )) && (( $(date +%s) < end )); do
  sleep "$INTERVAL" & wait $!
  t=$(date +%s)
  dt=$(( t - prev_t ))
  (( dt > 0 )) || continue
  tx=$(nic_bytes "$WAN_IF" tx);  rx=$(nic_bytes "$NAS_IF" rx)
  up=$(mbit $(( tx - prev_tx )) "$dt")
  rd=$(mbit $(( rx - prev_rx )) "$dt")
  usage="$(usage_now)"

  printf '%-8s  %-6s  %9s Mbit/s  %9s Mbit/s  %s\n' \
    "$(date +%H:%M:%S)" "$(mmss $(( t - start )))" "$up" "$rd" "${usage:-?}"
  printf '%s,%s,%s,%s,"%s"\n' "$(date +%F\ %T)" "$(( t - start ))" "$up" "$rd" "$usage" >> "$LOG"

  prev_t=$t; prev_tx=$tx; prev_rx=$rx
done
trap - INT TERM

# ── Resumé ──────────────────────────────────────────────────────────────────
t=$(date +%s)
total=$(( t - start ))
sent=$(( $(nic_bytes "$WAN_IF" tx) - tx0 ))
recv=$(( $(nic_bytes "$NAS_IF" rx) - rx0 ))

echo
echo "== Resumé ($(mmss "$total") min)"
echo "   Upload i snit:       $(mbit "$sent" "$total") Mbit/s  ($(mbyte "$sent" "$total") MB/s), i alt $(gbyte "$sent") GB"
echo "   NAS-læsning i snit:  $(mbit "$recv" "$total") Mbit/s  ($(mbyte "$recv" "$total") MB/s), i alt $(gbyte "$recv") GB"
echo "   Log:                 $LOG"
echo
timeout 20 jotta-cli status || true
echo

# ── Oprydning ───────────────────────────────────────────────────────────────
if (( ADDED_BY_US )); then
  ans="n"
  if [[ -t 0 ]]; then
    read -rp "Fjern $SRC fra backup og slet test-uploaden i Jottacloud? [J/n] " ans
    ans="${ans:-j}"
  fi
  if [[ $ans =~ ^[jJyY]$ ]]; then
    jotta-cli rem "$SRC" && echo "Fjernet: $SRC"
  else
    echo "Mappen er stadig tilføjet og uploader videre, indtil kvoten er fuld."
    echo "Fjern den, før du afmonterer eller genstarter: jotta-cli rem $SRC"
  fi
fi
