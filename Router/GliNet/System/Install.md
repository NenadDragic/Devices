# OPKG Install - Install.sh

This script installs the base set of tools this project's scripts depend on (`nano`, `git`, SFTP server, `sshpass`, `rsync`, `nmap`, `coreutils-nohup`) on the OpenWrt/GL.iNet router, then updates and upgrades all packages.

## How it works

The script first checks that it runs as root (`id -u`), since `opkg` needs root; otherwise it prints `FEJL: Scriptet skal køres som root.` and exits with status 1.

1. Installs `nano`, `git`, `openssh-sftp-server`, `sshpass`, `rsync`, `nmap`, and `coreutils-nohup` via `opkg install`.
2. Refreshes the package index with `opkg update`.
3. Lists upgradable packages and upgrades each one via `opkg upgrade`.
4. Includes commented-out `scp` commands for copying scripts to the router (`root@192.168.8.1:/root/Scripts/Old` and `root@192.168.1.1:/root`), left as reference/manual steps.

## Usage

Run once on a fresh router setup to install dependencies, or re-run to refresh and upgrade existing packages.

```shell
#!/bin/bash

# opkg kræver root
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Scriptet skal køres som root." >&2
    exit 1
fi

opkg install nano git openssh-sftp-server sshpass rsync nmap coreutils-nohup
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade

#scp *  root@192.168.8.1:/root/Scripts/Old

#scp -r * root@192.168.1.1:/root
```
