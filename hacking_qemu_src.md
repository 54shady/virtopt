将configure文件中如下内容设置为no(--enable-debug)

	fortify_source="no"

设置cflags

	CFLAGS='-O0 -pipe -ggdb' CXXFLAGS="${CFLAGS}" ./configure --target-list=x86_64-softmmu

用下面命令行即可

	./configure --target-list=aarch64-softmmu --prefix=$PWD/tmp --enable-debug
	./configure --target-list=x86_64-softmmu --prefix=$PWD/tmp --enable-debug --disable-docs --disable-nettle --disable-gnutls --disable-gcrypt

gdb配置文件~/.gdbinit

	handle SIGUSR1 SIGUSR2 nostop noprint
	set print pretty on
	set pagination off

使用gdb调试

	$ gdb -d /qemu-src-top-dir --args /qemu-src/tmp/bin/qemu-system-x86_64 -enable-kvm -cpu host,kvm=off -machine pc,accel=kvm,usb=off,dump-guest-core=off,mem-merge=off -smp 2 -m 2048 -realtime mlock=off -boot d -device child-device -hda /path-to-debug-vm/test.qcow2 -name debug
