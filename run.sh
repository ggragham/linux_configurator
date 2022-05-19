#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

USERNAME=""
SCRIPT_PATH="./scripts"

isSudo() {
    if [ "$(id -u)" -eq 0 ]; then
        USERNAME="$SUDO_USER"
    else
        USERNAME="$USER"
    fi
}

isSudo
select="*"
while :; do
    clear
    echo "Linux Configurator"
    echo
    echo "1. Base system configuration"
    echo "2. Load dotfile"
    echo "3. Load dconf"
    echo "4. Install flatpak apps"
    echo
    case $select in
    1)
        bash "$SCRIPT_PATH/fedora_init.sh"
        select="*"
        ;;
    2)
        sudo -u "$USERNAME" bash "$SCRIPT_PATH/dotfiles.sh"
        select="*"
        ;;
    3)
        sudo -u "$USERNAME" bash "$SCRIPT_PATH/dconf.sh"
        select="*"
        ;;
    4)
        bash "$SCRIPT_PATH/flatpak.sh"
        select="*"
        ;;
    *)
        read -rp "Select: " select
        continue
        ;;
    esac
done
