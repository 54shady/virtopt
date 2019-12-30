# BPF

## Install

安装必要软件(xenial)

	apt-get -y install bison build-essential cmake flex git libedit-dev \
	  libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev

Install and compile BCC

	git clone https://github.com/iovisor/bcc.git
	mkdir bcc/build; cd bcc/build
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr
	make
	sudo make install

## Basic Usage(/usr/share/bcc/tools)

查看每个disk IO的延时

	./biosnoop -Q

测量disk IO

	./biolatency

查看文件系统page cache命中率

	./cachestat

采集内核和用户栈回溯信息用"--"分割开

	./profile -p `pidof qemu-system-x86_64` -d 5

将调用信息写成一行输出

	./profile -p `pidof qemu-system-x86_64` -d -f 5

输出到文件,绘制火焰图

	./profile -df -p `pidof qemu-system-x86_64` 5 > /tmp/out.profile
	./flamegraph.pl < /tmp/out.profile > out.svg

在内核函数中添加一个"_[k]", 内核调用使用橙色显示,用户态调用使用红色显示

	./profile -adf -p `pidof qemu-system-x86_64` 5 > /tmp/out.profile
	./flamegraph.pl --color=java < /tmp/out.profile > out.svg
