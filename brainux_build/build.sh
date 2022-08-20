#!/bin/bash
set -o errexit
set -o nounset

### Prelimi
sudo apt install build-essential bison flex libncurses5-dev gcc-arm-linux-gnueabi gcc-arm-linux-gnueabihf libssl-dev bc lzop qemu-user-static debootstrap kpartx
sudo apt install dosfstools # Added by Haruki.

### Make sure the repositories and resources
echo ----- 1. Brainux Image / https://wiki.brainux.org/linux/linux-build/
if [ ! -d buildbrain ]
then
    git clone --recursive https://github.com/brain-hackers/buildbrain.git
fi

echo ----- 2. rtl8188eu driver / https://github.com/lwfinger/rtl8188eu
if [ ! -d rtl8188eu ]
then
    git clone 'https://github.com/lwfinger/rtl8188eu.git'
fi

### Below WIP
# echo ----- 3. cegcc mentioned in https://github.com/brain-hackers/brainlilo/tree/c826f2581ea8de6c32565be7ffa632c9766d5385#build-on-x86_64-linux
# if [ ! -e cegcc.zip ]
# then
#     wget -O cegcc.zip https://github.com/brain-hackers/cegcc-build/releases/download/2022-04-11-133546/cegcc-2022-04-11-133546.zip
#     mkdir 
#     unzip -q cegcc.zip
# fi
# # 

### TODO: automate BrainLILO download.
### on 2022/08/21, I did it manually... and copy to buildbrain/brainlilo.
### - download https://github.com/brain-hackers/brainlilo/releases
### - unzip it
### - put content in buildbrain/brainlilo and ` mv AppMain.exe BrainLILO.exe`


echo ----- Build phase.
echo ----- 1-0. Patch Brainux
if fgrep CONFIG_R8188EU=m buildbrain/linux-brain/arch/arm/configs/brain_defconfig
then
    echo Config already updated.
else
    cat >> buildbrain/linux-brain/arch/arm/configs/brain_defconfig << __EOT__

### Haruki Mod
CONFIG_R8188EU=m
__EOT__
fi

echo ----- 1. Brainux Kernel
(
    cd buildbrain

    # U-Boot (see the directory buildbrain/u-boot-brain/configs/pw*)
    make udefconfig-g4200
    make ubuild
    make nkbin-maker
    make nk.bin

    # Linux kernel
    make ldefconfig
    make lbuild
)

pwd



echo ----- 2. Build rtl8188eu driver
(
    cd rtl8188eu
    make KBUILD_MODPOST_WARN=1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- KSRC=`cd ..;pwd`/buildbrain/linux-brain/

)

echo ----- 3. Bootstrap Debian 11 - bullseye
(
    cd buildbrain
    make ldefconfig lbuild
    # aptcache?
    make aptcache &
    make brainux

    echo
    echo XXXXX WAITING XXXXX
    echo it may fail if aptcache execution was in weird state.. For me it ended up with empty ext4 root..

    make image/sd.img
)


echo ----- Show files needed from Brainux build.
ls -f buildbrain/linux-brain/arch/arm/boot/zImage \
      buildbrain/linux-brain/arch/arm/boot/dts/imx28-pwg4200.dts
      buildbrain/brainux/*
echo ----- Show files needed from RTL8188eu driver.
ls -f rtl8188eu/8188eu.ko

