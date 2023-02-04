#!/usr/bin/env bash

# Initial script.
# Install git and ansible (if not installed).
# Clone repo and execute Linux Configurator.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
PKGS_LIST=("git" "ansible")
PKGS_TO_INSTALL=""
DEST_PATH="/home/$USERNAME/.local/opt"
REPO_NAME="linux_configurator"
REPO_LINK="https://github.com/ggragham/${REPO_NAME}.git"
SCRIPT_NAME="install.sh"
EXECUTE="$DEST_PATH/$REPO_NAME/$SCRIPT_NAME"

errMsg() {
	echo "Failed"
	exit 1
}

isSudo() {
	if [[ $EUID != 0 ]] || [[ -z $USERNAME ]]; then
		exec sudo --preserve-env="DESKTOP_SESSION" bash "$(basename "$0")"
		exit 1
	fi
}

runAsUser() {
	sudo --user="$USERNAME" "$@"
}

installInitDeps() {
	# Check if git and ansibe is installed by return code
	for i in "${PKGS_LIST[@]}"; do
		if "$i" --version 2>/dev/null 1>&2; then
			echo "$i already installed"
		else
			PKGS_TO_INSTALL="$i $PKGS_TO_INSTALL"
		fi
	done

	if [[ -z "$PKGS_TO_INSTALL" ]]; then
		return 0
	else
		if dnf --setopt=install_weak_deps=False --setopt=countme=False install -y $PKGS_TO_INSTALL; then
			return "$?"
		else
			local errcode="$?"
			echo "Failed to install init pkgs"
			exit "$errcode"
		fi
	fi
}

cloneRepo() {
	cloneLinuxConfigRepo() { (
		set -eu
		runAsUser mkdir -p "$DEST_PATH"
		runAsUser git clone "$REPO_LINK" "$DEST_PATH/$REPO_NAME"
	); }

	if [[ -d "$DEST_PATH/$REPO_NAME" ]]; then
		echo "Repo already cloned"
	else
		if cloneLinuxConfigRepo; then
			return "$?"
		else
			local errcode="$?"
			echo "Failed to clone repo"
			exit "$errcode"
		fi
	fi
}

runConfigurator() {
	if bash "$EXECUTE"; then
		return "$?"
	else
		local errcode="$?"
		echo "Failed to start Linux Configurator"
		exit "$errcode"
	fi
}

main() {
	isSudo
	installInitDeps
	cloneRepo
	runConfigurator
}

main
