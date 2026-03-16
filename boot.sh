mediab="boot.img"
size="100M"



### Create empty img
truncate -s "$size" "$mediab"

cat <<-EOF | /usr/sbin/sfdisk "$mediab"
label: gpt
unit: sectors
first-lba: 34
part1: start=32768, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=boot
EOF
sync

lodev_boot="$(/usr/sbin/losetup -f)"
sudo losetup -vP "$lodev_boot" "$mediab" && sync
sudo mkfs.ext4 -L boot -vO metadata_csum_seed "${lodev_boot}p1" && sync

# Mount
sudo mkdir -p mnt/boot
sudo mount -o rw "${lodev_boot}p1" mnt/boot


lodev_rootfs="$(findmnt -nvo SOURCE mnt)"

### Download Linux Kernel from Inindev
latest='https://api.github.com/repos/inindev/linux-rockchip/releases/latest'
kurl=$(curl -s "$latest" | grep 'browser_download_url' | grep 'linux-image' | grep -v 'dbg' | grep -o 'https://[^"]*')
kfile="$(basename $kurl)"
wget "$kurl"

cp "$kfile" mnt/tmp/kernel.deb
sudo chroot mnt dpkg -i '/tmp/kernel.deb'
sudo mkdir -p 'mnt/boot/extlinux'
linux_version=$(sudo chroot mnt linux-version list | head -n 1)
echo -e "
menu title u-boot menu
prompt 0
default Linux
timeout 30

LABEL Linux
\tlinux /vmlinuz-$linux_version
\tinitrd /initrd.img-$linux_version
\tfdt /rk3576-nanopi-m5.dtb
\tappend root=UUID=$(sudo blkid -s UUID -o value -p "${lodev_rootfs}") rootwait" | sudo tee mnt/boot/extlinux/extlinux.conf


# DTB
sudo cp uboot/rk3576-nanopi-m5.dtb mnt/boot/rk3576-nanopi-m5.dtb

# Setup fstab

echo -e "
UUID=$(sudo blkid -s UUID -o value -p "${lodev_rootfs}") /     ext4 noatime 0 1
UUID=$(sudo blkid -s UUID -o value -p "${lodev_boot}p1") /boot ext4 noatime 0 1" | sudo tee mnt/etc/fstab


### Umount and install U-Boot

sudo umount mnt/boot

sudo dd if=uboot/idbloader of="${lodev_boot}" seek=64 bs=512 conv=notrunc && sync
sudo dd if=uboot/u-boot.itb of="${lodev_boot}" seek=16384 bs=512 conv=notrunc && sync

sudo losetup -d "${lodev_boot}"
# chmod 444 "$mediab"
