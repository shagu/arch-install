# arch-install

A simple install script, focused to make an encrypted archlinux installation as easy and fast as possible. This is my personal setup of packages and settigs, feel free to fork and adjust it to your needs. If you have any issues or feedback, please don't hesitate to create an issue.

## Preview

![preview](https://media.giphy.com/media/vvm3RXS2aLyZRHp73s/giphy.gif)

## Usage

Grab the latest Arch install iso, burn it to cdrom or usbstick and boot it. After that, your install procedure could look like the following:

    wifi-menu
    wget https://gitlab.com/shagu/arch-install/raw/master/arch-install.sh
    bash arch-install.sh

## Build ISO

### Dependencies
First make sure to have `archiso` installed. In order to modify it, copy it somewhere:

    pacman -S archiso
    cp -r /usr/share/archiso/configs/releng/ archiso

### Headless
If you wish to allow a headless installations, you can enable ssh by default and let root login with empty password (Don't do that in untrusted networks):

    echo "sed -i 's/#\(PermitEmptyPasswords \).\+/\1yes/' /etc/ssh/sshd_config" >> archiso/airootfs/root/customize_airootfs.sh
    echo "systemctl enable sshd" >> archiso/airootfs/root/customize_airootfs.sh

### Build
Copy the arch-installer into the new rootfs and create the ISO:

    mkdir -p archiso/airootfs/usr/bin
    cp arch-install.sh archiso/airootfs/usr/bin/arch-install

    cd archiso
    mkdir out
    ./build.sh -v

## Features

The core features are the following:

* Fast!
* Several Desktops
* LUKS Encryption
* LVM Volumes
* UEFI and BIOS
* Reuse Previous Installation (keep /home untouched)

## Supported Desktops

* MATE
* KDE
* GNOME
* CINNAMON
* XFCE
* DEEPIN

## Hardware Tweaks

Some of my hardware requires custom tweaks to work properly, so I've added them to the installer, but usually you might not want to enable them with your hardware.

* NVIDIA Optimus (install `bumbleebee`)
* Razer Blade 2017 (`pci=noaer`)
* GPD Win (`fbcon=rotate:1 dmi_product_name=GPD-WINI55`)
