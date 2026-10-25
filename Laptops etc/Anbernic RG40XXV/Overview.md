# Anbernic RG40XXV Overview

Scripts for backing up, checking and restoring the SD card of the Anbernic RG40XXV handheld, run on a Debian/Ubuntu PC with the card in a card reader. Each script has a matching `.md` file (same base name).

---

| Script | Doc | sudo | Summary |
| --- | --- | --- | --- |
| `sd-backup.sh` | [sd-backup.md](sd-backup.md) | Yes | Reads the whole card once into a `zstd`-compressed image and writes a `.sha256` and an `.info` file (size, sha256 of the raw data, partition table) next to it. |
| `sd-validate.sh` | [sd-validate.md](sd-validate.md) | Only with a device | Checks an image's checksum, unpacks it and checks size and sha256 against `.info`, and with a device also compares it byte for byte with the card. |
| `sd-restore.sh` | [sd-restore.md](sd-restore.md) | Yes | Checks the image first, then writes it to a card after you type the device name, and verifies the card byte for byte. |

---

## Notes

- **Workflow:** `sudo ./sd-backup.sh /dev/sdX` → `sudo ./sd-validate.sh <image> /dev/sdX` while the card is still in the reader → copy the three files to the NAS → `./sd-validate.sh <image>` on the copy.
- **Packages:** `zstd` and `diffutils` (`cmp`). Everything else is in a normal Debian/Ubuntu install. All three scripts check this at startup.
- **Safety:** all three refuse partitions and system disks (`/`, `/boot`, `/home`, swap and so on). Only `sd-restore.sh` writes to a card, and only after you type the device name.
- **Interactive only:** confirmations are read from `/dev/tty`, so the scripts are not meant for cron.
- The three scripts share the same helper functions (copied, not sourced), so a fix to `check_disk` or `system_disks` must be made in all three.
