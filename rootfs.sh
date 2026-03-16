#!/bin/bash
set -Eeuo pipefail
set -x

media="rootfs.img"
size="2g"
deb_dist='trixie'
deb_src="http://ftp.fr.debian.org/debian/"




### Create empty img
truncate -s "$size" "$media"

cat <<-EOF | /usr/sbin/sfdisk "$media"
label: gpt
unit: sectors
first-lba: 2048
part1: start=32768, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=rootfs
EOF
sync

lodev_rootfs="$(/usr/sbin/losetup -f)"
sudo losetup -vP "$lodev_rootfs" "$media" && sync
sudo mkfs.ext4 -L rootfs -vO metadata_csum_seed "${lodev_rootfs}p1" && sync

# Mount
mkdir -p mnt
sudo mount -o rw "${lodev_rootfs}p1" mnt
sudo mkdir -p mnt/sys/ && sudo mount --bind /sys/ mnt/sys/
sudo mkdir -p mnt/proc/ && sudo mount --bind /proc/ mnt/proc/
sudo mkdir -p mnt/dev/ && sudo mount --bind /dev/ mnt/dev/




### Install system
pkgs="initramfs-tools, dbus, dhcpcd, libpam-systemd, openssh-server, systemd-timesyncd, rfkill, wireless-regdb, wpasupplicant, \
bc, curl, pciutils, sudo, unzip, wget, xxd, xz-utils, zip, zstd, linux-base, network-manager"

#TODO: cache

sudo debootstrap --arch arm64 --include "$pkgs" --exclude "isc-dhcp-client" "$deb_dist" mnt "$deb_src"

if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
    sudo cp /usr/bin/qemu-aarch64-static mnt/usr/bin
fi
echo "deb http://deb.debian.org/debian ${deb_dist} main contrib non-free-firmware" | sudo tee mnt/etc/apt/sources.list >/dev/null
sudo chroot mnt apt update
sudo chroot mnt apt install -y firmware-realtek



### Config system

user="debian"
pswd="debian"
hostname="NanoPiM5"

sudo chroot mnt/ useradd -m "$user" -s '/bin/bash'
sudo chroot mnt/ sh -c "/usr/bin/echo $user:$pswd | /usr/sbin/chpasswd -c YESCRYPT"
sudo chroot mnt/ passwd -e "$user"
(umask 377 && echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "mnt/etc/sudoers.d/$user")

echo $hostname | sudo tee "mnt/etc/hostname"
sudo sed -i "s/127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\n127.0.1.1\t$hostname/" "mnt/etc/hosts"

#Startup script
sudo install -Dvm 754 'rc.local' "mnt/etc/rc.local"



### Boot img

./boot.sh


### Cleanup

#Regen machine-id
sudo truncate -s0 "mnt/etc/machine-id"

#Off sshd until regen key
sudo rm -fv "mnt/etc/systemd/system/sshd.service"
sudo rm -fv "mnt/etc/systemd/system/multi-user.target.wants/ssh.service"

# Remove cross-plat binary
if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
    sudo rm mnt/usr/bin/qemu-aarch64-static
fi


sudo fstrim -v mnt

sudo umount mnt/proc
sudo umount mnt/sys
sudo umount mnt/dev
sudo umount mnt
sudo losetup -d "$lodev_rootfs"
# chmod 444 "$media"