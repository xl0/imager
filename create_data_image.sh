#!/bin/bash

ROOTFS=rootfs.squashfs

# Currently everything runs as root, but that is going to change.
USER_UID=0
USER_GID=0

source ./su_command.sh

echo "Gathering rootfs and applications..."
if test -f ${ROOTFS}
then
	SIZE=$(stat -Lc %s ${ROOTFS})
	echo "rootfs: ${ROOTFS} - $((${SIZE} / 1024)) kB"
	TOTAL_SIZE=${SIZE}
else
	echo "missing rootfs: ${ROOTFS}"
	exit 1
fi
APPS=
for app in apps/*
do
	if test -f $app
	then
		APPS="${APPS} $app"
		SIZE=$(stat -Lc %s ${app})
		TOTAL_SIZE=$((${TOTAL_SIZE} + ${SIZE}))
		echo "app: ${app} - $((${SIZE} / 1024)) kB"
	elif [ $app != "apps/*" ]
	then
		echo "skipping non-regular file: $app"
	fi
done
echo "Total data size: ${TOTAL_SIZE} bytes"
echo

# Pick a partition size that is large enough to contain all files but not much
# larger so the image stays small.
IMAGE_SIZE=$((8 + ${TOTAL_SIZE} / (960*1024)))

echo "Creating data partition of ${IMAGE_SIZE} MB..."
mkdir -p images
dd if=/dev/zero of=images/data.bin bs=1M count=${IMAGE_SIZE}
/sbin/mkfs.ext4 -m3 -O ^huge_file -F images/data.bin
echo

echo "Populating data partition..."
echo "(this step needs superuser privileges)"
mkdir mnt
${SU_CMD} "
	mount images/data.bin mnt -o loop &&
	install -m 644 -o 0 -g 0 ${ROOTFS} mnt/rootfs.bin &&
	install -m 755 -o ${USER_UID} -g ${USER_GID} -d mnt/apps/ &&
	if [ \"${APPS}\" != \"\" ]
	then
		install -m 644 -o ${USER_UID} -g ${USER_GID} -t mnt/apps/ ${APPS}
	fi &&
	install -m 755 -o 0 -g 0 -d mnt/local/etc/init.d &&
	install -m 755 -o 0 -g 0 resize_data_part.target-sh mnt/local/etc/init.d/S00resize &&
	umount mnt
	"
rmdir mnt
