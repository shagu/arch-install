#!/bin/bash

DIALOG="dialog --clear"

# clean previous install attempts
umount -R /mnt &> /dev/null || true
cryptsetup luksClose /dev/mapper/* &> /dev/null || true

# ask for user configurationa
KEYMAP=$($DIALOG --title "Keymap" --inputbox "Please enter your keymap" 0 0 "" 3>&1 1>&2 2>&3)
KEYMAP=${KEYMAP:-$DEF_KEYMAP}
loadkeys $KEYMAP

USERNAME=$($DIALOG --title "Username" --inputbox "Please enter your username" 0 0 "" 3>&1 1>&2 2>&3)
USERNAME=${USERNAME:-$DEF_USER}

HOSTNAME=$($DIALOG --title "Hostname" --inputbox "Please enter your hostname" 0 0 "" 3>&1 1>&2 2>&3)
HOSTNAME=${HOSTNAME:-$DEF_HOSTNAME}

ROOTDEV=$($DIALOG --title "Harddisk" --radiolist "Please select the target device" 0 0 0 \
$(ls /dev/sd? /dev/mmcblk? /dev/nvme?n? -1 2> /dev/null | while read line; do
echo "$line" "$line" on; done) 3>&1 1>&2 2>&3)
ROOTDEV=${ROOTDEV:-$DEF_ROOTDEV}

if grep "mmcblk" <<< $ROOTDEV &> /dev/null; then
  RDAPPEND=p
fi

if grep "nvme" <<< $ROOTDEV &> /dev/null; then
  RDAPPEND=p
fi

if $DIALOG --title "UEFI" --yesno "Use UEFI Boot?" 0 0; then
  UEFI=y
else
  UEFI=n
fi

if $DIALOG --title "Reuse" --yesno "Do you want to reuse an existing installation?" 0 0; then
  WIPE=n
else
  WIPE=y
fi

DESKTOP=$($DIALOG --title "Desktop" --radiolist "Please select your Desktop" 0 0 0 \
  1 "MATE" on\
  2 "KDE" off\
  3 "GNOME" off\
  4 "CINNAMON" off\
  5 "DEEPIN" off 3>&1 1>&2 2>&3)


TWEAKS=`$DIALOG --title "Tweaks" --checklist "Select Custom Tweaks" 0 0 4 \
 OPTIMUS "Install NVIDIA Hybrid Graphic Drivers" on\
 FIX_PCI "Fix bad PCI Events (RazerBlade2017)" on\
 FIX_GPD "Fix Display Rotation (GPD Win)" off 3>&1 1>&2 2>&3`
for item in $TWEAKS; do
  if [ "$item" = "OPTIMUS" ]; then
    OPTIMUS=y
  elif [ "$item" = "FIX_PCI" ]; then
    FIX_PCI="pci=noaer button.lid_init_state=open"
  elif [ "$item" == "FIX_GPD" ]; then
    FIX_PCI="$FIX_PCI fbcon=rotate:1 dmi_product_name=GPD-WINI55"
  fi
done

while ! [ "$USERPW" = "$USERPW2" ] || [ -z "$USERPW" ]; do
  USERPW=$($DIALOG --title "User Password" --passwordbox "Enter your user password" 0 0 3>&1 1>&2 2>&3)
  USERPW2=$($DIALOG --title "User Password" --passwordbox "Repeat your user password" 0 0 3>&1 1>&2 2>&3)
done

while ! [ "$DISKPW" = "$DISKPW2" ] || [ -z "$DISKPW" ]; do
  DISKPW=$($DIALOG --title "Disk Encryption" --passwordbox "Enter your disk encryption password" 0 0 3>&1 1>&2 2>&3)
  DISKPW2=$($DIALOG --title "Disk Encryption" --passwordbox "Repeat your disk encryption password" 0 0 3>&1 1>&2 2>&3)
done

INSTALL_OPTIMUS="bumblebee mesa lib32-virtualgl nvidia lib32-nvidia-utils primus lib32-primus bbswitch"
INSTALL_BASE="vim openssh wget htop ncdu screen zsh net-tools unp debootstrap unrar unzip p7zip rfkill bind-tools rsnapshot lxc php php-gd lua mariadb-clients libmariadbclient"

INSTALL_DESKTOP="mpv youtube-dl git fuseiso atom chromium firefox vlc ffmpeg gimp blender owncloud-client wine wine-mono wine_gecko steam libreoffice ttf-liberation ttf-ubuntu-font-family ttf-droid ttf-dejavu ttf-freefont noto-fonts-emoji alsa-utils samba lib32-libpulse gst-plugins-ugly gst-plugins-bad gst-libav android-tools pulseaudio-zeroconf noto-fonts picard inkscape audacity pidgin virtualbox virtualbox-host-modules-arch keepassx2"

INSTALL_DESKTOP_GTK="easytag wireshark-gtk gtk-recordmydesktop openshot gcolor2 meld paprefs evolution"
INSTALL_DESKTOP_QT="kid3 wireshark-qt qt-recordmydesktop"

# Setup Variables
case $DESKTOP in
  "1")
    DESKTOP="MATE"
    DESKTOP_APPS="mate mate-extra lightdm lightdm-gtk-greeter-settings networkmanager pulseaudio network-manager-applet blueman gvfs-smb gvfs-mtp"
    DESKTOP_DM="lightdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK} totem gnome-keyring awesome  wireshark-gtk"
  ;;
  "2")
    DESKTOP="KDE"
    DESKTOP_APPS="plasma kde-applications kde-l10n-de"
    DESKTOP_DM="sddm"
    DESKTOP_MISC="${INSTALL_DESKTOP_QT}"
  ;;
  "3")
    DESKTOP="GNOME"
    DESKTOP_APPS="gnome gnome-extra networkmanager"
    DESKTOP_DM="gdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK}"
  ;;
  "4")
    DESKTOP="CINNAMON"
    DESKTOP_APPS="gnome gnome-extra networkmanager cinnamon nemo"
    DESKTOP_DM="gdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK}"
  ;;
  "5")
    DESKTOP="DEEPIN"
    DESKTOP_APPS="deepin deepin-extra networkmanager"
    DESKTOP_DM="lightdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK} gedit gtk-engine-murrine iw redshift zssh gvfs-smb gvfs-mtp gvfs-goa gvfs-afc"
  ;;
esac

cat > /tmp/install-summary.log << EOF
Simple Arch Linux Installer
===========================

Username: $USERNAME
Hostname: $HOSTNAME

Device: $ROOTDEV
Wipe: $WIPE

Desktop: $DESKTOP
Display Manager: $DESKTOP_DM

Packages
========

$INSTALL_BASE
$INSTALL_DESKTOP
$DESKTOP_MISC
$DESKTOP_APPS
$INSTALL_OPTIMUS

Hit Ctrl-C to abort, Return to continue ...
EOF
$DIALOG --title "Summary" --textbox /tmp/install-summary.log 0 0

if [ "$WIPE" = "y" ]; then
  dd if=/dev/zero of=${ROOTDEV} bs=4M conv=fsync count=1

  if [ "$UEFI" = "y" ]; then
    parted ${ROOTDEV} -s mklabel gpt
    parted ${ROOTDEV} -s mkpart ESP fat32 1MiB 513MiB
    parted ${ROOTDEV} -s set 1 boot on

    echo -e "\e[33m::\e[0m formatting ${ROOTDEV}1 as FAT32"
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1

  else
    parted ${ROOTDEV} -s mklabel msdos
    parted ${ROOTDEV} -s mkpart primary 1MiB 513MiB
    parted ${ROOTDEV} -s set 1 boot on

    echo -e "\e[33m::\e[0m formatting ${ROOTDEV}1 as EXT4"
    mkfs.ext4 ${ROOTDEV}${RDAPPEND}1 -L boot
  fi

  parted ${ROOTDEV} -s mkpart primary 513MiB 100%

  # create dm-crypt container
  echo -n "${DISKPW}" | cryptsetup -c aes-xts-plain64 -s 512 luksFormat ${ROOTDEV}${RDAPPEND}2 -
  echo -n "${DISKPW}" | cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d -

  # setup lvm groups
  pvcreate /dev/mapper/cryptlvm
  vgcreate lvm /dev/mapper/cryptlvm
  lvcreate -L 50G lvm -n system
  lvcreate -l 100%FREE lvm -n home

  # create partitions
  mkfs.ext4 /dev/mapper/lvm-system -L system
  mkfs.ext4 /dev/mapper/lvm-home -L home
else
  # unlocking dm-crypt container
  if ! echo -n "${DISKPW}" | cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d - ; then
    cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm || exit 1
  fi

  # reload lvm volumes
  vgchange -ay

  # wait for device
  sleep 1

  # format system partition as ext4
  mkfs.ext4 /dev/mapper/lvm-system -L system

  if [ "$UEFI" = "y" ]; then
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1
  else
    mkfs.ext4 ${ROOTDEV}${RDAPPEND}1 -L boot
  fi
fi

echo -e "\e[33m::\e[0m mounting partitions to /mnt"
mount /dev/mapper/lvm-system /mnt

mkdir /mnt/boot
mount ${ROOTDEV}${RDAPPEND}1 /mnt/boot

mkdir /mnt/home
mount /dev/mapper/lvm-home /mnt/home

echo -e "\e[33m::\e[0m setting up host pacman.conf"
sed -i "s/#Color/Color/" /etc/pacman.conf

echo -e "\e[33m::\e[0m installing base system"
while ! pacstrap /mnt base; do
  echo "Failed: repeating"
done

echo -e "\e[33m::\e[0m creating /etc/fstab"
genfstab -p /mnt > /mnt/etc/fstab

if [ "$CRYPTHOME" = "y" ]; then
  echo -e "\e[33m::\e[0m creating /etc/crypttab"
  echo "home	${ROOTDEV}${RDAPPEND}3	/.key" >> /mnt/etc/crypttab
fi

echo -e "\e[33m::\e[0m creating locales"
cat > /mnt/etc/locale.gen << EOF
de_DE.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOF

echo -e "\e[33m::\e[0m setting language to de_DE.UTF-8"
echo LANG=de_DE.UTF-8 > /mnt/etc/locale.conf

echo -e "\e[33m::\e[0m setting console maps"
cat > /mnt/etc/vconsole.conf << EOF
KEYMAP="$KEYMAP"
FONT=Lat2-Terminus16
FONT_MAP=
EOF

echo -e "\e[33m::\e[0m setting timezone"
ln -sf /usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime
echo $HOSTNAME > /mnt/etc/hostname

echo -e "\e[33m::\e[0m setting up pacman.conf"
sed -i "s/#Color/Color/" /mnt/etc/pacman.conf
sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /mnt/etc/pacman.conf

echo -e "\e[33m::\e[0m setting up initramfs"
sed -i "s/block filesystems/block keymap encrypt lvm2 filesystems/" /mnt/etc/mkinitcpio.conf
sed -i "s/MODULES=\"\"/MODULES=\"i915\"/" /mnt/etc/mkinitcpio.conf

# Second stage
cat > /mnt/finalize.sh << __END_OF_FILE__
#!/bin/bash

locale-gen
. /etc/locale.conf

echo -e "\e[33m::\e[0m installing updates"
while ! pacman -Syu --noconfirm; do echo "repeat..."; done

echo -e "\e[33m::\e[0m installing base tools"
while ! pacman -S --noconfirm base-devel cmake linux-headers ${INSTALL_BASE}; do echo "repeat..."; done

echo -e "\e[33m::\e[0m installing boot packages"
while ! pacman -S --noconfirm efibootmgr dosfstools gptfdisk grub-bios; do echo "repeat..."; done

echo -e "\e[33m::\e[0m installing desktop ($DESKTOP)"
while ! pacman -S --noconfirm xorg xorg-apps xf86-input-evdev xf86-input-synaptics ${DESKTOP_APPS}; do echo "repeat..."; done

echo -e "\e[33m::\e[0m installing applications"
while ! pacman -S --noconfirm ${INSTALL_DESKTOP} ${DESKTOP_MISC}; do echo "repeat..."; done

if [ "${OPTIMUS}" = "y" ]; then
  echo -e "\e[33m::\e[0m installing optimus drivers"
  while ! pacman -S --noconfirm ${INSTALL_OPTIMUS}; do echo "repeat..."; done
fi

if ! [ "$DESKTOP" = "KDE" ]; then
  echo -e "\e[33m::\e[0m Setting Qt5 GTK Look & Feel"
  echo "QT_QPA_PLATFORMTHEME=gtk2" >> /etc/environment
fi

if [ "$DESKTOP" = "DEEPIN" ]; then
  sed -i "s/#greeter-session=.*/greeter-session=lightdm-deepin-greeter/" /etc/lightdm/lightdm.conf
fi

mkinitcpio -p linux

echo -e "\e[33m::\e[0m Disable wine filetype associations"
sed "s/-a //g" -i /usr/share/wine/wine.inf

if [ "$UEFI" = "y" ]; then
  echo -e "\e[33m::\e[0m installing EFI bootloader to ${ROOTDEV}${RDAPPEND}1"
  efibootmgr -c -d ${ROOTDEV} -p 1 -l \vmlinuz-linux -L "Arch Linux" -u "initrd=/initramfs-linux.img cryptdevice=${ROOTDEV}${RDAPPEND}2:cryptlvm root=/dev/mapper/lvm-system rw ${FIX_PCI}"
else
  echo -e "\e[33m::\e[0m installing GRUB bootloader to ${ROOTDEV}${RDAPPEND}1"
  grub-install ${ROOTDEV}
  grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -e "\e[33m::\e[0m creating user (${USERNAME})"
useradd -m ${USERNAME}
gpasswd -a ${USERNAME} audio
gpasswd -a ${USERNAME} video
gpasswd -a ${USERNAME} storage
gpasswd -a ${USERNAME} optical
gpasswd -a ${USERNAME} network
gpasswd -a ${USERNAME} users
gpasswd -a ${USERNAME} wheel
gpasswd -a ${USERNAME} games
gpasswd -a ${USERNAME} rfkill
gpasswd -a ${USERNAME} scanner
gpasswd -a ${USERNAME} power
gpasswd -a ${USERNAME} lp
gpasswd -a ${USERNAME} bumblebee
gpasswd -a ${USERNAME} vboxusers
gpasswd -a ${USERNAME} ${DESKTOP_DM}

echo -e "\e[33m::\e[0m merge userdata into rootfs (${USERNAME})"
if [ -f /home/${USERNAME}/.bashrc ]; then
  ln -s /home/${USERNAME}/.bashrc /root/.bashrc
fi

if [ -f /home/${USERNAME}/.zshrc ]; then
  ln -s /home/${USERNAME}/.zshrc /root/.zshrc
fi

if [ -f /home/${USERNAME}/.vimrc ]; then
  ln -s /home/${USERNAME}/.vimrc /root/.vimrc
fi

if [ -f /home/${USERNAME}/lxc ]; then
  rmdir /var/lib/lxc && ln -s /home/${USERNAME}/lxc /var/lib/lxc
fi

echo "${USERNAME}:${USERPW}" | chpasswd
echo "root:${USERPW}" | chpasswd

echo -e "\e[33m::\e[0m enabling services"
systemctl enable ${DESKTOP_DM}
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable avahi-daemon
systemctl enable bumblebeed

echo -e "\e[33m::\e[0m enable legacy network names"
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

echo -e "\e[33m::\e[0m installing firstrun service"
cat > /etc/systemd/system/firstrun.service << EOF
[Unit]
Description=Firstrun Service

[Service]
ExecStart=/firstrun.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /firstrun.sh << EOF
#!/bin/bash
# Locale
localectl set-keymap $KEYMAP
localectl set-x11-keymap $KEYMAP
localectl set-locale LANG=de_DE.UTF-8

rm -f /etc/systemd/system/firstrun.service /firstrun.sh
EOF

chmod +x /firstrun.sh

systemctl enable firstrun

sync
__END_OF_FILE__

chmod +x /mnt/finalize.sh
arch-chroot /mnt /finalize.sh
rm /mnt/finalize.sh
sync

echo -e "\e[33m::\e[0m installation completed"
echo -e "\e[31m->\e[0m Reboot into the new system"
echo -n "[Hit Enter]" && read
sync && reboot
