#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BACKUP_PATH="$SCRIPT_DIR/backup"
DOTFILES_PATH_NAME="config"
DOTFILES_PATH="$SCRIPT_DIR/$DOTFILES_PATH_NAME"
DCONF_NAME="gnome.dconf"
DCONF_PATH="$SCRIPT_DIR/$DCONF_NAME"

backupConfig() {
    # Backup dotfiles
    currentTimestamp=$(date +'%d_%m_%Y_%H_%M_%S')
    mkdir "$BACKUP_PATH/dotfiles_$currentTimestamp"
    fullBackupPath="$BACKUP_PATH/dotfiles_$currentTimestamp"
    fileList=()
    dirList=()
    readarray -d '' fileList < <(find $DOTFILES_PATH_NAME/ -type f -print0)
    readarray -d '' dirList < <(find $DOTFILES_PATH_NAME/ -type d -print0)
    for ((i = 1; i < ${#dirList[*]}; i++)); do
        backupDirs="$(echo ${dirList[$i]} | sed "s:^$DOTFILES_PATH_NAME/::")"
        mkdir "$fullBackupPath/$backupDirs"
    done
    for ((i = 1; i < ${#fileList[*]}; i++)); do
        backupFiles="$(echo ${fileList[$i]} | sed "s:^$DOTFILES_PATH_NAME/::")"
        cp "$HOME/$backupFiles" "$fullBackupPath/$backupFiles"
    done

    # Backup dconf
    dconf dump / > "$fullBackupPath/$DCONF_NAME"
}

setConfig() {
    cp --recursive --symbolic --force "$DOTFILES_PATH/." --target-directory="$HOME"
    dconf load / < "$DCONF_PATH"
}

setConfig
backupConfig
