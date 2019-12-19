# KGDB

## KGDBoE

**Client端(被调试的机器)操作**

下载kgdboe源码

	git clone https://github.com/sysprogs/kgdboe.git

编译成模块

	make -C /lib/modules/$(uname -r)/build M=$(pwd)

加载模块(默认使用的eth0)

	insmod kgdboe.ko

如果网卡名为enp3s0

	insmod kgdboe.ko device_name=enp3s0

**Host端(调试机器)操作**

使用gdb启动带调试信息的client的内核,指定代码路径

	gdb vmlinux -d /path/to/src/linux
	(gdb) target remote udp:<IP>:<port>
	(gdb) c

可以在client端编译内核,也可以在host端编译client的内核

如果在host端编译client的内核可以省去拷贝vmlinux和指定目录的问题
