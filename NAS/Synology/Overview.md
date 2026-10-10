# Synology Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas. These are Synology NAS Task Scheduler scripts.

---

## Backup & Copy

| Script | Doc | Summary |
| --- | --- | --- |
| `Backup USB Disk.sh` | [Backup USB Disk.md](Backup%20USB%20Disk.md) | Moves every top-level folder from the USB drive to `/volume1/NetBackup/`: copies first, deletes from USB only files that are identical in NetBackup, then reports anything left behind. Replaces the two `Copy USB` scripts, now in `Old/`. |
| `Copy GPS log files.sh` | [Copy GPS log files.md](Copy%20GPS%20log%20files.md) | Copies GPS monitor CSV logs from a remote host to the NAS, then lists the destination contents. |
| `Loppe files Copy.sh` | [Loppe files Copy.md](Loppe%20files%20Copy.md) | Copies the `Loppe` directory from a remote host to the NAS, then lists the destination contents. |
| `Delete the oldest backups - Count 3.sh` | [Delete the oldest backups - Count 3.md](Delete%20the%20oldest%20backups%20-%20Count%203.md) | Loops through a list of backup folders and deletes all subdirectories except the 3 newest in each. |

## Disk & File Counting

| Script | Doc | Summary |
| --- | --- | --- |
| `Disk Used size - Dragic.sh` | [Disk Used size - Dragic.md](Disk%20Used%20size%20-%20Dragic.md) | Shows disk usage for `/volume1/Dragic/` up to 1 directory level deep, then prints the total. |
| `Disk Used size - NetBackup.sh` | [Disk Used size - NetBackup.md](Disk%20Used%20size%20-%20NetBackup.md) | Shows disk usage for `/volume1/NetBackup/` up to 2 directory levels deep, then prints the total. |

## Cleanup: Combined jobs

| Script | Doc | Summary |
| --- | --- | --- |
| `Oprydning - Find.sh` | [Oprydning - Find.md](Oprydning%20-%20Find.md) | One scan of `/volume1/Dragic` that reports `.bak`, `.tmp`, `Thumbs.db`, `~` files, CORRUPT/INVALID files and names with double spaces. Replaces the separate Find scripts, now in `Old/`. |
| `Oprydning - Delete.sh` | [Oprydning - Delete.md](Oprydning%20-%20Delete.md) | Same script as `Oprydning - Find.sh` but with `MODE=clean`: deletes `.bak`, `.tmp`, `Thumbs.db` and `~` files older than 24 hours and collapses double spaces in names. Replaces the separate Delete scripts, now in `Old/`. |
| `Oprydning - DashCam.sh` | [Oprydning - DashCam.md](Oprydning%20-%20DashCam.md) | Weekly DashCam job: deletes recordings older than 30 days, shows file counts and sizes per folder, and prints the router reports from the last 7 days. Replaces six DashCam jobs, now in `Old/`. |

## Status/Monitoring

| Script | Doc | Summary |
| --- | --- | --- |
| `Loppe Status.sh` | [Loppe Status.md](Loppe%20Status.md) | Prints the contents of the Loppe status file to the terminal. |
| `DNSSEC - StatusFile.sh` | [DNSSEC - StatusFile.md](DNSSEC%20-%20StatusFile.md) | Copies DNSSEC/DNS health-check report files from a remote host to the NAS, displays today's dated report via `more`, then deletes the local copy of that report. |
| `Web-Stat.sh` | [Web-Stat.md](Web-Stat.md) | Copies web status HTML reports from a remote host to `/volume1/Dragic/Rap/Web_Status/`. |

---

## Notes

- **Root:** the scripts are run by DSM's Task Scheduler, and the user is chosen per task there. None of the scripts has its own root check or calls `sudo`; the ones that delete, or that read every share, are meant to run as `root`.
- **Destructive/irreversible scripts:** `Oprydning - Delete.sh` (`MODE=clean`, deletes junk files with `rm` and renames names with double spaces), `Oprydning - DashCam.sh` (deletes recordings older than 30 days), `Backup USB Disk.sh` (`--remove-source-files` on the USB drive), `Delete the oldest backups - Count 3.sh` (keeps only the 3 newest subfolders per backup folder), and `DNSSEC - StatusFile.sh`, which deletes its own local copy of today's report after displaying it (the report is copied again from the remote host on the next run).
- **NAS and git can differ:** the NAS job `Oprydning - Delete` still had `MODE=find` in the config backup of 2026-10-06 - update it there as well. `nas-dss-check.sh` in the `Linux-Scripts` repository compares a DSM export with this folder.
- **`Old/`:** scripts that are no longer scheduled, or that were replaced by the combined jobs above, live in [Old/](Old/) and are indexed in [Old/Overview.md](Old/Overview.md).
