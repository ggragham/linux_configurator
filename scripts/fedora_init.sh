#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

DNF_CONFIG_SOURCE="../system_conf/dnf.conf"
DNF_CONFIG_DEST="/etc/dnf/dnf.conf"
PKG_DIR="../pkgs"
LOCAL_DIR="/home/$SUDO_USER/.local/opt"
OPT_DIR="$LOCAL_DIR/opt"

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

makeOptDir() {
    sudo -u "$SUDO_USER" mkdir -p "$OPT_DIR"
}

setShell() {
    dnf install -y zsh
    usermod -s /usr/bin/zsh "$SUDO_USER"
    sh -c "$(curl https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$OPT_DIR/install.sh")"
    chown "$SUDO_USER" "$OPT_DIR/install.sh"
    export ZSH=$OPT_DIR/oh-my-zsh
    export CHSH=no
    sudo -u "$SUDO_USER" sh "$OPT_DIR/install.sh"
}

dnfConfig
disableOpenh264
installRpmFusion
baseConfigure
hideGrub
installAdditionalPkgs
makeOptDir
setShell
