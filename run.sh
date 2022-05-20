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
    echo "2. Install additional packages"
    echo "3. Install flatpak apps"
    echo "4. Load dotfile"
    echo "5. Load dconf"
    echo "6. Fix gnome extensions compability"
    echo
    echo "0. Exit"
    echo
    case $select in
    1)
        bash "$SCRIPT_PATH/fedora_init.sh"
        select="*"
        ;;
    2)
        bash "$SCRIPT_PATH/more_additional_pkgs.sh"
        select="*"
        ;;
    3)
        bash "$SCRIPT_PATH/flatpak.sh"
        select="*"
        ;;
    4)
        sudo -u "$USERNAME" bash "$SCRIPT_PATH/dotfiles.sh"
        select="*"
        ;;
    5)
        sudo -u "$USERNAME" bash "$SCRIPT_PATH/dconf.sh"
        select="*"
        ;;
    6)
        sudo -u "$USERNAME" bash "$SCRIPT_PATH/fix_gnome_extensions.sh"
        select="*"
        ;;
    0)
        exit
        ;;
    *)
        read -rp "Select: " select
        continue
        ;;
    esac
done
