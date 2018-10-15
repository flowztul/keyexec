#!/bin/sh
set -x
set -e

. /etc/default/kexec

/sbin/kexec -l "$KERNEL_IMAGE" --initrd="$INITRD" --append="$APPEND"
