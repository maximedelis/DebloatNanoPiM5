mediab="boot.img"
size="100M"



### Create empty img
truncate -s "$size" "$mediab"

cat <<-EOF | /usr/sbin/sfdisk "$mediab"
label: gpt
unit: sectors
first-lba: 2048
part1: start=32768, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=boot
EOF
sync

lodevb="$(/usr/sbin/losetup -f)"
sudo losetup -vP "$lodevb" "$mediab" && sync
sudo mkfs.ext4 -L boot -vO metadata_csum_seed "${lodevb}p1" && sync

# Mount
sudo mkdir -p mnt/boot
sudo mount -o rw "${lodevb}p1" mnt/boot




### Download Linux Kernel from Inindev
latest='https://api.github.com/repos/inindev/linux-rockchip/releases/latest'
kurl=$(curl -s "$latest" | grep 'browser_download_url' | grep 'linux-image' | grep -v 'dbg' | grep -o 'https://[^"]*')
kfile="$(basename $kurl)"
wget "$kurl"

cp "$kfile" mnt/tmp/kernel.deb
sudo chroot mnt dpkg -i '/tmp/kernel.deb'
sudo mkdir -p 'mnt/boot/extlinux'
linux_version=$(sudo chroot mnt linux-version list)
echo -e "
menu title u-boot menu
prompt 0
default Linux
timeout 30

LABEL Linux
\tlinux /boot/vmlinuz-$linux_version
\tinitrd /boot/initrd-$linux_version
\tfdt /boot/rk3576-nanopi-m5.dtb
\tappend root=$(sudo chroot mnt blkid /dev/loop0p1 | grep -oPe '\s\KUUID="[^"]*"')" | sudo tee mnt/boot/extlinux/extlinux.conf


# DTB
sudo cp rk3576-nanopi-m5.dtb mnt/boot/rk3576-nanopi-m5.dtb

# Setup fstab

echo -e "
$(sudo chroot mnt blkid /dev/loop0p1 | grep -oPe '\s\KUUID="[^"]*"' | sed "s/\"//g") /     ext4 noatime 0 1
$(sudo chroot mnt blkid /dev/loop1p1 | grep -oPe '\s\KUUID="[^"]*"' | sed "s/\"//g") /boot ext4 noatime 0 1" | sudo tee mnt/etc/fstab


### Umount and install U-Boot

sudo umount mnt/boot
sudo losetup -d "$lodevb"

sudo dd if=uboot/idbloader of=boot.img seek=64 bs=512
sudo dd if=uboot/u-boot.itb of=boot.img seek=16384 bs=512

# chmod 444 "$mediab"
