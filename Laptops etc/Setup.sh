#!/usr/bin/env bash
# =============================================================================
# Setup.sh
# Installer mine mest brugte CLI-værktøjer på en Debian/Ubuntu-laptop.
# Viser status for hvert værktøj (installeret/ikke, og om det er seneste
# version) og lader dig vælge flere værktøjer, der installeres samlet.
# Kræver: sudo-adgang
# =============================================================================

set -euo pipefail

# ---------- farver & formatering ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------- hjælpefunktioner ----------
section() { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${RESET}"; \
            echo -e "${CYAN}${BOLD}  $1${RESET}"; \
            echo -e "${CYAN}${BOLD}══════════════════════════════════════════${RESET}"; }
ok()      { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
info()    { echo -e "  ${CYAN}→${RESET}  $1"; }
err()     { echo -e "  ${RED}✘${RESET}  $1"; }

# ---------- rod-check ----------
if [[ $EUID -ne 0 ]]; then
  err "Scriptet skal køres med sudo: sudo bash $0"
  exit 1
fi

# ---------- værktøjsliste ----------
# Tilføj/fjern værktøjer her som "apt-pakkenavn:kort beskrivelse"
TOOLS=(
  # Kerne/CLI
  "htop:Interaktiv proces-/ressourcemonitor"
  "tree:Viser mappestruktur som et træ"
  "curl:Overfører data fra/til URL'er"
  "wget:Downloader filer fra nettet"
  "git:Versionsstyring"
  "unzip:Udpakker .zip-arkiver"
  "krusader:To-panel filhåndtering (KDE)"
  "veracrypt:Diskkryptering — kræver evt. en PPA, se Setup.md"

  # Backup & filer
  "rsync:Synkroniserer/kopierer filer effektivt (bruges i Backup-scripts)"
  "7zip:Pakker/udpakker .7z-arkiver (kommandoen hedder 7zz; ældre systemer bruger p7zip-full/7z i stedet)"
  "libimage-exiftool-perl:Læser/skriver billed-metadata (EXIF) — kommandoen hedder exiftool"
  "darktable:RAW-billedbehandling (darktable-cli bruges i Sort_Total.sh)"
  "libheif-examples:HEIC/HEIF-billedkonvertering (heif-convert, heif-info)"
  "wkhtmltopdf:Konverterer HTML/websider til PDF (bruges i CreatePDF.sh)"

  # System & opdatering
  "fwupd:Firmware-opdateringer via fwupdmgr"
  "snapd:Snap-pakkehåndtering"
  "flatpak:Flatpak-pakkehåndtering"
  "plocate:Hurtig fil-søgning (updatedb/locate)"
  "dkms:Bygger kernel-moduler til tredjeparts-drivere (fx Wi-Fi-adaptere)"

  # Udvikling
  "python3-pip:Python-pakkehåndtering (pip3)"
  "npm:Node.js-pakkehåndtering"

  # Netværk & fjernadgang
  "openssh-client:SSH/SCP-klient — ikke altid forudinstalleret"
  "wireguard-tools:WireGuard VPN (wg/wg-quick, bruges i VPN.sh)"
  "dnsutils:DNS-opslagsværktøjer (dig, bruges i Dns_Sundhedstjek.sh)"
  "fzf:Fuzzy-finder (bruges til SSH-host picker i Hosts.sh)"

  # Terminal & diverse
  "screen:Terminal-sessioner der kan koble fra/til (bruges i Screen-scripts)"
  "pv:Viser fremgang i data-pipelines (bruges sammen med dd i Total_Backup.sh)"
  "dmidecode:Læser hardware-/BIOS-info (kun relevant på fysisk hardware)"
  "eject:Skubber flytbare drev ud sikkert (bruges i Backup_USB_Umount.sh)"
)

echo -e "\n${BOLD}Laptop Setup — installer mine mest brugte værktøjer${RESET}"
echo    "Startet: $(date '+%d-%m-%Y %H:%M:%S')"

# ─────────────────────────────────────────
#  1. Opdater pakkeliste
# ─────────────────────────────────────────
section "1/3 · APT — opdaterer pakkeliste"
apt-get update -qq
ok "Pakkeliste opdateret"

# ─────────────────────────────────────────
#  2. Vis status for hvert værktøj
# ─────────────────────────────────────────
section "2/3 · Status for værktøjer"

PKG_NAMES=()
STATUS_ICON=()
STATUS_TEXT=()
DESCRIPTIONS=()

for entry in "${TOOLS[@]}"; do
  pkg="${entry%%:*}"
  desc="${entry#*:}"
  PKG_NAMES+=("$pkg")
  DESCRIPTIONS+=("$desc")

  installed_version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)
  candidate_version=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}')

  if [[ -z "$installed_version" ]]; then
    STATUS_ICON+=("${RED}✘${RESET}")
    STATUS_TEXT+=("ikke installeret")
  elif [[ "$installed_version" == "$candidate_version" ]]; then
    STATUS_ICON+=("${GREEN}✔${RESET}")
    STATUS_TEXT+=("installeret (seneste: $installed_version)")
  else
    STATUS_ICON+=("${YELLOW}⚠${RESET}")
    STATUS_TEXT+=("opdatering klar ($installed_version → $candidate_version)")
  fi
done

printf "  %-3s %-3s %-10s %-40s %s\n" "#" " " "Pakke" "Status" "Beskrivelse"
for i in "${!PKG_NAMES[@]}"; do
  printf "  %-3s %b   %-10s %-40s %s\n" \
    "$((i+1))" "${STATUS_ICON[$i]}" "${PKG_NAMES[$i]}" "${STATUS_TEXT[$i]}" "${DESCRIPTIONS[$i]}"
done

# ─────────────────────────────────────────
#  3. Vælg og installer værktøjer
# ─────────────────────────────────────────
section "3/3 · Vælg værktøjer der skal installeres/opdateres"
echo "  Angiv numre adskilt af mellemrum eller komma (fx: 1 3 5), 'alle' for alle, eller Enter for at afslutte."
read -rp "  Valg: " selection

if [[ -z "$selection" ]]; then
  info "Intet valgt — afslutter."
  exit 0
fi

selected_pkgs=()
if [[ "$selection" =~ ^[Aa]lle$ ]]; then
  selected_pkgs=("${PKG_NAMES[@]}")
else
  IFS=', ' read -ra numbers <<< "$selection"
  for n in "${numbers[@]}"; do
    [[ -z "$n" ]] && continue
    if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 || n > ${#PKG_NAMES[@]} )); then
      warn "Ugyldigt valg: '$n' — springes over"
      continue
    fi
    selected_pkgs+=("${PKG_NAMES[$((n-1))]}")
  done
fi

if [[ ${#selected_pkgs[@]} -eq 0 ]]; then
  warn "Ingen gyldige værktøjer valgt — afslutter."
  exit 1
fi

info "Installerer/opdaterer: ${selected_pkgs[*]}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "${selected_pkgs[@]}"
ok "Følgende værktøjer er installeret/opdateret: ${selected_pkgs[*]}"
echo ""
