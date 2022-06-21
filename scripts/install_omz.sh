#!/usr/bin/env bash

# Install zsh, Oh My Zsh and some plugins.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
OPT_PATH="/home/$USERNAME/.local/opt"

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

installZSH() {
    if dnf install -y zsh; then
        usermod -s /usr/bin/zsh "$USERNAME"
        echo "zsh has been installed"
    else
        local errcode="$?"
        echo "Failed to install zsh"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

installOMZ() {
    local omzDownloadURL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    runAsUser curl "$omzDownloadURL" -o "$OPT_PATH/install.sh"
    export ZSH=$OPT_PATH/oh-my-zsh
    export CHSH=no
    export RUNZSH=no
    if [[ -f "$OPT_PATH/install.sh" ]]; then
        runAsUser bash "$OPT_PATH/install.sh"
        echo "Oh My Zsh has been installed"
    else
        echo "Failed to install Oh My Zsh"
        pressAnyKeyToContinue
        exit 1
    fi

}

installOMZPlugins() {
    local pluginDir="$ZSH/custom/plugins"
    if [[ -d $pluginDir ]]; then
        runAsUser git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$pluginDir/zsh-syntax-highlighting"
        runAsUser git clone https://github.com/zsh-users/zsh-autosuggestions.git "$pluginDir/zsh-autosuggestions"
        echo "Plugins for Oh My Zsh have been installed"
    else
        echo "Failed to install plugins for Oh My Zsh"
        pressAnyKeyToContinue
        exit 1
    fi
}

main() {
    isSudo

    installZSH
    installOMZ
    installOMZPlugins

    pressAnyKeyToContinue
}

main
