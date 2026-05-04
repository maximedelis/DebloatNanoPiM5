git clone https://github.com/u-boot/u-boot.git
git clone https://github.com/rockchip-linux/rkbin.git
git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm

# trustedfirmware
# cd trusted-firmware-a
# make CROSS_COMPILE=aarch64-linux-gnu- PLAT=rk3576


export BL31=../../rkbin/bin/rk35/rk3576_bl31_v1.20.elf 
# export BL31=../../trusted-firmware-a/build/rk3576/release/bl31/bl31.elf
export ROCKCHIP_TPL=../../rkbin/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.09.bin

# make roc-pc-rk3576_defconfig
make nanopi-m5-rk3576_defconfig
