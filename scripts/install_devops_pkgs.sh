#!/usr/bin/env bash

# Install packages for DevOps.

trap 'errMsg' ERR SIGTERM
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
TMP_PATH=""
PKG_LIST_PATH="../pkgs"
LOCAL_PATH="/home/$USERNAME/.local"
BIN_PATH="$LOCAL_PATH/bin"
BACKUP_PATH="../backup"
GNOME_BOXES_DIR_NAME="gnome-boxes"
GNOME_BOXES_LOCAL_PATH="$LOCAL_PATH/share/$GNOME_BOXES_DIR_NAME/"
GNOME_BOXES_LOCAL_IMAGES_PATH="$GNOME_BOXES_LOCAL_PATH/images"

errMsg() {
    cleanup
    echo "Failed"
    pressAnyKeyToContinue
    exit 1
}

cleanup() {
    rm --recursive --force "$TMP_PATH"
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

makeTmp() {
    TMP_PATH="$(runAsUser mktemp -d)"
}

installPkgsFromRepo() {
    if dnf install -y $(cat "$PKG_LIST_PATH/devops.pkgs"); then
        echo "DevOps packages from repo have been installed"
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
            mv "$currentDir" "$BACKUP_PATH/${dirName}_$currentTimestamp"
        fi
    }

    configDirs() {
        local currentDir="$1"
        runAsUser btrfs subvolume create "$currentDir"
        runAsUser chattr +C "$currentDir"
    }

    configGnomeBoxes() {
        backupDirs "$GNOME_BOXES_LOCAL_PATH" "$GNOME_BOXES_DIR_NAME"
        runAsUser mkdir -p "$GNOME_BOXES_LOCAL_PATH"
        configDirs "$GNOME_BOXES_LOCAL_IMAGES_PATH"
    }

    makeConfig() { (
        set -e
        configGnomeBoxes
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

installDocker() {
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    if dnf install -y $(cat "$PKG_LIST_PATH/docker.pkgs"); then
        systemctl enable docker

        if (! grep -q "docker" /etc/group); then
            groupadd docker
        fi

        usermod -aG docker "$USERNAME"
        echo "Docker has been installed"
    else
        local errcode="$?"
        echo "Failed to install Docker"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

}

installTerraform() {
    makeTmp
    local terraformFileName="terraform"
    local terraformArchiveName="$terraformFileName.zip"
    local terraformLatestVersion=""
    terraformLatestVersion="$(
        curl -s https://releases.hashicorp.com/index.json 2>/dev/null |
            jq ".[] | select(.name==\"terraform\") .versions[].version" |
            sort --version-sort -r |
            grep -v rc | grep -v beta | grep -v alpha |
            head -1 | awk -F'[\"]' '{print $2}'
    )"
    local terraformDownloadURL="https://releases.hashicorp.com/terraform/${terraformLatestVersion}/terraform_${terraformLatestVersion}_linux_amd64.zip"
    runAsUser curl -L "$terraformDownloadURL" -o "$TMP_PATH/$terraformArchiveName"
    runAsUser unzip -d "$TMP_PATH/" "$TMP_PATH/$terraformArchiveName"
    runAsUser mv "$TMP_PATH/$terraformFileName" "$BIN_PATH"
    runAsUser chmod +x "$BIN_PATH/$terraformFileName"

    if [[ -f "$BIN_PATH/$terraformFileName" ]]; then
        cleanup
        echo "Terraform has been installed"
    else
        echo "Failed to install Terraform"
        pressAnyKeyToContinue
        cleanup
        exit 1
    fi
}

installMinikube() {
    makeTmp
    local minikubeFileName="minikube"
    local minikubeDownoadURL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    runAsUser curl -L "$minikubeDownoadURL" -o "$TMP_PATH/$minikubeFileName"
    runAsUser mv "$TMP_PATH/$minikubeFileName" "$BIN_PATH"
    runAsUser chmod +x "$BIN_PATH/$minikubeFileName"

    if [[ -f "$BIN_PATH/$minikubeFileName" ]]; then
        cleanup
        echo "Minikube has been installed"
    else
        echo "Failed to install Minikube"
        pressAnyKeyToContinue
        cleanup
        exit 1
    fi
}

installKubectl() {
    makeTmp
    local kubectlFileName="kubectl"
    local kubectlDownloadURL=""
    kubectlDownloadURL="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    runAsUser curl -L "$kubectlDownloadURL" -o "$TMP_PATH/$kubectlFileName"
    runAsUser mv "$TMP_PATH/$kubectlFileName" "$BIN_PATH"
    runAsUser chmod +x "$BIN_PATH/$kubectlFileName"

    if [[ -f "$BIN_PATH/$kubectlFileName" ]]; then
        cleanup
        echo "Kubectl has been installed"
    else
        echo "Failed to install Kubectl"
        pressAnyKeyToContinue
        cleanup
        exit 1
    fi
}

installVSCodium() {
    rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
    printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" |
        tee -a /etc/yum.repos.d/vscodium.repo

    if dnf install -y codium; then
        return "$?"
    else
        local errcode="$?"
        echo "Failed to insall VSCodium"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    file=$(cat $PKG_LIST_PATH/vscode_extensions.pkgs)
    IFS=$'\n'
    for extension in $file; do
        runAsUser codium --install-extension "$extension"
    done

    echo "VSCodium has been installed"
}

main() {
    isSudo

    installPkgsFromRepo
    configureVirtDirs
    installDocker
    installTerraform
    installMinikube
    installKubectl
    installVSCodium

    cleanup
    pressAnyKeyToContinue
}

main
