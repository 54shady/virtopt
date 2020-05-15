# ARM-KVM

## 用到的配置文件

[用到的内核v5.7配置文件](arm64_defconfig)

[用到的busybox-1.31.1配置文件](kunpeng920_defconfig)

## 制作ramdisk(使用busybox-1.31.1)

编译busybox

	mv kunpeng920_defconfig config/
	make kunpeng920_defconfig
	make install -j4

构建文件系统目录[etc下所有配置文件](etc)

	mkdir -p ramdiskfs/{var,tmp,sys,root,proc,opt,mnt,lib,home,etc,dev}
	sudo mknod ramdiskfs/dev/console c 5 1
	sudo mknod ramdiskfs/dev/null c 1 3

制作ext4的ramdisk数据盘

	dd if=/dev/zero of=ramdisk bs=1M count=16
	mkfs.ext4 -F ramdisk

将编译好的busybox安装到ramdisk中

	mkdir -p tempfs
	sudo mount -t ext4 -o loop ramdisk tempfs
	sudo cp -raf ramdiskfs/* tempfs/
	sudo umount tempfs/

打包ramdisk成映像文件

	gzip --best -c ramdisk > ramdisk.gz
	mkimage -n "ramdisk" -A arm -O linux -T ramdisk -C gzip -d ramdisk.gz ramdisk.img

## 内核配置和编译

内核需要开启支持的选项

	CONFIG_EXT4_FS
	CONFIG_BLK_DEV_RAM

编译内核

	mv arm64_defconfig arch/arm64/configs/
	make arm64_defconfig

## 启动虚拟机

使用下面命令启动虚拟机

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/ram0 rw rootfstype=ext4 console=ttyAMA0 init=/linuxrc ignore_loglevel" -initrd ramdisk.img

## 使用linux发行版本启动虚拟机

[参考kernel_drivers_examples中rk3399制作系统镜像](https://github.com/54shady/kernel_drivers_examples/tree/Firefly_RK3399)

内核配置添加如下

	VIRTIO_BLK

制作linux根文件系统(arm64-distro可以是任意系统的base)

	tar xvf arm64-distro.tar.gz -C target/
	dd if=/dev/zero of=rootfs.raw bs=1M count=1024
	mkfs.ext4 -F rootfs.raw
	mv rootfs.raw rootfs.ext4
	mkdir tempfs
	sudo mount -t ext4 -o loop rootfs.ext4 tempfs
	sudo cp -raf target/* tempfs/
	sudo umount tempfs/

启动linux虚拟机

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/vda rootfstype=ext4 rw" -drive file=./rootfs.ext4,if=none,id=drive-virtio-disk0,cache=writeback -device virtio-blk-pci,scsi=off,drive=drive-virtio-disk0,id=virtio-disk0,write-cache=on
