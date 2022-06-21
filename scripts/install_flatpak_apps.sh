#!/usr/bin/env bash

# Install flatpak.
# Add flathub repo and support for some languages.
# Install some apps from flathub.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
PKG_LIST_PATH="../pkgs"
SCRIPT_PATH="../scripts"

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

installFlatpak() {
    if dnf install -y flatpak; then
        echo "Flatpak has been installed"
    else
        local errcode "?$"
        echo "Failed to install flatpak"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

}

configureFlatpak() {
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak remote-modify --enable flathub
    flatpak config --set languages "en;ru;ua;po;jp"

    echo "Flatpak has been configured"
}

installPkgsFromFlathub() {
    if runAsUser flatpak install -y $(cat "$PKG_LIST_PATH/flatpak.pkgs"); then
        echo "Packages from flathub have been installed"
    else
        local errcode="$?"
        echo "Failed to install packages from flathub"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

setFlatpakPkgsPermissions() {
    if runAsUser bash "$SCRIPT_PATH/set_flatpak_permissions.sh"; then
        return "$?"
    else
        local errcode="$?"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

main() {
    isSudo

    installFlatpak
    configureFlatpak
    installPkgsFromFlathub
    setFlatpakPkgsPermissions

    pressAnyKeyToContinue
}

main
