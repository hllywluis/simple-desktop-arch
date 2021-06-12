#!/bin/bash
#
# simple-desktop
# Opinionated, performant, and responsive experience to daily-users and developers on the Ubuntu 20+ desktop
#
# Copyright (C) 2021  Perlogix, Timothy Marcinowski
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
  command -v inxi 1>/dev/null && inxi -Fxz || echo "Install inxi:  pacman -S inxi" # TODO: might be wrong
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
      echo "options: slack,discord,chrome,firefox,spotify,zoom,teams,overclock,developer,theme,docker,flatpak,cleanup_script,disable_spectre"
      ;;
  esac
}

# Install common desktop apps (mostly using a combination of pacman and yay)
# TODO: For snap-specific packages, we need to make a method to check for and install snapd on arch
install() {
  case $1 in
    slack)
      snap install slack --classic # TODO: Change this to use yay later.
      ;;

    chrome)
      # TODO: Not sure if this will use Brave or Chrome?
      ;;

    spotify)
      # TODO: Use yay here.
      ;;

    zoom)
      # TODO: Use yay again.
      ;;

    team)
      # TODO: Oh look, more yay!
      ;;

    discord)
      # TODO: Did someone say yay again?
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
      pacman -S android-tools-adb wget curl lzip tar unzip squashfs-tools --noconfirm
      ;;
  esac
}