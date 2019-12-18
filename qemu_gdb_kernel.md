# Debug kernel using qemu

## 调试前准备

调试需要的一些配置

	CONFIG_DEBUG_INFO=y
	CONFIG_DEBUG_KERNEL=y
	CONFIG_GDB_SCRIPTS=y

准备initrd(拷贝/boot/initramfs-genkernel-x86_64-4.19.72-gentoo)

	mv initramfs-genkernel-x86_64-4.19.72-gentoo initramfs-genkernel-x86_64-4.19.72-gentoo.xz
	xz -d initramfs-genkernel-x86_64-4.19.72-gentoo.xz
	mv initramfs-genkernel-x86_64-4.19.72-gentoo initramfs-genkernel-x86_64-4.19.72-gentoo.cpio
	gzip initramfs-genkernel-x86_64-4.19.72-gentoo.cpio
	==> initramfs-genkernel-x86_64-4.19.72-gentoo.cpio.gz

## 开始调试

使用qemu启动内核(内核会卡在stopped状态)

	qemu-system-x86_64 -S /dev/zero -kernel arch/x86/boot/bzImage -initrd initramfs-genkernel-x86_64-4.19.72-gentoo.cpio.gz -gdb tcp::1234

可以配置gdb全局的配置文件(~/.gdbinit)

	target remote localhost:1234

使用gdb调试

	gdb ./vmlinux
	(gdb) target remote localhost:1234
	(gdb) continue
