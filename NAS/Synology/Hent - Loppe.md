# Hent - Loppe

Fetches the `Loppe` folder from `10.0.0.215` to `/volume1/Dragic/Rap/Loppe` with `rsync`, then prints `status.txt` and lists the fetched files. Replaces `Loppe files Copy.sh` and `Loppe Status.sh`. Runs as the user `ElBosso` (uses ElBosso's SSH key for `admina@10.0.0.215`).

## Steps

1. **Fetch** - copies `/home/admina/Loppe` (the folder itself, no trailing `/`) into `/volume1/Dragic/Rap`. Only new and changed files are transferred, and files deleted on the server stay on the NAS.
2. **Status** - prints `/volume1/Dragic/Rap/Loppe/status.txt`.
3. **Fetched** - lists the transferred files, or `(ingen nye eller ændrede filer)` if nothing was new.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `SRC` | `admina@10.0.0.215:/home/admina/Loppe` | Remote source folder |
| `DST` | `/volume1/Dragic/Rap` | Destination on the NAS (must exist) |
| `STATUS` | `$DST/Loppe/status.txt` | Status file that is printed |
| `SSH` | `ssh -o BatchMode=yes -o ConnectTimeout=15` | Fails instead of hanging on a password or host-key prompt |

## Options

| Option | Description |
| --- | --- |
| `rsync -rt` | Copy contents and timestamps. Not `-a`, so the files inherit the share's permissions |
| `-8` | Show non-ASCII names (æøå) correctly in the mail |
| `--timeout=300` | Give up if no data is transferred for 5 minutes |
| `--out-format='%n'` | Print the name of each transferred file |

## Usage

```bash
bash "Hent - Loppe.sh"
```

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Fetched and status printed |
| `1` | `DST` is missing, `rsync` failed, or `status.txt` is missing - so DSM sends an error mail |

`rsync` code 24 (files vanished during transfer) only gives a warning.
