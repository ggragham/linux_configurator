#!/usr/bin/env bash

# Make nested BTRFS subvolumes.

#BACKUP_PATH="../backup"
CURRENT_DIR="$1"
DIR_NAME="$2"

# set -euo pipefail

# Backup dir.
if [[ -d $CURRENT_DIR ]]; then
	currentTimestamp="$(date +'%d_%m_%Y_%H_%M_%S')"
	mv "$CURRENT_DIR" "$BACKUP_PATH/${DIR_NAME}_$currentTimestamp"
fi

# Create BTRFS subvol.
if btrfs subvolume create "$CURRENT_DIR"; then
	echo "Nested BTRFS subvolume for $CURRENT_DIR has been created"
else
	errcode="$?"
	echo "Failed to create subvol for $CURRENT_DIR"
	exit "$errcode"
fi
