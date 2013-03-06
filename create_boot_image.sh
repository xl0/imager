#!/bin/bash

source ./partition_layout.sh

echo "Creating boot sector..."
mkdir -p temp

# Just a standard PC MBR.
# Jump to the boot loader in sector 1.
printf "\x80\0\0\x10" > temp/bootsector.bin
# Fill the file up to 512 bytes.
head -c $((512 - 4)) /dev/zero >> temp/bootsector.bin

# Generate the partition table. -u B - operate in 1024b blocks.
/sbin/sfdisk -q -L -f -u B temp/bootsector.bin <<EOF
${KERNEL_START},$((${DATA_START} - ${KERNEL_START})),0b
${DATA_START},$((800 * 1024)),83
EOF

echo "Creating boot image..."
mkdir -p images
dd if=/dev/zero of=images/boot.bin bs=512 count=${KERNEL_START} status=noxfer
dd seek=0  if=temp/bootsector.bin of=images/boot.bin conv=notrunc bs=512 status=noxfer
dd seek=16 if=temp/bootsector.bin of=images/boot.bin conv=notrunc bs=512 status=noxfer
dd seek=1  if=ubiboot.bin of=images/boot.bin conv=notrunc bs=512 status=noxfer
dd seek=17 if=ubiboot.bin of=images/boot.bin conv=notrunc bs=512 status=noxfer
