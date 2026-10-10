# GliNet Old Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing how it works, with a copy of the script itself. These are deprecated or duplicate earlier versions of the GL.iNet router scripts in the parent [`GliNet`](../Overview.md) folder, kept for reference only.

---

## DashCam Download

| Script | Doc | Summary |
| --- | --- | --- |
| `DashCam-Router-Movie-RO_Old.sh` | [DashCam-Router-Movie-RO_Old.md](DashCam-Router-Movie-RO_Old.md) | Superseded by `DashCam-Router-Movie-RO.sh`, which replaced the ad-hoc `ps`-based duplicate check with a PID-file lock and trap-based cleanup. |
| `DashCam-Router-Movie-RO_Old_Old.sh` | [DashCam-Router-Movie-RO_Old_Old.md](DashCam-Router-Movie-RO_Old_Old.md) | An earlier draft of the RO-video downloader, also superseded by `DashCam-Router-Movie-RO.sh`. |
| `DashCam-Router-Pictures_Old.sh` | [DashCam-Router-Pictures_Old.md](DashCam-Router-Pictures_Old.md) | Superseded by `DashCam-Router-Pictures.sh`, which replaced the `ps`-based duplicate check with a PID-file lock and trap-based cleanup. |

## Upload to NAS

| Script | Doc | Summary |
| --- | --- | --- |
| `Router-NAS-Movie_Old.sh` | [Router-NAS-Movie_Old.md](Router-NAS-Movie_Old.md) | Superseded by `NotInUse/Router-NAS-Movie.sh`, which moved from a plaintext `sshpass -f /root/Adm/pw.txt` file to the named-pipe password approach over SSH. |
| `Router-NAS-Movie-Parking_Old.sh` | [Router-NAS-Movie-Parking_Old.md](Router-NAS-Movie-Parking_Old.md) | Superseded by `NotInUse/Router-NAS-Movie-Parking.sh`, which moved from a plaintext `sshpass -f` file to the named-pipe password approach over SSH. |
| `Router-NAS-Movie-RO_Old.sh` | [Router-NAS-Movie-RO_Old.md](Router-NAS-Movie-RO_Old.md) | Superseded by `Router-NAS-Movie-RO.sh`, which moved from a plaintext `sshpass -f` file to the named-pipe password approach over SSH. |
| `Router-NAS-Pictures_Old.sh` | [Router-NAS-Pictures_Old.md](Router-NAS-Pictures_Old.md) | Superseded by `Router-NAS-Pictures.sh`, which moved from a plaintext `sshpass -f` file to the named-pipe password approach over SSH. |
| `Backup_Old.sh` | [Backup_Old.md](Backup_Old.md) | Duplicate of the active `Backup.sh` (same commands, same NAS target by hostname). |
| `Backup_IP_Old.sh` | [Backup_IP_Old.md](Backup_IP_Old.md) | Superseded by `Backup.sh`, which targets the NAS by hostname (`nas.dragic.com`) instead of a hardcoded IP. |

## Counting & Cleanup

| Script | Doc | Summary |
| --- | --- | --- |
| `File-Count-FTP-Upload_Old.sh` | [File-Count-FTP-Upload_Old.md](File-Count-FTP-Upload_Old.md) | Superseded by `File-Count-SSH-Upload.sh`, which moved from a plaintext `sshpass -f` file to the named-pipe password approach over SSH. |
| `File-Delete-FTP-Upload.sh` | [File-Delete-FTP-Upload.md](File-Delete-FTP-Upload.md) | Superseded by the cleanup part of `File-Count-SSH-Upload.sh`. |

## Dynamic DNS

| Script | Doc | Summary |
| --- | --- | --- |
| `DDNS.sh` | [DDNS.md](DDNS.md) | Simply.com DDNS update. Reads the API key from the `SIMPLY_DDNS_APIKEY` environment variable; the key that used to be hardcoded is still in git history and must be treated as compromised. |

---

## Notes

- **Root:** written to run as `root` on the router. None has its own root check; `Backup_Old.sh` and `Backup_IP_Old.sh` call `sudo` for `sshpass`/`rsync`.
- Do not schedule these: each one has a newer replacement named in its row.
- Several of them read the NAS password from the plaintext file `/root/Adm/pw.txt` with `sshpass -f`; the password itself is not in git.
