# root-scripts Overview

The scripts in this folder are stored as files in `/volume1/root-scripts/` on the NAS. They are not pasted into DSM tasks themselves; DSM tasks in the parent [`Synology`](../Overview.md) folder set the parameters and call them. Each script has a matching `.md` file (same base name).

---

| Script | Doc | Called by | Summary |
| --- | --- | --- | --- |
| `Oprydning.sh` | [Oprydning.md](Oprydning.md) | `Oprydning - Find.sh` (`MODE=find`), `Oprydning - Delete.sh` (`MODE=clean`) | One scan of `/volume1/Dragic`: `find` reports `.bak`, `.tmp`, `Thumbs.db`, `~`, CORRUPT/INVALID files, double-space names and disk usage per folder; `clean` deletes the junk files (older than 24 hours) and collapses double spaces. Defaults to `find`. |
| `USB_Copy_Clean_Delete.sh` | [USB_Copy_Clean_Delete.md](USB_Copy_Clean_Delete.md) | `USB_Copy_Clean_Delete.sh` (`MODE=Dryrun` / `Run`) | Moves all folders from the USB disk to `/volume1/NetBackup`, keeps the `KEEP` newest backups per folder after testing the newest, optionally deletes old logs, and reports disk usage. Defaults to `Dryrun`. |

---

## Notes

- **Safe defaults:** both scripts default to their non-destructive mode (`find` / `Dryrun`) when the DSM task does not set `MODE`.
- **Run as root:** `USB_Copy_Clean_Delete.sh` checks it and exits with code `2` otherwise. `Oprydning.sh` has no check, but `clean` needs write access to the whole `Dragic` share.
- **Copy in Linux-Scripts:** `USB_Copy_Clean_Delete.sh` is also in the `Linux-Scripts` repository (`Synology/`), currently identical (v2.5). Keep the two in sync.
- **Deploying:** after changing a script here, copy it to `/volume1/root-scripts/` on the NAS - the DSM tasks run the copy on the NAS, not the one in git.
