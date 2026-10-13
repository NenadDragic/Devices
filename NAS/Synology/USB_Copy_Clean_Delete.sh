#!/bin/bash
# Version:      1.0
# Date:         2026-10-13
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Dryrun
export MODE=Dryrun
export KEEP=3
export LOG_DAYS=0
export NOPRUNE=""
bash /volume1/root-scripts/USB_Copy_Clean_Delete.sh

# Run
export MODE=Run
export KEEP=3
export LOG_DAYS=0
export NOPRUNE=""
bash /volume1/root-scripts/USB_Copy_Clean_Delete.sh