# 虚拟机性能优化

[参考RHEL7 PerformanceTuningGuide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/pdf/performance_tuning_guide/Red_Hat_Enterprise_Linux-7-Performance_Tuning_Guide-en-US.pdf)

## 开始前的准备

### 编译Qemu文档

进入文档目录

	cd /path/to/qemu/docs
	mkdir _build
	sphinx-build . _build

生成文件

	_build/index.html

### 编译kernel文档

在内核目录执行

	cd /path/to/src/kernel/
	make htmldocs

生成文件

	Documentation/output/index.html

## Latency

[FindingOriginsOfLatenciesUsingFtrace](Finding_Origins_of_Latencies_Using_Ftrace.pdf)

延时的定义

一个事件实际执行的时间点和本应该要在哪个时间点执行的时间差

内核中导致延时的四个情景

- 禁止中断(导致任务无法处理)
- 禁止抢占(阻止激活的任务无法运行)
- 调度延时
- 中断倒转(中断优先级比其中断的任务优先级低)

使用trace来测量相应的延时

- 禁止中断(irqoff)
	追踪关中断时间
- 禁止抢占(preemptoff)
	追踪抢占/中断任一被关闭的最大延迟时间。
- 调度延时(wakeup, wakeup_rt)
	追踪普通进程从被唤醒到真正得到执行之间的延迟
- 中断倒转

## 优化前的信息收集

查看Qemu启动后都有那些线程

	./scripts/find_thread_name.sh

	pid(14912) qemu-system-x86
	pid(14913) call_rcu
	pid(14914) trace-thread
	pid(14916) IO mon_iothread
	pid(14917) CPU 0/KVM
	pid(14918) CPU 1/KVM
	pid(14921) SPICE Worker
	pid(14922) vnc_worker

## CPU隔离

[Linux的tickless设置](http://www.litrin.net/2018/11/15/linux的tickless设置/)

![idv](idv.png)

isolcpus

- isolate one or more CPUs from the scheduler with the isolcpus boot parameter.
	This prevents the scheduler from scheduling any user-space threads on this CPU.

- Once a CPU is isolated, you must manually assign processes to the isolated CPU,
	either with the CPU affinity system calls or the numactl command

tickless and dynamic tickless kernel(CONFIG_NO_HZ_FULL)

- tickless does not interrupt idle CPUs in order to reduce power usage and allow newer processors to take advantage of deep sleep states
- dynamic tickless is useful for very latency-sensitive workloads, such as high performance computing or realtime computing

开启内核配置选项(dynamic tickless config)

	CONFIG_NO_HZ_FULL

通过在启动参数中设置isolcpus来配置cpu隔离和内核tick

在/etc/default/grub中设置

	GRUB_CMDLINE_LINUX_DEFAULT="isolcpus=1,3 nohz_full=1,3"

重新生成grub.cfg

	grub-mkconfig -o /boot/grub/grub.cfg

查看修改是否成功

	cat /proc/cmdline

测试程序

	# ./isol_cpu_test.sh

对测试结果解读

	grep 'Local timer interrupts' /proc/interrupts

未配置隔离核和全时钟中断的的情况下每个核上的中断一般在1000ticks左右

配置后在隔离核上理论上只有1个ticks(实际测试平均都在10ticks以内)

## 关于x2APIC

[Virt2apic](https://fedoraproject.org/wiki/Features/Virtx2apic)

**x2apic优点**

- x2apic improves guest performance by reducing the overhead of APIC access,
	which is used to program timers and for issuing inter-processor interrupts.
	By exposing x2apic to guests, and by enabling the guest to utilize x2apic,
	we improve guest performance

- improved guest performance and lower cpu utilization

x2APIC是硬件特性,内核提供一些参数来控制

默认开启,可以在/etc/default/grub中禁止该功能

	GRUB_CMDLINE_LINUX_DEFAULT="nox2apic"

开机后查看是否由该功能

	cat /proc/cpuinfo | ag x2apic
	dmesg | ag x2apic

**xAPIC模式**

- APIC寄存器被映射到4KB大小的内存区,因此访问APIC是通过MMIO

**x2APIC模式下**

- 一部分MSR地址区间为APIC寄存器预留,访问APIC是通过MSR

**测试方法**

- measure the overhead of an IPI with and without x2apic
