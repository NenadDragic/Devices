# Web-Stat

Copies web status HTML reports from a remote host to the NAS.

## Command

```bash
scp admina@10.0.0.214:'/home/admina/Web-Stat/reports/*.html' \
    /volume1/Dragic/Rap/Web_Status/
```

## Options

| Option | Description |
| ------ | ----------- |
| `admina@10.0.0.214` | Remote user and host IP |
| `/home/admina/Web-Stat/reports/*.html` | Source HTML reports on the remote host (quoted so the glob expands on the remote side, not locally) |
| `/volume1/Dragic/Rap/Web_Status/` | Destination directory on the NAS |

## Usage

```bash
bash "Web-Stat.sh"
```

Ensure SSH access (key-based) to `10.0.0.214` is available before running, and that `/volume1/Dragic/Rap/Web_Status/` already exists on the NAS.
