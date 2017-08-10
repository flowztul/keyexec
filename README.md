# keyexec

Collection of scripts to automatically unlock LUKS devices on kexec reboot.

## Compatibility

Scripts were tested on Ubuntu 16.04 LTS (Xenial Xerus).

## Usage

1. Install kexec-tools
1. Copy the files from `etc` to the corresponding directories in the root filesystem
1. Run `update-initramfs -u -k all`
1. Reboot

## How does this work?

### Preparation
Recent versions of Ubuntu support rebooting through kexec. This is implemented through two scripts in `/etc/init.d`:

* `/etc/init.d/kexec-load` takes care of loading a kernel and initramfs with `kexec -l`
* `/etc/init.d/kexec` executes `kexec -e` to reboot

Both scripts source `/etc/default/kexec`. That script was adapted to also source `/etc/default/kexec-cryptroot`, if it exists. That script:

* Creates a new temporary directory in /dev/shm
* Sets up a trap handler to wipe that directory on exit
* Copies the existing initramfs image to that directory
* Iterates over a list of all block devices of type `crypto_LUKS` (i.e. the LUKS backing devices) and for each
  * Obtains the UUID
  * Finds the corresponding unlocked LUKS device
  * Obtains the LUKS master key using `dmsetup --showkeys table`
  * Writes that key to a file `etc/${UUID}.key` in the temporary directory
* Appends the key files to the initramfs image
* Points `$CRYPTROOT_INITRD` to the temporary initramfs image
* If `$APPEND` is unset, sets `$CRYPTROOT_APPEND` to the current kernel command line and appends `panic=10`. The latter forces the initramfs to reboot on error, instead of spawning an emergency shell.

`$CRYPTROOT_INITRD` and `$CRYPTROOT_APPEND` are then used to overwrite `$INITRD` and `$APPEND` in `/etc/default/kexec`. This will cause `/etc/init.d/kexec-load` to invoke kexec to load the default kernel with the temporary initramfs and the new kernel command line:

```sh
/sbin/kexec -l "$KERNEL_IMAGE" --initrd="$INITRD" --append="$REAL_APPEND"
```
When `kexec-load` exits, the temporary initramfs image has been loaded to memory and the trap handler wipes the keys and initramfs from the temporary directory.

### Unlocking

The default `cryptroot` script from the initramfs-tools package was slightly adapted to use the key files in `/etc` to unlock matching devices with `cryptsetup luksOpen --master-key-file=/etc/${UUID}.key`. Keys are wiped after use to minimize exposure.

## Security Considerations

The scripts try to minimize exposure of key material, e.g. by setting a restrictive umask before creating any directories or files, only storing them in RAM (/dev/shm should hopefully be a tmpfs) and removing keys from filesystems when they are no longer needed. Adding `panic=10` to the kernel command line *should* prevent the initramfs from dropping to an emergency shell, where the keys could still be accessible in the initramfs /etc directory.

## Copyright and License

Copyright 2017, Lutz Wolf <flow@0x0badc0.de>

Licensed under GPLv2 or later.

The cryptroot script is an adaptation of the script from the Debian/Ubuntu cryptsetup package, which is licensed GPL v2 or later. Copyright and licensing information can be found in that package, or at:

https://anonscm.debian.org/cgit/pkg-cryptsetup/cryptsetup.git
