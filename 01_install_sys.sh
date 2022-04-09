#!/bin/bash

set -e

# Never run pacman -Sy on your system!
# here we start with our live system that's fine
pacman -Sy --noconfirm dialog

timedatectl set-ntp true

dialog --defaultno --title "Are you sure?" --yesno \
  "This is my personnal arch linux install. \n\n\
  It will DESTROY EVERYTHING on one of your hard disk. \n\n\
  Don't say YES if you are not sure what your're doing! \n\n\
  Do you want to continue?" 15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." \
  10 60 2> /tmp/comp

uefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && uefi=1

devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
  | grep -E 'sd|hd|vd|nvme|mmcblk'))

dialog --title "Choose your hard drive" --no-cancel --radiolist \
  "Where do you want to install your new system? \n\n\
  Select with SPACE, valid with ENTER. \n\n\
  WARNING: Everything will be DESTROYED on the hard disk!" \
  15 60 4 "${devices_list[@]}" 2> hd

hd=$(cat hd) && rm hd

################
# Partitioning #
################

default_size="8"
dialog --no-cancel --inputbox \
  "You need three partitions: Boot, Root and Swap \n\
  The boot partition will be 512M \n\
  The root partition will be the remaining of the hard disk \n\n\
  Enter below the partition size (in Gb) for the Swap. \n\n\
  If you don't enter anything, it will default to ${default_size}G. \n" \
  20 60 2> swap_size
size=$(cat swap_size) && rm swap_size

[[ $size =~ ^[0-9]+$ ]] || size=$default_size

dialog --no-cancel \
  --title "!!! DELETE EVERYTHING !!!" \
  --menu "Choose the way you'll wipe your hard disk ($hd)" \
  15 60 4 \
  1 "Use dd (wipe all disk)" \
  2 "Use shred (slow & secure)" \
  3 "No need - my hard disk is empty" 2> eraser

hderaser=$(cat eraser); rm eraser

function erase_disk() {
  case $1 in
    1) dd if=/dev/zero of="$hd" bs=1M status=progress 2>&1 \
      | dialog \
      --title "Formatting $hd..." \
      --progressbox --stdout 20 60;;
    2) shred -v "$hd" \
      | dialog \
      --title "Formatting $hd..." \
      --progressbox --stdout 20 60;;
    3) ;;
  esac
}

erase_disk "$hderaser"

boot_partition_type=1
[[ "$uefi" == 0 ]] && boot_partition_type=4

#
# Create the partitions
#g - create non empty GPT partition table
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit
#
partprobe "$hd"

fdisk "$hd" << EOF
g
n


+512M
t
$boot_partition_type
n


+${size}G
n



w
EOF

partprobe "$hd"

#
# Formatting partitions
# assuming 2 and 3 partition numbers created by fdisk on empty disk
#
mkswap "${hd}2"
swapon "${hd}2"

mkfs.ext4 "${hd}3"
mount "${hd}3" /mnt

if [ "$uefi" = 1 ]; then
  mkfd.fat -F32 "${hd}1"
  mkdir -p /mnt/boot/efi
  mount "${hd}1" /mnt/boot/efi
fi

#####################
# Install ArchLinux #
#####################

pacstrap /mnt base base-devel linux linux-firmware
# write mounting points to fstab
genfstab -U /mnt >> /mnt/etc/fstab

# persisting important values for next script
echo "$uefi" > /mnt/var_uefi
echo "$hd" > /mnt/var_hd
mv /tmp/comp /mnt/comp
 
arch_installer_root="/arch_installer"
if [ -f "${arch_installer_root}/02_install_chroot.sh" ]; then
  cp -rf "${arch_installer_root}" /mnt
else
  curl https://raw.githubusercontent.com/mweitner\
/arch_installer/main/02_install_chroot.sh > /mnt${arch_installer_root}/02_install_chroot.sh
fi

dialog --title "Install chroot" --yesno \
  "System preparation done.\n\n\
  Do you want to start 02_install_chroot.sh automatically?" \
  20 60

response=$?
# 0: is yes, 1: is no
if [ $response -eq 0 ]; then
  arch-chroot /mnt bash "${arch_installer_root}/02_install_chroot.sh"
else
  arch-chroot /mnt
  exit 0
fi

. "${arch_installer_root}/05_install_farewell.sh"
