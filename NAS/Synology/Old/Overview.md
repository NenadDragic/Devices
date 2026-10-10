# Old Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

This `Old` subfolder holds Synology NAS Task Scheduler scripts that are no longer in use. Most were replaced by the combined jobs in the parent [`Synology`](../Overview.md) folder (`Oprydning - Find.sh`, `Oprydning - Delete.sh`, `Oprydning - DashCam.sh` and `Backup USB Disk.sh`); the rest are simply no longer scheduled.

---

## Backup & Copy

Replaced by `Backup USB Disk.sh`.

| Script | Doc | Summary |
| --- | --- | --- |
| `Copy USB - Devices.sh` | [Copy USB - Devices.md](Copy%20USB%20-%20Devices.md) | Copies all files from a USB drive to `/volume1/NetBackup/`, removing source files after transfer, then cleans up empty directories and the source share. |
| `Copy USB - Log.sh` | [Copy USB - Log.md](Copy%20USB%20-%20Log.md) | Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then deletes the source directory. |

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
| `Bak files - Find.sh` | [Bak files - Find.md](Bak%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that are named `*.bak`. |
| `Bak files - Delete.sh` | [Bak files - Delete.md](Bak%20files%20-%20Delete.md) | Deletes all files in the `/volume1/Dragic` directory that end with the `.bak` extension. |
| `TMP files - Find.sh` | [TMP files - Find.md](TMP%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that end with the `.tmp` extension. |
| `TMP files - Delete.sh` | [TMP files - Delete.md](TMP%20files%20-%20Delete.md) | Deletes all files in the `/volume1/Dragic` directory that end with the `.tmp` extension. |
| `Thumbs.db files - Find.sh` | [Thumbs.db files - Find.md](Thumbs.db%20files%20-%20Find.md) | Finds all `Thumbs.db` files under `/volume1/Dragic` (Windows thumbnail cache files often left behind on network shares). |
| `Thumbs.db files - Delete.sh` | [Thumbs.db files - Delete.md](Thumbs.db%20files%20-%20Delete.md) | Deletes all `Thumbs.db` files under `/volume1/Dragic`. |
| `Tilde files - Find.sh` | [Tilde files - Find.md](Tilde%20files%20-%20Find.md) | Finds all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Tilde files - Delete.sh` | [Tilde files - Delete.md](Tilde%20files%20-%20Delete.md) | Deletes all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Two or more spaces in filename - Find.sh` | [Two or more spaces in filename - Find.md](Two%20or%20more%20spaces%20in%20filename%20-%20Find.md) | Finds all files under `/volume1/Dragic` that have two or more consecutive spaces in their names. |
| `Two or more spaces in filename - Delete.sh` | [Two or more spaces in filename - Delete.md](Two%20or%20more%20spaces%20in%20filename%20-%20Delete.md) | Finds files with two or more consecutive spaces in their names and renames them to collapse the double spaces to one — despite the "Delete" name, it renames rather than deletes. |

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

- **Root:** these were DSM Task Scheduler scripts, where the user is chosen per task. `Copy USB - Devices.sh`, `Copy USB - Log.sh` and `Reboot.sh` call `sudo` themselves; none of the scripts has its own root check.
- **Destructive/irreversible scripts:** the `-delete` find operations (`Bak files - Delete.sh`, `TMP files - Delete.sh`, `Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`), `Delete FTP DashCam 30 over days.sh`, the two `Copy USB` scripts (remove the source after copying) and `Reboot.sh`.
- **Secret in git:** `DDNS - Simply.sh` has a Simply.com API key in clear text in its URL. It is in git history and should be treated as exposed.
- The two DDNS scripts are not interchangeable: one calls the Simply.com DDNS API, the other a cPanel webcall on `dragic.com`.
