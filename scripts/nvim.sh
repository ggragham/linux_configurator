#!/usr/bin/env bash
cd "$(dirname "$0")" || exit

dnf remove -y vim\* vi nano
dnf install -y neovim

cd /usr/bin/ || exit

echo -e '#!/bin/sh\nexec nvim -e "$@"' >ex
echo -e '#!/bin/sh\nexec nvim -RZ "$@"' >rview
echo -e '#!/bin/sh\nexec nvim -Z "$@"' >rvim
echo -e '#!/bin/sh\nexec nvim -R "$@"' >view
echo -e '#!/bin/sh\nexec nvim -d "$@"' >vimdiff
chmod 755 ex rview rvim view vimdiff

for link in edit vedit vi vim; do
    ln -s nvim $link
done
