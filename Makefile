all: default ssh

default:
	rm -rf archiso
	cp -r /usr/share/archiso/configs/releng/ archiso
	mkdir -p archiso/airootfs/usr/bin archiso/out
	cp arch-install.sh archiso/airootfs/usr/bin/arch-install
	echo 'if [ "$$(tty)" = "/dev/tty1" ]; then arch-install; fi' >> archiso/airootfs/root/.zlogin
	echo 'netctl' >> archiso/packages.x86_64
	echo 'dialog' >> archiso/packages.x86_64
	mkarchiso -v -w /tmp/archiso-work archiso -L "ARINST" -A "arch-install"
	mv out/*.iso ./arch-install.iso

ssh:
	rm -rf archiso
	cp -r /usr/share/archiso/configs/releng/ archiso
	echo "sed -i 's/#\(PermitEmptyPasswords \).\+/\1yes/' /etc/ssh/sshd_config" >> archiso/airootfs/root/customize_airootfs.sh
	echo "systemctl enable sshd" >> archiso/airootfs/root/customize_airootfs.sh
	mkdir -p archiso/airootfs/usr/bin archiso/out
	cp arch-install.sh archiso/airootfs/usr/bin/arch-install
	echo 'if [ "$$(tty)" = "/dev/tty1" ]; then arch-install; fi' >> archiso/airootfs/root/.zlogin
	echo 'netctl' >> archiso/packages.x86_64
	echo 'dialog' >> archiso/packages.x86_64
	mkarchiso -v -w /tmp/archiso-work-ssh archiso -L "ARINSTSSH" -A "arch-install-ssh"
	mv out/*.iso ./arch-install-ssh.iso
