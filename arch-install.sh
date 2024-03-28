#!/bin/bash

function progress() {
  dialog --infobox "$1" 3 42
}

SYSTEMD=""
SYSTEMD_DESKTOP="NetworkManager bluetooth avahi-daemon cups"
UGROUPS="audio video storage optical network users wheel games rfkill scanner power lp"
PACKAGES="base-devel cmake linux-firmware linux-headers dosfstools gptfdisk amd-ucode intel-ucode vim openssh git wget htop ncdu screen net-tools unrar unzip p7zip rfkill bind-tools alsa-utils jack2 lvm2"
PACKAGE_DESKTOP="xorg xorg-drivers xorg-apps xf86-input-evdev xf86-input-synaptics lib32-vulkan-intel vulkan-intel lib32-vulkan-radeon vulkan-radeon xcursor-vanilla-dmz xcursor-vanilla-dmz-aa cups nss-mdns"
PACKAGE_DESKTOP_GTK="paprefs materia-gtk-theme papirus-icon-theme"
PACKAGE_DESKTOP_QT="qt5"
PACKAGE_DESKTOP_MATE="mate mate-extra lightdm-gtk-greeter-settings networkmanager network-manager-applet blueman gvfs-smb gvfs-mtp totem gnome-keyring"
PACKAGE_DESKTOP_MATE_DM="lightdm"
PACKAGE_DESKTOP_KDE_GLOBALMENU="libdbusmenu-glib libdbusmenu-gtk2 libdbusmenu-gtk3 libdbusmenu-qt5 lib32-libdbusmenu-glib lib32-libdbusmenu-gtk2 lib32-libdbusmenu-gtk3 appmenu-gtk-module"
PACKAGE_DESKTOP_KDE_COMPATIBILITY="plasma5-integration kwayland5 breeze5 oxygen5"
PACKAGE_DESKTOP_KDE="plasma kde-applications packagekit-qt5 kio-fuse flatpak fwupd $PACKAGE_DESKTOP_KDE_GLOBALMENU $PACKAGE_DESKTOP_KDE_COMPATIBILITY"
PACKAGE_DESKTOP_KDE_DM="sddm"
PACKAGE_DESKTOP_GNOME="gnome gnome-extra flatpak-builder networkmanager"
PACKAGE_DESKTOP_GNOME_DM="gdm"
PACKAGE_DESKTOP_CINNAMON="networkmanager cinnamon nemo mate-extra lightdm-gtk-greeter-settings blueberry"
PACKAGE_DESKTOP_CINNAMON_DM="lightdm"
PACKAGE_DESKTOP_XFCE="xfce4 xfce4-goodies lightdm-gtk-greeter-settings networkmanager network-manager-applet blueman gvfs-smb gvfs-mtp totem gnome-keyring"
PACKAGE_DESKTOP_XFCE_DM="lightdm"
PACKAGE_DESKTOP_DEEPIN_APPS="deepin deepin-extra networkmanager"
PACKAGE_DESKTOP_DEEPIN_DM="lightdm"
PACKAGE_DESKTOP_HTPC="gnome gnome-extra chrome-gnome-shell networkmanager steam kodi kodi kodi-addons kodi-addons-visualization"
PACKAGE_DESKTOP_HTPC_DM="gdm"
PACKAGE_EXT_CONSOLE="zsh unp lxc debootstrap rsnapshot yt-dlp samba android-tools fuseiso"
PACKAGE_EXT_OPTIMUS="bumblebee lib32-virtualgl nvidia lib32-nvidia-utils primus lib32-primus bbswitch primus_vk lib32-primus_vk"
PACKAGE_EXT_FONTS="ttf-liberation ttf-ubuntu-font-family ttf-droid ttf-dejavu gnu-free-fonts noto-fonts noto-fonts-emoji"
PACKAGE_EXT_CODECS="gst-plugins-ugly gst-plugins-bad gst-libav ffmpeg libbluray libaacs libdvdcss"
PACKAGE_EXT_APPS="mpv audacious chromium firefox vlc gimp blender libreoffice lib32-libpulse picard inkscape audacity pidgin virtualbox-host-modules-arch virtualbox keepassxc wireshark-qt syncthing"
PACKAGE_EXT_APPS_GAMING="wine wine-mono wine_gecko lib32-openssl lib32-gnutls lib32-mpg123 lib32-libltdl vkd3d lib32-vkd3d lib32-gst-plugins-good lib32-gst-plugins-base lib32-gst-plugins-base-libs steam"
PACKAGE_EXT_APPS_GTK="easytag openshot meld evolution quodlibet celluloid"
PACKAGE_EXT_APPS_QT="kid3 krita"

# external scripts
sshcrypt_udhcp='#!/bin/sh
NETMASK=""
BROADCAST="broadcast +"

[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="/$subnet"

case "$1" in
  deconfig)
    ip route flush 0/0 dev $interface
    ip addr flush dev $interface
  ;;

  renew|bound)
    ip addr add $ip$NETMASK $BROADCAST dev $interface
    if [ -n "$router" ]; then
      ip route flush 0/0 dev $interface
      metric=0
      for hop in $router; do
        if [ "$subnet" = "255.255.255.255" ]; then
          ip route add $hop dev $interface
        else
          ip route add default via $hop dev $interface metric $((metric++))
        fi
      done
    fi
  ;;
esac'

sshcrypt_install='#!/bin/bash
build() {
  local mod

  add_module "dm-crypt"
  if [[ $CRYPTO_MODULES ]]; then
    for mod in $CRYPTO_MODULES; do
      add_module "$mod"
    done
  else
    add_all_modules "/crypto/"
  fi

  umask 0022
  [ -d /etc/dropbear ] && mkdir -p /etc/dropbear

  # build keys
  if ! [ -f /etc/dropbear/dropbear_rsa_host_key ]; then
    local keyfile keytype
    for keytype in rsa dss ecdsa ; do
      keyfile="/etc/dropbear/dropbear_${keytype}_host_key"
      if [ ! -s "$keyfile" ]; then
        echo "Generating ${keytype} host key for dropbear ..."
        dropbearkey -t "${keytype}" -f "${keyfile}"
      fi
     done
  fi

  echo "root::0:0:root:/root:/bin/unlock" > "${BUILDROOT}"/etc/passwd
  echo "/bin/unlock" > "${BUILDROOT}"/etc/shells
  add_checked_modules "/drivers/net/"

  add_binary "rm"
  add_binary "killall"
  add_binary "dropbear"
  add_binary "dmsetup"
  add_binary "cryptsetup"
  add_binary "/usr/lib/libgcc_s.so.1"
  add_binary "/etc/initcpio/udhcpc.script" "/udhcpc.script"

  add_file "/usr/lib/udev/rules.d/10-dm.rules"
  add_file "/usr/lib/udev/rules.d/13-dm-disk.rules"
  add_file "/usr/lib/udev/rules.d/95-dm-notify.rules"
  add_file "/usr/lib/initcpio/udev/11-dm-initramfs.rules" "/usr/lib/udev/rules.d/11-dm-initramfs.rules"
  add_file "/lib/libnss_files.so.2"
  add_file "/etc/hostname"

  add_dir "/var/run"
  add_dir "/var/log"
  add_full_dir "/etc/dropbear"

  touch "${BUILDROOT}"/var/log/lastlog

  add_runscript
}'

sshcrypt_hook='#!/bin/sh
run_hook() {
  modprobe -a -q dm-crypt >/dev/null 2>&1

  # read cmdline
  if [ -n "${cryptdevice}" ]; then
    cryptdev=$(echo $cryptdevice | cut -d : -f 1)
    cryptname=$(echo $cryptdevice | cut -d : -f 2)
    cryptoptions=$(echo $cryptdevice | cut -d : -f 3)
  fi

  # resolve device
  if resolved=$(resolve_device "${cryptdev}" ${rootdelay}); then
    if cryptsetup isLuks ${resolved} >/dev/null 2>&1; then
      touch /tmp/.nocrypt

      # create unlock script
      echo "#!/bin/sh -e" > /bin/unlock
      echo "until cryptsetup open --type luks ${resolved} ${cryptname}; do" >> /bin/unlock
      echo "  sleep" >> /bin/unlock
      echo "done" >> /bin/unlock
      echo "rm /tmp/.nocrypt" >> /bin/unlock
      chmod +x "${BUILDROOT}"/bin/unlock

      # start udhcpc
      ip link set dev eth0 up
      udhcpc -p /var/run/udhcpc.pid -s /udhcpc.script -x hostname:$(cat /etc/hostname)

      # start dropbear
      [ -d /dev/pts ] || mkdir -p /dev/pts
      mount -t devpts devpts /dev/pts
      dropbear -E -B -j -k -p 2222

      until ! [ -f /tmp/.nocrypt ]; do sleep 1; done
    fi
  fi
}

run_cleanuphook () {
  # stop dropbear
  umount /dev/pts
  rm -R /dev/pts
  if [ -f /var/run/dropbear.pid ]; then
    kill `cat /var/run/dropbear.pid`
  fi

  if [ -f /var/run/udhcpc.pid ]; then
    kill `cat /var/run/udhcpc.pid`
  fi
}'

matebookxorg='Section "Monitor"
    Identifier "eDP-1"
    Modeline "1920x1280_60.00" 206.25  1920 2056 2256 2592  1280 1283 1293 1327 -hsync +vsync
    Modeline "2160x1440_60.00" 263.50 2160 2320 2552 2944 1440 1443 1453 1493 -hsync +vsync
    Option "PreferredMode" "2160x1440_60.00"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "eDP-1"
    DefaultDepth 24
    SubSection "Display"
        Modes "2160x1440_60.00"
    EndSubSection
EndSection

Section "Device"
    Identifier "Device0"
    Driver "modesetting"
EndSection'

# prepare system for installation
echo 'screen_color = (CYAN,BLACK,ON)' > ~/.dialogrc
systemctl stop getty@tty2
dmesg -D

# clean previous install attempts
umount -R /mnt &> /dev/null || true
if [ -b /dev/mapper/lvm-system ]; then
  vgchange -an lvm && sleep 2
fi

if [ -b /dev/mapper/cryptlvm ]; then
  cryptsetup luksClose /dev/mapper/cryptlvm
fi

# KEYMAP
while [ -z $KEYMAP ]; do
  KEYMAP=$(dialog --menu "Select your keyboard layout:" 0 0 0\
    de German\
    fr French\
    us English\
    "" Custom 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi

  if [ -z "$KEYMAP" ]; then
    KEYMAP=$(dialog --clear --title "Keymap" --inputbox "Please enter your keymap" 0 0 "" 3>&1 1>&2 2>&3)
  fi
done

loadkeys $KEYMAP

# WIFI
if iwconfig | grep IEEE &> /dev/null; then
  if dialog --clear --title "WiFi" --yesno "Connect to WiFi?" 0 0 3>&1 1>&2 2>&3; then
    nmtui
  fi
fi

# MIRROR
if dialog --clear --title "Mirror" --yesno "Select a mirror?" 0 0 3>&1 1>&2 2>&3; then
  vim /etc/pacman.d/mirrorlist
fi

# ROOTDEV
ROOTDEV=$(dialog --clear --title "Harddisk" --radiolist "Please select the target device" 0 0 0 \
$(ls /dev/sd? /dev/vd? /dev/mmcblk? /dev/nvme?n? -1 2> /dev/null | while read line; do
echo "$line" "$line" on; done) 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi
if grep -q "mmcblk" <<< $ROOTDEV || grep -q "nvme" <<< $ROOTDEV; then
  RDAPPEND=p
fi

# UEFI
if dialog --clear --title "UEFI" --yesno "Use UEFI Boot?" 0 0 3>&1 1>&2 2>&3; then
  UEFI=y
  PACKAGES="$PACKAGES efibootmgr"
else
  UEFI=n
  PACKAGES="$PACKAGES grub"
fi

DISKPW="..."
while ! [ "$DISKPW" = "$DISKPW2" ]; do
  DISKPW=$(dialog --clear --title "Disk Encryption" --insecure --passwordbox "Enter your disk encryption password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
  DISKPW2=$(dialog --clear --title "Disk Encryption" --insecure --passwordbox "Repeat your disk encryption password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi

  echo -n "$DISKPW" > /tmp/DISKPW
done

# try to unlock previous installation
progress "Trying to unlock disks..."
cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d /tmp/DISKPW &> /dev/tty2
vgchange -ay &> /dev/tty2
sleep 2

if ! [ -b /dev/mapper/lvm-system ]; then
  WIPE=y
else
  WIPE=n
fi

if [ "$WIPE" = "n" ]; then
  if ! dialog --clear --title "Reuse" --yesno "Do you want to reuse the existing installation?" 0 0 3>&1 1>&2 2>&3; then
    WIPE=y
  fi
fi

if [ "$WIPE" = "y" ]; then
  # close active installation
  progress "Reload disks..."
  vgchange -an lvm &> /dev/tty2
  cryptsetup luksClose cryptlvm &> /dev/tty2

  ROOTFS_SIZE=$(dialog --clear --title "Rootfs Size" --inputbox "Please enter the desired size of the root partition" 0 0 "50G" 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
fi

DESKTOP=$(dialog --clear --title "Desktop Selection" --radiolist "Please select your Desktop" 0 0 0 \
  1 "GNOME Desktop" on\
  2 "KDE Plasma Desktop" off\
  3 "MATE Desktop" off\
  4 "Cinnamon Desktop" off\
  5 "Xfce Desktop" off\
  6 "Deepin Desktop" off\
  7 "HTPC (Kodi & GNOME)" off\
  8 "Headless (Remote)" off\
  9 "Minimal" off 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

case $DESKTOP in
  "1")
    DESKTOP="GNOME"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_GNOME $PACKAGE_DESKTOP_GNOME_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_GNOME_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_GNOME_DM"
    EXT_APPS_GTK="on"
    EXT_APPS_QT="off"
  ;;
  "2")
    DESKTOP="KDE"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_QT $PACKAGE_DESKTOP_KDE $PACKAGE_DESKTOP_KDE_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_KDE_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_KDE_DM"
    EXT_APPS_GTK="off"
    EXT_APPS_QT="on"
  ;;
  "3")
    DESKTOP="MATE"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_MATE $PACKAGE_DESKTOP_MATE_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_MATE_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_MATE_DM"
    EXT_APPS_GTK="on"
    EXT_APPS_QT="off"
  ;;
  "4")
    DESKTOP="CINNAMON"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_CINNAMON $PACKAGE_DESKTOP_CINNAMON_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_CINNAMON_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_CINNAMON_DM"
    EXT_APPS_GTK="on"
    EXT_APPS_QT="off"
  ;;
  "5")
    DESKTOP="XFCE"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_XFCE $PACKAGE_DESKTOP_XFCE_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_XFCE_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_XFCE_DM"
    EXT_APPS_GTK="on"
    EXT_APPS_QT="off"
  ;;
  "6")
    DESKTOP="DEEPIN"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_QT $PACKAGE_DESKTOP_DEEPIN $PACKAGE_DESKTOP_DEEPIN_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_DEEPIN_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_DEEPIN_DM"
    EXT_APPS_GTK="off"
    EXT_APPS_QT="on"
  ;;
  "7")
    DESKTOP="HTPC"
    PACKAGES="$PACKAGES $PACKAGE_DESKTOP $PACKAGE_DESKTOP_GTK $PACKAGE_DESKTOP_HTPC $PACKAGE_DESKTOP_HTPC_DM"
    SYSTEMD="$SYSTEMD $SYSTEMD_DESKTOP $PACKAGE_DESKTOP_HTPC_DM"
    UGROUPS="$UGROUPS $PACKAGE_DESKTOP_HTPC_DM"
    EXT_APPS_GTK="off"
    EXT_APPS_QT="off"
  ;;
  "8")
    DESKTOP="HEADLESS"
    PACKAGES="dropbear dhcpcd $PACKAGES"
    SYSTEMD="$SYSTEMD sshd dhcpcd@eth0"
    EXT_APPS_GTK="off"
    EXT_APPS_QT="off"
  ;;
  "9")
    DESKTOP="MINIMAL"
    EXT_APPS_GTK="off"
    EXT_APPS_QT="off"
  ;;
esac

if [ "$DESKTOP" = "MINIMAL" ] || [ "$DESKTOP" = "HEADLESS" ] || [ "$DESKTOP" = "HTPC" ]; then
  HAS_DESKTOP=off
else
  HAS_DESKTOP=on
fi

WANT_FONTS=$HAS_DESKTOP
WANT_CODECS=$HAS_DESKTOP

if [ "$DESKTOP" = "HTPC" ]; then
  WANT_FONTS=on
  WANT_CODECS=on
fi

EXT_PACKAGES=$(dialog --clear --title "Additional Software" --checklist "Select Additional Software" 0 0 0 \
  EXT_FONTS "Fonts" $WANT_FONTS\
  EXT_CODECS "Codecs" $WANT_CODECS\
  EXT_CONSOLE "Console Applications" on\
  EXT_APPS "Desktop Applications" $HAS_DESKTOP\
  EXT_APPS_GAMING "Desktop Gaming Applications" $HAS_DESKTOP\
  EXT_APPS_GTK "Desktop GTK Applications" $EXT_APPS_GTK\
  EXT_APPS_QT "Desktop Qt Applications" $EXT_APPS_QT 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

for item in $EXT_PACKAGES; do
  if [ "$item" = "EXT_FONTS" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_FONTS"
  elif [ "$item" = "EXT_CODECS" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_CODECS"
  elif [ "$item" = "EXT_CONSOLE" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_CONSOLE"
  elif [ "$item" = "EXT_APPS" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_APPS"
    UGROUPS="$UGROUPS vboxusers"
  elif [ "$item" = "EXT_APPS_GAMING" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_APPS_GAMING"
  elif [ "$item" = "EXT_APPS_GTK" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_APPS_GTK"
  elif [ "$item" = "EXT_APPS_QT" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_APPS_QT"
  fi
done

if lspci | grep -i "3d\|video\|vga" | grep -iq intel; then
  HAS_INTEL=on
else
  HAS_INTEL=off
fi

if lspci | grep -i "3d\|video\|vga" | grep -iq 'ati\|amd'; then
  HAS_RADEON=on
else
  HAS_RADEON=off
fi

if lspci | grep -i "3d\|video\|vga" | grep -iq nvidia; then
  HAS_NVIDIA=on
else
  HAS_NVIDIA=off
fi

if [ "$HAS_INTEL" = "on" ] && [ "$HAS_NVIDIA" = "on" ]; then
  HAS_OPTIMUS=on
else
  HAS_OPTIMUS=off
fi

if [ "$(cat /sys/class/graphics/fb0/virtual_size)" = "3000,2000" ]; then
  MATEBOOK=on
else
  MATEBOOK=off
fi

if lsmod | grep -iq elan_i2c && dmesg | grep -iq elan0634; then
  YOGASLIM=on
else
  YOGASLIM=off
fi

TWEAKS=$(dialog --clear --title "Tweaks" --checklist "Select Custom Tweaks" 0 0 0 \
  RADEON "Setup Radeon Graphics" $HAS_RADEON\
  INTEL "Setup Intel Graphics" $HAS_INTEL\
  OPTIMUS "Setup NVIDIA Hybrid Graphics" $HAS_OPTIMUS\
  NO_HIDPI "Disable HiDPI Scaling" on\
  FIX_GPD "Hardware: GPD Win" off\
  FIX_YOGASLIM "Hardware: Yoga Slim 7" on\
  FIX_MATEBOOK "Hardware: Huawei Matebook X Pro" $MATEBOOK 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

for item in $TWEAKS; do
  if [ "$item" = "OPTIMUS" ]; then
    PACKAGES="$PACKAGES $PACKAGE_EXT_OPTIMUS"
    SYSTEMD="$SYSTEMD bumblebeed"
    UGROUPS="$UGROUPS bumblebee"
  elif [ "$item" = "RADEON" ]; then
    RADEON=y
  elif [ "$item" = "INTEL" ]; then
    INTEL=y
  elif [ "$item" = "NO_HIDPI" ]; then
    NO_HIDPI=y
  elif [ "$item" == "FIX_GPD" ]; then
    CUSTOM_CMDLINE="$CUSTOM_CMDLINE fbcon=rotate:1 dmi_product_name=GPD-WINI55"
  elif [ "$item" == "FIX_YOGASLIM" ]; then
    FIX_YOGASLIM=y
  elif [ "$item" == "FIX_MATEBOOK" ]; then
    FIX_MATEBOOK=y
  fi
done

HOSTNAME=$(dialog --clear --title "Hostname" --inputbox "Please enter your hostname" 0 0 "" 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

USERNAME=$(dialog --clear --title "Username" --inputbox "Please enter your username" 0 0 "" 3>&1 1>&2 2>&3)
if test $? -eq 1; then exit 1; fi

while ! [ "$USERPW" = "$USERPW2" ] || [ -z "$USERPW" ]; do
  USERPW=$(dialog --clear --title "User Password" --insecure --passwordbox "Enter your user password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
  USERPW2=$(dialog --clear --title "User Password" --insecure --passwordbox "Repeat your user password" 0 0 3>&1 1>&2 2>&3)
  if test $? -eq 1; then exit 1; fi
done

if [ "$WIPE" = "y" ]; then
  cryptsize=$(parted <<<'unit MB print all' | grep ${ROOTDEV} | cut -d " " -f 3)
  echo "\Z1WARNING: All data on '$ROOTDEV' will be deleted!\Zn" > /tmp/install-summary.log
  echo "" >> /tmp/install-summary.log
  echo "${ROOTDEV}" >> /tmp/install-summary.log
  echo "\Zb - ${ROOTDEV}${RDAPPEND}1 - Boot (512M)\Zn" >> /tmp/install-summary.log
  echo "\Zb - ${ROOTDEV}${RDAPPEND}2 - Encrypted LVM\Zn" >> /tmp/install-summary.log
  echo "" >> /tmp/install-summary.log
  echo "Encrypted LVM" >> /tmp/install-summary.log
  echo "\Zb - lvm-system ($ROOTFS_SIZE)\Zn" >> /tmp/install-summary.log
  echo "\Zb - lvm-home\Zn" >> /tmp/install-summary.log
else
  echo "\Z1WARNING: '/boot' ($ROOTDEV${RDAPPEND}1) and 'lvm-system' will be deleted!\Zn" > /tmp/install-summary.log
  echo "" >> /tmp/install-summary.log
  echo "${ROOTDEV}" >> /tmp/install-summary.log
  echo "\Zb - ${ROOTDEV}${RDAPPEND}1 - Boot (format)\Zn" >> /tmp/install-summary.log
  echo "\Zb - ${ROOTDEV}${RDAPPEND}2 - Encrypted LVM (keep)\Zn" >> /tmp/install-summary.log
  echo "" >> /tmp/install-summary.log
  echo "Encrypted LVM" >> /tmp/install-summary.log
  echo "\Zb - lvm-system (format)\Zn" >> /tmp/install-summary.log
  echo "\Zb - lvm-home (keep)\Zn" >> /tmp/install-summary.log
fi

echo "" >> /tmp/install-summary.log
echo "Profile: \Zb$DESKTOP\Zn" >> /tmp/install-summary.log
echo "" >> /tmp/install-summary.log
echo "User: \Zb$USERNAME\Zn" >> /tmp/install-summary.log
echo "Keymap: \Zb$KEYMAP\Zn" >> /tmp/install-summary.log
echo "Hostname: \Zb$HOSTNAME\Zn" >> /tmp/install-summary.log
echo "" >> /tmp/install-summary.log
echo "Packages: \Zb$PACKAGES\Zn" >> /tmp/install-summary.log
echo "" >> /tmp/install-summary.log
echo "Do you want to continue?" >> /tmp/install-summary.log

if ! dialog --clear --title "Summary" --colors --yesno "$(cat /tmp/install-summary.log)" 0 0 3>&1 1>&2 2>&3; then
  exit 1
fi

progress "Setting Up ${ROOTDEV}..."
if [ "$WIPE" = "y" ]; then
  dd if=/dev/zero of=${ROOTDEV} bs=4M conv=fsync count=1 &> /dev/tty2

  if [ "$UEFI" = "y" ]; then
    parted ${ROOTDEV} -s mklabel gpt &> /dev/tty2
    parted ${ROOTDEV} -s mkpart ESP fat32 1MiB 513MiB &> /dev/tty2
    parted ${ROOTDEV} -s set 1 boot on &> /dev/tty2
    parted ${ROOTDEV} -s mkpart primary 513MiB 100% &> /dev/tty2

    progress "Setting Up ${ROOTDEV}${RDAPPEND}1..."
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1 &> /dev/tty2
  else
    parted ${ROOTDEV} -s mklabel msdos &> /dev/tty2
    parted ${ROOTDEV} -s mkpart primary 1MiB 513MiB &> /dev/tty2
    parted ${ROOTDEV} -s set 1 boot on &> /dev/tty2
    parted ${ROOTDEV} -s mkpart primary 513MiB 100% &> /dev/tty2

    progress "Setting Up ${ROOTDEV}${RDAPPEND}1..."
    mkfs.ext4 -F ${ROOTDEV}${RDAPPEND}1 -L boot &> /dev/tty2
  fi

  progress "Setting Up ${ROOTDEV}${RDAPPEND}2..."
  cryptsetup -c aes-xts-plain64 -s 512 luksFormat ${ROOTDEV}${RDAPPEND}2 -d /tmp/DISKPW --batch-mode &> /dev/tty2
  cryptsetup luksOpen ${ROOTDEV}${RDAPPEND}2 cryptlvm -d /tmp/DISKPW &> /dev/tty2

  progress "Setting Up ${ROOTDEV}${RDAPPEND}2 (lvm)..."
  pvcreate /dev/mapper/cryptlvm &> /dev/tty2
  vgcreate lvm /dev/mapper/cryptlvm &> /dev/tty2
  lvcreate -L ${ROOTFS_SIZE} lvm -n system &> /dev/tty2
  lvcreate -l 100%FREE lvm -n home &> /dev/tty2

  progress "Setting Up ${ROOTDEV}${RDAPPEND}2 (lvm-system)..."
  mkfs.ext4 -F /dev/mapper/lvm-system -L system &> /dev/tty2

  progress "Setting Up ${ROOTDEV}${RDAPPEND}2 (lvm-home)..."
  mkfs.ext4 -F /dev/mapper/lvm-home -L home &> /dev/tty2
else
  progress "Setting Up ${ROOTDEV}${RDAPPEND}1..."
  if [ "$UEFI" = "y" ]; then
    mkfs.fat -F 32 -n EFIBOOT ${ROOTDEV}${RDAPPEND}1 &> /dev/tty2
  else
    mkfs.ext4 -F ${ROOTDEV}${RDAPPEND}1 -L boot &> /dev/tty2
  fi

  progress "Setting Up ${ROOTDEV}${RDAPPEND}2 (lvm-system)..."
  mkfs.ext4 -F /dev/mapper/lvm-system -L system &> /dev/tty2
fi

UUID_BOOT=$(blkid -o value -s UUID ${ROOTDEV}${RDAPPEND}1)
UUID_CRYPT=$(blkid -o value -s UUID ${ROOTDEV}${RDAPPEND}2)

progress "Mount Partitions..."
mount /dev/mapper/lvm-system /mnt &> /dev/tty2

mkdir /mnt/boot &> /dev/tty2
mount ${ROOTDEV}${RDAPPEND}1 /mnt/boot &> /dev/tty2

if [ -z "$DISKPW" ]; then
  cp /tmp/DISKPW /mnt/boot/.key
  DUMMY_KEY="cryptkey=UUID=${UUID_BOOT}:auto:/.key"
fi

mkdir /mnt/home &> /dev/tty2
mount /dev/mapper/lvm-home /mnt/home &> /dev/tty2

progress "Install Base System..."
sed -i "s/#Color/Color/" /etc/pacman.conf &> /dev/tty2
while ! pacstrap /mnt base linux &> /dev/tty2; do
  echo "Failed: repeating" &> /dev/tty2
done

# WORKAROUND: avoid bug FS#75378 where pacstrap does not
# unmount /mnt/dev properly under some circumstances:
# https://bugs.archlinux.org/task/75378
sleep 10 && sync && umount /mnt/dev

progress "Configure Base System..."
genfstab -p /mnt > /mnt/etc/fstab

cat > /mnt/etc/locale.gen << EOF
de_DE.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOF

echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf

cat > /mnt/etc/vconsole.conf << EOF
KEYMAP="$KEYMAP"
EOF

ln -sf /usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime &> /dev/tty2
echo $HOSTNAME > /mnt/etc/hostname

sed -i "s/#Color/Color/" /mnt/etc/pacman.conf &> /dev/tty2
sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /mnt/etc/pacman.conf &> /dev/tty2

if [ "$INTEL" = "y" ]; then
  echo "options i915 enable_guc=3" >> /mnt/etc/modprobe.d/i915.conf
  echo "options i915 enable_fbc=1" >> /mnt/etc/modprobe.d/i915.conf
  echo "options i915 fastboot=1" >> /mnt/etc/modprobe.d/i915.conf
  sed -i "s/MODULES=(/MODULES=(i915 /" /mnt/etc/mkinitcpio.conf &> /dev/tty2
fi

if [ "$RADEON" = "y" ]; then
  sed -i "s/MODULES=(/MODULES=(amdgpu /" /mnt/etc/mkinitcpio.conf &> /dev/tty2
fi

if [ "$UEFI" = "y" ]; then
  sed -i "s/MODULES=(/MODULES=(vfat /" /mnt/etc/mkinitcpio.conf
fi

if [ "$NO_HIDPI" = "y" ]; then
  echo "GDK_SCALE=1" >> /mnt/etc/environment
  echo "GDK_DPI_SCALE=1" >> /mnt/etc/environment
  echo "QT_SCALE_FACTOR=1" >> /mnt/etc/environment
  echo "QT_AUTO_SCREEN_SCALE_FACTOR=0" >> /mnt/etc/environment
  echo "WINIT_X11_SCALE_FACTOR=1.0" >> /mnt/etc/environment
  echo "WINIT_HIDPI_FACTOR=1.0" >> /mnt/etc/environment
fi

if [ "${DESKTOP}" = "HEADLESS" ]; then
  # use remote encrypt unlocker
  echo "$sshcrypt_install" > /mnt/etc/initcpio/install/sshcrypt
  echo "$sshcrypt_hook" > /mnt/etc/initcpio/hooks/sshcrypt
  echo "$sshcrypt_udhcp" > /mnt/etc/initcpio/udhcpc.script
  chmod +x /mnt/etc/initcpio/udhcpc.script
  sed -i "s/block filesystems/block keymap sshcrypt lvm2 filesystems/" /mnt/etc/mkinitcpio.conf &> /dev/tty2
else
  # use default encrypt hook
  sed -i "s/block filesystems/block keymap encrypt lvm2 filesystems/" /mnt/etc/mkinitcpio.conf &> /dev/tty2
fi

ln -s /dev/null /mnt/etc/udev/rules.d/80-net-setup-link.rules &> /dev/tty2

arch-chroot /mnt /bin/bash -c "locale-gen" &> /dev/tty2

progress "Update Package List..."
arch-chroot /mnt /bin/bash -c "while ! pacman -Sy; do echo repeat...; done" &> /dev/tty2

ID=0
MAX=$(echo $PACKAGES | wc -w)
for package in $PACKAGES; do
  ID=$(expr $ID + 1)
  PERC=$(expr $ID \* 100 / $MAX)

  echo $PERC | dialog --gauge "Validate: '$package'" 7 100 0
  if arch-chroot /mnt /bin/bash -c "pacman -Sp $package" &> /dev/null; then
    export PACKAGES_VALID="$PACKAGES_VALID $package"
  else
    export PACKAGES_INVALID="$PACKAGES_INVALID $package"
  fi
done

if ! [ -z "$PACKAGES_INVALID" ]; then
  dialog --yes-label "Continue" --no-label "Abort" --clear --title "Warning" --yesno "The following packages can not be installed:\n $PACKAGES_INVALID\n\nPlease report this issue on the bugtracker: https://github.com/shagu/arch-install/issues" 0 0
  if test $? -eq 1; then exit 1; fi
fi

ID=0
MAX=$(echo $PACKAGES_VALID | wc -w)
for package in $PACKAGES_VALID; do
  ID=$(expr $ID + 1)
  PERC=$(expr $ID \* 100 / $MAX)

  echo $PERC | dialog --gauge "Install Packages: '$package'" 7 100 0
  arch-chroot /mnt /bin/bash -c "while ! pacman -S --noconfirm --needed $package; do echo repeat...; done" | while read line; do
    echo "$line" &> /dev/tty2
    if grep -q "^::" <<< $line; then
      echo $PERC | dialog --gauge "Install Packages: '$package'\n$(sed 's/^:: //g' <<< $line)" 7 100 0
    fi
  done
done

progress "Configure Desktop..."

if [ -f /mnt/etc/speech-dispatcher/speechd.conf ]; then
  # Remove sound crackle while firefox is open and launched a speech-dispatcher session.
  # Setting the output method to libao seems to be a workaround:
  # https://www.reddit.com/r/archlinux/comments/4z2td2/speechdispatcher_makes_all_audio_crackle/
  # https://bbs.archlinux.org/viewtopic.php?id=215987
  sed -i 's/# AudioOutputMethod "pulse"/AudioOutputMethod "libao"/g' /mnt/etc/speech-dispatcher/speechd.conf
fi

case $DESKTOP in
"KDE")
  mkdir -p /mnt/etc/sddm.conf.d/
  echo "[Theme]" > /mnt/etc/sddm.conf.d/theme.conf
  echo "Current=breeze" >> /mnt/etc/sddm.conf.d/theme.conf
  echo "CursorTheme=breeze_cursors" >> /mnt/etc/sddm.conf.d/theme.conf
EOF
  ;;
"DEEPIN")
  sed -i "s/#greeter-session=.*/greeter-session=lightdm-deepin-greeter/" /mnt/etc/lightdm/lightdm.conf &> /dev/tty2
  ;;
esac

if [ "$DESKTOP" = "GNOME" ]; then
  ln -s /home/$USERNAME/.config/monitors.xml /mnt/var/lib/gdm/.config/
  # When using GDM, another instance of PulseAudio is started, which "captures" your bluetooth device connection.
  # This can be prevented by masking the pulseaudio socket for the GDM user.
  mkdir -p /mnt/var/lib/gdm/.config/systemd/user
  ln -s /dev/null /mnt/var/lib/gdm/.config/systemd/user/pulseaudio.socket
  chown -R 120:120 /mnt/var/lib/gdm
fi

if [ "$FIX_YOGASLIM" = "y" ]; then
  mkdir -p /mnt/etc/modprobe.d/
  echo "install elan_i2c /bin/true" > /mnt/etc/modprobe.d/touchpad.conf
  echo "blacklist elan_i2c" >> /mnt/etc/modprobe.d/touchpad.conf
fi

if [ "$FIX_MATEBOOK" = "y" ]; then
  mkdir -p /mnt/etc/X11/xorg.conf.d/
  echo "$matebookxorg" > /mnt/etc/X11/xorg.conf.d/20-monitor.conf
fi

if echo "$PACKAGES" | grep -q " wine "; then
  # disable wine filetype associations
  sed "s/-a //g" -i /mnt/usr/share/wine/wine.inf &> /dev/tty2
fi

progress "Install Bootloader..."
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux" &> /dev/tty2

if [ "$UEFI" = "y" ]; then
  arch-chroot /mnt /bin/bash -c "bootctl --path=/boot install" &> /dev/tty2
  echo "title   Arch Linux" > /mnt/boot/loader/entries/arch.conf
  echo "linux   /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
  echo "initrd  /amd-ucode.img" >> /mnt/boot/loader/entries/arch.conf
  echo "initrd  /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
  echo "initrd  /initramfs-linux.img" >> /mnt/boot/loader/entries/arch.conf
  echo "options root=/dev/mapper/lvm-system rw cryptdevice=UUID=${UUID_CRYPT}:cryptlvm $DUMMY_KEY quiet" >> /mnt/boot/loader/entries/arch.conf
else
  sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${UUID_CRYPT}:cryptlvm $DUMMY_KEY ${CUSTOM_CMDLINE}\"|" /mnt/etc/default/grub &> /dev/tty2
  sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/" /mnt/etc/default/grub &> /dev/tty2
  sed -i "s/GRUB_GFXMODE=auto/GRUB_GFXMODE=1920x1080,auto/" /mnt/etc/default/grub &> /dev/tty2
  arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc ${ROOTDEV}" &> /dev/tty2
  arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" &> /dev/tty2
fi

progress "Create User..."
echo "${USERNAME} ALL=(ALL) ALL" >> /mnt/etc/sudoers
arch-chroot /mnt /bin/bash -c "useradd -m ${USERNAME}" &> /dev/tty2
for group in $UGROUPS; do
  arch-chroot /mnt /bin/bash -c "gpasswd -a ${USERNAME} ${group}" &> /dev/tty2
done

arch-chroot /mnt /bin/bash -c "echo \"${USERNAME}:${USERPW}\" | chpasswd" &> /dev/tty2
arch-chroot /mnt /bin/bash -c "echo \"root:${USERPW}\" | chpasswd" &> /dev/tty2

ln -s /home/${USERNAME}/.bashrc /mnt/root/.bashrc &> /dev/tty2
ln -s /home/${USERNAME}/.zshrc /mnt/root/.zshrc &> /dev/tty2
ln -s /home/${USERNAME}/.vimrc /mnt/root/.vimrc &> /dev/tty2

if [ "$DESKTOP" = "HTPC" ]; then
  # setting up HTPC user
  arch-chroot /mnt /bin/bash -c "useradd -m kodi" &> /dev/tty2
  for group in $UGROUPS; do
    arch-chroot /mnt /bin/bash -c "gpasswd -a kodi ${group}" &> /dev/tty2
  done
  arch-chroot /mnt /bin/bash -c "echo \"kodi:${USERPW}\" | chpasswd" &> /dev/tty2

  # enable auto-login after 3 seconds
  cat > /mnt/etc/gdm/custom.conf << "EOF"
[daemon]
# WaylandEnable=false
TimedLoginEnable=true
TimedLogin=kodi
TimedLoginDelay=3

[security]

[xdmcp]

[chooser]

[debug]
EOF

  # set default session to kodi
  cat > /mnt/var/lib/AccountsService/users/kodi << "EOF"
[User]
Language=
XSession=kodi
EOF

  # allow passwordless login for kodi
  echo 'auth sufficient pam_succeed_if.so user ingroup nopasswdlogin' >> /mnt/etc/pam.d/gdm-password
  arch-chroot /mnt /bin/bash -c "groupadd nopasswdlogin" &> /dev/tty2
  arch-chroot /mnt /bin/bash -c "gpasswd -a kodi nopasswdlogin" &> /dev/tty2
fi

progress "Configure Services..."
for service in $SYSTEMD; do
  arch-chroot /mnt /bin/bash -c "systemctl enable ${service}" &> /dev/tty2
done

progress "Finalize Installation..."
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
sync

dialog --title "Installtion" --msgbox "Installation completed. Press Enter to reboot into the new system." 0 0
reboot
