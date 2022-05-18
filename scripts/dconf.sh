#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

BACKUP_PATH="../backup"
DCONF_PATH="../gnome.dconf"
USERNAME=""
USER_UID=""

isSudo() {
    if [ "$(id -u)" -eq 0 ]; then
        USERNAME="$SUDO_USER"
        USER_UID="$(id -u "$USERNAME")"
    else
        USERNAME="$USER"
        USER_UID="$(id -u)"
    fi
}

backupDconf() {
    currentTimestamp=$(date +'%d_%m_%Y_%H_%M_%S')
    dconf dump / >"$BACKUP_PATH/gnome_$currentTimestamp.dconf"
}

loadDconf() {
    dconf load / <"$DCONF_PATH"
}

isSudo
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/$USERNAME/$USER_UID/bus"export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/$USER/$USER_UID/bus"
backupDconf
loadDconf
