#!/usr/bin/env bash

# Remove vi, vim and nano.
# Install neovim as editor.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

BIN_PATH="/usr/bin"

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

pressAnyKeyToContinue() {
    read -n 1 -s -r -p "Press any key to continue"
    echo
}

main() {
    isSudo

    dnf remove -y vim\* vi nano

    if dnf install -y neovim; then
        cd "$BIN_PATH" || exit "$?"

        if [[ -f nvim ]]; then
            for link in edit vedit vi vim; do
                ln -s nvim "$link"
            done
        else
            echo "neovim is not installed"
            pressAnyKeyToContinue
            exit 1
        fi

        echo -e '#!/bin/sh\nexec nvim -e "$@"' >ex
        echo -e '#!/bin/sh\nexec nvim -R "$@"' >view
        echo -e '#!/bin/sh\nexec nvim -d "$@"' >vimdiff
        chmod 755 ex view vimdiff
    else
        local errcode="$?"
        echo "Failed to install neovim"
        pressAnyKeyToContinue
        exit "$errcode"
    fi

    echo "Neovim has been installed"
    pressAnyKeyToContinue
}

main
