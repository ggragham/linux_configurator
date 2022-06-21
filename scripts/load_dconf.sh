#!/usr/bin/env bash

# Backup old dconf config.
# Apply dconf config from repo.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

BACKUP_PATH="../backup"
DCONF_PATH="../gnome.dconf"

errMsg() {
    echo "Failed"
    pressAnyKeyToContinue
    exit 1
}

doNotRunAsRoot() {
    if [[ $EUID == 0 ]]; then
        echo "Don't run this script as root"
        exit 1
    fi
}

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

# Define current timestamp
# and save existing dconf with timestamp postfix
backupDconf() {
    local currentTimestamp=""
    currentTimestamp="$(date +'%d_%m_%Y_%H_%M_%S')"
    dconf dump / >"$BACKUP_PATH/gnome_$currentTimestamp.dconf"

    echo "Existing dconf config has been backed up to $BACKUP_PATH/gnome_$currentTimestamp.dconf"
}

loadDconf() {
    dconf load / <"$DCONF_PATH"

    echo "Dconf config has been loaded"
}

main() {
    doNotRunAsRoot

    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
    if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]; then
        echo "Failed to load dconf config"
        pressAnyKeyToContinue
        exit 1
    fi

    backupDconf
    loadDconf

    pressAnyKeyToContinue
}

main
