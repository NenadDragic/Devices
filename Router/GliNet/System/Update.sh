#!/bin/bash

# opkg kræver root
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Scriptet skal køres som root." >&2
    exit 1
fi

opkg update
