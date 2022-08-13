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
        --nofilesystem=host-etc \
        --nofilesystem=xdg-desktop \
        --nofilesystem=xdg-documents \
        --nofilesystem=xdg-videos \
        --nofilesystem=xdg-music \
        --system-no-talk-name=org.freedesktop.UPower \
        --system-no-talk-name=org.freedesktop.Avahi \
        com.brave.Browser

    # Planner
    flatpak override --user \
        --unshare=network \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nofilesystem=home \
        com.github.alainm23.planner

    # Slack messenger
    flatpak override --user \
        --nofilesystem=xdg-download \
        --nofilesystem=xdg-videos \
        --nofilesystem=xdg-music \
        --nofilesystem=xdg-pictures \
        --nofilesystem=xdg-documents \
        --filesystem=xdg-download/Slack com.slack.Slack

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

    # Celluloid Videoplayer
    flatpak override --user \
        --unshare=network \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nodevice=all \
        --device=dri \
        --nofilesystem=xdg-pictures \
        io.github.celluloid_player.Celluloid

    # LibreWolf browser
    flatpak override --user \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nosocket=pcsc \
        io.gitlab.librewolf-community

    # Paper
    flatpak override --user \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        --nofilesystem=host \
        io.posidon.Paper

    # # Apostrophe markdown editor
    # flatpak override --user \
    #     --unshare=network \
    #     --unshare=ipc \
    #     --nosocket=x11 \
    #     --nosocket=fallback-x11 \
    #     --nofilesystem=host \
    #     --filesystem=home \
    #     org.gnome.gitlab.somas.Apostrophe

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

    # Junction
    flatpak override --user \
        --unshare=ipc \
        --nosocket=x11 \
        --nosocket=fallback-x11 \
        re.sonny.Junction

    echo "Flatpak permissions have been set"
}

main
