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
		echo "1. Initial configuration"
		echo "2. System configuration"
		echo "3. Install packages"
		echo "4. Local configuration"
		echo
		echo "0. Exit"
		echo

		case $select in
		1)
			bash "$SCRIPT_PATH/fedora_init.sh"
			select="*"
			;;
		2)
			bash "$SCRIPT_PATH/select_system_config.sh"
			select="*"
			;;
		3)
			bash "$SCRIPT_PATH/select_additional_pkgs.sh"
			select="*"
			;;
		4)
			runAsUser bash "$SCRIPT_PATH/select_local_config.sh"
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
