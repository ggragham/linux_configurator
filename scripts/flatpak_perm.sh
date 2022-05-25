#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

USERNAME=""

isSudo() {
    if [ "$(id -u)" -eq 0 ]; then
        USERNAME="$SUDO_USER"
    else
        USERNAME="$USER"
    fi
}

isSudo
sudo -u "$USERNAME" flatpak override --user \
    --unshare=ipc \
    com.bitwarden.desktop
sudo -u "$USERNAME" flatpak override --user \
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
sudo -u "$USERNAME" flatpak override --user \
    --unshare=ipc \
    --nofilesystem=xdg-pictures \
    com.spotify.Client
sudo -u "$USERNAME" flatpak override --user \
    --unshare=network \
    --unshare=ipc \
    --nosocket=x11 \
    --nosocket=fallback-x11 \
    io.bassi.Amberol
sudo -u "$USERNAME" flatpak override --user \
    --unshare=ipc \
    io.freetubeapp.FreeTube
sudo -u "$USERNAME" flatpak override --user \
    --unshare=ipc \
    --nosocket=x11 \
    --nosocket=fallback-x11 \
    --nosocket=pcsc \
    io.gitlab.librewolf-community
sudo -u "$USERNAME" flatpak override --user \
    --unshare=network \
    --unshare=ipc \
    --nosocket=x11 \
    --nosocket=fallback-x11 \
    --nofilesystem=host \
    --filesystem=home \
    org.gnome.gitlab.somas.Apostrophe
sudo -u "$USERNAME" flatpak override --user \
    --unshare=network \
    --unshare=ipc \
    --nosocket=x11 \
    --nosocket=fallback-x11 \
    --nosocket=pulseaudio \
    --socket=cups \
    --nofilesystem=host \
    --filesystem=home \
    org.libreoffice.LibreOffice
sudo -u "$USERNAME" flatpak override --user \
    --unshare=ipc \
    --nosocket=x11 \
    --nofilesystem=host \
    --filesystem=home:ro \
    org.telegram.desktop
