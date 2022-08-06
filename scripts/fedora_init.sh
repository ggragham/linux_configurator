#!/usr/bin/env bash

# Only for Fedora Linux.
# Apply base configs, disable unused repos,
# add usefull repo, install core system pkgs,
# drivers, DE, base environment apps, etc.
# Make useful dirs and nested subvols
# to exlude unwanted dirs from snapshots.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
DNF_CONFIG_SOURCE="../system_conf/dnf.conf"
DNF_CONFIG_DEST="/etc/dnf/dnf.conf"
PKG_LIST_PATH="../pkgs"
HOME_PATH="/home/$SUDO_USER"
LOCAL_PATH="$HOME_PATH/.local"
OPT_PATH="$LOCAL_PATH/opt"
BIN_PATH="$LOCAL_PATH/bin"
GAMES_PATH="$LOCAL_PATH/games"
CACHE_PATH="$HOME_PATH/.cache"
VAR_PATH="$HOME_PATH/.var"

errMsg() {
    echo "Failed"
    pressAnyKeyToContinue
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

dnfConfig() {
    dnfConfFile="$(cat $DNF_CONFIG_SOURCE)"
    IFS=$'\n'
    # Find lines from $DNF_CONFIG_SOURCE in $DNF_CONFIG_DEST
    # and replace their values.
    # If there are no lines in file
    # it will add them.
    for line in $dnfConfFile; do
        selectedLine=$(echo -e "$line" | awk -F '=' '{print $1}')
        if grep -q "$selectedLine" "$DNF_CONFIG_DEST"; then
            sed -i "s/${selectedLine}.*/${line}/g" "$DNF_CONFIG_DEST"
        else
            echo -e "$line" >>"$DNF_CONFIG_DEST"
        fi
    done

    echo "DNF has been configured"
}

disableOpenh264Repo() {
    dnf config-manager --set-disabled fedora-cisco-openh264
    dnf clean all

    echo "Openh264 repo has been disabled"
}

installRpmFusionRepo() {
    if dnf update -y; then
        dnf install --nogpgcheck -y \
            https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
            https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
    else
        local errcode="$?"
        echo "Failed to install RPM Fusion "
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    echo "RPM Fusion has been installed"
}

baseConfiguration() {
    if dnf install -y $(cat "$PKG_LIST_PATH/core.pkgs"); then
        systemctl enable gdm
        systemctl set-default graphical.target
        plymouth-set-default-theme bgrt --rebuild-initrd
    else
        local errcode="$?"
        echo "Failed to install core packages"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    echo "Base system has been configured"
}

hideGrubOnStartup() {
    grub2-editenv - set menu_auto_hide=1
    grub2-mkconfig -o /boot/grub2/grub.cfg

    echo "Grub will no longer show up on startup"
}

installBasePkgs() {
    if dnf install -y $(cat "$PKG_LIST_PATH/base.pkgs"); then
        echo "Base packages have been installed"
    else
        local errcode="$?"
        echo "Failed to install base packages"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

}

makeLocalDirs() {
    makeDirs() { (
        set -eu
        runAsUser mkdir -p "$OPT_PATH"
        runAsUser mkdir -p "$BIN_PATH"
        runAsUser mkdir -p "$GAMES_PATH"
    ); }

    if makeDirs; then
        echo "Local dirs have been created"
    else
        local errcode="$?"
        echo "Failed to create local dirs"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

makeNestedBtrfsSubvols() {
    makeBtrfsSubvol() {
        if rm --recursive --force "$@"; then
            runAsUser btrfs subvolume create "$@"
        else
            local errcode="$?"
            echo "Failed to create subvol for $*"
            pressAnyKeyToContinue
            exit "$errcode"
        fi

        echo "Nested BTRFS subvolume for $* has been created"
    }

    # makeBtrfsSubvol "$CACHE_PATH"
    makeBtrfsSubvol "$VAR_PATH"
}

main() {
    isSudo

    dnfConfig
    disableOpenh264Repo
    installRpmFusionRepo
    baseConfiguration
    hideGrubOnStartup
    installBasePkgs
    makeLocalDirs
    makeNestedBtrfsSubvols

    pressAnyKeyToContinue
}

main
