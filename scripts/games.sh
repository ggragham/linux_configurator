#!/usr/bin/env bash

# Install lutris, wine and dependencies.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

PKG_LIST_PATH="../pkgs"

errMsg() {
    echo "Failed"
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

    if dnf install -y $(cat "$PKG_LIST_PATH/games.pkgs"); then
        echo "Gaming packages have been isntalled"
    else
        local errcode="$?"
        echo "Failed to install gaming packages"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    pressAnyKeyToContinue
}

main
