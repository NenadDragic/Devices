#!/bin/bash
# Version:      1.0
# Date:         2026-10-10
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# opkg kræver root
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Scriptet skal køres som root." >&2
    exit 1
fi

opkg update
