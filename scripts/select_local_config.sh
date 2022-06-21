#!/usr/bin/env bash

# Interactive menu to execute
# system configuration scripts.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

SCRIPT_PATH="../scripts"

errMsg() {
    echo "Failed"
    exit 1
}

doNotRunAsRoot() {
    if [[ $EUID == 0 ]]; then
        echo "Don't run this script as root"
        exit 1
    fi
}
main() {
    doNotRunAsRoot

    local select="*"
    while :; do
        clear
        echo
        echo "1. Load dotfiles"
        echo "2. Load dconf"
        echo "3. Fix gnome extensions compability"
        echo
        echo "0. Back"
        echo

        case $select in
        1)
            bash "$SCRIPT_PATH/load_dotfiles.sh"
            select="*"
            ;;
        2)
            bash "$SCRIPT_PATH/load_dconf.sh"
            select="*"
            ;;
        3)
            bash "$SCRIPT_PATH/fix_gnome_extensions.sh"
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
