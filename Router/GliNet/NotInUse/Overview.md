# GliNet NotInUse Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing how it works, with a copy of the script itself. These GL.iNet router scripts work but are not wired into the active pipeline in the parent [`GliNet`](../Overview.md) folder; they are kept for potential future use.

---

## DashCam Download

| Script | Doc | Summary |
| --- | --- | --- |
| `DashCam-Router-Movie.sh` | [DashCam-Router-Movie.md](DashCam-Router-Movie.md) | Downloads from the DashCam's combined `/DCIM/Movie` listing (all movie files, not split by RO/Parking), using a `ps`-grep duplicate-run check rather than the PID-file lock of the active `DashCam-Router-Movie-RO.sh`. |
| `DashCam-Router-Movie-Parking.sh` | [DashCam-Router-Movie-Parking.md](DashCam-Router-Movie-Parking.md) | Downloads from the DashCam's `/DCIM/Movie/Parking` listing, using a `ps`-grep duplicate-run check rather than the PID-file lock of the active `DashCam-Router-Movie-RO.sh`. |

## Upload to NAS

| Script | Doc | Summary |
| --- | --- | --- |
| `Router-NAS-Movie.sh` | [Router-NAS-Movie.md](Router-NAS-Movie.md) | Revised variant of `Old/Router-NAS-Movie_Old.sh` that passes the NAS password through a named pipe over SSH instead of a plaintext `sshpass -f` file. |
| `Router-NAS-Movie-Parking.sh` | [Router-NAS-Movie-Parking.md](Router-NAS-Movie-Parking.md) | Revised variant of `Old/Router-NAS-Movie-Parking_Old.sh` that passes the NAS password through a named pipe over SSH instead of a plaintext `sshpass -f` file. |
| `Backup_IP.sh` | [Backup_IP.md](Backup_IP.md) | Revised variant of `Old/Backup_IP_Old.sh` that targets the NAS module path `NetBackup/Muddi-E750/...`; the active `Backup.sh` addresses the NAS by hostname instead. |

---

## Notes

- **Root:** written to run as `root` on the router. None has its own root check; `Backup_IP.sh`, `Router-NAS-Movie.sh` and `Router-NAS-Movie-Parking.sh` call `sudo` for `sshpass`/`rsync`.
- The two download scripts can overlap with themselves less safely than the active ones: their duplicate-run check greps `ps` output instead of using a PID file.
