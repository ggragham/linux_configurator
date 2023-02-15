#!/usr/bin/env bash

# Initial script.
# Install git and ansible (if not installed).
# Clone repo and execute Linux Configurator.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
PRESERVE_USER_ENV="XDG_SESSION_TYPE,XDG_CURRENT_DESKTOP"
DISTRO_LIST=("fedora" "debian")
CURRENT_DISTRO=""
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
		exec sudo --preserve-env="$PRESERVE_USER_ENV" bash "$(basename "$0")"
		exit 1
	fi
}

runAsUser() {
	sudo --user="$USERNAME" "$@"
}

getDistroName() {
	for i in "${DISTRO_LIST[@]}"; do
		local checkDistro=""
		checkDistro="$(awk '/^ID=/' /etc/*-release | awk -F '=' '{print $2}')"
		if [[ "$i" == "$checkDistro" ]]; then
			CURRENT_DISTRO="$i"
			echo "Your disto is $CURRENT_DISTRO"
			return 0
		fi
	done

	echo "Distro $checkDistro is not supported"
	exit 1
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
		if [[ "$CURRENT_DISTRO" == "fedora" ]]; then
			dnf install -y \
				--setopt=install_weak_deps=False \
				--setopt=countme=False \
				$PKGS_TO_INSTALL
		elif [[ "$CURRENT_DISTRO" == "debian" ]]; then
			apt update
			apt install -y \
				--no-install-suggests \
				--no-install-recommends \
				$PKGS_TO_INSTALL
		else
			echo "Distro $CURRENT_DISTRO is not supported"
			exit 1
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
	getDistroName
	installInitDeps
	cloneRepo
	runConfigurator
}

main
