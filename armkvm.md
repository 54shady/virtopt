# ARM-KVM

## 用到的配置文件

[用到的内核v5.7配置文件](arm64_defconfig)

用到如下内核配置

	CONFIG_VIRTIO_NET
	CONFIG_VIRTIO_BLK
	CONFIG_EXT4_FS
	CONFIG_BLK_DEV_RAM

交叉编译

	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- arm64_defconfig
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4

[用到的busybox-1.31.1配置文件](kunpeng920_defconfig)

## 制作ramdisk(使用busybox-1.31.1)

交叉编译busybox

	mv kunpeng920_defconfig config/
	make kunpeng920_defconfig
	make install -j4

构建文件系统目录[添加etc下所有配置文件](etc)

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

编译内核

	mv arm64_defconfig arch/arm64/configs/
	make arm64_defconfig

## 使用ramdisk启动虚拟机

使用下面命令启动虚拟机

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/ram0 rw rootfstype=ext4 console=ttyAMA0 init=/linuxrc ignore_loglevel" -initrd ramdisk.img

## 使用linux发行版本启动虚拟机

[参考kernel_drivers_examples中rk3399制作系统镜像](https://github.com/54shady/kernel_drivers_examples/tree/Firefly_RK3399)

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

配置网络(host配置br0,虚拟机桥接到该网桥上)

添加配置文件(/etc/qemu-ifup)并添加执行权限

	#!/bin/bash

	ifconfig $1 0.0.0.0 promisc up
	brctl addif br0 $1

启动虚拟机添加(-nic tap)

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/vda rootfstype=ext4 rw" -drive file=./rootfs.ext4,if=none,id=drive-virtio-disk0,cache=writeback -device virtio-blk-pci,scsi=off,drive=drive-virtio-disk0,id=virtio-disk0,write-cache=on -nic tap

或者是用(-netdev tap,id=dev0 -device virtio-net-pci,netdev=dev0)

	qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 2 -m 4096 -kernel Image -nographic -append "root=/dev/vda rootfstype=ext4 rw" -drive file=./rootfs.ext4,if=none,id=drive-virtio-disk0,cache=writeback -device virtio-blk-pci,scsi=off,drive=drive-virtio-disk0,id=virtio-disk0,write-cache=on -netdev tap,id=dev0 -device virtio-net-pci,netdev=dev0

### 网络配置(for gentoo)

gentoo openrc网络配置(/etc/conf.d/net)

	config_eth0="172.28.107.222 netmask 255.255.252.0"
	routes_eth0="default via 172.28.106.1"
	dns_servers_eth0="192.168.5.28"

开机网卡配置

	cd /etc/init.d
	ln -s net.lo net.eth0
	rc-update add net.eth0 default

## KunPen920

### 网卡中断亲和性

查看网卡所在的NUMA节点(enp125s0f0,1,2,3, 结果都是在node 0)

	for i in `seq 0 3`; do cat /sys/class/net/enp125s0f$i/device/numa_node; done

网卡中断绑定,先关闭irqbalance

	service irqbalance status
	service irqbalance stop

查看网卡对应的中断号(假设用的是enp125s0f0, 第一列就是中断号,281)

	cat /proc/interrupts | grep enp125s0f0

	281:  ....       ITS-MSI 65536001 Edge      enp125s0f0-TxRx-0

查看当前网卡中断绑核情况

	cat /proc/irq/281/smp_affinity_list

手动绑定网卡的中断到CPU4(建议将中断绑定到物理网卡所在node的cpu上)

	echo 4 > /proc/irq/281/smp_affinity_list
