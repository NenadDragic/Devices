# Copy USB - Devices

Copies all files from a USB drive to `/volume1/NetBackup/`, removing source files after transfer, removes empty directories under `usbshare/NetBackup/`, then deletes the whole USB share with `rm -rf`.

> **Warning:** the final `rm -rf /volumeUSB1/usbshare/` is unconditional. It also runs if `rsync` failed, so any file that was not transferred is deleted from the USB drive.

## Command

```bash
sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/ \
  /volume1/NetBackup/

sudo find /volumeUSB1/usbshare/NetBackup/ -type d -empty -delete

sudo rm -rf /volumeUSB1/usbshare/
```

## Options

| Option | Description |
| --- | --- |
| `-a` | Archive mode — preserves permissions, timestamps, symlinks, etc. |
| `-v` | Verbose output |
| `--progress` | Show transfer progress |
| `--remove-source-files` | Delete source files after successful transfer |
| `find -type d -empty -delete` | Remove empty directories under `/volumeUSB1/usbshare/NetBackup/` only |
| `rm -rf` | Remove the whole source share, whether or not it is empty |

## Usage

```bash
bash "Copy USB - Devices.sh"
```

Ensure the USB drive is mounted at `/volumeUSB1/usbshare/` before running.
