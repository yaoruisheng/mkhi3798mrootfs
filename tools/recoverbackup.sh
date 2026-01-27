#!/bin/bash
set -e
if [ "$1" != "-y" ]; then
    read -r -p "This operation will restore the backup system. Continue? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS]) ;;
        *) exit 0 ;;
    esac
fi

platform=$(uname -m)
arch=""

case "$platform" in
    aarch64|arm64)
        arch=64 ;;
    *)
        arch=32 ;;
esac
cat > /tmp/bootargs_input.txt <<"eof"
baudrate=115200
ethaddr=00:11:22:33:44:55
ipaddr=192.168.1.10
netmask=255.255.255.0
gatewayip=192.168.1.1
serverip=192.168.1.1
bootcmd=mmc read 0 0x1FFFFC0 0x7000 0x14000;bootm 0x1FFFFC0
bootargs_512M=mem=512M mmz=ddr,0,0,256M vmalloc=500M
bootargs_1G=mem=1G mmz=ddr,0,0,256M vmalloc=500M
bootargs_2G=mem=2G mmz=ddr,0,0,256M vmalloc=500M
bootargs_768M=mem=768M mmz=ddr,0,0,256M vmalloc=500M
bootargs_1536M=mem=1536M mmz=ddr,0,0,256M vmalloc=500M
bootargs_3840M=mem=3840M mmz=ddr,0,0,256M vmalloc=500M
bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p7 rootfstype=ext4 rootwait blkdevparts=mmcblk0:1M(boot),1M(bootargs),4M(baseparam),4M(pqparam),4M(logo),40M(kernel),64M(busybox),512M(backup),-(ubuntu)
bootdelay=0
stdin=serial
stdout=serial
stderr=serial
eof
mkbootargs -s ${arch} -r /tmp/bootargs_input.txt -o /tmp/bootargs.bin
[ -b /dev/mmcblk0p2 ] || {
  echo "ERROR: /dev/mmcblk0p2 not found"
  exit 1
}
[ -s /tmp/bootargs.bin ] || {
    echo "ERROR: bootargs.bin is empty"
    exit 1
}
dd if=/tmp/bootargs.bin of=/dev/mmcblk0p2 bs=1024 count=1024
sync
reboot