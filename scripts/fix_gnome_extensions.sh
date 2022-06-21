#!/usr/bin/env bash

# Fix GnomeDE extensions compability.
# Use when older versions of gnome extensions
# don't work on newer versions of gnome.

trap 'errMsg' ERR

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

main() {
    doNotRunAsRoot

    gsettings set org.gnome.shell disable-extension-version-validation true

    echo "disable-extension-version-validation $(gsettings get org.gnome.shell disable-extension-version-validation)"
    pressAnyKeyToContinue
}

main
