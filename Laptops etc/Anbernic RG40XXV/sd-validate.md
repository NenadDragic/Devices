# sd-validate

Checks an image made by [`sd-backup.sh`](sd-backup.md). Without a device it only checks the files, so it can be used to check a copy on the NAS. With a device it also compares the image byte for byte with the card, which is how you check a backup or restore right after it was made.

---

## Usage

```bash
./sd-validate.sh IMAGE.img.zst              # file checks only, no sudo needed
sudo ./sd-validate.sh IMAGE.img.zst /dev/sdX # file checks + compare with the card
```

`-h` / `--help` prints the header comment.

Prerequisites:

- **`sudo` only when a device is given** (checked). File checks run as a normal user.
- **Packages:** `zstd` and `cmp` (package `diffutils`). The rest is part of `coreutils`/`util-linux`. Missing commands are reported with the `apt install` line.

---

## What the Script Does

### Check 1/3 – Checksum of the image file

Checks the `.zst` file against `<image>.sha256` with `sha256sum -c`. This catches files damaged or changed while copied, for example to the NAS. Skipped with a warning if the `.sha256` file is missing.

### Check 2/3 – Unpack and check the raw data

Unpacks the whole image (which also checks zstd's own block checksums) and counts bytes and calculates sha256 of the raw data in the same pass. Both are compared with `SIZE_BYTES` and `RAW_SHA256` in the `.info` file. Without a valid `.info` file, only the unpacking itself is checked.

### Check 3/3 – Compare with the card (only with `/dev/sdX`)

Same safety check as `sd-backup.sh` (whole disk, not a system disk). Unmounts the card's partitions (a mounted partition can change and give a false mismatch), flushes the cache and compares the unpacked image with the card using `cmp`. A card bigger than the image is compared over the image's length only.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | All checks that ran passed |
| `1` | At least one check failed, or wrong arguments / missing command / not root with a device |

---

## Notes

- **Reading the whole image takes time.** Check 2 and check 3 each unpack the full image, so with a device the image is unpacked twice.
- "All checks OK" only covers the checks that ran. Without `.sha256` or `.info`, those checks are skipped with a warning.
- Comments and console output are in Danish.
