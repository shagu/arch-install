# arch-install

A simple install script, focused to make an encrypted archlinux installation as easy and fast as possible. This is my personal setup of packages and settigs, feel free to fork and adjust it to your needs. If you have any issues or feedback, please don't hesitate to create an issue.

## Preview

![preview](https://media.giphy.com/media/vvm3RXS2aLyZRHp73s/giphy.gif)

## Usage

Grab the latest Arch install iso, burn it to cdrom or usbstick and boot it. After that, your install procedure could look like the following:

    wifi-menu
    wget https://gitlab.com/shagu/arch-install/raw/master/arch-install.sh
    bash arch-install.sh

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
