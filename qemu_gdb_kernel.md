# Debug kernel using qemu

## 调试前准备

调试需要的一些配置

	CONFIG_DEBUG_INFO=y
	CONFIG_DEBUG_KERNEL=y
	CONFIG_GDB_SCRIPTS=y

## 准备initrd

[参考Gentoo initramfs](https://wiki.gentoo.org/wiki/Early_Userspace_Mounting)

使用内核中(gen_initramfs_list.sh)脚本生成

	cd /usr/src/linux
	./usr/gen_initramfs_list.sh -o rootfs.cpio.gz /usr/src/initramfs/initramfs_list

或者使用系统中已经生成的(/boot/initramfs-genkernel-x86_64-4.19.72-gentoo)

	mv initramfs-genkernel-x86_64-4.19.72-gentoo initramfs-genkernel-x86_64-4.19.72-gentoo.xz
	xz -d initramfs-genkernel-x86_64-4.19.72-gentoo.xz
	mv initramfs-genkernel-x86_64-4.19.72-gentoo initramfs-genkernel-x86_64-4.19.72-gentoo.cpio
	gzip initramfs-genkernel-x86_64-4.19.72-gentoo.cpio
	==> initramfs-genkernel-x86_64-4.19.72-gentoo.cpio.gz
	mv initramfs-genkernel-x86_64-4.19.72-gentoo.cpio.gz rootfs.cpio.gz

## 开始调试

使用qemu启动内核(内核会卡在stopped状态)

如果有配置CONFIG_RANDOMIZE_BASE则需要在cmdline里添加nokaslr(否则打断点无法停住,也无法显示函数名称)

	qemu-system-x86_64 -S -kernel arch/x86/boot/bzImage -initrd rootfs.cpio.gz -gdb tcp::1234 --append "nokaslr"

可以在编译内核的时候去掉CONFIG_RANDOMIZE_BASE

	qemu-system-x86_64 -S -kernel arch/x86/boot/bzImage -initrd rootfs.cpio.gz -gdb tcp::1234

可以配置gdb全局的配置文件(~/.gdbinit)

	target remote localhost:1234

使用gdb调试

	gdb ./vmlinux
	(gdb) target remote localhost:1234
	(gdb) b start_kernel
	(gdb) continue
