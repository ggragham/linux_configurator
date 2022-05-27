#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

DNF_CONFIG_SOURCE="../system_conf/dnf.conf"
DNF_CONFIG_DEST="/etc/dnf/dnf.conf"
PKG_DIR="../pkgs"
HOME_DIR="/home/$SUDO_USER"
LOCAL_DIR="$HOME_DIR/.local"
OPT_DIR="$LOCAL_DIR/opt"
BIN_DIR="$LOCAL_DIR/bin"
GAMES_DIR="$LOCAL_DIR/games"
CACHE_DIR="$HOME_DIR/.cache"
VAR_DIR="$HOME_DIR/.var"

dnfConfig() {
    dnfConfFile="$(cat $DNF_CONFIG_SOURCE)"
    IFS=$'\n'
    for line in $dnfConfFile; do
        selectedLine=$(echo -e "$line" | awk -F '=' '{print $1}')
        if grep -q "$selectedLine" "$DNF_CONFIG_DEST"; then
            sed -i "s/${selectedLine}.*/${line}/g" "$DNF_CONFIG_DEST"
        else
            echo -e "$line" >>"$DNF_CONFIG_DEST"
        fi
    done
}

disableOpenh264() {
    dnf config-manager --set-disabled fedora-cisco-openh264
    dnf clean all
    dnf update -y
}

installRpmFusion() {
    sudo dnf install --nogpgcheck -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
}

baseConfigure() {
    dnf install -y $(cat "$PKG_DIR/base.pkgs")
    systemctl enable gdm
    systemctl set-default graphical.target
    plymouth-set-default-theme bgrt --rebuild-initrd
}

hideGrub() {
    grub2-editenv - set menu_auto_hide=1
    grub2-mkconfig -o /boot/grub2/grub.cfg
}

installAdditionalPkgs() {
    dnf install -y $(cat "$PKG_DIR/additional.pkgs")
}

makeLocalDir() {
    sudo -u "$SUDO_USER" mkdir -p "$OPT_DIR"
    sudo -u "$SUDO_USER" mkdir -p "$BIN_DIR"
    sudo -u "$SUDO_USER" mkdir -p "$GAMES_DIR"
}

makeBtrfsSubvols() {
    rm -rf "$CACHE_DIR"
    sudo -u "$SUDO_USER" btrfs subvolume create "$CACHE_DIR"
    rm -rf "$VAR_DIR"
    sudo -u "$SUDO_USER" btrfs subvolume create "$VAR_DIR"
}

setShell() {
    dnf install -y zsh
    usermod -s /usr/bin/zsh "$SUDO_USER"
    sh -c "$(curl https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$OPT_DIR/install.sh")"
    chown "$SUDO_USER" "$OPT_DIR/install.sh"
    export ZSH=$OPT_DIR/oh-my-zsh
    export CHSH=no
    export RUNZSH=no
    sudo -Eu "$SUDO_USER" sh "$OPT_DIR/install.sh"
}

installZshPlugins() {
    pluginDir="$ZSH/custom/plugins"
    sudo -u "$SUDO_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$pluginDir/zsh-syntax-highlighting"
    sudo -u "$SUDO_USER" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$pluginDir/zsh-autosuggestions"
}

dnfConfig
disableOpenh264
installRpmFusion
baseConfigure
hideGrub
installAdditionalPkgs
makeLocalDir
makeBtrfsSubvols
setShell
installZshPlugins
