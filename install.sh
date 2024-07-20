#!/usr/bin/env bash

# Main script.
# Check and download dependencies
# Interactive menu to execute playbooks.

cd "$(dirname "$0")" || exit "$?"
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

# Global constants
readonly DISTRO_LIST=("fedora" "debian")
readonly PKGS_LIST=("git" "ansible")
readonly REPO_NAME="linux_configurator"
readonly REPO_LINK="https://github.com/ggragham/${REPO_NAME}.git"
readonly DEFAULT_REPO_PATH="$HOME/.local/opt/$REPO_NAME"

# Global vars
USER_PASSWORD="${USER_PASSWORD:-}"
SCRIPT_PATH="$(dirname "$0")"
if [[ -d "$SCRIPT_PATH/.git" ]]; then
	REPO_ROOT_PATH="$SCRIPT_PATH"
else
	REPO_ROOT_PATH="${REPO_ROOT_PATH:-"$DEFAULT_REPO_PATH"}"
fi
ANSIBLE_PLAYBOOK_PATH="$REPO_ROOT_PATH/ansible"
CURRENT_DISTRO=""
DISTRO_NAME_COLOR=""
PKGS_TO_INSTALL=""

# Text formating
readonly BOLD='\033[1m'
readonly BLINK='\033[5m'
readonly LONG_TAB='\033[64G'
readonly RED='\033[0;31m'
readonly LIGHTBLUE='\033[1;34m'
readonly GREEN='\033[0;32m'
readonly NORMAL='\033[0m'

cleanup() {
	local exitStatus="$?"
	unset USER_PASSWORD
	unset mokPassword
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
		mkdir -p "$REPO_ROOT_PATH"
		git clone "$REPO_LINK" "$REPO_ROOT_PATH"
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

restartSystemNote() {
	local returnCode="$?"
	if [ "$returnCode" -eq 0 ]; then
		echo
		echo -e "\t${BLINK}It's recommended to ${BOLD}restart${NORMAL} ${BLINK}the system${NORMAL}\n"
		echo
	fi
}

runAnsiblePlaybook() {
	local playbookName="$1"
	local tagsList="$2"
	local extraVars="$3"

	ansible-playbook "$ANSIBLE_PLAYBOOK_PATH/$playbookName.yml" --tags "prepare,$tagsList" --extra-vars "ansible_become_password=$USER_PASSWORD $extraVars"
}

installOtherPkgs() {
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
			runAnsiblePlaybook "install_extra_pkgs" "extra_pkgs"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAnsiblePlaybook "install_extra_pkgs" "neovim"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			runAnsiblePlaybook "install_extra_pkgs" "omz"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			runAnsiblePlaybook "install_extra_pkgs" "iwd"
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
			runAnsiblePlaybook "install_dev_pkgs" "vscodium"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAnsiblePlaybook "install_dev_pkgs" "virtualization"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			runAnsiblePlaybook "install_dev_pkgs" "devops"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			runAnsiblePlaybook "install_dev_pkgs" "docker"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			runAnsiblePlaybook "install_dev_pkgs" "podman"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			runAnsiblePlaybook "install_dev_pkgs" "kubernetes"
			pressAnyKeyToContinue
			select="*"
			;;
		7)
			runAnsiblePlaybook "install_dev_pkgs" "pyenv"
			pressAnyKeyToContinue
			select="*"
			;;
		8)
			runAnsiblePlaybook "install_dev_pkgs" "nvm"
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
			runAnsiblePlaybook "install_flatpak_pkgs" "base_flatpak_pkgs"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAnsiblePlaybook "install_flatpak_pkgs" "media"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			runAnsiblePlaybook "install_flatpak_pkgs" "brave"
			pressAnyKeyToContinue
			select="*"
			;;
		4)
			runAnsiblePlaybook "install_flatpak_pkgs" "librewolf"
			pressAnyKeyToContinue
			select="*"
			;;
		5)
			runAnsiblePlaybook "install_flatpak_pkgs" "bitwarden"
			pressAnyKeyToContinue
			select="*"
			;;
		6)
			runAnsiblePlaybook "install_flatpak_pkgs" "telegram"
			pressAnyKeyToContinue
			select="*"
			;;
		7)
			runAnsiblePlaybook "install_flatpak_pkgs" "spotify"
			pressAnyKeyToContinue
			select="*"
			;;
		8)
			runAnsiblePlaybook "install_flatpak_pkgs" "freetube"
			pressAnyKeyToContinue
			select="*"
			;;
		9)
			runAnsiblePlaybook "install_flatpak_pkgs" "libreoffice"
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
			runAnsiblePlaybook "install_gaming_pkgs" "bottles"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAnsiblePlaybook "install_gaming_pkgs" "lutris"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			runAnsiblePlaybook "install_gaming_pkgs" "steam"
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

extraActions() {
	installNvidia() {
		nvidiaSecureBootPreNote() {
			echo
			echo -e "\t========================================================================="
			echo -e "\t================================ ${BOLD}${RED}${BLINK}WARNING${NORMAL} ================================"
			echo -e "\t========================================================================="
			echo -e "\t=                                                                       ="
			echo -e "\t=                          ${BOLD}ONLY FOR SECUREBOOT${NORMAL}                          ="
			echo -e "\t=                                                                       ="
			echo -e "\t=       ${BOLD}Preconditions:${NORMAL}                                                  ="
			echo -e "\t=    ${BOLD}1.${NORMAL} If you are ${BOLD}NOT using SecureBoot${NORMAL}, go straight to the ${BOLD}2${NORMAL} option.   ="
			echo -e "\t=    ${BOLD}2.${NORMAL} Worked with ${LIGHTBLUE}Fedora 39+${NORMAL} versions and latest ${GREEN}NVIDIA${NORMAL} drivers.      ="
			echo -e "\t=    ${BOLD}3.${NORMAL} Turn on ${BOLD}SecureBoot${NORMAL} in ${BOLD}Setup Mode${NORMAL}.                               ="
			echo -e "\t=    ${BOLD}4.${NORMAL} Delete ${BOLD}ALL${NORMAL} older ${GREEN}NVIDIA${NORMAL} installations.                          ="
			echo -e "\t=                                                                       ="
			echo -e "\t========================================================================="
			echo
		}

		nvidiaSecureBootPostNote() {
			local returnCode="$?"
			if [ "$returnCode" -eq 0 ]; then
				echo
				echo "TODO: fill note about next steps after setting up signing modules"
				echo
			fi
		}

		getMokPassword() {
			mokPassword=""
			echo
			read -rp "Enter MOK password: " -s mokPassword
		}

		local select="*"
		while :; do
			printHeader
			nvidiaSecureBootPreNote
			echo
			menuItem "1" "Prepare SecureBoot signing modules"
			menuItem "2" "Install NVIDIA drivers and firmware"
			echo
			menuItem "0" "Back"
			echo

			case $select in
			1)
				getMokPassword
				runAnsiblePlaybook "install_nvidia" "nvidia_secureboot" "mok_password=$mokPassword"
				nvidiaSecureBootPostNote
				pressAnyKeyToContinue
				select="*"
				;;
			2)
				runAnsiblePlaybook "install_nvidia" "nvidia_firmware"
				restartSystemNote
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

	local select="*"
	while :; do
		printHeader
		menuItem "1" "Install NVIDIA drivers and firmware"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			installNvidia
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
	local select="*"
	while :; do
		printHeader
		menuItem "1" "Apply system config"
		menuItem "2" "Apply local config"
		menuItem "3" "System Hardening"
		echo
		menuItem "0" "Back"
		echo

		case $select in
		1)
			runAnsiblePlaybook "apply_config" "system_config"
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			runAnsiblePlaybook "apply_config" "local_config"
			pressAnyKeyToContinue
			select="*"
			;;
		3)
			runAnsiblePlaybook "hardening" "hardening"
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
			runAnsiblePlaybook "install_themes" "themes"
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
		menuItem "2" "Extra Actions"
		menuItem "3" "Install extra packages"
		menuItem "4" "Apply configs"
		echo
		menuItem "0" "Exit"
		echo

		case $select in
		1)
			runAnsiblePlaybook "init" "init"
			restartSystemNote
			pressAnyKeyToContinue
			select="*"
			;;
		2)
			extraActions
			select="*"
			;;
		3)
			installAddPkgs
			select="*"
			;;
		4)
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
