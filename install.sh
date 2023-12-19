#!/usr/bin/env bash

# Main script.
# Check and download depen
# Interactive menu to execute playbooks.

cd "$(dirname "$0")" || exit "$?"
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

# Global vars
USER_PASSWORD="${USER_PASSWORD:-}"
DISTRO_LIST=("fedora" "debian")
CURRENT_DISTRO=""
DISTRO_NAME_COLOR=""
PKGS_LIST=("git" "ansible")
PKGS_TO_INSTALL=""
REPO_NAME="linux_configurator"
REPO_LINK="https://github.com/ggragham/${REPO_NAME}.git"
REPO_ROOT_PATH="${REPO_ROOT_PATH:-$HOME/.local/opt/$REPO_NAME}"
ANSIBLE_PLAYBOOK_PATH="$REPO_ROOT_PATH/ansible"

# Text formating
BOLD='\033[1m'
BLINK='\033[5m'
LONG_TAB='\033[64G'
RED='\033[0;31m'
LIGHTBLUE='\033[1;34m'
GREEN='\033[0;32m'
NORMAL='\033[0m'

cleanup() {
	local exitStatus="$?"
	unset USER_PASSWORD
	exit "$exitStatus"
}

trap cleanup TERM EXIT

checkSudo() {
	if [ "$EUID" -eq 0 ]; then
		echo "Error: Running this script with sudo is not allowed."
		exit 1
	fi
}

enterUserPassword() {
	sudo -K

	checkPassword() {
		if echo "$USER_PASSWORD" | sudo -S true >/dev/null 2>&1; then
			sudo -K
			return 0
		else
			echo -e "\nSorry, try again."
			return 1
		fi
	}

	if [ -n "$USER_PASSWORD" ]; then
		if checkPassword; then
			return 0
		fi
		exit $?
	fi

	while :; do
		read -rsp "Password: " USER_PASSWORD
		if checkPassword; then
			break
		fi
	done

	return 0
}

runAsSudo() {
	echo "$USER_PASSWORD" | sudo --stdin "$@"
	sudo -K
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
			runAsSudo dnf install -y \
				--setopt=install_weak_deps=False \
				--setopt=countme=False \
				$PKGS_TO_INSTALL
		elif [[ "$CURRENT_DISTRO" == "debian" ]]; then
			runAsSudo apt update
			runAsSudo apt install -y \
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
	(
		set -eu
		if [[ ! -d "$REPO_ROOT_PATH/.git" ]]; then
			mkdir -p "$REPO_ROOT_PATH"
			git clone "$REPO_LINK" "$REPO_ROOT_PATH"
		fi
	)
}

init() {
	installInitDeps
	if [ "$PWD/$0" != "$REPO_ROOT_PATH/$0" ]; then
		cloneRepo
	fi
	cd "$REPO_ROOT_PATH" || exit "$?"
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

printHeader() {
	clear
	echo -e "${GREEN}${BOLD}"
	asciiLogo
	echo -e "${NORMAL}"
	echo
	echo -e "${LONG_TAB} By ${BOLD}ggragham${NORMAL}"
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

installOtherPkgs() {
	otherAnsiblePlaybook() {
		ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/install_extra_pkgs.yml" --tags "prepare,$*" --extra-vars "ansible_become_password=$USER_PASSWORD"
	}

	local select="*"
	while :; do
		printHeader
		menuItem "1" "Extra"
		menuItem "2" "Neovim"
		menuItem "3" "Oh My Zsh"
		menuItem "4" "iNet wireless daemon"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			otherAnsiblePlaybook "extra"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			otherAnsiblePlaybook "neovim"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			otherAnsiblePlaybook "omz"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			otherAnsiblePlaybook "iwd"
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

installDevPkgs() {
	devAnsiblePlaybook() {
		ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/install_dev_pkgs.yml" --tags "prepare,$*" --extra-vars "ansible_become_password=$USER_PASSWORD"
	}

	local select="*"
	while :; do
		printHeader
		menuItem "1" "VSCodium"
		menuItem "2" "Virtualization"
		menuItem "3" "DevOps Base"
		menuItem "4" "Docker"
		menuItem "5" "Podman"
		menuItem "6" "Kubernetes"
		menuItem "7" "PyEnv"
		menuItem "8" "Node Version Manager"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			devAnsiblePlaybook "vscodium"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			devAnsiblePlaybook "virtualization"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			devAnsiblePlaybook "devops"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			devAnsiblePlaybook "docker"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			devAnsiblePlaybook "podman"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			devAnsiblePlaybook "kubernetes"
			pressAnyKeyToContinue
			select="*"
			;;
		7)
			devAnsiblePlaybook "pyenv"
			pressAnyKeyToContinue
			select="*"
			;;
		8)
			devAnsiblePlaybook "nvm"
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

installFlatpakPkgs() {
	flatpakAnsiblePlaybook() {
		ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/install_flatpak_pkgs.yml" --tags "prepare,$*" --extra-vars "ansible_become_password=$USER_PASSWORD"
	}

	local select="*"
	while :; do
		printHeader
		menuItem "1" "Base pkgs"
		menuItem "2" "Media pkgs"
		menuItem "3" "Brave"
		menuItem "4" "Librewolf"
		menuItem "5" "Bitwarden"
		menuItem "6" "Telegram"
		menuItem "7" "Spotify"
		menuItem "8" "FreeTube"
		menuItem "9" "LibreOffice"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			flatpakAnsiblePlaybook "base"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			flatpakAnsiblePlaybook "media"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			flatpakAnsiblePlaybook "brave"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			flatpakAnsiblePlaybook "librewolf"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			flatpakAnsiblePlaybook "bitwarden"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			flatpakAnsiblePlaybook "telegram"
			pressAnyKeyToContinue
			select="*"
			;;
		7)
			flatpakAnsiblePlaybook "spotify"
			pressAnyKeyToContinue
			select="*"
			;;
		8)
			flatpakAnsiblePlaybook "freetube"
			pressAnyKeyToContinue
			select="*"
			;;
		9)
			flatpakAnsiblePlaybook "libreoffice"
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

installGamingPkgs() {
	gamingAnsiblePlaybook() {
		ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/install_gaming_pkgs.yml" --tags "prepare,$*" --extra-vars "ansible_become_password=$USER_PASSWORD"
	}

	local select="*"
	while :; do
		printHeader
		menuItem "1" "Bottles"
		menuItem "2" "Lutris"
		menuItem "3" "Steam"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			gamingAnsiblePlaybook "bottles"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			gamingAnsiblePlaybook "lutris"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			gamingAnsiblePlaybook "steam"
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

applyConfig() {
	configAnsiblePlaybook() {
		ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/apply_config.yml" --tags "prepare,$*" --extra-vars "ansible_become_password=$USER_PASSWORD"
	}

	local select="*"
	while :; do
		printHeader
		menuItem "1" "Apply system config"
		menuItem "2" "Apply local config"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			configAnsiblePlaybook "system"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			configAnsiblePlaybook "user"
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

installAddPkgs() {
	local select="*"
	while :; do
		printHeader
		menuItem "1" "Install Extra pkgs"
		menuItem "2" "Install Dev pkgs"
		menuItem "3" "Install Flatpak pkgs"
		menuItem "4" "Install Themes"
		menuItem "5" "I wanna play games"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			installOtherPkgs
			select="*"
			;;
		2)
			installDevPkgs
			select="*"
			;;
		3)
			installFlatpakPkgs
			select="*"
			;;
		4)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/install_themes.yml" --extra-vars "ansible_become_password=$USER_PASSWORD"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			installGamingPkgs
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
	checkSudo
	enterUserPassword
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
		printHeader
		menuItem "1" "Initial configuration"
		menuItem "2" "Install extra packages"
		menuItem "3" "Apply configs"
		echo
		menuItem "0" "Exit"
		echo

		case $select in
		1)
			ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/init.yml" --extra-vars "ansible_become_password=$USER_PASSWORD"
			echo -e "\t${BLINK}It's recommended to ${BOLD}restart${NORMAL} ${BLINK}the system${NORMAL}\n"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			installAddPkgs
			select="*"
			;;
		3)
			applyConfig
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
