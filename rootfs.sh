media="rootfs.img"
size="2g"
deb_dist='bookworm'
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

lodev="$(/usr/sbin/losetup -f)"
sudo losetup -vP "$lodev" "$media" && sync
sudo mkfs.ext4 -L rootfs -vO metadata_csum_seed "${lodev}p1" && sync

# Mount
mkdir -p mnt
sudo mount -o rw "${lodev}p1" mnt
sudo mkdir -p mnt/sys/ && sudo mount --bind /sys/ mnt/sys/
sudo mkdir -p mnt/proc/ && sudo mount --bind /proc/ mnt/proc/
sudo mkdir -p mnt/dev/ && sudo mount --bind /dev/ mnt/dev/




### Install system
pkgs="initramfs-tools, dbus, dhcpcd, libpam-systemd, openssh-server, systemd-timesyncd, rfkill, wireless-regdb, wpasupplicant, \
bc, curl, pciutils, sudo, unzip, wget, xxd, xz-utils, zip, zstd"

#TODO: cache

sudo debootstrap --arch arm64 --include "$pkgs" --exclude "isc-dhcp-client" "$deb_dist" mnt "$deb_src"




### Config system

user="debian"
pswd="debian"
hostname="NanoPiM5"

sudo chroot mnt/ /usr/sbin/useradd -m "$user" -s '/bin/bash'
sudo chroot mnt/ /bin/sh -c "/usr/bin/echo $user:$pswd | /usr/sbin/chpasswd -c YESCRYPT"
sudo chroot mnt/ /usr/bin/passwd -e "$user"
(umask 377 && echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "mnt/etc/sudoers.d/$user")

echo $hostname | sudo tee "mnt/etc/hostname"
sudo sed -i "s/127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\n127.0.1.1\t$hostname/" "mnt/etc/hosts"

#Startup script
sudo install -Dvm 754 'rc.local' "mnt/etc/rc.local"




### Cleanup

#Regen machine-id
sudo truncate -s0 "mnt/etc/machine-id"

#Off sshd until regen key
sudo rm -fv "mnt/etc/systemd/system/sshd.service"
sudo rm -fv "mnt/etc/systemd/system/multi-user.target.wants/ssh.service"





### Boot img

./boot.sh



sudo fstrim -v mnt

sudo umount mnt/proc
sudo umount mnt/sys
sudo umount mnt/dev
sudo umount mnt
sudo losetup -d "$lodev"
# chmod 444 "$media"