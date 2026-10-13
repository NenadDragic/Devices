#!/bin/bash
# Version:      1.0
# Date:         2026-08-20
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Set SIMPLY_DDNS_APIKEY in the environment before running (do not hardcode it here).
curl -s -L "https://api.simply.com/ddns.php?apikey=${SIMPLY_DDNS_APIKEY}&domain=dragic.com&hostname=car"

