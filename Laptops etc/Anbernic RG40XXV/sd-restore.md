# sd-restore

Writes an image made by [`sd-backup.sh`](sd-backup.md) back to an SD card and checks the result byte for byte. **Everything on the target card is overwritten.**

---

## Usage

```bash
sudo ./sd-restore.sh IMAGE.img.zst /dev/sdX
```

| Argument | Meaning |
| --- | --- |
| `IMAGE.img.zst` | Image made by `sd-backup.sh`. The `.img.zst.sha256` and `.info` files are used if they lie next to it. |
| `/dev/sdX` | The whole target card, not a partition. |

`-h` / `--help` prints the header comment.

Prerequisites:

- **Must run with `sudo`** (checked).
- **Packages:** `zstd` and `cmp` (package `diffutils`). The rest (`dd`, `blockdev`, `lsblk`, `findmnt`, `blkid`, `partx`, `sha256sum`) is part of `coreutils`/`util-linux`. Missing commands are reported with the `apt install` line.
- An interactive terminal for the confirmation.
- The target card must be at least as big as the original card.

---

## What the Script Does

### Step 1 – Check the image before writing

Requires a `.img.zst` file. If the `.sha256` file exists, it is checked with `sha256sum -c` and the script stops before touching the card if it does not match. Without it, you must confirm that you want to continue unchecked.

The original size is read from `SIZE_BYTES` in the `.info` file. Without a `.info` file, the image is unpacked once just to measure it.

### Step 2 – Check the card

Same safety check as `sd-backup.sh`: whole disk, not a system disk (`/`, `/boot`, `/home`, swap and so on). It also refuses if the image file itself lies on the target card, and if the card is smaller than the image.

### Step 3 – Confirmation

Shows the card (`lsblk`), the image name, date and source model from `.info`, and a red warning. You must type the device name (for example `sdb`) to continue. Anything else aborts without writing.

### Step 4 – Write

Unmounts all partitions on the card and writes with `zstd -dc | dd bs=4M conv=fsync`, followed by `sync`.

### Step 5 – Verify

Flushes the kernel's cache for the card (`blockdev --flushbufs`) so it is read from the card and not from memory, then compares the unpacked image with the first `SIZE_BYTES` of the card using `cmp`. On a mismatch it reports the first differing byte.

Finally it makes the kernel re-read the partition table. If the card uses GPT and is bigger than the image, it prints the `sfdisk --relocate gpt-bak-std` command to move the backup GPT to the end of the card.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Written and verified |
| `1` | Wrong arguments, not root, missing command, image fails its checksum, failed safety check, aborted, write error or verification mismatch |

---

## Notes

- **A failed write leaves the card in an unknown state.** Try again, or use another card or card reader.
- **Bigger card than the original:** the extra space is left unused. Grow the last partition yourself afterwards if needed (and fix the backup GPT first, see step 5).
- Comments and console output are in Danish.
