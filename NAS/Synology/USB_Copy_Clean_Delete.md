# USB_Copy_Clean_Delete

Wrapper for the DSM task that runs `/volume1/root-scripts/USB_Copy_Clean_Delete.sh` on the NAS. It sets the parameters as environment variables and calls the real script. The real script is in [`root-scripts/USB_Copy_Clean_Delete.sh`](root-scripts/USB_Copy_Clean_Delete.md) (an identical copy is also in the `Linux-Scripts` repository).

> **WARNING:** The file contains two blocks - `MODE=Dryrun` and then `MODE=Run` - with nothing between them. Run as-is, it does a dry run and then **immediately a real run**, which moves data off the USB disk and deletes old backups. The blocks are meant as the commands for two separate DSM tasks (one dry run, one real run); paste only the block you want into each task.

## Command

```bash
export MODE=Dryrun      # or Run
export KEEP=3
export LOG_DAYS=0
export NOPRUNE=""
bash /volume1/root-scripts/USB_Copy_Clean_Delete.sh
```

## Parameters

| Variable | Value | Description |
| --- | --- | --- |
| `MODE` | `Dryrun` / `Run` | `Dryrun` only shows what would happen; `Run` does it |
| `KEEP` | `3` | Backups to keep in each `NetBackup` folder |
| `LOG_DAYS` | `0` | Delete files in `NetBackup/Log` older than this many days; `0` turns it off |
| `NOPRUNE` | *(empty)* | Space-separated `NetBackup` folders that are never cleaned up |

## What the called script does

1. Moves every folder from the USB disk (`/volumeUSB1/usbshare`) to `/volume1/NetBackup` (copy first, then delete from USB only what is identical in NetBackup).
2. Keeps the newest `KEEP` date-named `.zip`/`.gz` backups in each `NetBackup` folder and deletes the older ones, after testing the newest.
3. Deletes old log files if `LOG_DAYS` > 0.
4. Prints disk usage for `NetBackup`.

See [root-scripts/USB_Copy_Clean_Delete.md](root-scripts/USB_Copy_Clean_Delete.md) for details, prerequisites (root, marker file `.netbackup-usb` on the USB disk) and exit codes. Note that a dry run exits with `3`, which DSM reports as a failure.

## Usage

Run as `root` from DSM Task Scheduler (User-defined script).
