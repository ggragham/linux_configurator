#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

PKG_DIR="../pkgs"
SCRIPT_PATH="../scripts"

select="*"
while :; do
    clear
    echo
    echo "1. Install more packages"
        echo "2. Install Oh My Zsh"
        echo "3. Install DevOps packages"
        echo "4. Install nvim"
        echo "5. I want play the games"
    echo
    echo "0. Back"
    echo
    case $select in
    1)
            bash "$SCRIPT_PATH/install_additional_packages.sh"
        select="*"
        ;;
    2)
            bash "$SCRIPT_PATH/install_omz.sh"
            select="*"
            ;;
        3)
        bash "$SCRIPT_PATH/devops.sh"
        select="*"
        ;;
        4)
        bash "$SCRIPT_PATH/nvim.sh"
        select="*"
        ;;
        5)
        bash "$SCRIPT_PATH/games.sh"
        select="*"
        ;;
    0)
        exit
        ;;
    *)
        read -rp "Select: " select
        continue
        ;;
    esac
done
