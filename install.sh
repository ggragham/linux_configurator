#!/usr/bin/env bash

# Main script.
# Interactive menu to execute playbooks.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

USERNAME="$SUDO_USER"
PRESERVE_ENV="ANSIBLE_LOCALHOST_WARNING,ANSIBLE_INVENTORY_UNPARSED_WARNING,DESKTOP_SESSION,SUDO_USER,SUDO_UID"
DISTRO_LIST=("fedora" "debian")
CURRENT_DISTRO=""
REPO_ROOT_PATH="$(git rev-parse --show-toplevel)"
ANSIBLE_PLAYBOOK_PATH="$REPO_ROOT_PATH/ansible"
ANSIBLE_OTHER_PATH="$ANSIBLE_PLAYBOOK_PATH/other"

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
	sudo --preserve-env="$PRESERVE_ENV" --user="$USERNAME" "$@"
}

pressAnyKeyToContinue() {
	read -n 1 -s -r -p "Press any key to continue"
	echo
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
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_additional_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_themes.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_dev_pkgs.yml"
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
	getDistroName

	if [[ -z $DESKTOP_SESSION ]]; then
		clear
		echo "Desktop Environment is not defined"
		echo
		pressAnyKeyToContinue
	fi

	local select="*"
	while :; do
		clear
		echo "Linux Configurator"
		echo
		echo "Current distro is $CURRENT_DISTRO"
		echo
		echo "1. Initial configuration"
		echo "2. Install additional packages"
		echo "3. Apply local config"
		echo
		echo "0. Exit"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/${CURRENT_DISTRO}_init.yml"
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
