#!/bin/bash

source ./partition_layout.sh

if [ ! -x "`which mcopy`" ]
then
	echo "mcopy not found. Please install 'mtools'"
	exit 1
fi


echo "Checking presence of kernel files..."
if test -f vmlinuz.bin
then
	SIZE=$(stat -Lc %s vmlinuz.bin)
	echo "vmlinuz.bin: $((${SIZE} / 1024)) kB"
else
	echo "missing kernel: vmlinuz.bin"
	exit 1
fi

echo "Creating kernel partition..."
echo "(please ignore the warning about not having enough clusters for FAT32)"
IMAGE_SIZE=$((${DATA_START} - ${KERNEL_START}))
mkdir -p images
dd if=/dev/zero of=images/kernel.bin bs=1024 count=${IMAGE_SIZE} status=noxfer
/sbin/mkdosfs -F 32 images/kernel.bin
echo

mcopy -i images/kernel.bin vmlinuz.bin ::vmlinuz.bin

