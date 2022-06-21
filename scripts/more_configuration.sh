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

isSudo() {
    if [[ $EUID != 0 ]]; then
        echo "Run script with sudo"
        exit 1
    fi
}

main() {
    isSudo

    local select="*"
    while :; do
        clear
        echo
        echo "1. Configure network"
        echo "2. Install and configure iwd"
        echo
        echo "0. Back"
        echo

        case $select in
        1)
            bash "$SCRIPT_PATH/network.sh"
            select="*"
            ;;
        2)
            bash "$SCRIPT_PATH/iwd.sh"
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
