#!/bin/bash

ROOTFS=rootfs.squashfs

# Currently everything runs as root, but that is going to change.
USER_UID=0
USER_GID=0

if [ ! -x "`which e2cp`" ]
then
	echo "e2cp not found, please install 'e2tools'"
	exit 1
fi

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

# Copy as an "update image" to trigger the rootfs_update script on
# the first run.
e2cp -P 644 -G 0 -O 0 ${ROOTFS} images/data.bin:/update_r.bin
e2mkdir -P 755 -O ${USER_UID} -G  ${USER_GID} images/data.bin:/apps
if [ -n "${APPS}" ]
then
	e2cp -P 644 -O ${USER_UID} -G ${USER_GID} ${APPS} images/data.bin:/apps/

fi
e2mkdir -P 755 -G 0 -O 0 images/data.bin:/local/etc/init.d
e2cp -P 755 -G 0 -O 0 resize_data_part.target-sh images/data.bin:/local/etc/init.d/S00resize

