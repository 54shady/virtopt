# 使用volatility分析操作系统内存

[volatility使用方法](https://github.com/volatilityfoundation/volatility/wiki/Volatility-Usage)

## 获取系统内存的dump文件(vmcore)

使用GDB获取虚拟机内存

	(gdb) source /qemu_src/scripts/dump-guest-memory.py
	(gdb) dump-guest-memory /path/to/store/vmcore X86_64

使用virsh命令获取虚拟机内存

	virsh qemu-monitor-command <domain> --hmp dump-guest-memory /path/to/vmcore

## 安装volatility工具

使用volatility工具分析(python2)

	git clone https://github.com/volatilityfoundation/volatility

安装distrom

	git clone https://github.com/gdabah/distorm
	python setup.py install

## 使用volatility分析windows内存情况

打印所有进程情况

	python vol.py --profile=Win7SP1x64 -f vmcore pslist --tz=Asia/Shanghai

保存屏幕截图

	python vol.py --profile=Win7SP1x64 -f vmcore screenshot --dump-dir /path/to/somewhere

将内存信息保存为windows可以识别的格式用windbg调试(需要以.dmp结尾才可被windbg识别到)

	python vol.py --profile=Win7SP1x64 --plugins=raw2dmp -f vmcore raw2dmp --output-image=vmcore.dmp

## 使用volatility分析linux系统内存

安装相应的工具dwarfdump

	apt-get install -y --allow-unauthenticated dwarfdump

制作ubuntu(1604)的profile(内核版本4.13.0-36-generic)

先制作module.dwarf文件

	cd /path/to/volatility/tools/linux
	make

将dwarf和System.map打包成相应的zip文件(Ubuntu.zip)

	zip Ubuntu.zip module.dwarf /boot/System.map-4.13.0-36-generic

将zip文件放到相应目录下(文件名必须为Ubuntu.zip)

	mv Ubuntu.zip volatility/plugins/overlays/linux/

查看生成的profile名字(LinuxUbuntux64)

	python vol.py --info

执行相应命令

	python vol.py --profile=LinuxUbuntux64 -f vmcore-ubuntu1604 linux_pslist
	python vol.py --profile=LinuxUbuntux64 -f vmcore-ubuntu1604 linux_dmesg
	python vol.py --profile=LinuxUbuntux64 -f vmcore-ubuntu1604 linux_elfs
