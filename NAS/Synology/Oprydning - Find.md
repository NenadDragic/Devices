# Oprydning - Find

Command for the DSM task that runs `/volume1/root-scripts/Oprydning.sh` with `MODE=find`. It reports junk files and bad file names in `/volume1/Dragic` and shows disk usage, without changing anything. Replaces the separate Find scripts (`bak files - Find.sh`, `tmp files - Find.sh`, `Thumbs.db files - Find.sh`, `Tilde files - Find.sh`, `Find Corrup files.sh`, `Find Invalid files.sh`, `Two or more spaces in filename - Find.sh`).

`Oprydning - Delete.sh` calls the same script with `MODE=clean`. Run Find first and read the log before the Delete job runs.

The script itself is documented in [root-scripts/Oprydning.md](root-scripts/Oprydning.md).

## Command

```bash
MODE=find bash /volume1/root-scripts/Oprydning.sh
```

## What it reports

| List | Match |
| --- | --- |
| `.bak` files | `*.bak` (case-insensitive) |
| `.tmp` files | `*.tmp` (case-insensitive) |
| `Thumbs.db` | `Thumbs.db` (case-insensitive) |
| `~` files | `~*.*` |
| CORRUPT | `*CORRUPT*.*` - report only, never deleted |
| INVALID | `*INVALID*.*` - report only, never deleted |
| Double spaces | Files and folders with two or more consecutive spaces in the name |

It also shows disk usage per top-level folder (without `Log`). `#recycle` and `@eaDir` are skipped.

## Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `MODE` | `find` | `find` reports only; `clean` deletes and renames (see [Oprydning - Delete.md](Oprydning%20-%20Delete.md)) |
| `ROOT` | `/volume1/Dragic` | Share to scan (set in [`Oprydning.sh`](root-scripts/Oprydning.md)) |
| `MIN_AGE_MIN` | `1440` | Only used in `clean` mode (set in [`Oprydning.sh`](root-scripts/Oprydning.md)) |

## Notes

- The file is the command for the DSM task; the task runs the `MODE=… bash …` line.
- `Oprydning.sh` must be copied from `root-scripts/` to `/volume1/root-scripts/` on the NAS.
