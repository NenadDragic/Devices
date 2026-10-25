#!/bin/bash
# Version:      1.0
# Date:         2026-10-10
# Test Run:
# Developper:   Nenad(a)dragic(.)com

files_count=0

echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
echo ""
echo "Uptime: $(uptime)"
echo ""

files_count=$(find /mnt/sda1/DCIM/Photo -maxdepth 1 -type f | wc -l)
echo "Photos: $files_count"

files_count=$(find /mnt/sda1/DCIM/Movie -maxdepth 1 -type f | wc -l)
echo "Movie: $files_count"

files_count=$(find /mnt/sda1/DCIM/Movie/RO -maxdepth 1 -type f | wc -l)
echo "Movie RO: $files_count" 

files_count=$(find /mnt/sda1/DCIM/Movie/Parking -maxdepth 1 -type f | wc -l)
echo "Movie Parking: $files_count"

echo ""
echo "Disk Info:"
df -h
echo ""
echo "WWAN0:"
ip address show wwan0 | grep 'inet'
echo ""
echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
