# arch-install
A simple (re)installer script, focused to make encrypted archlinux installations as easy and fast as possible. The main goal of arch-install is to provide a solution to easilly install and re-install archlinux on a full disk encryption. The entire install procedure is based on `dialog`.

## Features
* Supports several desktops
* Uses LUKS Encryption
* Uses LVM Volumes
* Compatible to UEFI and BIOS
* Can reuse previous installation (keep /home untouched)
* Remote crypt unlock via ssh on headless machines
* Optional pseudo-crypt (empty disk password)
