# Nas_Mount

Manages the NAS shares that the Ubuntu server `misc` mounts **read-only** over SMB for remote backup (IDrive and Jottacloud). Each Synology shared folder is its own SMB share with its own line in `/etc/fstab`, mounted by systemd-automount on first access and unmounted at shutdown. The script generates the fstab lines, creates the credentials file, and mounts, unmounts and checks the shares.

[`Nas_Backup.sh`](Nas_Backup.md) and [`Jotta_Speedtest.sh`](Jotta_Speedtest.md) expect this script at `~/scripts/Nas_Mount.sh` on the server.

---

## Usage

```bash
sudo ./Nas_Mount.sh creds    # create the credentials file (asks for user name/password)
     ./Nas_Mount.sh fstab    # print the fstab lines for NAS_SHARES
sudo ./Nas_Mount.sh mount    # start automount and mount all shares
sudo ./Nas_Mount.sh umount   # unmount all shares (until 'mount' or a reboot)
     ./Nas_Mount.sh status   # show status, no root needed
```

First-time setup:

1. `sudo apt install cifs-utils`
2. `sudo ./Nas_Mount.sh creds`
3. `./Nas_Mount.sh fstab | sudo tee -a /etc/fstab` and `sudo systemctl daemon-reload`
4. `sudo ./Nas_Mount.sh mount` and `./Nas_Mount.sh status`

Prerequisites:

- **Root for `creds`, `mount` and `umount`.** Run as a normal user, the script restarts itself with `sudo`. That needs the file to be executable (`chmod +x`). `fstab` and `status` do not need root.
- **Packages:** `cifs-utils` (`mount.cifs`, checked by `mount`) and systemd. `fuser` (package `psmisc`) is optional and only used to show which processes block an unmount.
- The local group `MOUNT_GROUP` (`misc`) must exist, and the backup user must be in it.

### Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `NAS_HOST` | `192.168.1.50` | IP or DNS name of the NAS |
| `NAS_SHARES` | `DashCam Dragic NetBackup` | Shared folders; each is mounted at `$MOUNT_BASE/<name>` |
| `MOUNT_BASE` | `/mnt/nas` | Parent folder of the mount points |
| `CRED_FILE` | `/etc/nas/nas.cred` | Credentials file, `root:root` `0600` |
| `MOUNT_OWNER` / `MOUNT_GROUP` | `root` / `misc` | Local owner and group of the files on the mount |
| `SMB_VERS` | `3.0` | SMB version |
| `EXTRA_OPTS` | empty | Extra mount options, for example `seal` for encrypted transport. `rw` is refused. |
| `TIMEOUT` | `10` | Seconds for network, mount and response checks |

---

## What the Script Does

### `creds`

Asks for user name, password (twice, hidden) and an optional domain, and writes them to `CRED_FILE` with `umask 077`, then `root:root` `0600`. Creates the folder with `0700` only if it does not exist, so it never changes permissions on an existing folder like `/etc`. Asks before overwriting an existing file.

### `fstab`

Prints one line per share with these options: `ro`, `credentials=`, `vers=`, `uid=`/`gid=`, `file_mode=0440`, `dir_mode=0550`, `nosuid,nodev,noexec`, `iocharset=utf8`, `_netdev,nofail`, `x-systemd.automount`, `x-systemd.mount-timeout=30`. Spaces in share names are escaped as `\040`.

### `mount`

Checks `mount.cifs`, the credentials file and its permissions (warns if not `root` and `600`/`400`), and that the NAS answers on port 445. For each share it:

1. Checks that the automount unit exists, meaning the share is in `/etc/fstab`.
2. Locks the empty mount point folder (`chmod 000`).
3. Starts the `.automount` unit and triggers the mount by accessing the folder.
4. Checks in `/proc/self/mountinfo` that the right share is mounted as `cifs`, and that the kernel really mounted it `ro`. A share that is not read-only is unmounted again.

### `umount`

Stops the automount and mount units, unmounts any `cifs` mount left over, and locks the folder again. It does not touch a folder that has something else mounted on it. If unmounting fails, it lists the processes using it (`fuser`).

### `status`

Shows whether the NAS answers on port 445, then one line per share: not in fstab, not mounted (folder locked or not), automount active but mount failed, wrong share mounted, or mounted with read-only state and disk usage. A mount that does not answer within `TIMEOUT` is reported as possibly stale.

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | All OK |
| `1` | At least one share not mounted or failed, or a setup error (no `cifs-utils`, no credentials, NAS unreachable) |
| `2` | Problem: not read-only, not answering, wrong source, or missing in `/etc/fstab` |

---

## Notes

- **Why the empty folders are locked:** when a share is not mounted, its folder is `chmod 000`, so it gives "Permission denied" instead of looking empty. A backup program that sees an empty folder could otherwise think all files were deleted and remove them from the backup.
- **Read-only is checked, not just requested.** The script reads the real mount options from the kernel.
- **The password is stored in plain text** in `CRED_FILE`, readable only by root. Use a NAS user with read-only rights to the shares.
- `status` reads `/proc/self/mountinfo` directly, so it does not hang if the NAS is gone.
- `NAS_HOST` is also hardcoded in `Jotta_Speedtest.sh`. Change both if the NAS gets a new address.
- Comments and console output are in Danish.
