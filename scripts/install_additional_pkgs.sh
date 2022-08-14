#!/usr/bin/env bash

# Install some additional packages.

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

coprInstall() {
    coprRepo="$1/$2"
    coprPkgName="$2"
    dnf copr enable -y "$coprRepo"
    dnf install -y "$coprPkgName"

    echo "$coprPkgName has been installed"
}

main() {
    isSudo

    if dnf install -y $(cat "$PKG_LIST_PATH/additional.pkgs"); then
        echo "Additional packages have been installed"
    else
        local errcode="$?"
        echo "Failed to insall additional packages"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    coprInstall "nickavem" "adw-gtk3"
    coprInstall "rubemlrm" "act-cli"

    pressAnyKeyToContinue
}

main
