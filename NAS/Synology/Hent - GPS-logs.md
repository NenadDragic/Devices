# Hent - GPS-logs

Fetches the GPS monitor logs from `10.0.0.149` to `/volume1/Dragic/Rap/GPS_log` with `rsync`, lists the fetched files and then the CSV folder. Replaces `Copy GPS log files.sh` (now in `Old/`), which used `scp`. Runs as the user `ElBosso` (uses ElBosso's SSH key for `admina@10.0.0.149`).

## Steps

1. **Check** - exits with an error if `/volume1/Dragic/Rap` is missing, and creates `GPS_log` if needed.
2. **Fetch** - copies `/home/admina/gps_monitor/logs` (the folder itself, no trailing `/`) into `GPS_log`, so the files land in `GPS_log/logs`. Only new and changed files are transferred, and files deleted on the source stay on the NAS.
3. **Fetched** - lists the transferred files, or `(ingen nye eller ændrede filer)` if nothing was new.
4. **Result** - stops with an error if `rsync` failed. `rsync` code 24 (files vanished during transfer, e.g. log rotation) only gives a warning.
5. **List** - shows `ls -alh` of `GPS_log/logs/csv/`.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `SRC` | `admina@10.0.0.149:/home/admina/gps_monitor/logs` | Remote source folder |
| `DST` | `/volume1/Dragic/Rap/GPS_log` | Destination on the NAS (the parent folder must exist) |

## Options

| Option | Description |
| --- | --- |
| `rsync -rt` | Copy contents and timestamps. Not `-a`, so the files inherit the share's permissions instead of the server's |
| `-8` | Show non-ASCII names (æøå) correctly in the mail |
| `--timeout=300` | Give up if no data is transferred for 5 minutes |
| `-o BatchMode=yes -o ConnectTimeout=15` | Fail instead of hanging on a password or host-key prompt |
| `--out-format='%n'` | Print the name of each transferred file |

## Usage

```bash
bash "Hent - GPS-logs.sh"
```

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Fetched and listed |
| `1` | `/volume1/Dragic/Rap` is missing, `GPS_log` cannot be created, or `rsync` failed - so DSM sends an error mail |
| other | The final `ls` failed, e.g. because `GPS_log/logs/csv` does not exist yet |

Console output is in Danish.
