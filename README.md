# arch-install
A simple (re)installer script, focused to make encrypted archlinux installations as easy and fast as possible.

## Preview
![preview](https://media.giphy.com/media/vvm3RXS2aLyZRHp73s/giphy.gif)

## Features
* Supports several desktops
* Uses LUKS Encryption
* Uses LVM Volumes
* Compatible to UEFI and BIOS
* Can reuse previous installation (keep /home untouched)
* Remote crypt unlock via ssh on headless machines

## Create Arch-Install ISO
### Build
First make sure to have `archiso` installed and run the `Makefile`:

    pacman -S archiso
    make

### Usage
1. Write the iso to an empty USB stick
2. Boot the USB stick
3. Type `arch-install`

## Optional: Use Archlinux ISO
### Usage
1. Download the lastest archlinux live iso
2. Write the iso to an empty USB stick
3. Boot the USB stick
4. Connect your network
5. Download the installer: `wget https://gitlab.com/shagu/arch-install/raw/master/arch-install.sh`
6. Run the installer: `./arch-install.sh`
