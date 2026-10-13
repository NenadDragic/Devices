#!/bin/bash
# Version:      1.2
# Date:         2026-10-06
# Test Run:     2026-04-13
# Developper:   Nenad(a)dragic(.)com

sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/ \
  /volume1/NetBackup/

sudo find /volumeUSB1/usbshare/NetBackup/ -type d -empty -delete

sudo rm -rf /volumeUSB1/usbshare/
