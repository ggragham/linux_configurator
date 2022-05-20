#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

PKG_DIR="../pkgs"

dnf install -y $(cat "$PKG_DIR/games.pkgs")
