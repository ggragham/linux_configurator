#!/usr/bin/env bash

# Install packages for DevOps.

trap 'errMsg' ERR SIGTERM
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
TMP_PATH=""
PKG_LIST_PATH="../pkgs"
HOME_PATH="/home/$USERNAME"
LOCAL_PATH="$HOME_PATH/.local"
BIN_PATH="$LOCAL_PATH/bin"

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

installActCli() {
    if dnf copr enable -y rubemlrm/act-cli; then
        if dnf install -y act-cli; then
            echo "act-cli has been installed"
        else
            local errcode="$?"
            echo "Failed to insall act-cli"
            pressAnyKeyToContinue
            exit "$errcode"
        fi
    else
        local errcode="$?"
        echo "Failed to add copr repo"
        pressAnyKeyToContinue
        exit "$errcode"
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

    installPkgsFromRepo
    installDocker
    installTerraform
    installMinikube
    installKubectl
    installActCli
    installNVM
    installPyenv

    cleanup
    pressAnyKeyToContinue
}

main
