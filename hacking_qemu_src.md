将configure文件中如下内容设置为no

	fortify_source="no"

设置cflags

	CFLAGS='-O0 -pipe -ggdb' CXXFLAGS="${CFLAGS}" ./configure --target-list=x86_64-softmmu

使用gdb调试

	$ gdb -d /qemu-src-top-dir --args /qemu-src-top-dir/x86_64-softmmu/qemu-system-x86_64 -enable-kvm -cpu host,kvm=off -machine pc-i440fx-2.7,accel=kvm,usb=off,dump-guest-core=off,mem-merge=off -smp 2 -m 2048 -realtime mlock=off -boot d -device child-device -hda /path-to-debug-vm/test.qcow2 -name debug
