# Oprydning - DashCam

Weekly DashCam cleanup and report in one job. Replaces six separate jobs: `Delete FTP DashCam 30 over days.sh`, `Disk Used size - DashCam.sh`, `FileCount - SFTP - DashCam.sh`, `FileCount - Router - DashCam.sh`, `FileCount - Router - SD.sh` and `FileDelete - Router - DashCam.sh`. Runs as the user `DashCam`.

## Steps

1. **Delete old recordings** - deletes files under `/volume1/DashCam` older than `KEEP_DAYS`, skipping `#recycle` and any folder in `PROTECT`, and prints how many files and how much space was freed.
2. **Content** - prints the file count and size of each folder in `FOLDERS`, plus the total size of the share.
3. **Router reports** - prints the router report files from the last `REPORT_DAYS` days for each folder in `REPORTS`, with a warning if none arrived.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `ROOT` | `/volume1/DashCam` | DashCam share |
| `KEEP_DAYS` | `30` | Delete files older than this |
| `REPORT_DAYS` | `7` | Show router reports from this many days (job runs weekly) |
| `FOLDERS` | `Photo Movie Movie/RO Movie/Parking` | Folders that are counted |
| `REPORTS` | `File-Count-DashCam File-Delete File-Count-SD` | Folders holding router reports |
| `PROTECT` | *(empty)* | Folders that are never deleted from, e.g. `(Movie/RO)` |

## Usage

```bash
bash "Oprydning - DashCam.sh"
```

Step 1 deletes files permanently (`rm`, not the recycle bin). Add folders to `PROTECT` to keep their recordings.
