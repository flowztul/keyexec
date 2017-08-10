#!/bin/bash

# Manual reboot script

. /etc/default/kexec

APPEND=""
APPEND="${APPEND} root=$(blkid -o export "$(findmnt -o SOURCE -n -T /)" | grep "^UUID=") ro quiet panic=10"

/sbin/kexec -l "${KERNEL_IMAGE}" --initrd="${INITRD}" --append="${APPEND}"

echo -e "Now run\n    kexec -e"
