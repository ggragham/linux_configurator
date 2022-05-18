#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

OWNER_USERNAME="$SUDO_USER"
DEST_PATH="/home/$OWNER_USERNAME/.local/opt"
REPO_NAME="LinuxConfigurator"
SCRIPT_NAME="run.sh"

isSudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "Run as sudo"
        exit
    fi
}

cloneRepo() {
    sudo -u "$OWNER_USERNAME" mkdir -p "$DEST_PATH"
    sudo -u "$OWNER_USERNAME" git clone https://github.com/ggragham/dotfiles.git "$DEST_PATH/$REPO_NAME"
}

runConfig() {
    cd "$DEST_PATH/$REPO_NAME" || exit
    sudo -u "$OWNER_USERNAME" bash "$DEST_PATH/$REPO_NAME/$SCRIPT_NAME"
}

isSudo
if git --version 2>/dev/null 1>&2; then
    cloneRepo
    runConfig
else
    if dnf --setopt=install_weak_deps=False --setopt=countme=False install git -y; then
        cloneRepo
        runConfig
    else
        echo -e "Unable to install git"
    fi
fi
