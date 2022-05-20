#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

INTERFACE_NAME=""
WIFI_MAC=""
NETWORKMANAGER_CONFIG_SOURCE="../system_conf/nm.conf"
NETWORKMANAGER_CONFIG_DEST="/etc/NetworkManager/conf.d"
SYSTEMD_NETWORD_CONFIG_SOURCE="../system_conf/systemd_networkd"
SYSTEMD_NETWORD_CONFIG_DEST="/etc/systemd/network"
SYSTEMD_WIFI_CONFIG="00-wifi.network"

getWifiMac() {
    INTERFACE_NAME=$(ip link show | grep "wl" | awk '{print $2}' | tr -d ':')
    WIFI_MAC=$(ip link show "$INTERFACE_NAME" | awk '/permaddr/ {print $6}')
    if [ -z "$WIFI_MAC" ]; then
        WIFI_MAC=$(ip link show "$INTERFACE_NAME" | awk '/link/ {print $2}')
    fi
}

configNetworkManager() {
    cp $NETWORKMANAGER_CONFIG_SOURCE $NETWORKMANAGER_CONFIG_DEST
    chmod 0644 $NETWORKMANAGER_CONFIG_DEST/*
    systemctl restart NetworkManager
}

configSystemdNetworkd() {
    cp -r $SYSTEMD_NETWORD_CONFIG_SOURCE/. $SYSTEMD_NETWORD_CONFIG_DEST
    sed -i "/MACAddress/s/\$SET_MAC/$WIFI_MAC/" $SYSTEMD_NETWORD_CONFIG_DEST/$SYSTEMD_WIFI_CONFIG
    chmod 0644 $/SYSTEMD_NETWORD_CONFIG_DEST/*
}

getWifiMac
configNetworkManager
configSystemdNetworkd
