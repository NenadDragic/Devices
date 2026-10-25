#!/usr/bin/env bash
# Version:      1.0
# Date:         2026-10-12
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Nas_Backup.sh — backup af NAS-shares fra misc
#   IDrive:     arkiv – slettede filer bliver liggende (kører efter 'run')
#   Jottacloud: spejl – jottad kører løbende af sig selv
#
# Kør som misc (samme bruger som IDrive-profilen):
#   Nas_Backup.sh status               Samlet status: mounts, IDrive (inkl. fremdrift), Jottacloud
#   Nas_Backup.sh run                  Tjek mounts (med genforsøg) og start IDrive-backup
#   Nas_Backup.sh sample [share] [n]   Vælg n tilfældige testfiler til en restore-test
#   Nas_Backup.sh compare [mappe]      Sammenlign gendannede filer med originalerne
#
# Restore-test: 'sample' -> læg stierne i IDrive (7 Edit restore set) ->
#               IDrive (8 Restore now) -> 'compare'.
#
# Exit-koder: 0 = OK, 1 = fejl/afvigelse, 2 = sprunget over (mounts ikke OK)
#
# UVERIFICERET: kommandoen i IDRIVE_BACKUP_CMD. Ret den efter 'idrive -h'.

set -uo pipefail

# ── Konfiguration ───────────────────────────────────────────────────────────
MOUNT_SCRIPT="$HOME/scripts/Nas_Mount.sh"
MOUNT_BASE="/mnt/nas"
IDRIVE_SHARES=(DashCam Dragic NetBackup)   # Skal svare til IDrives backup-sæt (menu 1) – styrer det ikke
IDRIVE_BIN="/opt/IDriveForLinux/bin/idrive"
IDRIVE_BACKUP_CMD=("$IDRIVE_BIN" --backup)   # UVERIFICERET – se 'idrive -h'
STATE_DIR="$HOME/nas-backup"   # Log, lås og liste over testfiler
RESTORE_DIR="$HOME/restore-test"
SAMPLE_COUNT=3                 # Antal testfiler pr. restore-test
SAMPLE_MIN_AGE_MIN=1440        # Kun filer, der ikke er ændret det seneste døgn
MOUNT_RETRIES=3                # Forsøg på at få mounts op, før 'run' giver op
RETRY_WAIT=60                  # Sekunder mellem forsøg
TIMEOUT=20                     # Sekunder til mount- og svar-tjek
IDRIVE_PROGRESS_WAIT=6         # Sekunder 'idrive -j' får til at tegne fremdriften
# ────────────────────────────────────────────────────────────────────────────

MOUNT_BASE="${MOUNT_BASE%/}"
LOG="$STATE_DIR/nas-backup.log"
SAMPLE_FILE="$STATE_DIR/sample.txt"
PROG="$(basename -- "$0")"

die() { echo "FEJL: $*" >&2; exit 1; }

log() {
  local line
  line="$(date '+%F %T') $*"
  echo "$line"
  echo "$line" >> "$LOG" 2>/dev/null || true
}

usage() {
  cat <<EOF
Brug: $PROG {status|run|sample|compare}

  status               Samlet status: mounts, IDrive, Jottacloud
  run                  Tjek mounts og start IDrive-backup af: ${IDRIVE_SHARES[*]}
  sample [share] [n]   Vælg n tilfældige testfiler (standard: ${IDRIVE_SHARES[0]}, $SAMPLE_COUNT)
  compare [mappe]      Sammenlign gendannede filer med originalerne (standard: $RESTORE_DIR)
EOF
}

# Et share er OK, når adgang udløser automount, og der ligger et read-only
# cifs-mount på mappen. Låste tomme mapper (000) og hængende mounts fejler.
check_share() {
  local mp="$MOUNT_BASE/$1"
  timeout -k 2 "$TIMEOUT" stat -t -- "$mp/." >/dev/null 2>&1 || return 1
  findmnt -rn -M "$mp" -t cifs -O ro >/dev/null 2>&1
}

wait_for_share() {
  local share=$1 i
  for (( i = 1; i <= MOUNT_RETRIES; i++ )); do
    if check_share "$share"; then return 0; fi
    if (( i < MOUNT_RETRIES )); then
      log "[$share] ikke klar (forsøg $i/$MOUNT_RETRIES) – venter ${RETRY_WAIT}s"
      sleep "$RETRY_WAIT"
    fi
  done
  return 1
}

# IDrive-processer fra installationsmappen, undtagen de faste baggrundstjenester
# (--utilities, --cdp-*, dashboard), så kun egentlige job vises i status.
# Dashboard kører som '.../python/dashboard start' – derfor også '/dashboard'.
IDRIVE_SVC_RE='--(utilities|cdp-|dashboard)|/dashboard( |$)'

idrive_procs() {
  pgrep -af "^${IDRIVE_BIN%/bin/*}/" 2>/dev/null \
    | grep -vE -- "$IDRIVE_SVC_RE" | cut -c1-110 | head -n 5
}

idrive_services() {
  pgrep -af "^${IDRIVE_BIN%/bin/*}/" 2>/dev/null | grep -cE -- "$IDRIVE_SVC_RE"
}

# Fremdrift fra 'idrive -j'. Den er interaktiv, så den får IDRIVE_PROGRESS_WAIT
# sekunder til at tegne og bliver så stoppet. Skærmkoder fjernes, og for hvert
# felt bruges den seneste værdi, fordi skærmen tegnes flere gange.
# Afhænger af IDrives engelske labels – giver tomme felter, hvis layoutet ændres.
idrive_progress() {
  local raw cur pct amount warn line
  raw="$(timeout -k 2 "$IDRIVE_PROGRESS_WAIT" "$IDRIVE_BIN" -j </dev/null 2>/dev/null \
        | sed -E 's/\x1B\[[0-9;?]*[A-Za-z]//g; s/\x1B[78]//g; s/\x1B[()][A-Z0-9]//g' \
        | tr '\r' '\n')"

  if ! grep -q 'Files count' <<<"$raw"; then
    echo "  (ingen fremdrift fra 'idrive -j' – kør den manuelt)"
    return 1
  fi

  # Værdi efter "Label : " frem til dobbelt mellemrum eller linjeslut
  _idrive_field() {
    grep -oE "$1 *: [^ ]+( [^ ]+)*" <<<"$raw" | tail -n 1 | sed -E "s/^$1 *: //"
  }

  cur="$(grep -E '^\[[A-Za-z ]*[Bb]ackup\] \[' <<<"$raw" | tail -n 1 \
         | sed -E 's/^\[([^]]*)\] \[(.*)\] \[([^]]*)\]$/\1 (\3): \2/')"
  pct="$(grep -oE '^ *[0-9]{1,3}% ' <<<"$raw" | tail -n 1 | tr -d ' ')"
  amount="$(grep -E '^ *\[[^]]+ of [^]]+\] \[[^]]+\]' <<<"$raw" | tail -n 1 | sed -E 's/^ +//')"
  warn="$(grep -E '^\* ' <<<"$raw" | sort -u)"

  echo "  Status:      $(_idrive_field 'Status' | sed -E 's/ \(Enter.*//')"
  echo "  Fremdrift:   ${pct:-?}  ${amount}"
  echo "  Tid tilbage: $(_idrive_field 'Time left')"
  echo "  Filer:       $(_idrive_field 'Files count')   (C=færdige, M=mangler, R=resterende)"
  echo "  Konto:       $(_idrive_field 'Storage used')"
  # Lange stier forkortes forfra, så filnavnet bevares
  if (( ${#cur} > 150 )); then cur="${cur%%: *}: …${cur: -120}"; fi
  if [[ -n $cur ]]; then echo "  Nu:          $cur"; fi
  if [[ -n $warn ]]; then
    echo "  ADVARSEL fra IDrive:"
    while IFS= read -r line; do echo "    $line"; done <<<"$warn"
  fi
  return 0
}

# ── status ──────────────────────────────────────────────────────────────────
cmd_status() {
  local rc=0 last

  echo "== Status $(date '+%F %T')"
  echo
  echo "== Mounts"
  if [[ -r $MOUNT_SCRIPT ]]; then
    bash "$MOUNT_SCRIPT" status || rc=$?
  else
    echo "($MOUNT_SCRIPT findes ikke – tjekker selv)"
    local share
    for share in "${IDRIVE_SHARES[@]}"; do
      if check_share "$share"; then echo "$share: OK"; else echo "$share: IKKE OK"; rc=1; fi
    done
  fi

  echo
  echo "== IDrive"
  if [[ ! -x $IDRIVE_BIN ]]; then
    echo "Ikke installeret ($IDRIVE_BIN)"
  else
    echo "Backup-sæt (ifølge scriptet): ${IDRIVE_SHARES[*]}"
    local procs line nsvc
    procs="$(idrive_procs)"
    nsvc="$(idrive_services || true)"
    if [[ -n $procs ]]; then
      echo "Job kører:"
      while IFS= read -r line; do echo "  $line"; done <<<"$procs"
      echo
      echo "Fremdrift (idrive -j):"
      idrive_progress || true
      echo
    else
      echo "Job:        intet kører lige nu"
    fi
    echo "Tjenester:  ${nsvc:-0} IDrive-baggrundstjenester kører (tidsplan m.m.)"
    last="$(grep -E ' run: ' "$LOG" 2>/dev/null | tail -n 1)"
    echo "Seneste run fra dette script: ${last:-ingen}"
    echo "IDrives egen historik (også tidsplan): idrive -l"
  fi

  echo
  echo "== Jottacloud"
  if command -v jotta-cli >/dev/null 2>&1; then
    # "Sync is not enabled" er korrekt: Jotta bruges som backup (spejl), ikke som Sync
    timeout 20 jotta-cli status 2>&1 \
      | sed 's/^ *Sync is not enabled.*/ Sync      : slået fra (korrekt – Jotta bruges som backup, ikke Sync)/' \
      || echo "jottad svarer ikke (start: run_jottad)"
  else
    echo "jotta-cli er ikke installeret"
  fi

  return "$rc"
}

# ── run ─────────────────────────────────────────────────────────────────────
cmd_run() {
  local share rc

  [[ -x $IDRIVE_BIN ]] || die "IDrive er ikke installeret ($IDRIVE_BIN)."
  mkdir -p -- "$STATE_DIR"

  # Kun én kørsel ad gangen
  exec 9>"$STATE_DIR/run.lock"
  if ! flock -n 9; then
    log "run: springer over – en kørsel er allerede i gang"
    return 0
  fi

  for share in "${IDRIVE_SHARES[@]}"; do
    if ! wait_for_share "$share"; then
      log "run: SPRUNGET OVER – $share er ikke monteret read-only efter $MOUNT_RETRIES forsøg"
      return 2
    fi
  done
  log "run: mounts OK (${IDRIVE_SHARES[*]}) – starter IDrive-backup"

  "${IDRIVE_BACKUP_CMD[@]}" </dev/null >>"$LOG" 2>&1
  rc=$?
  if (( rc == 0 )); then
    log "run: IDrive-backup afsluttet OK"
  else
    log "run: IDrive-backup FEJLEDE (exit $rc) – se $LOG og '$IDRIVE_BIN -l'"
    return 1
  fi
}

# ── sample ──────────────────────────────────────────────────────────────────
cmd_sample() {
  local share="${1:-${IDRIVE_SHARES[0]}}" n="${2:-$SAMPLE_COUNT}" src count

  [[ $n =~ ^[1-9][0-9]*$ ]] || die "Antal skal være et helt tal, fx 3."
  src="$MOUNT_BASE/$share"
  check_share "$share" || die "$src er ikke monteret read-only. Tjek: bash $MOUNT_SCRIPT status"
  mkdir -p -- "$STATE_DIR"

  echo "Vælger $n tilfældige filer i $src (uændret det seneste døgn) – kan tage tid over SMB ..."
  find "$src" -type f \
       -not -path '*/#recycle/*' -not -path '*/@eaDir/*' \
       -mmin +"$SAMPLE_MIN_AGE_MIN" -print0 2>/dev/null \
    | shuf -z -n "$n" | tr '\0' '\n' > "$SAMPLE_FILE"

  count=$(grep -c . "$SAMPLE_FILE" || true)
  (( count > 0 )) || die "Fandt ingen egnede filer i $src."

  echo
  echo "Testfiler (gemt i $SAMPLE_FILE):"
  cat "$SAMPLE_FILE"
  cat <<EOF

Næste skridt:
  1. idrive -> 7) Edit restore set: indsæt stierne ovenfor (én pr. linje) og gem
  2. idrive -> 8) Restore now  (restore location: $RESTORE_DIR)
  3. bash $PROG compare
EOF
}

# Finder den gendannede kopi af $1 under $2. IDrive kan lægge filen med fuld
# sti, med sti relativt til MOUNT_BASE eller kun med filnavnet.
find_restored() {
  local f=$1 dir=$2 rel base c match="" n=0
  rel="${f#"$MOUNT_BASE"/}"
  base="$(basename -- "$f")"

  for c in "$dir$f" "$dir/$rel" "$dir/$base"; do
    if [[ -f $c ]]; then printf '%s' "$c"; return 0; fi
  done

  while IFS= read -r -d '' c; do
    n=$(( n + 1 ))
    if [[ $c == *"/$rel" ]]; then match=$c; break; fi
    match=$c
  done < <(find "$dir" -type f -name "$base" -print0 2>/dev/null)

  if [[ -n $match && ( $match == *"/$rel" || $n -eq 1 ) ]]; then
    printf '%s' "$match"
    return 0
  fi
  return 1
}

# ── compare ─────────────────────────────────────────────────────────────────
cmd_compare() {
  local dir="${1:-$RESTORE_DIR}" f r ok=0 bad=0 miss=0 a b

  [[ -s $SAMPLE_FILE ]] || die "Ingen testfiler. Kør først: $PROG sample"
  [[ -d $dir ]] || die "Restore-mappen $dir findes ikke."

  echo "Sammenligner med gendannede filer i $dir (sha256) ..."
  echo
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    if ! r="$(find_restored "$f" "$dir")"; then
      echo "MANGLER  $f"
      miss=$(( miss + 1 ))
      continue
    fi
    if [[ $(stat -c %s -- "$f") != $(stat -c %s -- "$r") ]]; then
      echo "FORSKEL  $f  (størrelse)"
      bad=$(( bad + 1 ))
      continue
    fi
    a="$(sha256sum < "$f" | cut -d' ' -f1)"
    b="$(sha256sum < "$r" | cut -d' ' -f1)"
    if [[ $a == "$b" ]]; then
      echo "OK       $f"
      ok=$(( ok + 1 ))
    else
      echo "FORSKEL  $f  (sha256)"
      bad=$(( bad + 1 ))
    fi
  done < "$SAMPLE_FILE"

  echo
  mkdir -p -- "$STATE_DIR"
  log "compare: $ok OK, $bad forskellige, $miss mangler (restore-mappe: $dir)"
  if (( bad == 0 && miss == 0 )); then
    echo "Restore-testen bestod."
    return 0
  fi
  echo "Restore-testen bestod IKKE."
  return 1
}

# ── main ────────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-}"
  shift || true
  # Med sudo bliver $HOME /root – forkert STATE_DIR, MOUNT_SCRIPT og IDrive-profil
  [[ $EUID -ne 0 ]] || die "Kør som misc, ikke med sudo – IDrive-profilen og \$HOME skal være misc's."
  case $cmd in
    status)          cmd_status ;;
    run)             cmd_run ;;
    sample)          cmd_sample "$@" ;;
    compare)         cmd_compare "$@" ;;
    -h|--help|help)  usage ;;
    *)               usage >&2; exit 1 ;;
  esac
}

main "$@"
