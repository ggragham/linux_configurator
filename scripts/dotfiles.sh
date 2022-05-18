#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

REPO_ROOT="$(git rev-parse --show-toplevel)"
BACKUP_PATH="$REPO_ROOT/backup"
DOTFILES_PATH="$REPO_ROOT/config"

backupConfig() {
    # Backup dotfiles
    currentTimestamp=$(date +'%d_%m_%Y_%H_%M_%S')
    mkdir "$BACKUP_PATH/dotfiles_$currentTimestamp"
    fullBackupPath="$BACKUP_PATH/dotfiles_$currentTimestamp"
    fileList=()
    dirList=()
    readarray -d '' fileList < <(find $DOTFILES_PATH/ -type f -print0)
    readarray -d '' dirList < <(find $DOTFILES_PATH/ -type d -print0)
    for ((i = 1; i < ${#dirList[*]}; i++)); do
        backupDirs="$(echo ${dirList[$i]} | sed "s:^$DOTFILES_PATH/::")"
        mkdir "$fullBackupPath/$backupDirs"
    done
    for ((i = 0; i < ${#fileList[*]}; i++)); do
        backupFiles="$(echo ${fileList[$i]} | sed "s:^$DOTFILES_PATH/::")"
        cp "$HOME/$backupFiles" "$fullBackupPath/$backupFiles" 2>/dev/null
    done
}

loadConfig() {
    cp --recursive --symbolic --force "$DOTFILES_PATH/." --target-directory="$HOME"
}

backupConfig
loadConfig
