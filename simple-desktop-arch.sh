#!/bin/bash
#
# simple-desktop-manjaro
# Adapting the opinionated, performant, and responsive experience to daily-users and developers to Manjaro
#
# Copyright (C) 2021  Perlogix, Timothy Marcinowski
# With contributions from: Luis Bauza.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PRIM_DISK=$(df -h / | grep dev | awk '{ print $1 }')
SETUP_LOG="/opt/simple-desktop/logs/setup.log"
SETUP_ERR_LOG="/opt/simple-desktop/logs/setup_err.log"

# check if current user is root
is_root() {
  if [[ $(whoami) != "root" ]]; then
    echo "run again with:  sudo -E $0"
    exit 1
  fi
}

# Create GitHub issue submission by gathering basic system information. systemd, dmesg, journalctl, mokutil logs, etc.
system_info() {
  command -v inxi 1>/dev/null && inxi -Fxz || echo "Install inxi:  yay -S inxi"
  echo -e "\033[1mSystemD:  \033[0m $(systemctl --failed --no-pager | grep -v UNIT)"
  echo -e "\033[1mDmesg:    \033[0m \n$(dmesg -tP --level=err,emerg,crit,alert | sed 's/^/           /')"
  echo -e "\033[1mJournal:  \033[0m \n$(journalctl -p "emerg..err" --no-pager -b | grep -v 'kernel\|Logs\|ssh' | sed 's/^/           /')"
  echo -e "\033[1mSecureBoot:  \033[0m \n$(mokutil --sb-state 2>/dev/null | sed 's/^/           /')"
  if [[ -f /opt/simple-desktop/logs/setup.log ]]; then
    echo -e "\033[1mSetupErrors:    \033[0m \n$(sed 's/^/           /' /opt/simple-desktop/logs/setup_err.log)"
  fi
  if [[ -f /opt/simple-desktop/.first_run ]]; then
      echo -e "\033[1mFirstRun:    \033[0m \n$(sed 's/^/           /' /opt/simple-desktop/.first_run)"
  fi
}

# Update components
update() {
  case $1 in
    hosts)
      wget -c 'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts'
      sed -i "s/localhost$/localhost $(hostname)/g" hosts
      mv -f hosts /etc
      ;;
    *)
      echo "options: slack,discord,brave,firefox,spotify,zoom,teams,overclock,developer,theme,docker,flatpak,cleanup_script,disable_spectre"
      ;;
  esac
}

# TODO: Add a function to check if yay is installed and if not, install yay.
check_yay() {
  if [ ! -e /usr/local/bin/yay ]; then
    if [ -e /usr/local/bin/git ]; then
      cd /opt || mkdir /opt && cd /opt || exit
      git clone https://aur.archlinux.org/yay.git
      su -c nobody
      chown -R nobody:nobody ./yay
      cd yay || exit && exit
      makepkg -si
      exit
    else
        pacman -S git
        check_yay
    fi
  fi
}

# TODO: Add a function to install the gnome package group and allow users to choose if they want gnome-extra.

# Install common desktop apps (mostly using a combination of pacman and yay)
# TODO: For snap-specific packages, we need to make a method to check for and install snapd on manjaro

# TODO: Install plymouth, configure silent boot, configure wayland (add option for xorg too?)
install() {
  case $1 in
    slack)
      yay -S slack-desktop # TODO: Add verification skip to this and all other yay commands.
      ;;

    brave)
      yay -S brave
      ;;

    spotify)
      yay -S spotify
      ;;

    zoom)
      yay -S zoom
      ;;

    teams)
      yay -S teams
      ;;

    discord)
      pacman -S discord --noconfirm
      ;;

    firefox)
      pacman -S firefox --noconfirm
      ;;

    overclock)
      echo 'arm_freq=1900' >> /boot/firmware/config.txt
      echo 'over_voltage=4' >> /boot/firmware/config.txt
      ;;

    docker)
      curl -sSL https://get.docker.com | sh
      ;;

    theme)
      setup_theme # TODO: Implement this method
      ;;

    cleanup_script)
      setup_cleanup_script # TODO: Implement this as well.
      ;;

    disable_spectre)
      setup_disable_spectre # TODO: This one too.
      ;;

    anbox)
      pacman -Syu
      pacman -S android-tools wget curl lzip tar unzip squashfs-tools --noconfirm
      # TODO: Use yay to install anbox-git
      ;;

    developer)
      # TODO: Use pacman to install base-devel (depends on what packages base-devel contains)

      ZSH="$(command -v zsh || grep zsh /etc/shells | tail -n 1)" # TODO: zsh might not be installed by default
      sed -i "s|/bin/bash|$ZSH|g" /etc/passwd

      # Create a temp install directory
      TEMPDIR="$HOME/.tmp-sd-a"
      mkdir -p "$TEMPDIR"
      cd "$TEMPDIR" || echo "Can\'t make temp dir." >& 2

      # Install a better top/htop
      wget -c https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz
      tar -zxvf bottom_x86_64-unkown-linux-gnu.tar.gz
      cp -f ./btm /usr/bin

      # Install a better ls
      wget -c https://github.com/Peltoche/lsd/releases/download/0.20.1/lsd-0.20.1-x86_64-unknown-linux-gnu.tar.gz
      tar -zxvf lsd-0.20.1-x86_64-unkown-linux-gnu.tar.gz
      cp -f /.lsd-*-x86_64-unkown-linux-gnu/lsd /usr/bin

      # Install a colorful cat
      wget -c https://github.com/sharkdp/bat/releases/download/v0.18.0/bat-v0.18.0-x86_64-unknown-linux-gnu.tar.gz
      tar -zxvf -zxvf bat-v0.18.0-x86_64-unknown-linux-gnu.tar.gz
      cp -f ./bat-v0.18.0-x86_64-unknown-linux-gnu/bat /usr/bin/

      # Install lazydocker
      wget -c https://github.com/jesseduffield/lazydocker/releases/download/v0.12/lazydocker_0.12_Linux_x86_64.tar.gz
      tar -zxvf ./lazydocker_0.12_Linux_x86_64.tar.gz
      chmod -f 0755 ./lazydocker
      cp -f ./lazydocker /usr/bin/

      # Install a better colorful diff
      wget -c https://github.com/dandavison/delta/releases/download/0.7.1/delta-0.7.1-x86_64-unknown-linux-gnu.tar.gz
      tar -zxvf ./delta-0.7.1-x86_64-unknown-linux-gnu.tar.gz
      cp -f ./delta-0.7.1-x86_64-unknown-linux-gnu/delta /usr/bin/

      # Install procs a colorful ps
      wget -c https://github.com/dalance/procs/releases/download/v0.11.4/procs-v0.11.4-x86_64-lnx.zip
      unzip procs-v0.11.4-x86_64-lnx.zip
      cp -f ./procs /usr/bin/

      # Install network utilization CLI bandwich
      wget -c https://github.com/imsnif/bandwhich/releases/download/0.20.0/bandwhich-v0.20.0-x86_64-unknown-linux-musl.tar.gz
      tar -zxvf ./bandwhich-v0.20.0-x86_64-unknown-linux-musl.tar.gz
      cp -f ./bandwhich /usr/bin/

      # Install git credential helper
      make --directory=/usr/share/doc/git/contrib/credential/libsecret
      git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret

      # Install better vim defaults
      git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
      sh ~/.vim_runtime/install_awesome_vimrc.sh

      # Install oh-my-zsh
      git clone --depth=1 git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
      chsh -s "$ZSH" && "$ZSH" -i -c "omz update"

      # Install powerlevel10k and oh-my-zsh plugins
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME"/.oh-my-zsh/custom/themes/powerlevel10k
      git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

      rm -rf "$TEMPDIR"

      # TODO: Check installation paths in manjaro

      # Create a better system monitor desktop icon
      cat << 'EOF' >/usr/share/applications/sysmonitor.desktop
      [Desktop Entry]
      Version=1.0
      Name=System Monitor
      Type=Application
      Comment=View System Performance
      Terminal=true
      Exec=btm -g --hide_time --hide_table_gap
      Icon=org.gnome.SystemMonitor
      Categories=ConsoleOnly;System;Monitor;Task;
      GenericName=Process Viewer
      Keywords=Monitor;System;Process;CPU;Memory;Network;History;Usage;Performance;Task;Manager;Activity;
EOF

      # Install a better default zsh PS1 TODO: (.zshrc might not exist by default in manjaro)
      cp "$HOME"/.zshrc /opt/simple-desktop-manjaro/backup_confs
      ;;
  esac
}