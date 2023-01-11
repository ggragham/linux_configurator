#!/usr/bin/env bash

# Interactive menu to select themes to install.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

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
        echo "1. Install Papirus icon theme"
        echo "2. Install adw-gtk3 theme"
        echo
        echo "0. Back"
        echo

        case $select in
        1)
            dnf install -y papirus-icon-theme
            select="*"
            ;;
        2)
            dnf copr enable -y nickavem/adw-gtk3
            dnf install -y adw-gtk3
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
