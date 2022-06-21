#!/usr/bin/env bash

# Install and configure iwd.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

IWD_CONFIG_SOURCE="../system_conf/iwd/main.conf"
IWD_CONFIG_DEST="/etc/iwd"
NETWORKMANAGER_CONFIG_SOURCE="../system_conf/iwd/wifi_backend.conf"
NETWORKMANAGER_CONFIG_DEST="/etc/NetworkManager/conf.d"

errMsg() {
    echo "Failed"
    pressAnyKeyToContinue
    exit 1
}

isSudo() {
    if [[ $EUID != 0 ]]; then
        echo "Run script with sudo"
        exit 1
    fi
}

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

main() {
    isSudo

    if dnf install -y iwd; then
        mkdir "$IWD_CONFIG_DEST"
        cp "$IWD_CONFIG_SOURCE" "$IWD_CONFIG_DEST"
        chmod 0644 $IWD_CONFIG_DEST/*
        cp "$NETWORKMANAGER_CONFIG_SOURCE" "$NETWORKMANAGER_CONFIG_DEST"
        chmod 0644 $NETWORKMANAGER_CONFIG_DEST/*
        systemctl restart NetworkManager

        echo "iwd has been installed"
    else
        local errcode="$?"
        echo "Failed to install iwd"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    pressAnyKeyToContinue
}

main
