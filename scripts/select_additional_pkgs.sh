#!/usr/bin/env bash

# Interactive menu to execute other
# package installation scripts.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

SCRIPT_PATH="../scripts"

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

main() {
    isSudo

    local select="*"
    while :; do
        clear
        echo
        echo "1. Install more packages"
        echo "2. Install Oh My Zsh"
        echo "3. Install DevOps packages"
        echo "4. Install optional pkgs"
        echo "5. Install nvim"
        echo "6. Install Flatpak apps"
        echo "7. I want play the games"
        echo
        echo "0. Back"
        echo

        case $select in
        1)
            bash "$SCRIPT_PATH/install_additional_pkgs.sh"
            select="*"
            ;;
        2)
            bash "$SCRIPT_PATH/install_omz.sh"
            select="*"
            ;;
        3)
            bash "$SCRIPT_PATH/install_devops_pkgs.sh"
            select="*"
            ;;
        4)
            bash "$SCRIPT_PATH/install_opts.sh"
            select="*"
            ;;
        5)
            bash "$SCRIPT_PATH/install_nvim.sh"
            select="*"
            ;;
        6)
            bash "$SCRIPT_PATH/install_flatpak_apps.sh"
            select="*"
            ;;
        7)
            bash "$SCRIPT_PATH/install_gaming_pkgs.sh"
            select="*"
            ;;
        0)
            exit 0
            ;;
        *)
            read -rp "Select: " select
            continue
            ;;
        esac
    done
}

main
