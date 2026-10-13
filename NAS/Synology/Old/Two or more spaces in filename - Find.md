# Two or more spaces in filename - Find

Finds all files and folders under `/volume1/Dragic` that have two or more consecutive spaces in their names (there is no `-type f`, so folders are listed too).

## Command

```bash
find /volume1/Dragic/ -name '*  *'
```

## Options

| Option | Description |
| --- | --- |
| `-name '*  *'` | Match filenames containing two consecutive spaces (single quotes prevent shell wildcard expansion) |

## Usage

```bash
bash "Two or more spaces in filename - Find.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
