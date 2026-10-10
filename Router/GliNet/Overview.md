# GliNet Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing how it works, with a copy of the script itself. These are the scripts in use on the GL.iNet (OpenWrt) travel router that collects DashCam files and sends them to the NAS.

---

## DashCam Download

| Script | Doc | Summary |
| --- | --- | --- |
| `DashCam-Router-Movie-RO.sh` | [DashCam-Router-Movie-RO.md](DashCam-Router-Movie-RO.md) | Downloads new "RO" (protected/locked) DashCam video files from the DashCam's web-exposed `/DCIM/Movie/RO` folder to local storage, using a PID file to prevent overlapping runs. |
| `DashCam-Router-Pictures.sh` | [DashCam-Router-Pictures.md](DashCam-Router-Pictures.md) | Downloads new photo files from the DashCam's web-exposed `/DCIM/Photo` folder to local storage, using a PID file to prevent overlapping runs. |

## Upload to NAS

| Script | Doc | Summary |
| --- | --- | --- |
| `Router-NAS-Movie-RO.sh` | [Router-NAS-Movie-RO.md](Router-NAS-Movie-RO.md) | Rsyncs the locally stored "RO" DashCam video files from the router's SD card to the NAS backup share. |
| `Router-NAS-Pictures.sh` | [Router-NAS-Pictures.md](Router-NAS-Pictures.md) | Rsyncs the locally stored DashCam photos from the router's SD card to the NAS backup share. |
| `Backup.sh` | [Backup.md](Backup.md) | Rsyncs the router's home directory to a date-stamped folder on the NAS backup share. |

## Counting, Reporting & Cleanup

| Script | Doc | Summary |
| --- | --- | --- |
| `File-Count-SSH-Upload.sh` | [File-Count-SSH-Upload.md](File-Count-SSH-Upload.md) | The router's daily orchestration script: runs the SD card and DashCam file-count scripts and the old-file cleanup script, logs their output to daily text files, then uploads the log folders to the NAS over SSH. |
| `Count_Files_SD.sh` | [Count_Files_SD.md](Count_Files_SD.md) | Prints a status report for the router's SD card: photo/video counts by folder, disk usage, and the `wwan0` interface's IP address. |
| `Count_Files_DashCam.sh` | [Count_Files_DashCam.md](Count_Files_DashCam.md) | Queries the DashCam's web file listing over HTTP and prints a count of photos and videos in each folder. |
| `Delete_10Days_Old_Files.sh` | [Delete_10Days_Old_Files.md](Delete_10Days_Old_Files.md) | Cleans up old files on the router's SD card and log folders: raw SD card files older than 10 days, and DashCam/log files older than 30 days. |

## Subfolders

| Folder | Overview | What's there |
| --- | --- | --- |
| `System` | [Overview](System/Overview.md) | Package installation/update via `opkg` and crontab backup. |
| `NotInUse` | [Overview](NotInUse/Overview.md) | Working variants that are not wired into the active pipeline. |
| `Old` | [Overview](Old/Overview.md) | Deprecated or duplicate earlier versions, kept for reference. |

---

## Notes

- **Root:** the scripts run as `root` on the router, normally from cron (see `System/crontab.txt`). None has its own root check. `Backup.sh`, `File-Count-SSH-Upload.sh`, `Router-NAS-Movie-RO.sh` and `Router-NAS-Pictures.sh` call `sudo` for `sshpass`/`rsync`.
- **Dependency check:** every script except `Delete_10Days_Old_Files.sh` starts by sourcing the shared `lib/require_tools.sh`, found by walking up from the script's own folder, and exits if that file is not found. The `lib` folder must therefore exist above the scripts on the router too, and the install hint it prints is for `apt`, not the router's `opkg`.
- **Destructive:** `Delete_10Days_Old_Files.sh` deletes files by age with no confirmation; `File-Count-SSH-Upload.sh` runs it daily.
- **Password handling:** the upload scripts read the NAS password from a file under `/root/Adm/` and pass it to `sshpass` through a named pipe at `/tmp/pw_pipe`; the password itself is not in git.
- Comments and console output are partly in Danish.
