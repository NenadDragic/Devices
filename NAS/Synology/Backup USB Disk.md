# Backup USB Disk

Moves every top-level folder from the USB drive to the matching folder in `/volume1/NetBackup/` (`usbshare/<folder>/` -> `NetBackup/<folder>/`). Replaces `Copy USB - Devices.sh` and `Copy USB - Log.sh` with a safer copy-verify-delete flow. Runs as root (no `sudo`).

## Steps

1. **Copy** - every folder is copied with `rsync`. If any copy fails the script stops and nothing is deleted from the USB drive.
2. **Delete from USB** - `rsync --remove-source-files` runs again and removes only the files that are now identical in NetBackup. Empty subfolders are removed; the top-level folders themselves (`Log`, `<device>`) are kept.
3. **Check** - lists any files still left on the USB drive (and loose files in the USB root, which are never moved) and exits with an error if anything remains.

## Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `USB` | `/volumeUSB1/usbshare` | USB share to empty |
| `DST` | `/volume1/NetBackup` | Destination share |
| `SKIP` | `#recycle`, `@eaDir`, `System Volume Information`, `$RECYCLE.BIN`, `lost+found` | Top-level folders that are never moved |
| `OPTS` | `-a -u --exclude='@eaDir' --exclude='#recycle'` | `rsync` options |

## Options

| Option | Description |
| ------ | ----------- |
| `rsync -a` | Archive mode - preserves permissions, timestamps, symlinks, etc. |
| `rsync -u` | Never overwrite a newer file in NetBackup - such a file stays on USB and is reported in step 3 |
| `--remove-source-files` | Delete source files that were transferred or are already identical |
| `find -type d -empty -delete` | Remove empty subfolders left on the USB drive |

## Usage

```bash
bash "Backup USB Disk.sh"
```

If the USB drive is not mounted the script exits with code 0 and does nothing. Exit code 1 means something failed or files were left on the USB drive.
