# Nas_Backup

Backs up NAS shares from the Ubuntu server `misc` to two cloud services, and helps run a restore test:

- **IDrive:** archive. Deleted files stay in the backup. Started by `run`.
- **Jottacloud:** mirror. `jottad` runs continuously by itself; this script only shows its status.

The shares are mounted read-only under `/mnt/nas` by [`Nas_Mount.sh`](Nas_Mount.md).

---

## Usage

Run as the user `misc` (the same user as the IDrive profile), **not with `sudo`**:

```bash
Nas_Backup.sh status               # mounts, IDrive (incl. progress) and Jottacloud
Nas_Backup.sh run                  # check mounts (with retries) and start the IDrive backup
Nas_Backup.sh sample [share] [n]   # pick n random test files for a restore test
Nas_Backup.sh compare [folder]     # compare restored files with the originals
```

Restore test: `sample` → paste the paths in IDrive (*7 Edit restore set*) → IDrive (*8 Restore now*, restore location `~/restore-test`) → `compare`.

Prerequisites:

- **No sudo** (checked). The script uses `$HOME` for its state, for `Nas_Mount.sh` and for the IDrive profile; with `sudo`, `$HOME` becomes `/root` on Ubuntu and IDrive would run with root's profile.
- **IDrive for Linux** installed in `/opt/IDriveForLinux` and configured for `misc`. Needed for `run`; `status` reports it as not installed if missing.
- **`jotta-cli`** (Jottacloud CLI, from Jottacloud's own apt repository) with `jottad` running. Optional; only used by `status`.
- `Nas_Mount.sh` at `~/scripts/Nas_Mount.sh` and the shares in `/etc/fstab`.
- `flock`, `findmnt` (`util-linux`), `pgrep` (`procps`), `shuf`, `timeout` (`coreutils`) – all part of a normal Ubuntu install.

### Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `MOUNT_SCRIPT` | `$HOME/scripts/Nas_Mount.sh` | Used by `status` |
| `MOUNT_BASE` | `/mnt/nas` | Where the shares are mounted |
| `IDRIVE_SHARES` | `DashCam Dragic NetBackup` | Shares checked before `run`. Must match IDrive's backup set (menu 1); it does not control it. |
| `IDRIVE_BIN` | `/opt/IDriveForLinux/bin/idrive` | IDrive program |
| `IDRIVE_BACKUP_CMD` | `idrive --backup` | **Unverified** – check against `idrive -h` |
| `STATE_DIR` | `$HOME/nas-backup` | Log (`nas-backup.log`), lock file and `sample.txt` |
| `RESTORE_DIR` | `$HOME/restore-test` | Default folder for `compare` |
| `SAMPLE_COUNT` | `3` | Test files per restore test |
| `SAMPLE_MIN_AGE_MIN` | `1440` | Only files not changed in the last 24 hours |
| `MOUNT_RETRIES` / `RETRY_WAIT` | `3` / `60` | Attempts and seconds between them before `run` gives up |
| `TIMEOUT` | `20` | Seconds for mount and response checks |
| `IDRIVE_PROGRESS_WAIT` | `6` | Seconds `idrive -j` gets to draw its progress screen |

---

## What the Script Does

### `status`

1. **Mounts:** runs `Nas_Mount.sh status`, or checks the shares itself if that script is missing.
2. **IDrive:** lists running IDrive jobs (background services like the scheduler and dashboard are counted, not listed). While a job runs, it captures `idrive -j` for a few seconds and shows status, percentage, time left, file counts, storage used and the current file. Also shows the last `run` from this script's log.
3. **Jottacloud:** `jotta-cli status`. The line "Sync is not enabled" is rewritten as correct, because Jottacloud is used as backup, not Sync.

### `run`

Takes a lock (`flock`) so only one run happens at a time; a second run is logged and skipped. Waits until every share in `IDRIVE_SHARES` is mounted read-only as `cifs` (up to `MOUNT_RETRIES` tries). If one is not, it skips the backup with exit code `2`, so IDrive never backs up an empty or locked folder. Then runs `IDRIVE_BACKUP_CMD` with its output appended to the log.

### `sample [share] [n]`

Picks `n` random files from the share (default the first in `IDRIVE_SHARES`), skipping `#recycle`, `@eaDir` and files changed in the last 24 hours. Saves the paths in `sample.txt` and prints the next steps in IDrive.

### `compare [folder]`

For each path in `sample.txt`, finds the restored copy in the folder (IDrive may restore with the full path, the path relative to `/mnt/nas`, or only the file name), then compares size and sha256 with the original on the mount. Prints `OK`, `FORSKEL` or `MANGLER` per file and logs a summary.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | OK |
| `1` | Error or difference (run as root, missing IDrive, IDrive failed, restore test failed, wrong arguments) |
| `2` | `run` skipped because the mounts were not OK. `status` can also return `2` from `Nas_Mount.sh status`. |

---

## Notes

- **Verify `IDRIVE_BACKUP_CMD` before relying on `run`.** The `--backup` option is marked unverified in the script.
- The progress display depends on IDrive's English screen labels. If IDrive changes the layout, the fields come out empty.
- `sample` runs `find` over SMB and can take a long time on a big share.
- Comments and console output are in Danish.
