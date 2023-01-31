#!/usr/bin/env bash

# Backup files that will be replaced
# by softlinks of files from this repo.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

REPO_PATH="$(pwd)/.."
BACKUP_PATH="$REPO_PATH/backup"
DOTFILES_PATH="$REPO_PATH/config"

errMsg() {
    echo "Failed"
    pressAnyKeyToContinue
    exit 1
}

doNotRunAsRoot() {
    if [[ $EUID == 0 ]]; then
        echo "Don't run this script as root"
        exit 1
    fi
}

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

backupConfig() {
    # Make dir with current timestamp
    local currentTimestamp=""
    currentTimestamp=$(date +'%d_%m_%Y_%H_%M_%S')
    mkdir "$BACKUP_PATH/dotfiles_$currentTimestamp"
    local fullBackupPath="$BACKUP_PATH/dotfiles_$currentTimestamp"
    # Add list of dirs and files from ../config to arrays
    local fileList=()
    local dirList=()
    readarray -d '' fileList < <(find $DOTFILES_PATH/ -type f -print0)
    readarray -d '' dirList < <(find $DOTFILES_PATH/ -type d -print0)

    # Recreate directory structure for backup
    # from configs directory inside repository
    local backupDirs=""
    for ((i = 1; i < ${#dirList[*]}; i++)); do
        # Cut the contents of $dirList
        # while excluding contents of $DOTFILES_PATH
        backupDirs="$(echo ${dirList[$i]} | sed "s:^$DOTFILES_PATH/::")"
        # If such directory exists in the home directory
        if [[ -d "$HOME/$backupDirs" ]]; then
            mkdir "$fullBackupPath/$backupDirs"
        fi
    done

    # Copy files with names form array
    local backupFiles=""
    for ((i = 0; i < ${#fileList[*]}; i++)); do
        # The same as loop above but with $fileList
        backupFiles="$(echo ${fileList[$i]} | sed "s:^$DOTFILES_PATH/::")"
        # If such file exists in the home directory
        if [[ -f "$HOME/$backupFiles" ]]; then
            cp "$HOME/$backupFiles" "$fullBackupPath/$backupFiles"
        fi
    done

    echo "Existing dotfiles has been backed up to $BACKUP_PATH/dotfiles_$currentTimestamp"
}

loadConfig() {
    cp --recursive --symbolic --force "$DOTFILES_PATH/." "$HOME"

    echo "Dotfiles has been loaded"
}

main() {
    doNotRunAsRoot

    backupConfig
    loadConfig

    pressAnyKeyToContinue
}

main
