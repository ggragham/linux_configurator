#!/usr/bin/env bash

# Main script.
# Interactive menu to execute playbooks.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"
export ANSIBLE_LOCALHOST_WARNING=False

USERNAME="$SUDO_USER"
PRESERVE_ENV="ANSIBLE_LOCALHOST_WARNING,DESKTOP_SESSION,SUDO_USER,SUDO_UID"
REPO_ROOT_PATH="$(git rev-parse --show-toplevel)"
ANSIBLE_PLAYBOOK_PATH="$REPO_ROOT_PATH/ansible"
ANSIBLE_FEDORA_PATH="$ANSIBLE_PLAYBOOK_PATH/fedora"
ANSIBLE_OTHER_PATH="$ANSIBLE_PLAYBOOK_PATH/other"

errMsg() {
	echo "Failed"
	exit 1
}

isSudo() {
	if [[ -z "$DESKTOP_SESSION" ]]; then
		echo "Run script without sudo"
		exit 1
	elif [[ $EUID != 0 ]] || [[ -z $USERNAME ]]; then
		exec sudo --preserve-env="DESKTOP_SESSION" bash "$0"
		exit 1
	fi
}

runAsUser() {
	sudo --preserve-env="$PRESERVE_ENV" --user="$USERNAME" "$@"
}

pressAnyKeyToContinue() {
	read -n 1 -s -r -p "Press any key to continue"
	echo
}

installAddPkgs() {
	local select="*"
	while :; do
		clear
		echo "Other actions menu"
		echo
		echo "1. Install Additional pkgs"
		echo "2. Install Themes"
		echo "3. Install Dev pkgs"
		echo "4. Install DevOps pkgs"
		echo "5. Install IWD"
		echo "6. Install Flatpak pkgs"
		echo "7. I wanna play games"
		echo
		echo "0. Back"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_FEDORA_PATH/install_additional_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			ansible-playbook "$ANSIBLE_FEDORA_PATH/install_themes.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			ansible-playbook "$ANSIBLE_FEDORA_PATH/install_dev_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_devops_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_iwd.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_flatpak_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		7)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_gaming_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		0)
			return 0
			;;
		*)
			read -rp "Select: " select
			continue
			;;
		esac
	done
}

main() {
	isSudo

	local select="*"
	while :; do
		clear
		echo "Linux Configurator"
		echo
		echo "1. Initial configuration"
		echo "2. Install additional packages"
		echo "3. Apply local config"
		echo
		echo "0. Exit"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_FEDORA_PATH/fedora_init.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			installAddPkgs
			select="*"
			;;
		3)
			runAsUser ansible-playbook "$ANSIBLE_OTHER_PATH/apply_local_config.yml"
			pressAnyKeyToContinue
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
