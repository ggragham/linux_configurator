#!/usr/bin/env bash

# Install and configure Bottles

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"

errMsg() {
    echo "Failed"
    exit 1
}

isSudo() {
    if [[ $EUID != 0 ]] || [[ -z $USERNAME ]]; then
        echo "Run script with sudo"
        exit 1
    fi
}

runAsUser() {
    sudo -u "$USERNAME" "$@"
}

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

main() {
    isSudo

    if runAsUser flatpak install -y com.usebottles.bottles; then
        runAsUser flatpak override --user \
            --filesystem=xdg-data/applications \
            com.usebottles.bottles
        echo "Bottles package have been installed and configured"
    else
        local errcode="$?"
        echo "Failed to install Bottles package"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    pressAnyKeyToContinue
}

main

# Yep. So many lines of code just to install only the one package  ╮(. ❛ ᴗ ❛.)╭
