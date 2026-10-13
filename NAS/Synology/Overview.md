# Synology Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas. These are Synology NAS Task Scheduler scripts.

---

## Backup & Copy

| Script | Doc | Summary |
| --- | --- | --- |
| `USB_Copy_Clean_Delete.sh` | [USB_Copy_Clean_Delete.md](USB_Copy_Clean_Delete.md) | Wrapper for the DSM task: sets `MODE`, `KEEP=3`, `LOG_DAYS=0`, `NOPRUNE` and calls `/volume1/root-scripts/USB_Copy_Clean_Delete.sh` (documented in the `Linux-Scripts` repo). Holds a `Dryrun` block and a `Run` block - run as-is, it does both back-to-back. |
| `Hent - GPS-logs.sh` | [Hent - GPS-logs.md](Hent%20-%20GPS-logs.md) | Fetches the GPS monitor logs from `10.0.0.149` with `rsync` (new and changed files only), lists the fetched files and the CSV folder. Exits 1 on error. Replaces `Copy GPS log files.sh` (now in `Old/`). |
| `Hent - Loppe.sh` | [Hent - Loppe.md](Hent%20-%20Loppe.md) | Fetches the `Loppe` folder from `10.0.0.215` with `rsync` (new and changed files only), then prints `status.txt` and the fetched files. Exits 1 on error. Replaces `Loppe files Copy.sh` and `Loppe Status.sh` (both in `Old/`). |

## Cleanup: Combined jobs

| Script | Doc | Summary |
| --- | --- | --- |
| `Oprydning - Find.sh` | [Oprydning - Find.md](Oprydning%20-%20Find.md) | One scan of `/volume1/Dragic` that reports `.bak`, `.tmp`, `Thumbs.db`, `~` files, CORRUPT/INVALID files and names with double spaces. Replaces the separate Find scripts, now in `Old/`. |
| `Oprydning - Delete.sh` | [Oprydning - Delete.md](Oprydning%20-%20Delete.md) | Same script as `Oprydning - Find.sh` but with `MODE=clean`: deletes `.bak`, `.tmp`, `Thumbs.db` and `~` files older than 24 hours and collapses double spaces in names (regardless of age). Replaces the separate Delete scripts, now in `Old/`. |
| `Oprydning - DashCam.sh` | [Oprydning - DashCam.md](Oprydning%20-%20DashCam.md) | Weekly DashCam job: deletes files older than 30 days, shows file counts and sizes per folder, and prints the router reports from the last 7 days. Replaces six DashCam jobs, now in `Old/`. |

---

## Notes

- **User:** the scripts are run by DSM's Task Scheduler, and the user is chosen per task there. None of the scripts has its own root check or calls `sudo`. `Oprydning - Find.sh` and `Oprydning - Delete.sh` read and change the whole `Dragic` share; `USB_Copy_Clean_Delete.sh` must run as `root` (the called script checks it). `Oprydning - DashCam.sh` runs as the user `DashCam`, and the `Hent` scripts run as `ElBosso` (they use ElBosso's SSH key).
- **Destructive/irreversible scripts:** `Oprydning - Delete.sh` (`MODE=clean`, deletes junk files with `rm` and renames names with double spaces), `Oprydning - DashCam.sh` (deletes files older than 30 days), `USB_Copy_Clean_Delete.sh` (in `Run` mode the called script removes files from the USB disk after copying and deletes old backups; as-is the file also runs `Run` right after `Dryrun`).
- **NAS and git can differ:** the NAS job `Oprydning - Delete` still had `MODE=find` in the config backup of 2026-10-06 - update it there as well. `nas-dss-check.sh` in the `Linux-Scripts` repository compares a DSM export with this folder.
- **`Old/`:** scripts that are no longer scheduled, or that were replaced by the jobs above, live in [Old/](Old/) and are indexed in [Old/Overview.md](Old/Overview.md).
