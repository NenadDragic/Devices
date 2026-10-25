#!/usr/bin/env bash
# Version:      1.0
# Date:         2026-10-01
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Nas_Mount.sh — styring af NAS-shares, der monteres read-only via /etc/fstab
#                og systemd-automount
#
# Hver delt mappe er sit eget SMB-share med sin egen linje i /etc/fstab:
#   //NAS/DashCam -> /mnt/nas/DashCam, //NAS/Dragic -> /mnt/nas/Dragic, ...
# systemd monterer ved første adgang efter opstart og afmonterer ved nedlukning.
#
# Brug:
#   sudo ./Nas_Mount.sh creds    Opret credentials-fil (spørger om brugernavn/kode)
#        ./Nas_Mount.sh fstab    Udskriv fstab-linjerne til NAS_SHARES
#   sudo ./Nas_Mount.sh mount    Start automount og montér alle shares
#   sudo ./Nas_Mount.sh umount   Afmontér alle shares (indtil 'mount' eller genstart)
#        ./Nas_Mount.sh status   Vis status (kræver ikke root)
#
# Exit-koder: 0 = alt OK
#             1 = mindst ét share ikke monteret / fejlede
#             2 = problem (ikke read-only, svarer ikke, forkert kilde, mangler i fstab)
#
# Kræver: cifs-utils og linjerne fra 'Nas_Mount.sh fstab' i /etc/fstab.

set -euo pipefail

# ── Konfiguration ───────────────────────────────────────────────────────────
NAS_HOST="192.168.1.50"                 # IP eller DNS-navn på NAS'en (også i Jotta_Speedtest.sh)
NAS_SHARES=(DashCam Dragic NetBackup)   # Delte mapper (navne med mellemrum i "")
MOUNT_BASE="/mnt/nas"                   # Hvert share monteres i $MOUNT_BASE/<navn>
CRED_FILE="/etc/nas/nas.cred"           # Oprettes af 'creds' som root:root 0600
MOUNT_OWNER="root"                      # Lokal ejer af filerne på mountet
MOUNT_GROUP="misc"                      # Lokal gruppe med læseadgang (0440/0550)
SMB_VERS="3.0"                          # Synology DSM 6/7 understøtter SMB3
EXTRA_OPTS=""                           # Ekstra options, fx "seal" (krypteret transport)
TIMEOUT=10                              # Sekunder til netværks-, mount- og svar-tjek
# ────────────────────────────────────────────────────────────────────────────

MOUNT_BASE="${MOUNT_BASE%/}"
PROG="$(basename -- "$0")"

die()  { echo "FEJL: $*" >&2; exit 1; }
warn() { echo "ADVARSEL: $*" >&2; }

usage() {
  cat <<EOF
Brug: $PROG {creds|fstab|mount|umount|status}

  creds    Opret credentials-fil ($CRED_FILE)
  fstab    Udskriv fstab-linjer til ${NAS_SHARES[*]}
  mount    Start automount og montér alle shares read-only
  umount   Afmontér alle shares (indtil 'mount' eller genstart)
  status   Vis status (exit 0=OK, 1=ikke monteret, 2=problem)
EOF
}

src_for() { printf '//%s/%s' "$NAS_HOST" "$1"; }
mp_for()  { printf '%s/%s' "$MOUNT_BASE" "$1"; }

# /proc/self/mountinfo og fstab skriver backslash og mellemrum som oktale escapes
mi_escape() {
  local s=${1//\\/\\134}
  printf '%s' "${s// /\\040}"
}

# Læser /proc/self/mountinfo direkte (stat'er ikke mountet, så den hænger
# ikke, hvis NAS'en er væk). Udskriver "KILDE FSTYPE MOUNT-OPTIONS" for det
# øverste mount på mappen i $1, eller ingenting.
mount_info() {
  MP="$(mi_escape "$1")" awk '
    $5 == ENVIRON["MP"] {
      for (i = 7; i <= NF; i++)
        if ($i == "-") { line = $(i+2) " " $(i+1) " " $6; break }
    }
    END { if (line != "") print line }
  ' /proc/self/mountinfo
}

unit_for() {     # $1 = mappe, $2 = automount|mount
  systemd-escape -p --suffix="$2" "$1"
}

unit_loaded() {  # true hvis systemd kender enheden (dvs. den står i fstab)
  [[ $(systemctl show -p LoadState --value "$1" 2>/dev/null) == loaded ]]
}

# Adgang til mappen udløser automount. Fejler, hvis sharet ikke kan monteres
# eller ikke svarer inden for TIMEOUT.
trigger() {
  timeout -k 2 "$TIMEOUT" stat -t -- "$1/." >/dev/null 2>&1
}

# Den tomme mappe under mountet låses (000), så den giver "Permission denied"
# i stedet for at se tom ud, når sharet ikke er monteret. Det beskytter
# backup-programmer mod at tro, at alle filer er slettet. Kun når intet er
# monteret på mappen.
lock_dir() {
  if [[ -z "$(mount_info "$1")" && -d $1 ]]; then
    chmod 000 -- "$1"
  fi
}

nas_reachable() {
  # shellcheck disable=SC2016  # $1 skal udvides af den indre bash, ikke her
  timeout "$TIMEOUT" bash -c '</dev/tcp/"$1"/445' _ "$NAS_HOST" 2>/dev/null
}

check_cred_perms() {
  local perm owner
  perm="$(stat -c '%a' -- "$CRED_FILE")"
  owner="$(stat -c '%U' -- "$CRED_FILE")"
  if [[ $owner != root || ( $perm != 600 && $perm != 400 ) ]]; then
    warn "$CRED_FILE er $owner/$perm – bør være root/600. Ret: sudo chown root:root $CRED_FILE && sudo chmod 600 $CRED_FILE"
  fi
}

fstab_opts() {
  local o="ro,credentials=${CRED_FILE},vers=${SMB_VERS},uid=${MOUNT_OWNER},gid=${MOUNT_GROUP}"
  o+=",file_mode=0440,dir_mode=0550,nosuid,nodev,noexec,iocharset=utf8"
  o+=",_netdev,nofail,x-systemd.automount,x-systemd.mount-timeout=30"
  if [[ -n $EXTRA_OPTS ]]; then o+=",${EXTRA_OPTS}"; fi
  printf '%s' "$o"
}

check_extra_opts() {
  if [[ ",$EXTRA_OPTS," == *,rw,* ]]; then
    die "EXTRA_OPTS indeholder 'rw' – sharene skal være read-only."
  fi
}

# ── creds ───────────────────────────────────────────────────────────────────
cmd_creds() {
  local dir ans user pass pass2 domain
  dir="$(dirname -- "$CRED_FILE")"

  if [[ -e $CRED_FILE ]]; then
    read -rp "$CRED_FILE findes allerede. Overskriv? [j/N] " ans
    [[ $ans =~ ^[jJyY]$ ]] || die "Afbrudt."
  fi

  IFS= read -rp  "Brugernavn på NAS: " user
  [[ -n $user ]] || die "Tomt brugernavn."
  IFS= read -rsp "Adgangskode: " pass;          echo
  IFS= read -rsp "Gentag adgangskode: " pass2;  echo
  [[ $pass == "$pass2" ]] || die "Adgangskoderne er ikke ens."
  IFS= read -rp  "Domæne/workgroup (tom = ingen): " domain

  # Opret kun mappen, hvis den ikke findes (ændr aldrig rettigheder på fx /etc)
  if [[ ! -d $dir ]]; then
    install -d -m 0700 -o root -g root -- "$dir"
  fi

  (
    umask 077
    {
      printf 'username=%s\n' "$user"
      printf 'password=%s\n' "$pass"
      if [[ -n $domain ]]; then printf 'domain=%s\n' "$domain"; fi
    } > "$CRED_FILE"
  )
  chown root:root -- "$CRED_FILE"
  chmod 0600 -- "$CRED_FILE"
  unset pass pass2

  echo "Credentials gemt i $CRED_FILE (root:root, 0600)."
}

# ── fstab ───────────────────────────────────────────────────────────────────
cmd_fstab() {
  local share opts
  check_extra_opts
  opts="$(fstab_opts)"
  echo "# NAS-shares, read-only med systemd-automount – genereret af $PROG $(date +%F)"
  for share in "${NAS_SHARES[@]}"; do
    printf '%-26s %-20s cifs  %s  0  0\n' \
      "$(mi_escape "$(src_for "$share")")" "$(mi_escape "$(mp_for "$share")")" "$opts"
  done
}

# ── mount ───────────────────────────────────────────────────────────────────
mount_one() {
  local share=$1 mp src am mu mi cur fstype mopts
  mp="$(mp_for "$share")"
  src="$(src_for "$share")"
  am="$(unit_for "$mp" automount)"
  mu="$(unit_for "$mp" mount)"

  if ! unit_loaded "$am"; then
    warn "[$share] findes ikke i /etc/fstab. Tilføj linjen fra '$PROG fstab'" \
         "og kør 'sudo systemctl daemon-reload'."
    return 1
  fi

  lock_dir "$mp"
  if ! systemctl start "$am"; then
    warn "[$share] kunne ikke starte $am."
    return 1
  fi
  if ! trigger "$mp"; then
    warn "[$share] blev ikke monteret inden for ${TIMEOUT}s. Se: journalctl -u $mu"
    return 1
  fi

  mi="$(mount_info "$mp")"
  read -r cur fstype mopts <<<"$mi"
  if [[ $fstype != cifs || $cur != "$(mi_escape "$src")" ]]; then
    warn "[$share] forventede $src (cifs) på $mp, fandt ${cur:-intet} (${fstype:-?})."
    return 2
  fi

  # Verificér at kernen faktisk har monteret read-only
  if [[ ",$mopts," != *,ro,* ]]; then
    systemctl stop "$am" "$mu" || true
    warn "[$share] blev ikke read-only – afmonteret igen. Ret linjen i /etc/fstab."
    return 2
  fi

  echo "[$share] monteret read-only på $mp"
}

cmd_mount() {
  local share rc=0 r

  command -v mount.cifs >/dev/null 2>&1 \
    || die "mount.cifs mangler. Installer: sudo apt install cifs-utils"
  [[ -f $CRED_FILE ]] || die "$CRED_FILE findes ikke. Kør først: sudo $PROG creds"
  check_cred_perms
  (( ${#NAS_SHARES[@]} > 0 )) || die "NAS_SHARES er tom."
  nas_reachable || die "Kan ikke nå $NAS_HOST på port 445 (SMB) inden for ${TIMEOUT}s."

  for share in "${NAS_SHARES[@]}"; do
    r=0
    mount_one "$share" || r=$?
    if (( r > rc )); then rc=$r; fi
  done

  if (( rc )); then echo "Mindst ét share blev ikke monteret." >&2; fi
  return "$rc"
}

# ── umount ──────────────────────────────────────────────────────────────────
umount_one() {
  local share=$1 mp src am mu mi cur fstype
  mp="$(mp_for "$share")"
  src="$(src_for "$share")"
  am="$(unit_for "$mp" automount)"
  mu="$(unit_for "$mp" mount)"

  mi="$(mount_info "$mp")"
  if [[ -n $mi ]]; then
    read -r cur fstype _ <<<"$mi"
    if [[ $fstype != autofs && $cur != "$(mi_escape "$src")" ]]; then
      warn "[$share] $mp er monteret med $cur ($fstype) – rører det ikke."
      return 1
    fi
  fi

  if unit_loaded "$am"; then
    systemctl stop "$am" "$mu" 2>/dev/null || true
  fi

  # Stadig et cifs-mount tilbage (fx monteret uden om systemd)?
  mi="$(mount_info "$mp")"
  if [[ -n $mi ]]; then
    read -r _ fstype _ <<<"$mi"
    if [[ $fstype == cifs ]]; then umount -- "$mp" 2>/dev/null || true; fi
  fi

  if [[ -n "$(mount_info "$mp")" ]]; then
    warn "[$share] kunne ikke afmontere $mp."
    if command -v fuser >/dev/null 2>&1; then
      echo "Processer der bruger mountet:" >&2
      timeout -k 2 "$TIMEOUT" fuser -vm -- "$mp" >&2 || true
    fi
    return 1
  fi

  lock_dir "$mp"
  echo "[$share] afmonteret"
}

cmd_umount() {
  local share rc=0

  for share in "${NAS_SHARES[@]}"; do
    umount_one "$share" || rc=1
  done

  if (( rc )); then
    echo "Luk processerne og prøv igen. Er NAS'en væk: 'sudo umount -l <mappe>' som sidste udvej." >&2
  else
    echo "Mapperne er låst (000), mens de er afmonteret. 'sudo $PROG mount' eller en genstart monterer igen."
  fi
  return "$rc"
}

# ── status ──────────────────────────────────────────────────────────────────
status_one() {
  local share=$1 mp src am mi cur="" fstype="" mopts="" state space perm rc=0
  mp="$(mp_for "$share")"
  src="$(src_for "$share")"
  am="$(unit_for "$mp" automount)"

  if ! unit_loaded "$am"; then
    printf '%-12s mangler i /etc/fstab (se: %s fstab)\n' "$share" "$PROG"
    return 2
  fi

  # Er automount aktiv, udløser adgangen mountet, hvis det ikke allerede er sket
  if systemctl is-active --quiet "$am"; then
    trigger "$mp" || true
  fi

  mi="$(mount_info "$mp")"
  if [[ -n $mi ]]; then read -r cur fstype mopts <<<"$mi"; fi

  case $fstype in
    "")
      perm="$(stat -c '%a' -- "$mp" 2>/dev/null || echo '?')"
      if [[ $perm == 0 ]]; then
        printf '%-12s ikke monteret (mappen er låst)\n' "$share"
      else
        printf '%-12s ikke monteret – ADVARSEL: tom mappe kan læses (%s)\n' "$share" "$perm"
      fi
      return 1
      ;;
    autofs)
      if nas_reachable; then
        printf '%-12s automount aktiv, men mount fejlede – NAS svarer (kode/rettighed?). Se: journalctl -u %s\n' \
          "$share" "$(unit_for "$mp" mount)"
      else
        printf '%-12s automount aktiv, men sharet kunne ikke monteres – NAS svarer ikke\n' "$share"
      fi
      return 2
      ;;
    cifs)
      if [[ $cur != "$(mi_escape "$src")" ]]; then
        printf '%-12s %s har et andet share monteret: %s\n' "$share" "$mp" "$cur"
        return 2
      fi
      ;;
    *)
      printf '%-12s %s har noget andet monteret: %s (%s)\n' "$share" "$mp" "$cur" "$fstype"
      return 2
      ;;
  esac

  if [[ ",$mopts," == *,ro,* ]]; then
    state="read-only"
  else
    state="IKKE READ-ONLY!"
    rc=2
  fi

  if trigger "$mp"; then
    space="$(timeout -k 2 "$TIMEOUT" df -hP -- "$mp" 2>/dev/null \
      | awk 'NR==2 { printf "%s af %s brugt (%s)", $3, $2, $5 }')" || true
  else
    space="SVARER IKKE inden for ${TIMEOUT}s (stale?)"
    rc=2
  fi

  printf '%-12s monteret, %s, %s\n' "$share" "$state" "$space"
  return "$rc"
}

cmd_status() {
  local share rc=0 r

  if nas_reachable; then
    echo "NAS:         $NAS_HOST svarer på port 445"
  else
    echo "NAS:         $NAS_HOST SVARER IKKE på port 445"
  fi
  echo "Mountpoints: $MOUNT_BASE/<share> (automount via /etc/fstab)"
  echo

  for share in "${NAS_SHARES[@]}"; do
    r=0
    status_one "$share" || r=$?
    if (( r > rc )); then rc=$r; fi
  done

  return "$rc"
}

# ── main ────────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-}"

  case $cmd in
    creds|mount|umount|unmount) ;;
    status) cmd_status; exit $? ;;
    fstab)  cmd_fstab;  exit 0 ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac

  if [[ $EUID -ne 0 ]]; then
    exec sudo -- "$(readlink -f -- "$0")" "$@"
  fi

  case $cmd in
    creds)          cmd_creds ;;
    mount)          cmd_mount ;;
    umount|unmount) cmd_umount ;;
  esac
}

main "$@"
