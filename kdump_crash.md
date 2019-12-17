# Ubuntu 16.04(xenial) Kdump Crash使用

## 内核源码准备

	apt-get source linux-image-$(uname -r)
	tar xvf linux-hwe_4.15.0.orig.tar.gz -C /usr/src/
	cd /usr/src/linux-4.15/

## 编译内核代码(不带调试信息)

	make menuconfig
	make -j4
	make install
	make modules_install

## 再编译一个带调试信息的内核(CONFIG_DEBUG_INFO)

	make menuconfig
	make -j4

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
	   /var/lib/kdump/vmlinuz: symbolic link to /boot/vmlinuz-4.15.0
	kdump initrd:
	   /var/lib/kdump/initrd.img: symbolic link to /var/lib/kdump/initrd.img-4.15.0
	current state:    ready to kdump

	kexec command:
	  /sbin/kexec -p --command-line="BOOT_IMAGE=/boot/vmlinuz-4.15.0 root=UUID=93175768-5bee-47b8-8841-383fe2cd2c6e ro quiet splash vt.handoff=7 nr_cpus=1 systemd.unit=kdump-tools.service irqpoll nousb ata_piix.prefer_ms_hyperv=0" --initrd=/var/lib/kdump/initrd.img /var/lib/kdump/vmlinuz

查看/proc/cmdline是否配置成功

	BOOT_IMAGE=/boot/vmlinuz-4.15.0 root=UUID=93175768-5bee-47b8-8841-383fe2cd2c6e ro quiet splash crashkernel=384M-:128M crashkernel=384M-:128M vt.handoff=7

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

	crash /usr/src/linux-4.15/vmlinux /var/crash/201912171903/dump.201912171903
