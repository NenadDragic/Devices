# Oprydning - Find

Scans `/volume1/Dragic` once and reports junk files and bad file names, without changing anything. Replaces the separate Find scripts (`bak files - Find.sh`, `tmp files - Find.sh`, `Thumbs.db files - Find.sh`, `Tilde files - Find.sh`, `Find Corrup files.sh`, `Find Invalid files.sh`, `Two or more spaces in filename - Find.sh`).

The same script is used by `Oprydning - Delete.sh`; only `MODE` differs.

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

`#recycle` and `@eaDir` are skipped.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `MODE` | `find` | `find` reports only; `clean` deletes and renames (see `Oprydning - Delete.md`) |
| `ROOT` | `/volume1/Dragic` | Share to scan |
| `MIN_AGE_MIN` | `1440` | In `clean` mode, only touch files not modified in the last 24 hours |

## Usage

```bash
bash "Oprydning - Find.sh"
```
