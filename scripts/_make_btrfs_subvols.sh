#!/usr/bin/env bash

# Make nested BTRFS subvolumes.

#BACKUP_PATH="../backup"
CURRENT_DIR="$1"
DIR_NAME="$2"

# set -euo pipefail

# Check for subvol existing.
if [ "$(stat --format=%i "$CURRENT_DIR")" == "256" ]; then
	echo "Nested subvolume already created"
	exit 0
fi

# Backup dir.
if [[ -d $CURRENT_DIR ]]; then
	currentTimestamp="$(date +'%d_%m_%Y_%H_%M_%S')"
	if mv "$CURRENT_DIR" "$BACKUP_PATH/${DIR_NAME}_$currentTimestamp"; then
		echo "Backup of $CURRENT_DIR was successful"
	else
		errcode="$?"
		echo "Backup of $CURRENT_DIR failed"
		exit "$errcode"
	fi
fi

# Create BTRFS subvol.
if btrfs subvolume create "$CURRENT_DIR"; then
	echo "Nested BTRFS subvolume for $CURRENT_DIR has been created"
else
	errcode="$?"
	echo "Failed to create subvol for $CURRENT_DIR"
	exit "$errcode"
fi
