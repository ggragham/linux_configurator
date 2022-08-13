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

installNVM() {
    local optName="Node Version Manager"
    local optFileName=install_nvm.sh
    local downloadURL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
    export NVM_DIR=$OPT_PATH/nvm
    runAsUser mkdir -p "$NVM_DIR"
    installOpt "$optName" "$optFileName" "$downloadURL"
}

installPyenv() {
    local optName="Simple Python Version Management"
    local optFileName=install_pyenv.sh
    local downloadURL="https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer"
    export PYENV_ROOT=$OPT_PATH/pyenv
    installOpt "$optName" "$optFileName" "$downloadURL"
}

main() {
    isSudo

    installNVM
    installPyenv

    pressAnyKeyToContinue
}

main
