# Laptops etc Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas. These are Debian/Ubuntu laptop setup/maintenance scripts.

---

## Setup

| Script | Doc | Summary |
| --- | --- | --- |
| `Setup.sh` | [Setup.md](Setup.md) | Shows install status (installed/not, and whether it's the latest version) for ~29 frequently used CLI tools spanning core utilities, backup/file handling, system updates, development, networking, and terminal tools, and lets you pick several at once to install/upgrade together via `apt-get`. |

## Subfolders

| Folder | Overview | What's there |
| --- | --- | --- |
| `Anbernic RG40XXV` | [Overview](Anbernic%20RG40XXV/Overview.md) | Backup, validation and restore of the handheld's SD card as a compressed whole-card image (`sd-backup.sh`, `sd-validate.sh`, `sd-restore.sh`). Needs `sudo` and `zstd`. |

---

## Notes

- `Setup.sh` requires root/sudo and an `apt`-based system; the tool list itself is edited directly in the script's `TOOLS` array (see [Setup.md](Setup.md) for the full categorized list).
- Non-destructive until you actively pick tools to install in its last step — the status listing itself only refreshes the local package index (`apt-get update`).
- Scoped to tools that run on the PC/laptop itself — router (GL.iNet/OpenWrt) and NAS (Synology) tooling is tracked separately in their own folders' `Overview.md`.
