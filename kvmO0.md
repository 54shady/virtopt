# 使用O0编译KVM编译

全编时使用O0编译kvm_main模块

	make CFLAGS_kvm_main.o='-O0 -ftree-ter'

全编时使用O0编译所有kmv模块

	make CFLAGS_kvm-intel.o='-O0 -ftree-ter' CFLAGS_kvm.o='-O0 -ftree-ter'

或单独编译时使用O0编译

	make CONFIG_KVM=y CONFIG_INTEL_KVM=y M=arch/x86/kvm CFLAGS_kvm_main.o='-O0 -ftree-ter'

使用O0编译vmx时需要修改顶层Makefile关闭CC_HAVE_ASM_GOTO

	# check for 'asm goto'
	#ifeq ($(call shell-cached,$(CONFIG_SHELL) $(srctree)/scripts/gcc-goto.sh $(CC) $(KBUILD_CFLAGS)), y)
	#   KBUILD_CFLAGS += -DCC_HAVE_ASM_GOTO
	#   KBUILD_AFLAGS += -DCC_HAVE_ASM_GOTO
	#endif

	make CFLAGS_vmx.o='-O0 -ftree-ter' CFLAGS_kvm.o='-O0 -ftree-ter'

使用O0编译vmx后才能调试vmcs

	(gdb) b vmx_vcpu_load
	(gdb) b vmx_vcpu_run
	(gdb) b vmx_complete_interrupts
	(gdb) p *vmx
	(gdb) p *vmx->loaded_vmcs
	(gdb) p *vmx->loaded_vmcs->msr_bitmap
	(gdb) display *vmx->loaded_vmcs
