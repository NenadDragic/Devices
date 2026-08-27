# GliNet System Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas. These are OpenWrt/GL.iNet router system-maintenance scripts.

---

## Package Management

| Script | Doc | Summary |
|---|---|---|
| `Install.sh` | [Install.md](Install.md) | Installs the base set of tools (`nano`, `git`, SFTP server, `sshpass`, `rsync`, `nmap`, `coreutils-nohup`) via `opkg`, then updates and upgrades all packages. |
| `Update.sh` | [Update.md](Update.md) | Refreshes the router's `opkg` package index (`opkg update`). |

## Backup

| Script | Doc | Summary |
|---|---|---|
| `Crontab_Backup.sh` | [Crontab_Backup.md](Crontab_Backup.md) | POSIX `sh` script that saves each user's crontab to a timestamped file under `/root/Scripts/Crontab` (configurable), with options to target specific users, include system cron, prune old backups, and dry-run. |

---

## Notes

- `Crontab_Backup.sh` is the only script here that requires root for full functionality — without it, it silently restricts itself to the current user's own crontab and skips system cron even if `-s` is passed.
- `Install.sh` contains commented-out `scp` commands referencing two different router IPs (`192.168.8.1` and `192.168.1.1`) as manual/reference steps — not executed by the script itself.
