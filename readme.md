# Usefull commands

dd if=DebloatNanoPiM5/uboot/idbloader of=/dev/rdisk5 seek=64 bs=512 conv=notrunc && sync
dd if=DebloatNanoPiM5/uboot/u-boot.itb of=/dev/rdisk5 seek=16384 bs=512 conv=notrunc && sync

sudo mount -o loop,offset=16777216 ../sd_first_500M.img mnt-sd
sudo mount -o loop,offset=16777216 boot.img mnt/

sudo mount -o loop,offset=16777216 rootfs.img mnt/
sudo mkdir -p mnt/sys/ && sudo mount --bind /sys/ mnt/sys/
sudo mkdir -p mnt/proc/ && sudo mount --bind /proc/ mnt/proc/
sudo mkdir -p mnt/dev/ && sudo mount --bind /dev/ mnt/dev/
sudo mount -o loop,offset=16777216 boot.img mnt/boot/

sudo mount -o loop,offset=1048576 ../rootfs.img mnt-sd

sudo mount -o loop,offset=209715200 ../boot.bak.img mnt-sd


im trying to use a nano-m5 with the last Debian.
Im trying to use a modern version of uboot and a modern version of the kernel.
Do do that I use the inindev version (uboot: https://github.com/inindev/uboot-rockchip/tree/main) (and the kernel is from inindev also).

The main issue I have is that the wifi is not working. the wifi chip is from an m2 port.
I don't know where the issue come from (uboot ? dtb file ? kernel ?).
help me find out 