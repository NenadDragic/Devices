# Jotta_Speedtest

Measures upload speed from the Ubuntu server `misc` to Jottacloud by adding one NAS share to the Jottacloud backup for a set time. It measures traffic on the network cards every 30 seconds, writes a CSV log, and at the end offers to remove the share from the backup again, which deletes the test upload in Jottacloud.

The share must be mounted by [`Nas_Mount.sh`](Nas_Mount.md).

---

## Usage

Run as the user `misc`, **not with `sudo`**, preferably in `tmux` because the test runs for a while:

```bash
tmux new -s jottatest
bash ~/scripts/Jotta_Speedtest.sh [minutes] [folder]
# Ctrl-b d                   detach – the test keeps running
# tmux attach -t jottatest   attach again
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `minutes` | `15` | Test duration. Stop early with Ctrl-C. |
| `folder` | `/mnt/nas/DashCam` | Mounted NAS share to upload |

`INTERVAL=<seconds>` in the environment changes the measurement interval (default `30`).

Prerequisites:

- **No sudo** (checked): `jotta-cli` must talk to `misc`'s own `jottad`.
- **`jotta-cli`** (Jottacloud CLI, from Jottacloud's own apt repository) installed and logged in, with `jottad` running (start it with `run_jottad`).
- The folder must be a mounted `cifs` share (see `Nas_Mount.sh status`).
- `ip` (`iproute2`), `findmnt`, `timeout`, `awk` – all part of a normal Ubuntu install. `tmux` is recommended, not required.

---

## What the Script Does

### Step 1 – Check prerequisites

Checks that it is not root, that `minutes` is a whole number, that `jotta-cli` exists, that the folder answers within 15 seconds and is a `cifs` mount, and that `jottad` answers. Finds the network card towards the internet (route to `1.1.1.1`) and towards the NAS (route to `NAS_HOST`).

### Step 2 – Add the folder

If the folder is already in the Jottacloud backup, it just measures. Otherwise it runs `jotta-cli add <folder>` (answer any warning about network mounts) and remembers that it added it.

### Step 3 – Measure

Every `INTERVAL` seconds it reads the byte counters in `/sys/class/net/<card>/statistics/` and prints upload (sent on the internet card) and NAS read (received on the NAS card) in Mbit/s, plus Jottacloud's used storage. Each line is also written to `~/jotta-speedtest-YYYYMMDD-HHMM.csv`. Ctrl-C stops the measurement and goes on to the summary.

### Step 4 – Summary

Average upload and NAS read in Mbit/s and MB/s, total GB, and `jotta-cli status`.

### Step 5 – Clean up

Only if the script added the folder: asks `Fjern … fra backup og slet test-uploaden i Jottacloud? [J/n]` (default yes) and runs `jotta-cli rem`. Without a terminal it does not remove anything and prints the command to do it.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Test finished |
| `1` | A prerequisite failed or `jotta-cli add` failed |

---

## Notes

- **The measurement counts all traffic on the network card**, not only Jottacloud. Other traffic during the test makes the numbers too high. If the NAS and the internet use the same card, "NAS read" also includes other incoming traffic.
- **Remove the folder before unmounting or rebooting** if you answered no at the end. Otherwise Jottacloud keeps uploading until the quota is full, and may see the locked empty folder as deleted files.
- `NAS_HOST` (`192.168.1.50`) is hardcoded and must match `Nas_Mount.sh`.
- Comments and console output are in Danish.
