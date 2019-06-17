all: clean default ssh

clean:
	rm -rf archlinux-*.iso archiso

default:
	cp -r /usr/share/archiso/configs/releng/ archiso
	mkdir -p archiso/airootfs/usr/bin archiso/out
	cp arch-install.sh archiso/airootfs/usr/bin/arch-install
	echo 'if [ "$(tty)" = "/dev/tty1" ]; then arch-install; fi' >> archiso/airootfs/root/.zlogin
	cd archiso && ./build.sh -v -N arch-install
	mv archiso/out/*.iso .

ssh:
	cp -r /usr/share/archiso/configs/releng/ archiso
	echo "sed -i 's/#\(PermitEmptyPasswords \).\+/\1yes/' /etc/ssh/sshd_config" >> archiso/airootfs/root/customize_airootfs.sh
	echo "systemctl enable sshd" >> archiso/airootfs/root/customize_airootfs.sh
	mkdir -p archiso/airootfs/usr/bin archiso/out
	cp arch-install.sh archiso/airootfs/usr/bin/arch-install
	echo 'if [ "$(tty)" = "/dev/tty1" ]; then arch-install; fi' >> archiso/airootfs/root/.zlogin
	cd archiso && ./build.sh -v -N arch-install-ssh
	mv archiso/out/*.iso .
