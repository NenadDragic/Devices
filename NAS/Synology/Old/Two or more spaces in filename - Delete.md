# Two or more spaces in filename - Delete

Finds all files and folders under `/volume1/Dragic` that have two or more consecutive spaces in their names and renames them by replacing each pair of spaces with a single space.

Limitations:

- Three spaces become two, not one (`${1//  / }` replaces non-overlapping pairs once).
- The replacement is applied to the whole path, not just the name. If a parent folder also has double spaces, the target path does not exist yet and `mv` fails.
- When a folder is renamed, `find` then tries to descend into the old path and reports an error, so its contents are not renamed in that run.

## Command

```bash
find /volume1/Dragic/ -name '*  *' -exec sh -c 'mv "$1" "${1//  / }"' find-sh {} \;
```

## Options

| Option | Description |
| --- | --- |
| `-name '*  *'` | Match filenames containing two consecutive spaces (single quotes prevent shell wildcard expansion) |
| `-exec sh -c '...' find-sh {} \;` | Execute a shell command on each matched file or folder |
| `mv "$1" "${1//  / }"` | Rename by replacing each pair of spaces in the full path with a single space |

## Usage

```bash
bash "Two or more spaces in filename - Delete.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
