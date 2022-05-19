#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

USERNAME=""
PKG_DIR="../pkgs"

isSudo() {
    if [ "$(id -u)" -eq 0 ]; then
        USERNAME="$SUDO_USER"
    else
        USERNAME="$USER"
    fi
}

dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak config --set languages "en;ru;ua;po;jp"

isSudo
sudo -u "$USERNAME" flatpak install -y $(cat "$PKG_DIR/flatpak.pkgs")
