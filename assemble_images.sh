#!/bin/bash

source ./partition_layout.sh

cp images/boot.bin images/sd_image.bin
dd if=images/kernel.bin of=images/sd_image.bin bs=1024 seek=${KERNEL_START}
dd if=images/data.bin of=images/sd_image.bin bs=1024 seek=${DATA_START}
