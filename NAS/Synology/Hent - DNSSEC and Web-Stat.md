# Hent - DNSSEC and Web-Stat

Fetches the DNSSEC/DNS health-check reports and the web status HTML reports from `10.0.0.214` to the NAS with `rsync`, prints today's DNS health-check report, then deletes the NAS copy of today's report. Replaces `DNSSEC - StatusFile.sh` and `Web-Stat.sh`. Runs as the user `ElBosso` (uses ElBosso's SSH key for `admina@10.0.0.214`).

## Steps

1. **DNSSEC** - copies `*.txt` from `/home/admina/DNSSEC/` and `/home/admina/DNSSEC/Old/` to `/volume1/Dragic/Rap/DNS_Status` (and its `Old/`).
2. **Web-Stat** - copies `*.html` from `/home/admina/Web-Stat/reports/` to `/volume1/Dragic/Rap/Web_Status`.
3. **Today's report** - prints `DNS_Status/Sundhedscheck-<YYYY-MM-DD>.txt` with `cat`, then deletes it on the NAS with `rm -f`. If the file is missing, an error is printed instead.
4. **Report** - lists the files fetched in each part, or `(ingen nye eller ændrede filer)` if nothing was new.

Both parts are fetched even if the other one fails. Only new and changed files are transferred, and files deleted on the server stay on the NAS. The destination folders are created if they are missing.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `SRV` | `admina@10.0.0.214:/home/admina` | Remote user, host and base folder |
| `RAP` | `/volume1/Dragic/Rap` | Base folder on the NAS (must exist) |
| `SSH` | `ssh -o BatchMode=yes -o ConnectTimeout=15` | Fails instead of hanging on a password or host-key prompt |
| `TODAY` | `$RAP/DNS_Status/Sundhedscheck-$(date +%F).txt` | Today's DNS health-check report |

## Options

| Option | Description |
| --- | --- |
| `rsync -rt` | Copy contents and timestamps. Not `-a`, so the files inherit the share's permissions |
| `-8` | Show non-ASCII names (æøå) correctly |
| `--timeout=300` | Give up if no data is transferred for 5 minutes |
| `--out-format='%n'` | Print the name of each transferred file |
| `--include` / `--exclude='*'` | Only `*.txt` (DNSSEC, incl. `Old/`) or `*.html` (Web-Stat) |

## Usage

```bash
bash "Hent - DNSSEC and Web-Stat.sh"
```

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Both parts fetched and today's report was found |
| `1` | `RAP` is missing, a destination folder could not be created, `rsync` failed in either part, or today's report is missing |

`rsync` code 24 (files vanished during transfer) only gives a warning.

## Notes

- Today's report is deleted on the NAS after it is shown, as the old job did. When the server has moved it to `DNSSEC/Old/`, it is fetched from there, so it only exists in one place. If it stays in `DNSSEC/` instead, it is fetched again the next day and kept, because it is no longer today's.
