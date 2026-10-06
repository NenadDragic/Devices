# Oprydning - Delete

Scans `/volume1/Dragic` once, deletes junk files and fixes file names with double spaces. Replaces the separate Delete scripts (`bak files - Delete.sh`, `tmp files - Delete.sh`, `Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`, `Two or more spaces in filename - Delete.sh`).

The same script is used by `Oprydning - Find.sh`; only `MODE` differs.

> **Note:** The version on the NAS (and in this repo) has `MODE=find`, so this job currently only reports, exactly like `Oprydning - Find.sh`. Set `MODE=clean` to make it delete.

## What it does in `clean` mode

1. Deletes `.bak`, `.tmp`, `Thumbs.db` and `~*.*` files that have not been modified for `MIN_AGE_MIN` minutes.
2. Renames files and folders with two or more consecutive spaces so the spaces collapse to one. Names are handled deepest-first, so contents are renamed before their folder. If the new name already exists the item is skipped and reported.
3. `CORRUPT` and `INVALID` files are never deleted.

`#recycle` and `@eaDir` are skipped.

## Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `MODE` | `find` | `find` reports only; `clean` deletes and renames |
| `ROOT` | `/volume1/Dragic` | Share to clean |
| `MIN_AGE_MIN` | `1440` | Only touch files not modified in the last 24 hours |

## Usage

```bash
bash "Oprydning - Delete.sh"
```

Deleted files are removed with `rm` and do not go to the recycle bin.
