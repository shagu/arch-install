FROM archlinux:latest

RUN mkdir /run/shm && \
  mknod /dev/loop0 -m0660 b 7 0 && \
  mknod /dev/loop1 -m0660 b 7 1 && \
  mknod /dev/loop2 -m0660 b 7 2 && \
  mknod /dev/loop3 -m0660 b 7 3 && \
  mknod /dev/loop4 -m0660 b 7 4 && \
  mknod /dev/loop5 -m0660 b 7 5 && \
  mknod /dev/loop6 -m0660 b 7 6 && \
  mknod /dev/loop7 -m0660 b 7 7 && \
  mknod /dev/loop8 -m0660 b 7 8 && \
  mknod /dev/loop9 -m0660 b 7 9 && \
  pacman --noconfirm -Syu && \
  pacman --noconfirm -S base base-devel && \
  pacman --noconfirm -S archiso

WORKDIR /root

ADD Makefile .
ADD arch-install.sh .

CMD make
