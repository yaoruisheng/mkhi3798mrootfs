#!/bin/bash
if [ ! -f /etc/first_init ]; then
	rootfs_partition=/dev/$(lsblk -l|grep /|awk '{print $1}')
	logger -t "resize-disk[$$]" "resizing $rootfs_partition"
    if [ "$(echo $rootfs_partition | grep "mmc")" = "" ];then
        rootfs_disk=$(echo "$rootfs_partition" |sed -E -e 's/^(.*)[0-9]+/\1/g')
    else
        rootfs_disk=$(echo "$rootfs_partition" |sed -E -e 's/^(.*)p[0-9]+/\1/g')
    fi

    if [ "$rootfs_disk" = "mmcblk0" ]; then
        resize2fs $rootfs_partition 2>&1 > /dev/null
    else
        rootfs_partition_num=$(echo "$rootfs_partition" |sed -E -e 's/^.*([0-9]+)/\1/g')
        startfrom=$(fdisk -l ${rootfs_disk} -o device,start|grep ${rootfs_partition}|awk '{print $2}')
        #lastsector=$(fdisk -l ${rootfs_disk} -o device,end|grep ${rootfs_partition}|awk '{print $2}')
        (echo d; echo $rootfs_partition_num; echo n; echo p; echo $rootfs_partition_num; echo $startfrom; echo ; echo p; echo w;) | fdisk $rootfs_disk
        sync
        resize2fs $rootfs_partition
    fi
    logger -t "resize-disk[$$]" "resized $rootfs_partition"
fi
exit 0