# Router Home Backup - Backup.sh

This script rsyncs the router's home directory to a date-stamped folder on the NAS backup share.

## How it works

Before anything else, the script sources the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `sudo`, `sshpass`, `rsync`, `ssh`. It also stops if `lib/require_tools.sh` itself is not found.

1. Creates a named pipe (`mkfifo`) at `/tmp/pw_pipe` to pass the NAS password to `sshpass` without exposing it as a plain argument.
2. Streams the password file content into the pipe in the background.
3. Runs `rsync -av` over SSH (as user `Debian_Backup`) to copy the home directory (`~`) to the NAS module `NetBackup/Muddi-E750/<today's date>`.
4. Removes the named pipe afterwards.

## Usage

Intended to run periodically (e.g. via cron) on the GL.iNet router to back up its home directory to the NAS.

```shell
#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools sudo sshpass rsync "ssh:openssh-client"

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe &
sudo sshpass -f /tmp/pw_pipe sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/Muddi-E750/$(date +%Y-%m-%d)

rm /tmp/pw_pipe

#Exit
exit
```
