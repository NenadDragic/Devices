# OPKG Update - Update.sh

This script refreshes the OpenWrt/GL.iNet router's `opkg` package index.

## How it works

The script first checks that it runs as root (`id -u`), since `opkg` needs root; otherwise it prints `FEJL: Scriptet skal køres som root.` and exits with status 1.

1. Runs `opkg update` to refresh the list of available packages from the configured feeds.

## Usage

Run this before installing or upgrading packages on the router.

```shell
#!/bin/bash

# opkg kræver root
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Scriptet skal køres som root." >&2
    exit 1
fi

opkg update
```
