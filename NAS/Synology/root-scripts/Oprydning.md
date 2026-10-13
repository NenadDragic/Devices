# Oprydning

Cleanup script for the `Dragic` share. It scans `/volume1/Dragic` once per run and, depending on `MODE`, either reports junk files, bad file names and disk usage per folder (`find`) or deletes the junk files and fixes the names (`clean`). It lives at `/volume1/root-scripts/Oprydning.sh` on the NAS and is called by two DSM tasks:

| DSM task | Command |
| --- | --- |
| [`Oprydning - Find`](../Oprydning%20-%20Find.md) | `MODE=find bash /volume1/root-scripts/Oprydning.sh` |
| [`Oprydning - Delete`](../Oprydning%20-%20Delete.md) | `MODE=clean bash /volume1/root-scripts/Oprydning.sh` |

It replaces the separate Find/Delete scripts for `.bak`, `.tmp`, `Thumbs.db`, `~` files, CORRUPT/INVALID files and double spaces, and `Disk Used size - Dragic` (all in `../Old/`).

---

## Usage

```bash
MODE=find  bash /volume1/root-scripts/Oprydning.sh
MODE=clean bash /volume1/root-scripts/Oprydning.sh
```

Without `MODE` the script runs `find`, so a task that forgets to set `MODE` never deletes anything. Run the Find task first and read its log before the Delete task runs.

### Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `MODE` | `find` (from the environment) | `find` reports only; `clean` deletes and renames. Anything else exits with an error |
| `ROOT` | `/volume1/Dragic` | Share to scan |
| `MIN_AGE_MIN` | `1440` | In `clean` mode, only delete files not modified in the last 24 hours |
| `SIZE_SKIP` | `Log` | Disk usage: files and folders with this name (and everything under them) are not counted |

Only `MODE` is read from the environment; the others are set in the script.

---

## What the Script Does

### Step 1 – Check

Exits with code `1` if `MODE` is not `find` or `clean`, or if `ROOT` does not exist. Prints `MODE` and `ROOT`.

### Step 2 – One scan

A single `find` over `ROOT`, skipping `#recycle` and every `@eaDir`, writes each match to its own list:

| List | Match | Age filter in `clean` |
| --- | --- | --- |
| `.bak` files | `*.bak` (case-insensitive) | Yes |
| `.tmp` files | `*.tmp` (case-insensitive) | Yes |
| `Thumbs.db` | `Thumbs.db` (case-insensitive) | Yes |
| `~` files | `~*.*` | Yes |
| CORRUPT | `*CORRUPT*.*` | Report only |
| INVALID | `*INVALID*.*` | Report only |
| Double spaces | Files and folders with two or more consecutive spaces in the name | No |

In `find` mode the same scan also prints the block count of every file and folder, which is summed per top-level item of `ROOT`.

### Step 3a – `find`: report

Prints each list with its count, then `Diskforbrug pr. mappe` - the size of each top-level folder (and loose file) in `ROOT`, sorted by name, followed by `I alt`. Sizes are in B/KB/MB/GB/TB (1024-based) and are based on allocated blocks, like `du`. Exits with `0`.

### Step 3b – `clean`: delete and rename

1. Deletes the `.bak`, `.tmp`, `Thumbs.db` and `~` files with `rm` and lists what was deleted. A file already deleted via another list (e.g. `~WRL1.tmp`) is skipped.
2. Renames files and folders with double spaces so each run of spaces becomes one space. Names are handled deepest-first, so contents are renamed before their folder. If the new name already exists, the item is skipped and reported (`SPRUNGET OVER`).
3. CORRUPT and INVALID files are never deleted.

---

## Notes

- **Destructive in `clean` mode:** files are removed with `rm` and do not go to the recycle bin. The double-space renames ignore `MIN_AGE_MIN`.
- **Disk usage is only calculated in `find` mode.** It excludes `#recycle`, `@eaDir` and anything named `Log`. Hard-linked files are counted once per link, unlike `du`.
- The scan runs once per run, so a big share is only traversed once even though seven lists and the disk usage are produced.
- Comments and console output are in Danish.
