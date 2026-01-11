#!/bin/bash
set -e

FIRST_INIT=/root/first_init

if [ ! -f "$FIRST_INIT" ]; then
    # 获取根分区
    rootfs_partition=$(findmnt -n -o SOURCE /)

    # 分离磁盘和分区号
    if [[ "$rootfs_partition" =~ mmcblk[0-9]+p[0-9]+ ]]; then
        rootfs_disk="${rootfs_partition%%p*}"
        rootfs_partition_num="${rootfs_partition##*p}"
    else
        rootfs_disk="${rootfs_partition%%[0-9]*}"
        rootfs_partition_num="${rootfs_partition##*[!0-9]}"
    fi

    # 仅当磁盘有分区表时，才尝试扩展分区
    if sfdisk -d "$rootfs_disk" >/dev/null 2>&1; then
        if [ -x /root/growpart ]; then
            /root/growpart "$rootfs_disk" "$rootfs_partition_num" || true
        fi
    fi

    # 扩展文件系统
    if [ -x /root/resize2fs ]; then
        /root/resize2fs "$rootfs_partition"
    fi

    # 标记首次初始化完成
    touch "$FIRST_INIT"
fi

exit 0
