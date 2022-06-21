#!/usr/bin/env bash

# Set permissions for some flatpak apps.

trap 'errMsg' ERR
cd "$(dirname "$0")" || exit "$?"

errMsg() {
    echo "Failed to set flatpak permissions"
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

    # Bitwarden password manager
    flatpak override --user \
        --unshare=ipc \
        com.bitwarden.desktop

    # Brave browser
    flatpak override --user \
        --unshare=ipc \
        --nosocket=cups \
        --device=dri \
        --nodevice=all \
        --nofilesystem=host-etc \
        --nofilesystem=xdg-desktop \
        --nofilesystem=xdg-documents \
        --nofilesystem=xdg-videos \
        --nofilesystem=xdg-music \
        --system-no-talk-name=org.freedesktop.UPower \
        --system-no-talk-name=org.freedesktop.Avahi \
        com.brave.Browser

    # Spotify music client
    flatpak override --user \
        --unshare=ipc \
        --nofilesystem=xdg-pictures \
        com.spotify.Client

    # Amberol music player
    flatpak override --user \
        --unshare=network \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        io.bassi.Amberol

    # FreeTube YouTube client
    flatpak override --user \
        --unshare=ipc \
        io.freetubeapp.FreeTube

    # LibreWolf browser
    flatpak override --user \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nosocket=pcsc \
        io.gitlab.librewolf-community

    # Apostrophe markdown editor
    flatpak override --user \
        --unshare=network \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nofilesystem=host \
        --filesystem=home \
        org.gnome.gitlab.somas.Apostrophe

    # LibreOffice
    flatpak override --user \
        --unshare=network \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nosocket=pulseaudio \
        --socket=cups \
        --nofilesystem=host \
        --filesystem=home \
        org.libreoffice.LibreOffice

    # Telegram messenger
    flatpak override --user \
        --unshare=ipc \
        --nosocket=x11 \
        --nofilesystem=host \
        --filesystem=home:ro \
        org.telegram.desktop

    echo "Flatpak permissions have been set"
}

main
