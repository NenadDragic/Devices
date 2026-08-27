# Crontab Backup - Crontab_Backup.sh

POSIX `sh` script (runs on BusyBox ash/OpenWrt, dash, and bash) that saves each user's crontab to its own timestamped file, so it can be restored later with `crontab -u <user> <file>`.

## How it works

1. Parses options (`-d`, `-u`, `-k`, `-s`, `-n`, `-q`, `-h`) and validates that `-k` is a non-negative integer.
2. Locates the system's cron spool directory by checking, in order: `/etc/crontabs` (BusyBox/OpenWrt), `/var/spool/cron/crontabs`, `/var/spool/cron` (Debian/Ubuntu). Exits with an error if neither the `crontab` command nor a spool directory can be found.
3. Builds the list of users to back up: defaults to every user in `getent passwd` / `/etc/passwd`, plus any extra usernames found only as files in the spool directory (common on OpenWrt); `-u` overrides this to specific users (repeatable).
4. If not running as root, restricts the backup to the current user only (root is required to read other users' crontabs) and disables `-s`.
5. Creates the output directory (default `/root/Scripts/Crontab`, `chmod 700`) unless `-n` (dry-run) is set.
6. For each user, reads their crontab via `crontab -l -u <user>`, falling back to reading the file directly from the spool directory if the `crontab` command isn't available. Users with no crontab, or whose crontab is only blank lines/comments, are skipped.
7. Writes each non-empty crontab to `$OUTDIR/crontab_<user>_<YYYY-MM-DD>.txt` (`chmod 600`; the username is sanitized to `A-Za-z0-9._@-`, other characters become `_`). In dry-run mode, logs what would be written instead of writing anything.
8. If `-s` is set, also concatenates `/etc/crontab` and `/etc/cron.d/*` (each prefixed with a `### <path>` header) into a single `crontab_system_<date>.txt`.
9. If `-k DAYS` is greater than 0 (and not a dry-run), deletes backup files older than `DAYS` days from the output directory.
10. Prints a summary line: how many files were written and how many users were skipped.

## Usage

```console
chmod +x Crontab_Backup.sh
./Crontab_Backup.sh [-d katalog] [-u bruger]... [-k dage] [-s] [-n] [-q] [-h]
```

| Option | Description |
| ------ | ----------- |
| `-d KATALOG` | Output directory (default: `/root/Scripts/Crontab`) |
| `-u BRUGER` | Back up only this user (repeatable). Default: every user in passwd (plus any spool-only users) |
| `-k DAGE` | Delete backup files older than this many days in the output directory (`0` = no cleanup) |
| `-s` | Also back up system cron (`/etc/crontab` + `/etc/cron.d/*`) — ignored when not running as root |
| `-n` | Dry-run: show what would happen, write nothing |
| `-q` | Quiet (errors only) |
| `-h` | Show help |

Run as root on the router/host to back up all users' crontabs; run as a non-root user to back up only your own. Intended to be run manually or via a scheduled cron job itself.

To restore a backup:

```console
crontab -u <bruger> crontab_<bruger>_<dato>.txt
```
