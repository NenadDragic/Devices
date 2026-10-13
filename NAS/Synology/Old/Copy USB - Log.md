# Copy USB - Log

Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then deletes the source directory with `rm -rf`.

> **Warning:** the final `rm -rf /volumeUSB1/usbshare/Log/` is unconditional. It also runs if `rsync` failed, so any file that was not transferred is deleted from the USB drive.

## Command

```bash
sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo rm -rf /volumeUSB1/usbshare/Log/
```

## Options

| Option | Description |
| --- | --- |
| `-a` | Archive mode — preserves permissions, timestamps, symlinks, etc. |
| `-v` | Verbose output |
| `--progress` | Show transfer progress |
| `--remove-source-files` | Delete source files after successful transfer |
| `sudo rm -rf` | Remove the source directory, whether or not it is empty |

## Usage

```bash
bash "Copy USB - Log.sh"
```

Ensure the USB drive is mounted at `/volumeUSB1/usbshare/` before running.
