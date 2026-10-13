#!/bin/bash
# Version:      1.0
# Date:         2026-10-10
# Test Run:
# Developper:   Nenad(a)dragic(.)com

mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /mnt/sda1/DCIM/Movie/RO -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam/Movie

rm /tmp/pw_pipe

#Exit
exit
