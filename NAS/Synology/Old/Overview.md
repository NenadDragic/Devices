# Old Scripts Overview

An index of the scripts in this folder and their documentation. Each script listed below has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

This `Old` subfolder holds Synology NAS Task Scheduler scripts that are no longer in use. Most were replaced by jobs in the parent [`Synology`](../Overview.md) folder (`Oprydning - Find.sh`, `Oprydning - Delete.sh`, `Oprydning - DashCam.sh`, `Hent - Loppe.sh` and `Hent - GPS-logs.sh`); the rest are simply no longer scheduled.

---

## Backup & Copy

`Copy USB - Devices.sh` and `Copy USB - Log.sh` were replaced by `Backup USB Disk.sh`, which is itself no longer scheduled. `Loppe files Copy.sh` was replaced by `Hent - Loppe.sh` and `Copy GPS log files.sh` by `Hent - GPS-logs.sh`, both in the parent folder.

| Script | Doc | Summary |
| --- | --- | --- |
| `Backup USB Disk.sh` | [Backup USB Disk.md](Backup%20USB%20Disk.md) | Moves every top-level folder from the USB drive to `/volume1/NetBackup/`: copies first, deletes from USB only files that are identical in NetBackup, then reports anything left behind. |
| `Copy USB - Devices.sh` | [Copy USB - Devices.md](Copy%20USB%20-%20Devices.md) | Copies all files from a USB drive to `/volume1/NetBackup/`, removing source files after transfer, then runs an unconditional `rm -rf` on the whole USB share - files that failed to transfer are deleted too. |
| `Copy USB - Log.sh` | [Copy USB - Log.md](Copy%20USB%20-%20Log.md) | Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then runs an unconditional `rm -rf` on the source folder - files that failed to transfer are deleted too. |
| `Loppe files Copy.sh` | [Loppe files Copy.md](Loppe%20files%20Copy.md) | Copies the `Loppe` directory from a remote host to the NAS, then lists the destination contents. |
| `Copy GPS log files.sh` | [Copy GPS log files.md](Copy%20GPS%20log%20files.md) | Copies GPS monitor CSV logs from a remote host to the NAS with `scp`, then lists the destination contents. |
| `Delete the oldest backups - Count 3.sh` | [Delete the oldest backups - Count 3.md](Delete%20the%20oldest%20backups%20-%20Count%203.md) | Loops through a list of backup folders and deletes all subdirectories except the 3 newest in each. |

## Disk Usage

| Script | Doc | Summary |
| --- | --- | --- |
| `Disk Used size - Dragic.sh` | [Disk Used size - Dragic.md](Disk%20Used%20size%20-%20Dragic.md) | Shows disk usage for `/volume1/Dragic/` up to 1 directory level deep, then prints the total. |
| `Disk Used size - NetBackup.sh` | [Disk Used size - NetBackup.md](Disk%20Used%20size%20-%20NetBackup.md) | Shows disk usage for `/volume1/NetBackup/` up to 2 directory levels deep, then prints the total. |

## Status & Reports

`Loppe Status.sh` was replaced by `Hent - Loppe.sh` in the parent folder. `DNSSEC - StatusFile.sh` and `Web-Stat.sh` were replaced by `Hent - DNSSEC and Web-Stat.sh`, which is itself in this folder now.

| Script | Doc | Summary |
| --- | --- | --- |
| `Hent - DNSSEC and Web-Stat.sh` | [Hent - DNSSEC and Web-Stat.md](Hent%20-%20DNSSEC%20and%20Web-Stat.md) | Fetches the DNSSEC `.txt` reports and Web-Stat `.html` reports from `10.0.0.214` with `rsync`, prints today's DNS health-check report and deletes the NAS copy of it. Exits 1 on error or if today's report is missing. |
| `DNSSEC - StatusFile.sh` | [DNSSEC - StatusFile.md](DNSSEC%20-%20StatusFile.md) | Copies DNSSEC/DNS health-check report files from a remote host to the NAS with `scp`, displays today's dated report via `more`, then deletes the local copy of that report. |
| `Web-Stat.sh` | [Web-Stat.md](Web-Stat.md) | Copies web status HTML reports from a remote host to `/volume1/Dragic/Rap/Web_Status/` with `scp`. |
| `Loppe Status.sh` | [Loppe Status.md](Loppe%20Status.md) | Prints the contents of the Loppe status file to the terminal. |

## DashCam

Replaced by `Oprydning - DashCam.sh`.

| Script | Doc | Summary |
| --- | --- | --- |
| `Delete FTP DashCam 30 over days.sh` | [Delete FTP DashCam 30 over days.md](Delete%20FTP%20DashCam%2030%20over%20days.md) | Deletes all files in `/volume1/DashCam` that were last modified more than 30 days ago, skipping the recycle bin. |
| `Disk Used size - DashCam.sh` | [Disk Used size - DashCam.md](Disk%20Used%20size%20-%20DashCam.md) | Shows disk usage for `/volume1/DashCam/` up to 1 directory level deep, then prints the total. |
| `FileCount - Router - DashCam.sh` | [FileCount - Router - DashCam.md](FileCount%20-%20Router%20-%20DashCam.md) | Finds all files in `/volume1/DashCam/File-Count-DashCam/` modified today and displays their contents using `more`. |
| `FileCount - Router - SD.sh` | [FileCount - Router - SD.md](FileCount%20-%20Router%20-%20SD.md) | Finds all files in `/volume1/DashCam/File-Count-SD/` modified today and displays their contents. |
| `FileCount - SFTP - DashCam.sh` | [FileCount - SFTP - DashCam.md](FileCount%20-%20SFTP%20-%20DashCam.md) | Counts the number of files in each DashCam directory and prints the results to the console. |
| `FileDelete - Router - DashCam.sh` | [FileDelete - Router - DashCam.md](FileDelete%20-%20Router%20-%20DashCam.md) | Finds all files in `/volume1/DashCam/File-Delete/` modified today and displays their contents using `more` — despite the name, it does not delete anything. |

## File Cleanup: Find/Delete pairs

Replaced by `Oprydning - Find.sh` and `Oprydning - Delete.sh`.

| Script | Doc | Summary |
| --- | --- | --- |
| `bak files - Find.sh` | [bak files - Find.md](bak%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that are named `*.bak`. |
| `bak files - Delete.sh` | [bak files - Delete.md](bak%20files%20-%20Delete.md) | Deletes all files in the `/volume1/Dragic` directory that end with the `.bak` extension. |
| `tmp files - Find.sh` | [tmp files - Find.md](tmp%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that end with the `.tmp` extension. |
| `tmp files - Delete.sh` | [tmp files - Delete.md](tmp%20files%20-%20Delete.md) | Deletes all files in the `/volume2/Dragic` directory (note: `volume2`, not `volume1`) that end with the `.tmp` extension. |
| `Thumbs.db files - Find.sh` | [Thumbs.db files - Find.md](Thumbs.db%20files%20-%20Find.md) | Finds all `Thumbs.db` files under `/volume1/Dragic` (Windows thumbnail cache files often left behind on network shares). |
| `Thumbs.db files - Delete.sh` | [Thumbs.db files - Delete.md](Thumbs.db%20files%20-%20Delete.md) | Deletes all `Thumbs.db` files under `/volume1/Dragic`. |
| `Tilde files - Find.sh` | [Tilde files - Find.md](Tilde%20files%20-%20Find.md) | Finds all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Tilde files - Delete.sh` | [Tilde files - Delete.md](Tilde%20files%20-%20Delete.md) | Deletes all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Two or more spaces in filename - Find.sh` | [Two or more spaces in filename - Find.md](Two%20or%20more%20spaces%20in%20filename%20-%20Find.md) | Finds all files and folders under `/volume1/Dragic` that have two or more consecutive spaces in their names. |
| `Two or more spaces in filename - Delete.sh` | [Two or more spaces in filename - Delete.md](Two%20or%20more%20spaces%20in%20filename%20-%20Delete.md) | Finds files and folders with two or more consecutive spaces in their names and renames them, replacing each pair of spaces with one (so three spaces become two, not one) — despite the "Delete" name, it renames rather than deletes. |

## Integrity Checks

Replaced by `Oprydning - Find.sh`.

| Script | Doc | Summary |
| --- | --- | --- |
| `Find Corrup files.sh` | [Find Corrup files.md](Find%20Corrup%20files.md) | Finds all files under `/volume1/Dragic` that contain `CORRUPT` in their filename. |
| `Find Invalid files.sh` | [Find Invalid files.md](Find%20Invalid%20files.md) | Finds all files under `/volume1/Dragic` that contain `INVALID` in their filename. |

## Dynamic DNS

| Script | Doc | Summary |
| --- | --- | --- |
| `DDNS - E-Studie.sh` | [DDNS - E-Studie.md](DDNS%20-%20E-Studie.md) | Triggers a DDNS update via a cPanel webcall on `dragic.com`. |
| `DDNS - Simply.sh` | [DDNS - Simply.md](DDNS%20-%20Simply.md) | Sends a DDNS update request to the Simply.com API to update the `nas.dragic.com` subdomain with the current IP. |

## System

| Script | Doc | Summary |
| --- | --- | --- |
| `Reboot.sh` | [Reboot.md](Reboot.md) | Immediately reboots the NAS via `shutdown -r now` — irreversible, with no confirmation prompt. Not set up as a scheduled task on the NAS (config backup 2026-10-06). |

---

## Notes

- **Root:** these were DSM Task Scheduler scripts, where the user is chosen per task. `Copy USB - Devices.sh`, `Copy USB - Log.sh` and `Reboot.sh` call `sudo` themselves; none of the scripts has its own root check. The `Hent` script and the scripts it replaced ran as `ElBosso` with ElBosso's SSH key.
- **Destructive/irreversible scripts:** the `-delete` find operations (`bak files - Delete.sh`, `tmp files - Delete.sh`, `Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`), `Two or more spaces in filename - Delete.sh` (renames), `Delete FTP DashCam 30 over days.sh`, `Delete the oldest backups - Count 3.sh` (`rm -rf` of all but the 3 newest subfolders), `Backup USB Disk.sh` (`--remove-source-files` on the USB drive), the two `Copy USB` scripts (remove the source after copying, then `rm -rf` it), `Hent - DNSSEC and Web-Stat.sh` and `DNSSEC - StatusFile.sh` (delete the NAS copy of today's report after displaying it) and `Reboot.sh`.
- **Secret in git:** `DDNS - Simply.sh` has a Simply.com API key in clear text in its URL. It is in git history and should be treated as exposed.
- The two DDNS scripts are not interchangeable: one calls the Simply.com DDNS API, the other a cPanel webcall on `dragic.com`.
