#!/bin/bash
# Version:      1.0
# Date:         2026-10-10
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av ~ -e "ssh -l Debian_Backup" "nas.dragic.com::NetBackup/Muddi-E750/$(date +%Y-%m-%d)"

rm /tmp/pw_pipe

#Exit
exit
