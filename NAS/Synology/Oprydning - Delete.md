# Oprydning - Delete

Command for the DSM task that runs `/volume1/root-scripts/Oprydning.sh` with `MODE=clean`. It deletes junk files in `/volume1/Dragic` and fixes file names with double spaces. Replaces the separate Delete scripts (`bak files - Delete.sh`, `tmp files - Delete.sh`, `Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`, `Two or more spaces in filename - Delete.sh`).

`Oprydning - Find.sh` calls the same script with `MODE=find`. Run Find first and read the log before this job runs.

The script itself is documented in [root-scripts/Oprydning.md](root-scripts/Oprydning.md).

## Command

```bash
MODE=clean bash /volume1/root-scripts/Oprydning.sh
```

## What it does

1. Deletes `.bak`, `.tmp`, `Thumbs.db` and `~*.*` files that have not been modified for `MIN_AGE_MIN` minutes.
2. Renames files and folders with two or more consecutive spaces so the spaces collapse to one. `MIN_AGE_MIN` does not apply here - names are fixed regardless of age. Names are handled deepest-first, so contents are renamed before their folder. If the new name already exists the item is skipped and reported.
3. `CORRUPT` and `INVALID` files are never deleted.

`#recycle` and `@eaDir` are skipped.

## Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `MODE` | `clean` | `clean` deletes and renames; `find` reports only (see [Oprydning - Find.md](Oprydning%20-%20Find.md)) |
| `ROOT` | `/volume1/Dragic` | Share to clean (set in [`Oprydning.sh`](root-scripts/Oprydning.md)) |
| `MIN_AGE_MIN` | `1440` | Only delete files not modified in the last 24 hours (does not apply to the double-space renames; set in `Oprydning.sh`) |

## Notes

- Deleted files are removed with `rm` and do not go to the recycle bin.
- The file is the command for the DSM task; the task runs the `MODE=… bash …` line.
- `Oprydning.sh` must be copied from `root-scripts/` to `/volume1/root-scripts/` on the NAS.
