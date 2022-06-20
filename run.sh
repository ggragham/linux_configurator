#!/usr/bin/env bash

# Main script.
# Interactive menu to execute other
# installation and configuration scripts.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

USERNAME="$SUDO_USER"
SCRIPT_PATH="./scripts"

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

main() {
	isSudo

	local select="*"
	while :; do
		clear
		echo "Linux Configurator"
		echo
		echo "1. Base system configuration"
		echo "2. More configs"
		echo "3. Install additional packages"
		echo "4. Install flatpak apps"
		echo "5. Load dotfiles"
		echo "6. Load dconf"
		echo "7. Fix gnome extensions compability"
		echo
		echo "0. Exit"
		echo

		case $select in
		1)
			bash "$SCRIPT_PATH/fedora_init.sh"
			select="*"
			;;
		2)
			bash "$SCRIPT_PATH/more_configuration.sh"
			select="*"
			;;
		3)
			bash "$SCRIPT_PATH/more_additional_pkgs.sh"
			select="*"
			;;
		4)
			bash "$SCRIPT_PATH/flatpak.sh"
			select="*"
			;;
		5)
			runAsUser bash "$SCRIPT_PATH/dotfiles.sh"
			select="*"
			;;
		6)
			runAsUser bash "$SCRIPT_PATH/dconf.sh"
			select="*"
			;;
		7)
			runAsUser bash "$SCRIPT_PATH/fix_gnome_extensions.sh"
			select="*"
			;;
		0)
			exit 0
			;;
		*)
			read -rp "Select: " select
			continue
			;;
		esac
	done
}

main
