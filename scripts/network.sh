#!/usr/bin/env bash

# Set configs for NetworkManager and systemd-networkd.

trap 'errMsg' ERR SIGTERM
cd "$(dirname "$0")" || exit "$?"

INTERFACE_NAME=""
WIFI_MAC=""
TMP_PATH=""
NETWORKMANAGER_CONFIG_SOURCE="../system_conf/nm.conf"
NETWORKMANAGER_CONFIG_DEST="/etc/NetworkManager/conf.d"
SYSTEMD_NETWORKD_CONFIG_SOURCE="../system_conf/systemd_networkd"
SYSTEMD_NETWORKD_CONFIG_DEST="/etc/systemd/network"
SYSTEMD_WIFI_CONFIG="00-wifi.network"
SYSTEMD_NET_CONFIG="10-net.network"

errMsg() {
    cleanup
    echo "Failed"
    pressAnyKeyToContinue
    exit 1
}

cleanup() {
    rm --recursive --force "$TMP_PATH"
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

makeTmp() {
    TMP_PATH="$(mktemp -d)"
}

getWifiMac() {
    INTERFACE_NAME=$(ip link show | grep "wl" | awk '{print $2}' | tr -d ':')
    WIFI_MAC=$(ip link show "$INTERFACE_NAME" 2>/dev/null | awk '/permaddr/ {print $6}')

    if [[ -z $WIFI_MAC ]]; then
        WIFI_MAC=$(ip link show "$INTERFACE_NAME" 2>/dev/null | awk '/link/ {print $2}')

        if [[ -z $WIFI_MAC ]]; then
            echo "Failed to detect Wi-Fi adapter MAC address"
            return 1
        fi
    fi

    return 0
}

configSystemdNetworkd() {
    if getWifiMac; then
        makeTmp
        cp "$SYSTEMD_NETWORKD_CONFIG_SOURCE/$SYSTEMD_WIFI_CONFIG" "$TMP_PATH/"
        sed -i "/MACAddress/s/\$SET_MAC/$WIFI_MAC/" "$TMP_PATH/$SYSTEMD_WIFI_CONFIG"
        cp "$TMP_PATH/$SYSTEMD_WIFI_CONFIG" "$SYSTEMD_NETWORKD_CONFIG_DEST/"
        cleanup
    fi

    cp "$SYSTEMD_NETWORKD_CONFIG_SOURCE/$SYSTEMD_NET_CONFIG" "$SYSTEMD_NETWORKD_CONFIG_DEST/"
    chmod 0644 $SYSTEMD_NETWORKD_CONFIG_DEST/*
    
    echo "Systemd Networkd has been configured"
}

configNetworkManager() {
    cp $NETWORKMANAGER_CONFIG_SOURCE $NETWORKMANAGER_CONFIG_DEST
    chmod 0644 $NETWORKMANAGER_CONFIG_DEST/*
    systemctl restart NetworkManager

    echo "Network Manager has been configured"
}

main() {
    isSudo

    configSystemdNetworkd
    configNetworkManager

    pressAnyKeyToContinue
}

main
