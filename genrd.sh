mkdir -p ramdiskfs/{var,tmp,sys,root,proc,opt,mnt,lib,home,etc,dev}
sudo mknod ramdiskfs/dev/console c 5 1
sudo mknod ramdiskfs/dev/null c 1 3

dd if=/dev/zero of=rootfs.raw bs=1M count=16
mkfs.ext4 -F rootfs.raw
mv rootfs.raw rootfs.ext4

mkdir -p tempfs
sudo mount -t ext4 -o loop rootfs.ext4 tempfs
sudo cp -raf ramdiskfs/* tempfs/
sudo umount tempfs/

gzip --best -c rootfs.ext4 > ramdisk.gz
mkimage -n "ramdisk" -A arm -O linux -T ramdisk -C gzip -d ramdisk.gz ramdisk.img
