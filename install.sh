#!/usr/bin/env bash

# Main script.
# Check and download depen
# Interactive menu to execute playbooks.

cd "$(dirname "$0")" || exit "$?"
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

# Global vars
USERNAME="$SUDO_USER"
PRESERVE_USER_ENV="XDG_SESSION_TYPE,XDG_CURRENT_DESKTOP"
PRESERVE_ENV="${PRESERVE_USER_ENV},ANSIBLE_LOCALHOST_WARNING,ANSIBLE_INVENTORY_UNPARSED_WARNING,SUDO_USER,SUDO_UID"
DISTRO_LIST=("fedora" "debian")
CURRENT_DISTRO=""
DISTRO_NAME_COLOR=""
PKGS_LIST=("git" "ansible")
PKGS_TO_INSTALL=""
DEST_PATH="/home/$USERNAME/.local/opt"
REPO_NAME="linux_configurator"
REPO_LINK="https://github.com/ggragham/${REPO_NAME}.git"
SCRIPT_NAME="install.sh"
CURRENT_SCRIPT_PATH="$(readlink -f "$0")"
DEFAULT_SCRIPT_PATH="$DEST_PATH/$REPO_NAME/$SCRIPT_NAME"
REPO_ROOT_PATH="$(git rev-parse --show-toplevel 2>/dev/null)"
ANSIBLE_PLAYBOOK_PATH="$REPO_ROOT_PATH/ansible"
ANSIBLE_OTHER_PATH="$ANSIBLE_PLAYBOOK_PATH/other"

# Text formating
BOLD='\033[1m'
BLINK='\033[5m'
RED='\033[0;31m'
LIGHTBLUE='\033[1;34m'
GREEN='\033[0;32m'
NORMAL='\033[0m'

isSudo() {
	if [[ $EUID != 0 ]] || [[ -z $USERNAME ]]; then
		sudo --preserve-env="$PRESERVE_USER_ENV" bash "$SCRIPT_NAME"
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
	getDistroColor() {
		if [[ "$CURRENT_DISTRO" == "fedora" ]]; then
			DISTRO_NAME_COLOR="${LIGHTBLUE}"
		elif [[ "$CURRENT_DISTRO" == "debian" ]]; then
			DISTRO_NAME_COLOR="${RED}"
		fi
	}

	for i in "${DISTRO_LIST[@]}"; do
		local checkDistro=""
		checkDistro="$(awk '/^ID=/' /etc/*-release | awk -F '=' '{print $2}')"
		if [[ "$i" == "$checkDistro" ]]; then
			CURRENT_DISTRO="$i"
			getDistroColor
			return 0
		fi
	done

	echo -e "Distro ${BOLD}${checkDistro^}${NORMAL} is not supported"
	exit 1
}

installInitDeps() {
	# Check if git and ansibe is installed by return code
	for i in "${PKGS_LIST[@]}"; do
		if "$i" --version 2>/dev/null 1>&2; then
			continue
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

	runConfigurator() {
		if bash "$DEFAULT_SCRIPT_PATH"; then
			exit "$?"
		else
			local errcode="$?"
			echo "Failed to start Linux Configurator"
			exit "$errcode"
		fi
	}

	if [[ -d "./.git" ]]; then
		return "$?"
	elif [[ "$DEFAULT_SCRIPT_PATH" != "$CURRENT_SCRIPT_PATH" ]]; then
		if [[ ! -d "$DEST_PATH/$REPO_NAME" ]]; then
			cloneLinuxConfigRepo
		fi
		runConfigurator
	fi
}

asciiLogo() {
	cat <<'EOF'

   __      __  __   __  __  __  __  __                                                          
  /\ \    /\ \/\ "-.\ \/\ \/\ \/\_\_\_\                                                         
  \ \ \___\ \ \ \ \-.  \ \ \_\ \/_/\_\/_              	                             
   \ \_____\ \_\ \_\\"\_\ \_____\/\_\/\_\                                                       
    \/_____/\/_/\/_/ \/_/\/_____/\/_/\/_/                                                       
   ______  ______  __   __  ______ __  ______  __  __  ______  ______  ______ ______  ______    
  /\  ___\/\  __ \/\ "-.\ \/\  ___/\ \/\  ___\/\ \/\ \/\  == \/\  __ \/\__  _/\  __ \/\  == \   
  \ \ \___\ \ \/\ \ \ \-.  \ \  __\ \ \ \ \__ \ \ \_\ \ \  __<\ \  __ \/_/\ \\ \ \/\ \ \  __<   
   \ \_____\ \_____\ \_\\"\_\ \_\  \ \_\ \_____\ \_____\ \_\ \_\ \_\ \_\ \ \_\\ \_____\ \_\ \_\ 
    \/_____/\/_____/\/_/ \/_/\/_/   \/_/\/_____/\/_____/\/_/ /_/\/_/\/_/  \/_/ \/_____/\/_/ /_/ 
EOF
}

printLogo() {
	echo -e "${GREEN}${BOLD}"
	asciiLogo
	echo -e "${NORMAL}"
	echo
	echo -e "\033[64G By ${BOLD}ggragham${NORMAL}"
	echo -e "\tCurrent distro is ${DISTRO_NAME_COLOR}${BOLD}${CURRENT_DISTRO^}${NORMAL}"
	echo
	echo -e "${GREEN}Choose an option:${NORMAL}"
	echo
}

menuItem() {
	local number="$1"
	local text="$2"
	echo -e "${GREEN}$number.${NORMAL} $text"
}

installAddPkgs() {
	local select="*"
	while :; do
		clear
		printLogo
		menuItem "1" "Install Additional pkgs"
		menuItem "2" "Install Dev pkgs"
		menuItem "3" "Install DevOps pkgs"
		menuItem "4" "Install IWD"
		menuItem "5" "Install Flatpak pkgs"
		menuItem "6" "Install Themes"
		menuItem "7" "I wanna play games"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_additional_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_dev_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_devops_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_iwd.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			ansible-playbook "$ANSIBLE_OTHER_PATH/install_flatpak_pkgs.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/install_themes.yml"
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
			read -rp "> " select
			continue
			;;
		esac
	done
}

main() {
	isSudo
	getDistroName
	installInitDeps
	cloneRepo

	if [[ -z $XDG_CURRENT_DESKTOP ]]; then
		clear
		echo
		echo -e "${RED}${BOLD}Desktop Environment is not defined${NORMAL}"
		echo
		pressAnyKeyToContinue
	fi

	local select="*"
	while :; do
		clear
		printLogo
		menuItem "1" "Initial configuration"
		menuItem "2" "Apply system config"
		menuItem "3" "Install additional packages"
		menuItem "4" "Apply local config"
		echo
		menuItem "0" "Exit"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$CURRENT_DISTRO/${CURRENT_DISTRO}_init.yml"
			echo -e "\t${BLINK}It's recommended to ${BOLD}restart${NORMAL} ${BLINK}the system${NORMAL}\n"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAsUser ansible-playbook "$ANSIBLE_OTHER_PATH/apply_system_config.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			installAddPkgs
			select="*"
			;;
		4)
			runAsUser ansible-playbook "$ANSIBLE_OTHER_PATH/apply_local_config.yml"
			pressAnyKeyToContinue
			select="*"
			;;
		0)
			exit 0
			;;
		*)
			read -rp "> " select
			continue
			;;
		esac
	done
}

main
