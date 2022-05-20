#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

IWD_CONFIG_SOURCE="../system_conf/iwd/main.conf"
IWD_CONFIG_DEST="/etc/iwd"
NETWORKMANAGER_CONFIG_SOURCE="../system_conf/iwd/wifi_backend.conf"
NETWORKMANAGER_CONFIG_DEST="/etc/NetworkManager/conf.d"

dnf install -y iwd
mkdir $IWD_CONFIG_DEST
cp -r $IWD_CONFIG_SOURCE $IWD_CONFIG_DEST
chmod 0644 $IWD_CONFIG_DEST/*
cp -r $NETWORKMANAGER_CONFIG_SOURCE $NETWORKMANAGER_CONFIG_DEST
chmod 0644 $NETWORKMANAGER_CONFIG_DEST/*
systemctl restart NetworkManager
