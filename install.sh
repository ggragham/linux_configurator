#!/usr/bin/env bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
DOTFILES_PATH_NAME="config"
DOTFILES_PATH="$SCRIPT_DIR/$DOTFILES_PATH_NAME"
BACKUP_PATH="$SCRIPT_DIR/backup"

backupDotfiles() {
    currentTimestamp=$(date +'%d_%m_%Y_%H_%M_%S')
    mkdir "$BACKUP_PATH/dotfiles_$currentTimestamp"
    fullBackupPath="$BACKUP_PATH/dotfiles_$currentTimestamp"
    dotfileList=()
    readarray -d '' dotfileList < <(find config/ -print0)
    for (( i=1; i<${#dotfileList[*]}; i++ )); do
        backupDotfiles="$(echo ${dotfileList[$i]} | sed "s:^$DOTFILES_PATH_NAME/::")"
        cp "$HOME/$backupDotfiles" --target-directory="$fullBackupPath"
    done
}

makeDotfilesSymlink() {
    cp --recursive --symbolic --force "$DOTFILES_PATH/." --target-directory="$SCRIPT_DIR/temp/"
}

# makeDotfilesSymlink
backupDotfiles
