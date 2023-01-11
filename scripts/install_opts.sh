#!/usr/bin/env bash

# Install zsh, Oh My Zsh and some plugins.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
PKG_LIST_PATH="../pkgs"
LOCAL_PATH="/home/$USERNAME/.local"
OPT_PATH="$LOCAL_PATH/opt"
BIN_PATH="$LOCAL_PATH/bin"

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
    sudo -Eu "$USERNAME" "$@"
}

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

downloadScritps() {
    local pkgsFile=""
    pkgsFile="$(cat "$PKG_LIST_PATH/script.pkgs")"
    IFS=$'\n'

    for scriptName in $pkgsFile; do
        echo "Downloading $scriptName"
        runAsUser curl "https://raw.githubusercontent.com/ggragham/just_bunch_of_scripts/master/linux/bin/$scriptName" -o "$BIN_PATH/$scriptName"
        runAsUser chmod +x "$BIN_PATH/$scriptName"
    done

    echo "Scripts has been downloaded"
}

installOpt() {
    local optName="$1"
    local optFileName="$2"
    local downloadURL="$3"
    runAsUser curl "$downloadURL" -o "$OPT_PATH/$optFileName"

    if [[ -f "$OPT_PATH/$optFileName" ]]; then
        runAsUser bash "$OPT_PATH/$optFileName"
        echo "$optName has been installed"
    else
        echo "Failed to install $optName"
        pressAnyKeyToContinue
        exit 1
    fi
}

main() {
    isSudo
    downloadScritps
    pressAnyKeyToContinue
}

main
