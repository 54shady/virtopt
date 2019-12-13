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
