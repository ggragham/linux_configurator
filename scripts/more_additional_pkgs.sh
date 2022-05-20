#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

PKG_DIR="../pkgs"
SCRIPT_PATH="../scripts"

select="*"
while :; do
    clear
    echo
    echo "1. Install more packages"
    echo "2. Install DevOps packages"
    echo "3. Install nvim"
    echo "4. I want play the games"
    echo
    case $select in
    1)
        dnf install -y $(cat "$PKG_DIR/more_additional.pkgs")
        select="*"
        ;;
    2)
        bash "$SCRIPT_PATH/devops.sh"
        select="*"
        ;;
    3)
        bash "$SCRIPT_PATH/nvim.sh"
        select="*"
        ;;
    4)
        bash "$SCRIPT_PATH/games.sh"
        select="*"
        ;;

    *)
        read -rp "Select: " select
        continue
        ;;
    esac
done
