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
