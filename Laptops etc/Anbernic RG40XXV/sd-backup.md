# sd-backup

Takes a complete, compressed image of an SD card (the whole card, all partitions) on a Debian/Ubuntu PC. Made for the Anbernic RG40XXV handheld's SD card, but works for any SD card or USB disk. The image can be checked with [`sd-validate.sh`](sd-validate.md) and written back with [`sd-restore.sh`](sd-restore.md).

The card is only read, never written. Its partitions are unmounted before reading.

---

## Usage

```bash
sudo ./sd-backup.sh /dev/sdX [target-folder] [name]
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `/dev/sdX` | – | The whole card, not a partition (`/dev/sdb`, not `/dev/sdb6`). Run without `sudo` to get a list of disks. |
| `target-folder` | `~/sd-backups` | Folder for the backup files. `~` is the home folder of the user who ran `sudo`, not `/root`. Created if missing. |
| `name` | `sd` | Prefix for the file names. Only `A-Z a-z 0-9 . _ -` allowed. |

`-h` / `--help` prints the header comment.

Prerequisites:

- **Must run with `sudo`** (checked; exits with an error and a list of disks otherwise).
- **Packages:** `zstd` is the only one that is often missing. `sfdisk` (package `fdisk`), `blockdev`, `lsblk`, `findmnt` (`util-linux`) and `coreutils` are part of a normal install. The script checks all commands at startup and prints the `apt install` line for anything missing.
- An interactive terminal: confirmations are read from `/dev/tty`, so the script cannot run unattended.

---

## What the Script Does

### Step 1 – Safety checks

Resolves the device path and checks that it is a block device of type `disk` (not a partition) and that it is not a system disk. A system disk is any disk under `/`, `/boot`, `/boot/efi`, `/home`, `/usr`, `/var` or an active swap, followed through LVM/LUKS/btrfs to the physical disk. If the system disk cannot be determined, you must confirm that the device really is the SD card.

### Step 2 – Space check and confirmation

Shows the card (`lsblk`), its size and the free space in the target folder. If free space is smaller than the card, it warns (compression usually makes the image much smaller, but that is not guaranteed) and asks before continuing. Then asks `Tag backup af /dev/sdX? [j/N]`.

### Step 3 – Read the card

Unmounts all partitions on the card, then reads it once with `dd bs=4M`. The data stream is split with `tee`: one copy is compressed with `zstd -T0` to `<base>.img.zst.partial`, the other goes through a named pipe to `sha256sum`, so the checksum of the raw data is calculated without reading the card twice. The `.partial` file is renamed when everything succeeded and deleted if the script stops halfway.

### Step 4 – Write checksum and metadata

| File | Content |
| --- | --- |
| `<name>-YYYY-MM-DD_HHMM.img.zst` | Compressed image of the whole card |
| `<name>-YYYY-MM-DD_HHMM.img.zst.sha256` | sha256 of the `.zst` file (`sha256sum -c` format, relative file name) |
| `<name>-YYYY-MM-DD_HHMM.info` | `key=value` lines read by `sd-validate.sh` and `sd-restore.sh`: `DATE`, `SOURCE_DEVICE`, `SOURCE_MODEL`, `SOURCE_SERIAL`, `SIZE_BYTES`, `RAW_SHA256`, `IMAGE_FILE`, `IMAGE_BYTES`, plus the partition list and `sfdisk -d` dump as comments |

The files (and the target folder if the script created it) are given to the user who ran `sudo`, so they are not owned by root.

### Step 5 – Summary

Prints the time used, the image size as a percentage of the card, and the exact `sd-validate.sh` command to compare the new image with the card.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Backup finished (or `--help`) |
| `1` | Wrong arguments, not root, missing command, failed safety check, answered no, or read/compress error |

---

## Notes

- **Validate right away.** Run the `sd-validate.sh … /dev/sdX` line printed at the end while the card is still in the reader. It reads the card again and compares it byte for byte with the image.
- **The image is as big as the card when unpacked**, including empty space. A restore needs a card at least as big as the original.
- Will not overwrite an existing backup with the same time stamp.
- Comments and console output are in Danish.
