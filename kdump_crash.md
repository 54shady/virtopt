# Ubuntu 16.04(xenial) Kdump Crash使用

[参考kernel-crash-dump](https://help.ubuntu.com/lts/serverguide/kernel-crash-dump.html)

## 内核源码准备

	apt-get install linux-source-4.15.0
	tar jxvf linux-source-4.15.0.tar.bz2 -C /usr/src/
	cd /usr/src/linux-source-4.15.0

## 使用提供的配置文件编译内核代码(CONFIG_DEBUG_INFO)

	make ubuntu_xenial_defconfig
	make -j4
	make install
	make modules_install

## 安装和配置kdump和crash

安装必要工具(有弹框配置yes)

	apt-get install linux-crashdump kexec-tool

确认是否配置kdump成功(/etc/default/kdump-tools)

	USE_KDUMP=1

查看kdump状态确认是否(read to kdump)

	kdump-config show
	DUMP_MODE:        kdump
	USE_KDUMP:        1
	KDUMP_SYSCTL:     kernel.panic_on_oops=1
	KDUMP_COREDIR:    /var/crash
	crashkernel addr: 0x2e000000
	   /var/lib/kdump/vmlinuz: symbolic link to /boot/vmlinuz-4.15.18
	kdump initrd:
	   /var/lib/kdump/initrd.img: symbolic link to /var/lib/kdump/initrd.img-4.15.18
	current state:    ready to kdump

	kexec command:
	  /sbin/kexec -p --command-line="BOOT_IMAGE=/boot/vmlinuz-4.15.18 root=UUID=93175768-5bee-47b8-8841-383fe2cd2c6e ro quiet splash vt.handoff=7 nr_cpus=1 systemd.unit=kdump-tools.service irqpoll nousb ata_piix.prefer_ms_hyperv=0" --initrd=/var/lib/kdump/initrd.img /var/lib/kdump/vmlinuz

查看/proc/cmdline是否配置成功

	BOOT_IMAGE=/boot/vmlinuz-4.15.18 root=UUID=93175768-5bee-47b8-8841-383fe2cd2c6e ro quiet splash crashkernel=384M-:128M crashkernel=384M-:128M vt.handoff=7

crashkernel参数解释

crashkernel=384M-2G:64M,2G-:128M

- if the RAM is smaller than 384M, then don't reserve anything (this is the "rescue" case)
- if the RAM size is between 386M and 2G (exclusive), then reserve 64M
- if the RAM size is larger than 2G, then reserve 128M

crashkernel=384-:128表示当可用内存大于384才会触发dump,否则会因内存不足而不触发

可以在内核日志中查看到结果

	dmesg | grep -i crash

	...
	[    0.000000] Reserving 64MB of memory at 800MB for crashkernel (System RAM: 1023MB)


查看sysrq状态

	cat /proc/sys/kernel/sysrq

查看sysrq对应值的含义

	cat /etc/sysctl.d/10-magic-sysrq.conf

设置sysrq全功能

	echo 1 > /proc/sys/kernel/sysrq

执行下面命令验证测试环境是否安装好

	echo c > /proc/sysrq-trigger

执行后可以看到系统首先会挂住,然后重启,进入系统后发现转存文件已经生成并保存在/var/crash目录下了即成功

使用crash调试(crash <带调试信息的内核> <dump file>)

	crash /usr/src/linux-source-4.15.0/vmlinux /var/crash/201912172043/dump.201912172043

如果触发不了很可能是由于内存大小不够导致,调整内存大小即可(/etc/default/grub.d/kdump-tools.cfg)

	GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT crashkernel=384M-:512M"

## FAQ

crash本身软件版本问题(7.2.3, 更换7.2.7后问题解决)

	crash: invalid size request: -2812443080  type: "module gpl symbol strings" Segmentation fault
