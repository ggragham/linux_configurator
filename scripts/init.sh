#!/usr/bin/env bash

# Initial script.
# Install git (if not installed).
# Clone repo and execute Linux Configurator.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
DEST_PATH="/home/$USERNAME/.local/opt"
REPO_NAME="LinuxConfigurator"
SCRIPT_NAME="install.sh"
EXECUTE="$DEST_PATH/$REPO_NAME/$SCRIPT_NAME"

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
	sudo -u "$USERNAME" "$@"
}

installGit() {
	# Check if git is installed by return code
	if git --version 2>/dev/null 1>&2; then
		return "$?"
	else
		if dnf --setopt=install_weak_deps=False --setopt=countme=False install -y git; then
			return "$?"
		else
			local errcode="$?"
			echo "Failed to install git"
			exit "$errcode"
		fi
	fi
}

cloneRepo() {
	runAsUser mkdir -p "$DEST_PATH"

	if runAsUser git clone https://github.com/ggragham/linux_configurator.git "$DEST_PATH/$REPO_NAME"; then
		return "$?"
	else
		local errcode="$?"
		echo "Failed to clone repo"
		exit "$errcode"
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
	installGit
	cloneRepo
	runConfigurator
}

main
