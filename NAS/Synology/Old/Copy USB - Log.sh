#!/bin/bash
# Version:      1.1
# Date:         2026-10-06
# Test Run:     2026-03-29
# Developper:   Nenad(a)dragic(.)com

sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo rm -rf /volumeUSB1/usbshare/Log/
