# Backup-Remote Overview

Scripts on the Ubuntu server `misc` that back up the Synology NAS to cloud services (IDrive and Jottacloud). The NAS shares are mounted read-only on `misc` and backed up from there. Each script has a matching `.md` file (same base name). On the server the scripts live in `~/scripts/` of the user `misc`.

---

| Script | Doc | Run as | Summary |
| --- | --- | --- | --- |
| `Nas_Mount.sh` | [Nas_Mount.md](Nas_Mount.md) | `sudo` for `creds`/`mount`/`umount`, normal user for `fstab`/`status` | Generates fstab lines and credentials, and mounts, unmounts and checks the NAS shares (`DashCam`, `Dragic`, `NetBackup`) read-only under `/mnt/nas` with systemd-automount. Locks the empty folders while unmounted. |
| `Nas_Backup.sh` | [Nas_Backup.md](Nas_Backup.md) | `misc`, no sudo (checked) | Combined status of mounts, IDrive and Jottacloud; starts the IDrive backup only when all shares are mounted read-only; picks test files and compares them after a restore test. |
| `Jotta_Speedtest.sh` | [Jotta_Speedtest.md](Jotta_Speedtest.md) | `misc`, no sudo (checked) | Adds one share to Jottacloud for a set time, measures upload speed into a CSV log, and offers to remove the test upload afterwards. |

---

## Notes

- **Setup order:** `Nas_Mount.sh` first (`cifs-utils`, `creds`, fstab lines, `mount`), then IDrive and `jotta-cli` for the user `misc`.
- **Packages beyond a normal Ubuntu install:** `cifs-utils`, IDrive for Linux (`/opt/IDriveForLinux`) and `jotta-cli` (Jottacloud's apt repository). `tmux` is recommended for `Jotta_Speedtest.sh`.
- **Read-only is the safety net:** the shares are mounted `ro`, and both `Nas_Mount.sh` and `Nas_Backup.sh` check the real mount options before anything is backed up.
- **`NAS_HOST`** is set in both `Nas_Mount.sh` and `Jotta_Speedtest.sh`.
- `IDRIVE_BACKUP_CMD` in `Nas_Backup.sh` is still marked unverified.
