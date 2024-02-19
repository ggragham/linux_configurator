# Linux Configurator
Just bunch of Ansible playbooks and scripts designed for personal Linux system configuration. Primarily developed for Fedora and Debian. You feel free to use it as source for your configuration.


## Table of contents
- [Usage (Easy way)](#usage-easy-way)
- [Usage (Manual way)](#usage-manual-way)
- [Tags](#tags)
- [To Do](#to-do)
- [Important Note](#important-note)
- [Author](#author)
- [License](#license)


## Usage (Easy way)
0. Set the preferred path for downloading the configurator (Optional).
```bash
export REPO_ROOT_PATH="~/preferred/path/"
```

1. Run:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ggragham/linux_configurator/master/install.sh)"
```

2. Wait for the repository to be cloned and the dependencies to be installed.

3. Select the item you need.


## Usage (Manual way)
1. Install git and ansible.
On Fedora Linux:
```bash
sudo dnf install git ansible
```
On Debian Linux:
```bash
sudo apt install git ansible
```

2. Clone the repo to convenient location (In my case it's ```~/.local/opt/```).
```bash
export REPO_ROOT_PATH="~/.local/opt/linux_configurator"
git clone https://github.com/ggragham/linux_configurator.git "$REPO_ROOT_PATH"
```

3. Change the list of packages to install (optional).
```bash
vi "$REPO_ROOT_PATH/ansible/_vars_pkgs.yml"
```

4. Run playbook as is ...
```bash
ansible-playbook -K "$REPO_ROOT_PATH/playbook.yml"
```

5. ... or use tags (The list of tags is provided below).
```bash
ansible-playbook -K "$REPO_ROOT_PATH/playbook.yml" --tags="prepare,extra_pkgs,local_config" # E.g.
```


## Tags
* **init** - init playbook. Install and config minimal base system.
* **prepare** - preparatory steps. Restore the directory structure in the local directory or install the necessary dependencies.
* **extra_pkgs** - install list of extra pkgs.
* **neovim** - install [NeoVim](https://neovim.io/).
* **omz** - install [Oh My Zsh](https://ohmyz.sh/).
* **iwd** - install [iNet Wireless Daemon](https://iwd.wiki.kernel.org/).

* **devops** - install and configure some devops-related packages.
* **vscodium** - install and configure [VSCodium](https://vscodium.com/).
* **virtualization** - install and configure virtualization-related packages.
* **docker** - install and configure [Docker](https://www.docker.com/).
* **podman** - install [Podman](https://podman.io/).
* **kubernetes** - install and configure [Kubernetes](https://kubernetes.io/)-related packages.
* **pyenv** - install and config [pyenv](https://github.com/pyenv/pyenv).
* **nvm** - install and config [Node Version Manager](https://github.com/nvm-sh/nvm).

* **base_flatpak_pkgs** - install and config some base flatpak packages.
* **media** - install media flatpak packages.
* **brave** - install [Brave Browser](https://flathub.org/apps/com.brave.Browser) flatpak package.
* **librewolf** - install [Librewolf](https://flathub.org/apps/io.gitlab.librewolf-community) flatpak package.
* **bitwarden** - install [Bitwarden](https://flathub.org/apps/com.bitwarden.desktop) flatpak package.
* **telegram** - install [Telegram](https://flathub.org/apps/org.telegram.desktop) flatpak package.
* **spotify** - install [Spotify](https://flathub.org/apps/com.spotify.Client) flatpak package.
* **freetube** - install [FreeTube](https://flathub.org/apps/io.freetubeapp.FreeTube) flatpak package.
* **libreoffice** - install [LibreOffice](https://flathub.org/apps/org.libreoffice.LibreOffice) flatpak package.

* **bottles** - install [Bottles](https://flathub.org/apps/com.usebottles.bottles) flatpak package.
* **lutris** - install [Lutris](https://flathub.org/apps/net.lutris.Lutris) flatpak package.
* **steam** - install [Steam](https://flathub.org/apps/com.valvesoftware.Steam) flatpak package.

* **themes** - install and configure themes.

* **system_config** - apply system configuration.
* **local_config** - apply user configuration.


## To Do
* [ ] I need more configs (ﾉ◕ヮ◕)ﾉ*.✧
    * [x] Basic Fedora config
    * [x] Basic Debian config
    * [x] Dotfiles symlinks
    * [x] NetworkNamager config
    * [x] IWD config
    * [x] GnomeDE dconf
    * [x] MateDE dconf
    * [ ] XFCE config
    * [ ] Sway config
    * [ ] i3wm config
    * [x] Flatpak config
* [x] Make more convenient and beautiful menu
* [ ] Make configs for different types of hardware
    * [x] Intel/AMD
    * [ ] Radeon/Nvidia
    * [ ] ARM devices


## Important Note
Before using the scripts and/or playbooks in this repository, ensure you have created a backup of your data and configurations. The author of this repository assumes no responsibility for any data loss or system issues that may arise from using these scripts. Use them at your own risk.


## Author
This project was created by [Grell Gragham](https://github.com/ggragham).


## License
This software is published under the UNLICENSE license.
