#!/bin/bash

rm /mnt/var_uefi
rm /mnt/var_hd
[ -d "/mnt${arch_installer_root}" ] && rm -rfd /mnt${arch_installer_root}

####################
# Farewell Message #
####################

dialog --title "To reboot or not to reboot?" --yesno \
  "Congrats! The install is done! \n\n\
  Do you want to reboot your computer?" 20 60

response=$?
case $response in
  0) reboot;;
  1) clear;;
esac

