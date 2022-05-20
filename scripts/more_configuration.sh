#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

SCRIPT_PATH="../scripts"

select="*"
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
        exit
        ;;
    *)
        read -rp "Select: " select
        continue
        ;;
    esac
done
