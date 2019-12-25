# VMCS Hacking

断点观察方法

	hbreak vmx.c:2523
	commands 1
	>x /xg vmx->loaded_vmcs->vmcs->data+0x478
	>c
	>end

VMCS对应的数据结构

	struct vmcs {
		u32 revision_id;
		u32 abort;
		char data[0];
	};

将vmcs中data域dump到文件

	(gdb) dump binary memory vmcs_data vmx->loaded_vmcs->vmcs->data vmx->loaded_vmcs->vmcs->data+0x1000
