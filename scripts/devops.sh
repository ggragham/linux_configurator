#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

USERNAME=""
PKG_DIR="../pkgs"
TMP_PATH="../tmp"
BIN_PATH=""

isSudo() {
    if [ "$(id -u)" -eq 0 ]; then
        USERNAME="$SUDO_USER"
    else
        USERNAME="$USER"
    fi
    BIN_PATH="/home/$USERNAME/.local/bin"
}

installPkgsFromRepo() {
    dnf install -y $(cat "$PKG_DIR/devops.pkgs")
}

installDocker() {
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    groupadd docker
    usermod -aG docker "$USERNAME"
}

installTerraform() {
    terraformFileName="terraform"
    terraformArchiveName="$terraformFileName.zip"
    terraform_latest_version="$(
        curl -s https://releases.hashicorp.com/index.json 2>/dev/null |
            jq ".[] | select(.name==\"terraform\") .versions[].version" |
            sort --version-sort -r |
            grep -v rc | grep -v beta | grep -v alpha |
            head -1 | awk -F'[\"]' '{print $2}'
    )"
    terraform_download_url="https://releases.hashicorp.com/terraform/${terraform_latest_version}/terraform_${terraform_latest_version}_linux_amd64.zip"
    sudo -u "$USERNAME" curl -L "$terraform_download_url" -o "$TMP_PATH/$terraformArchiveName"
    sudo -u "$USERNAME" unzip -d "$TMP_PATH/" "$TMP_PATH/$terraformArchiveName"
    sudo -u "$USERNAME" mv "$TMP_PATH/$terraformFileName" "$BIN_PATH"
    sudo -u "$USERNAME" chmod +x "$BIN_PATH/$terraformFileName"
}

installMinikube() {
    minikubeFileName="minikube"
    sudo -u "$USERNAME" curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o "$TMP_PATH/$minikubeFileName"
    sudo -u "$USERNAME" mv "$TMP_PATH/$minikubeFileName" "$BIN_PATH"
    sudo -u "$USERNAME" chmod +x "$BIN_PATH/$minikubeFileName"
}

installKubectl() {
    kubectlFileName="kubectl"
    sudo -u "$USERNAME" curl -L https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o "$TMP_PATH/$kubectlFileName"
    sudo -u "$USERNAME" mv "$TMP_PATH/$kubectlFileName" "$BIN_PATH"
    sudo -u "$USERNAME" chmod +x "$BIN_PATH/$kubectlFileName"
}

isSudo
installPkgsFromRepo
installDocker
installTerraform
installMinikube
installKubectl
