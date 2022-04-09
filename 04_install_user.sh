#!/bin/bash

set -e

mkdir -p "/home/$(whoami)/Documents"
mkdir -p "/home/$(whoami)/Downloads"

# this must be done at i3 level when x11 is started
# here it's not supported
#localectl --no-convert set-x11-keymap "us"

function aur_install() {
  curl -L "https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz" \
    > "$1.tar.gz"
  tar -xvf "$1.tar.gz" \
  && cd "$1" \
  && makepkg --noconfirm -si \
  && cd - \
  && rm -rf "$1" "$1.tar.gz" ;
}

function aur_check() {
  #first extract package name of aur repo package
  qm=$(pacman -Qm | awk '{print $1}')
  #loop through function arguments and if aur package is not installed install it by yay
  for arg in "$@"
  do
    if [[ "$qm" != *"$arg"* ]]; then
      #try to install with yay, if it fails, try install with aur_install
      yay --noconfirm -S "$arg" &>> /tmp/aur_install \
        || aur_install "$arg" &>> /tmp/aur_install
    fi
  done
}

cd /tmp
count=$(wc -l < /tmp/aur_queue)
c=0

echo "install_user.sh:42: going to install from /tmp/aur_queue"
cat /tmp/aur_queue | while read -r line
do
  c=$(( "$c" + 1 ))
  dialog --infobox \
    "AUR install - Downloading and installing program $c out of $count: $line..." \
    10 60
  aur_check "$line"
done

# install spacevim hard coded here
curl -sLf https://spacevim.org/install.sh | bash

#########################
# Install dotfiles repo #
#########################

DOTFILES="/home/$(whoami)/dotfiles"
if [ ! -d "$DOTFILES" ]; then
  git clone https://github.com/mweitner/dotfiles.git \
    "$DOTFILES" >/dev/null
fi

source "$DOTFILES/zsh/.zshenv"
cd "$DOTFILES" && bash install.sh

