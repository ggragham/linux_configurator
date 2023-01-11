#!/usr/bin/env bash

# Install pkgs for development.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
PKG_LIST_PATH="../pkgs"
HOME_PATH="/home/$USERNAME"
LOCAL_PATH="$HOME_PATH/.local"
SHARE_PATH="$LOCAL_PATH/share"
BACKUP_PATH="../backup"
GNOME_BOXES_DIR_NAME="gnome-boxes"
GNOME_BOXES_LOCAL_PATH="$SHARE_PATH/$GNOME_BOXES_DIR_NAME/"
GNOME_BOXES_LOCAL_IMAGES_PATH="$GNOME_BOXES_LOCAL_PATH/images"
LIBVIRT_DIR_NAME="libvirt"
LIBVIRT_LOCAL_PATH="$SHARE_PATH/$LIBVIRT_DIR_NAME"
LIBVIRT_LOCAL_IMAGES_PATH="$LIBVIRT_LOCAL_PATH/images"

errMsg() {
    cleanup
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

installPkgsFromRepo() {
    if dnf install -y $(cat "$PKG_LIST_PATH/dev.pkgs"); then
        echo "Dev packages from repo have been installed"
    else
        local errcode="$?"
        echo "Failed to insall packages"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

configureVirtDirs() {
    backupDirs() {
        local currentDir="$1"
        local dirName="$2"
        if [[ -d $currentDir ]]; then
            local currentTimestamp=""
            currentTimestamp="$(date +'%d_%m_%Y_%H_%M_%S')"
            runAsUser mv "$currentDir" "$BACKUP_PATH/${dirName}_$currentTimestamp"
        fi
    }

    configDirs() {
        local currentDir="$1"
        runAsUser btrfs subvolume create "$currentDir"
        runAsUser chattr +C "$currentDir"
    }

    configGnomeBoxesDir() {
        backupDirs "$GNOME_BOXES_LOCAL_PATH" "$GNOME_BOXES_DIR_NAME"
        runAsUser mkdir -p "$GNOME_BOXES_LOCAL_PATH"
        configDirs "$GNOME_BOXES_LOCAL_IMAGES_PATH"
    }

    configLibvirtDir() {
        backupDirs "$LIBVIRT_LOCAL_PATH" "$LIBVIRT_DIR_NAME"
        runAsUser mkdir -p "$LIBVIRT_LOCAL_PATH"
        configDirs "$LIBVIRT_LOCAL_IMAGES_PATH"
    }

    makeConfig() { (
        set -e
        configGnomeBoxesDir
        configLibvirtDir
    ); }

    if makeConfig; then
        echo "Virt dirs has been configured"
    else
        local errcode="$?"
        echo "Failed to configure virt dirs"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

configLibvirt() {
    firewall-cmd --permanent --zone=libvirt --add-service=nfs3
    firewall-cmd --permanent --zone=libvirt --add-service=mountd
    firewall-cmd --permanent --zone=libvirt --add-service=rpc-bind
    firewall-cmd --reload
    sed -i "s/#\ udp=.*/udp=y/g" /etc/nfs.conf
    systemctl restart nfs-server.service
    systemctl enable --now virtnetworkd

    echo "Libvirt has been configured"
}

installVSCodium() {
    rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
    printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" |
        tee -a /etc/yum.repos.d/vscodium.repo

    if dnf install -y codium; then
        # file=$(cat $PKG_LIST_PATH/vscode_extensions.pkgs)
        # IFS=$'\n'
        # for extension in $file; do
        #     runAsUser codium --install-extension "$extension"
        # done
        echo "VSCodium has been installed"
    else
        local errcode="$?"
        echo "Failed to insall VSCodium"
        pressAnyKeyToContinue
        exit "$errcode"
    fi
}

main() {
    isSudo

    installPkgsFromRepo
    configureVirtDirs
    configLibvirt
    installVSCodium

    pressAnyKeyToContinue
}

main
