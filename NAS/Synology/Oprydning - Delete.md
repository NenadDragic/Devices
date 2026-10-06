# Oprydning - Delete

Scans `/volume1/Dragic` once, deletes junk files and fixes file names with double spaces. Replaces the separate Delete scripts (`bak files - Delete.sh`, `tmp files - Delete.sh`, `Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`, `Two or more spaces in filename - Delete.sh`).

The same script is used by `Oprydning - Find.sh`; only `MODE` differs.

> **Note:** The repo version (1.1) has `MODE=clean`. The job on the NAS still had `MODE=find` in the config backup of 2026-10-06 and must be updated there too.

## What it does

1. Deletes `.bak`, `.tmp`, `Thumbs.db` and `~*.*` files that have not been modified for `MIN_AGE_MIN` minutes.
2. Renames files and folders with two or more consecutive spaces so the spaces collapse to one. Names are handled deepest-first, so contents are renamed before their folder. If the new name already exists the item is skipped and reported.
3. `CORRUPT` and `INVALID` files are never deleted.

`#recycle` and `@eaDir` are skipped.

## Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `MODE` | `clean` | `clean` deletes and renames; `find` reports only |
| `ROOT` | `/volume1/Dragic` | Share to clean |
| `MIN_AGE_MIN` | `1440` | Only touch files not modified in the last 24 hours |

## Usage

```bash
bash "Oprydning - Delete.sh"
```

Deleted files are removed with `rm` and do not go to the recycle bin.
