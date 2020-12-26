# Bochs(编译时开启debug模式)

[参考文章: https://www.cnblogs.com/chengmf/p/12540327.html](https://www.cnblogs.com/chengmf/p/12540327.html)

[参考文章: https://segmentfault.com/a/1190000008342230](https://segmentfault.com/a/1190000008342230)

## 8086第一条指令

直接执行bochs后看到第一条指令0x0000fffffff0

	Next at t=0
	(0) [0x0000fffffff0] f000:fff0 (unk. ctxt): jmpf 0xf000:e05b          ; ea5be000f0
	<bochs:1> n
	Next at t=1
	(0) [0x0000000fe05b] f000:e05b (unk. ctxt): xor ax, ax                ; 31c0

但为什么是0x0000fffffff0？

	因为和8086不同,现代处理器在加电时,
	段寄存器CS的内容为,0xF000,指令指针寄存器IP的内容为0xFFF0,
	这就使得处理器地址线的低20位同样是0xFFFF0.
	在刚启动时,处理器将其余(高位部分)的地址线强制为高电平.
	因为当前Bochs虚拟机的地址线是32根,所以,初始发出的物理内存地址就是0x0000fffffff0了

## 第一个程序

bochs -f bochsrc.hello

打断点到代码入口(0x7c00是所有程序入口)

	b 0x7c00

打开观察寄存器设置

	trace-reg on

查看堆栈

	print-stack

执行程序

	c

查看代码

	u 0x7c00 0x7c16
