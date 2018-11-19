#!/bin/bash

function progress() {
  echo $2 | dialog --title "Installation" --gauge "$1" 0 40 0
}

# clean previous install attempts
umount -R /mnt &> /dev/null || true
cryptsetup luksClose /dev/mapper/* &> /dev/null || true

KEYMAP=$(dialog --clear --title "Keymap" --inputbox "Please enter your keymap" 0 0 "" 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi
loadkeys $KEYMAP

USERNAME=$(dialog --clear --title "Username" --inputbox "Please enter your username" 0 0 "" 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

HOSTNAME=$(dialog --clear --title "Hostname" --inputbox "Please enter your hostname" 0 0 "" 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

ROOTDEV=$(dialog --clear --title "Harddisk" --radiolist "Please select the target device" 0 0 0 \
$(ls /dev/sd? /dev/mmcblk? /dev/nvme?n? -1 2> /dev/null | while read line; do
echo "$line" "$line" on; done) 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

if grep "mmcblk" <<< $ROOTDEV &> /dev/null; then
  RDAPPEND=p
fi

if grep "nvme" <<< $ROOTDEV &> /dev/null; then
  RDAPPEND=p
fi

if dialog --clear --title "UEFI" --yesno "Use UEFI Boot?" 0 0 3>&1 1>&2 2>&3; then
  UEFI=y
else
  UEFI=n
fi

if dialog --clear --title "Reuse" --yesno "Do you want to reuse an existing installation?" 0 0 3>&1 1>&2 2>&3; then
  WIPE=n
else
  WIPE=y
fi

DESKTOP=$(dialog --clear --title "Desktop" --radiolist "Please select your Desktop" 0 0 0 \
  1 "MATE" on\
  2 "KDE" off\
  3 "GNOME" off\
  4 "CINNAMON" off\
  5 "XFCE" off\
  6 "DEEPIN" off 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

TWEAKS=$(dialog --clear --title "Tweaks" --checklist "Select Custom Tweaks" 0 0 0 \
 OPTIMUS "Install NVIDIA Hybrid Graphic Drivers" off\
 INTEL "Enable Latest Intel Graphic Options" off\
 NO_HDPI "Disable HiDPI Scaling" off\
 FIX_PCI "Fix bad PCI Events (RazerBlade2017)" off\
 FIX_GPD "Fix Display Rotation (GPD Win)" off 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

for item in $TWEAKS; do
  if [ "$item" = "OPTIMUS" ]; then
    OPTIMUS=y
  elif [ "$item" = "INTEL" ]; then
    INTEL=y
  elif [ "$item" = "NO_HIDPI" ]; then
    NO_HIDPI=y
  elif [ "$item" = "FIX_PCI" ]; then
    CUSTOM_CMDLINE="pci=noaer button.lid_init_state=open"
  elif [ "$item" == "FIX_GPD" ]; then
    CUSTOM_CMDLINE="$CUSTOM_CMDLINE fbcon=rotate:1 dmi_product_name=GPD-WINI55"
  fi
done

if dialog --clear --title "Mirror" --yesno "Select a mirror?" 0 0 3>&1 1>&2 2>&3; then
  vim /etc/pacman.d/mirrorlist
fi

while ! [ "$USERPW" = "$USERPW2" ] || [ -z "$USERPW" ]; do
  USERPW=$(dialog --clear --title "User Password" --insecure --passwordbox "Enter your user password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
  USERPW2=$(dialog --clear --title "User Password" --insecure --passwordbox "Repeat your user password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
done

while ! [ "$DISKPW" = "$DISKPW2" ] || [ -z "$DISKPW" ]; do
  DISKPW=$(dialog --clear --title "Disk Encryption" --insecure --passwordbox "Enter your disk encryption password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
  DISKPW2=$(dialog --clear --title "Disk Encryption" --insecure --passwordbox "Repeat your disk encryption password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
done

INSTALL_OPTIMUS="bumblebee mesa lib32-virtualgl nvidia lib32-nvidia-utils primus lib32-primus bbswitch"
INSTALL_BASE="vim openssh wget htop ncdu screen zsh net-tools unp debootstrap unrar unzip p7zip rfkill bind-tools rsnapshot lxc php php-gd lua mariadb-clients libmariadbclient"

INSTALL_DESKTOP="mpv youtube-dl git fuseiso atom chromium firefox vlc ffmpeg gimp blender owncloud-client wine wine-mono wine_gecko steam libreoffice ttf-liberation ttf-ubuntu-font-family ttf-droid ttf-dejavu ttf-freefont noto-fonts-emoji alsa-utils samba lib32-libpulse gst-plugins-ugly gst-plugins-bad gst-libav android-tools pulseaudio-zeroconf noto-fonts picard inkscape audacity pidgin virtualbox virtualbox-host-modules-arch keepassx2"

INSTALL_DESKTOP_GTK="easytag wireshark-gtk gtk-recordmydesktop openshot gcolor2 meld paprefs evolution qt5-styleplugins"
INSTALL_DESKTOP_QT="kid3 wireshark-qt qt5"

# Setup Variables
case $DESKTOP in
  "1")
    DESKTOP="MATE"
    DESKTOP_APPS="mate mate-extra lightdm-gtk-greeter-settings networkmanager pulseaudio network-manager-applet blueman gvfs-smb gvfs-mtp"
    DESKTOP_DM="lightdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK} totem gnome-keyring awesome  wireshark-gtk"
  ;;
  "2")
    DESKTOP="KDE"
    DESKTOP_APPS="plasma kde-applications"
    DESKTOP_DM="sddm"
    DESKTOP_THEME="materia-kde materia-gtk-theme kvantum-theme-materia papirus-icon-theme"
    DESKTOP_TWEAKS="libdbusmenu-{qt4,qt5,gtk2,gtk3} lib32-libdbusmenu-{glib,gtk2,gtk3} appmenu-gtk-module appmenu-qt4 plasma5-applets-active-window-control"
    DESKTOP_MISC="${INSTALL_DESKTOP_QT} ${DESKTOP_TWEAKS} ${DESKTOP_THEME}"
  ;;
  "3")
    DESKTOP="GNOME"
    DESKTOP_APPS="gnome gnome-extra chrome-gnome-shell flatpak-builder networkmanager"
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
    DESKTOP="XFCE"
    DESKTOP_APPS="xfce4 xfce4-goodies lightdm-gtk-greeter-settings networkmanager pulseaudio network-manager-applet blueman gvfs-smb gvfs-mtp"
    DESKTOP_DM="lightdm"
    DESKTOP_MISC="${INSTALL_DESKTOP_GTK} totem gnome-keyring awesome  wireshark-gtk"
  ;;
  "6")
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
dialog --clear --title "Summary" --textbox /tmp/install-summary.log 0 0 3>&1 1>&2 2>&3
if test $? -eq 1; then exit 1; fi

progress "Setting Up Disk" 0
if [ "$WIPE" = "y" ]; then
  progress "Deleting MBR Record" 1
  dd if=/dev/zero of=${ROOTDEV} bs=4M conv=fsync count=1

  if [ "$UEFI" = "y" ]; then
    progress "Create GPT Partitiontable" 2
    parted ${ROOTDEV} -s mklabel gpt &> /dev/tty2
    progress "Create Boot Partition" 3
    parted ${ROOTDEV} -s mkpart ESP fat32 1MiB 513MiB &> /dev/tty2
    parted ${ROOTDEV} -s set 1 boot on &> /dev/tty2
    progress "Formatting Boot Partition as FAT32" 4
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1 &> /dev/tty2
  else
    progress "Create MSDOS Partitiontable" 2
    parted ${ROOTDEV} -s mklabel msdos &> /dev/tty2
    progress "Create Boot Partition" 3
    parted ${ROOTDEV} -s mkpart primary 1MiB 513MiB &> /dev/tty2
    parted ${ROOTDEV} -s set 1 boot on &> /dev/tty2
    progress "Formatting Boot Partition as EXT4" 4
    mkfs.ext4 -F ${ROOTDEV}${RDAPPEND}1 -L boot &> /dev/tty2
  fi

  progress "Create System Partition" 5
  parted ${ROOTDEV} -s mkpart primary 513MiB 100% &> /dev/tty2

  progress "Create DM-Crypt Container" 6
  echo -n "${DISKPW}" | cryptsetup -c aes-xts-plain64 -s 512 luksFormat ${ROOTDEV}${RDAPPEND}2 - &> /dev/tty2
  echo -n "${DISKPW}" | cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d - &> /dev/tty2

  progress "Setup LVM Volumes" 7
  pvcreate /dev/mapper/cryptlvm &> /dev/tty2
  vgcreate lvm /dev/mapper/cryptlvm &> /dev/tty2
  lvcreate -L 50G lvm -n system &> /dev/tty2
  lvcreate -l 100%FREE lvm -n home &> /dev/tty2

  progress "Formatting Root Partition as EXT4" 8
  mkfs.ext4 -F /dev/mapper/lvm-system -L system &> /dev/tty2

  progress "Formatting Home Partition as EXT4" 9
  mkfs.ext4 -F /dev/mapper/lvm-home -L home &> /dev/tty2
else
  if [ "$UEFI" = "y" ]; then
    progress "Formatting Boot Partition as FAT32" 2
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1 &> /dev/tty2
  else
    progress "Formatting Boot Partition as EXT4" 4
    mkfs.ext4 -F ${ROOTDEV}${RDAPPEND}1 -L boot &> /dev/tty2
  fi

  progress "Unlocking DM-Crypt Container" 6
  if ! echo -n "${DISKPW}" | cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d - ; then
    cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm || exit 1 &> /dev/tty2
  fi

  progress "Load LVM Volumes" 8
  vgchange -ay &> /dev/tty2
  sleep 1

  progress "Formatting Root Partition as EXT4" 9
  mkfs.ext4 -F /dev/mapper/lvm-system -L system &> /dev/tty2
fi

progress "Mounting /root to /mnt" 10
mount /dev/mapper/lvm-system /mnt &> /dev/tty2

progress "Mounting /boot to /mnt/boot" 15
mkdir /mnt/boot &> /dev/tty2
mount ${ROOTDEV}${RDAPPEND}1 /mnt/boot &> /dev/tty2

progress "Mounting /home to /mnt/home" 20
mkdir /mnt/home &> /dev/tty2
mount /dev/mapper/lvm-home /mnt/home &> /dev/tty2

progress "Installing Target: Base System" 25
sed -i "s/#Color/Color/" /etc/pacman.conf &> /dev/tty2
while ! pacstrap /mnt base &> /dev/tty2; do
  echo "Failed: repeating" &> /dev/tty2
done

progress "Configure Base System" 30
genfstab -p /mnt > /mnt/etc/fstab

cat > /mnt/etc/locale.gen << EOF
de_DE.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOF

echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf

cat > /mnt/etc/vconsole.conf << EOF
KEYMAP="$KEYMAP"
FONT=Lat2-Terminus16
FONT_MAP=
EOF

ln -sf /usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime &> /dev/tty2
echo $HOSTNAME > /mnt/etc/hostname

sed -i "s/#Color/Color/" /mnt/etc/pacman.conf &> /dev/tty2
sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /mnt/etc/pacman.conf &> /dev/tty2

sed -i "s/block filesystems/block keymap encrypt lvm2 filesystems/" /mnt/etc/mkinitcpio.conf &> /dev/tty2
sed -i "s/MODULES=\"\"/MODULES=\"i915\"/" /mnt/etc/mkinitcpio.conf &> /dev/tty2

progress "Generating Locales" 35
arch-chroot /mnt /bin/bash -c "locale-gen" &> /dev/tty2

progress "Installing Target: Updates" 40
arch-chroot /mnt /bin/bash -c "while ! pacman -Syu --noconfirm; do echo repeat...; done" &> /dev/tty2

progress "Installing Target: Base Utils" 45
arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm base-devel cmake linux-headers ${INSTALL_BASE}; do echo repeat...; done" &> /dev/tty2

progress "Installing Target: Boot" 50
arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm dosfstools gptfdisk grub efibootmgr intel-ucode; do echo repeat...; done" &> /dev/tty2

progress "Installing Target: Desktop ($DESKTOP)" 55
arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm xorg xorg-apps xf86-input-evdev xf86-input-synaptics ${DESKTOP_APPS}; do echo repeat...; done" &> /dev/tty2

progress "Installing Target: Applications" 60
arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm ${INSTALL_DESKTOP} ${DESKTOP_MISC}; do echo repeat...; done" &> /dev/tty2

if [ "${OPTIMUS}" = "y" ]; then
  progress "Installing Target: Optimus Drivers" 65
  arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm ${INSTALL_OPTIMUS}; do echo repeat...; done" &> /dev/tty2
fi

progress "Configuring Desktop" 70
# disable wine filetype associations
sed "s/-a //g" -i /mnt/usr/share/wine/wine.inf &> /dev/tty2

if ! [ "$DESKTOP" = "KDE" ]; then
  echo "QT_QPA_PLATFORMTHEME=gtk2" >> /mnt/etc/environment
  echo "QT_STYLE_OVERRIDE=gtk" >> /mnt/etc/environment
fi

if [ "$DESKTOP" = "KDE" ]; then
  cat > /mnt/etc/sddm.conf << EOF
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=
RebootCommand=

[Theme]
Current=breeze
CursorTheme=breeze_cursors

[Users]
MaximumUid=65000
MinimumUid=1000
EOF
fi

if [ "$DESKTOP" = "DEEPIN" ]; then
  sed -i "s/#greeter-session=.*/greeter-session=lightdm-deepin-greeter/" /mnt/etc/lightdm/lightdm.conf &> /dev/tty2
fi

progress "Configuring Hardware Settings" 71
if [ "$INTEL" = "y" ]; then
  echo "options i915 enable_guc=3" >> /mnt/etc/modprobe.d/i915.conf
  echo "options i915 enable_fbc=1" >> /mnt/etc/modprobe.d/i915.conf
  echo "options i915 fastboot=1" >> /mnt/etc/modprobe.d/i915.conf
fi

if [ "$NO_HIDPI" = "y" ]; then
  echo "GDK_SCALE=1" >> /mnt/etc/environment
  echo "GDK_DPI_SCALE=1" >> /mnt/etc/environment
  echo "QT_SCALE_FACTOR=1" >> /mnt/etc/environment
  echo "QT_AUTO_SCREEN_SCALE_FACTOR=0" >> /mnt/etc/environment
fi

progress "Rebuild Initramfs" 75
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux" &> /dev/tty2

if [ "$UEFI" = "y" ]; then
  progress "Installing systemd-boot to ${ROOTDEV}${RDAPPEND}1" 80
  arch-chroot /mnt /bin/bash -c "bootctl --path=/boot install" &> /dev/tty2
  echo "title   Arch Linux" > /mnt/boot/loader/entries/arch.conf
  echo "linux   /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
  echo "initrd  /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
  echo "initrd  /initramfs-linux.img" >> /mnt/boot/loader/entries/arch.conf
  echo "options root=/dev/mapper/lvm-system rw cryptdevice=${ROOTDEV}${RDAPPEND}2:cryptlvm quiet" >> /mnt/boot/loader/entries/arch.conf
else
  progress "Installing GRUB Bootloader to ${ROOTDEV}${RDAPPEND}1" 80
  arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm grub efibootmgr intel-ucode; do echo repeat...; done" &> /dev/tty2
  sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=${ROOTDEV}${RDAPPEND}2:cryptlvm ${CUSTOM_CMDLINE}\"|" /mnt/etc/default/grub &> /dev/tty2
  sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/" /mnt/etc/default/grub &> /dev/tty2
  sed -i "s/GRUB_GFXMODE=auto/GRUB_GFXMODE=1920x1080,auto/" /mnt/etc/default/grub &> /dev/tty2
  arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc ${ROOTDEV}" &> /dev/tty2
  arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" &> /dev/tty2
fi


progress "Setting up User: ${USERNAME}" 85
echo "${USERNAME} ALL=(ALL) ALL" >> /mnt/etc/sudoers
arch-chroot /mnt /bin/bash -c "useradd -m ${USERNAME}" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "usermod -a -G audio,video,storage,optical,network,users,wheel,games,rfkill,scanner,power,lp,vboxusers ${USERNAME}" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "gpasswd -a ${USERNAME} bumblebee" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "gpasswd -a ${USERNAME} ${DESKTOP_DM}" &> /dev/tty2

arch-chroot /mnt /bin/bash -c "echo \"${USERNAME}:${USERPW}\" | chpasswd" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "echo \"root:${USERPW}\" | chpasswd" &> /dev/tty2

ln -s /home/${USERNAME}/.bashrc /mnt/root/.bashrc &> /dev/tty2
ln -s /home/${USERNAME}/.zshrc /mnt/root/.zshrc &> /dev/tty2
ln -s /home/${USERNAME}/.vimrc /mnt/root/.vimrc &> /dev/tty2

progress "Configuring systemd Services" 90
arch-chroot /mnt /bin/bash -c "systemctl enable ${DESKTOP_DM}" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "systemctl enable bluetooth" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "systemctl enable avahi-daemon" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "systemctl enable bumblebeed" &> /dev/tty2

ln -s /dev/null /mnt/etc/udev/rules.d/80-net-setup-link.rules &> /dev/tty2

progress "Installing Firstrun Service" 95
cat > /mnt/etc/systemd/system/firstrun.service << EOF
[Unit]
Description=Firstrun Service

[Service]
ExecStart=/firstrun.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /mnt/firstrun.sh << EOF
#!/bin/bash
# Locale
localectl set-keymap $KEYMAP
localectl set-x11-keymap $KEYMAP
localectl set-locale LANG=en_US.UTF-8

rm -f /etc/systemd/system/firstrun.service /firstrun.sh
EOF

chmod +x /mnt/firstrun.sh &> /dev/tty2
arch-chroot /mnt /bin/bash -c "systemctl enable firstrun.service" &> /dev/tty2

progress "Syncing Disks" 100
sync

dialog --title "Installtion" --msgbox "Installation completed. Press Enter to reboot into the new system." 0 0
reboot
