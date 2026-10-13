#!/bin/bash
# Version:      1.1
# Date:         2026-10-06
# Test Run:     2026-04-24
# Developper:   Nenad(a)dragic(.)com

scp -r admina@10.0.0.214:/home/admina/DNSSEC/*.txt /volume1/Dragic/Rap/DNS_Status

scp -r admina@10.0.0.214:/home/admina/DNSSEC/Old/*.txt /volume1/Dragic/Rap/DNS_Status/Old

more  "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"

rm "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"