## 交叉编译busybox-1.31.1[配置文件defconfig](kunpeng920_defconfig)

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

内核需要开启支持的选项

	CONFIG_EXT4_FS
	CONFIG_BLK_DEV_RAM

编译内核(v5.7)

	mv arm64-ramdisk_defconfig arch/arm64/configs/
	make arm64-ramdisk_defconfig

启动虚拟机

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/ram0 rw rootfstype=ext4 console=ttyAMA0 init=/linuxrc ignore_loglevel" -initrd ramdisk.img
