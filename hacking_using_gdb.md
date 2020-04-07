# 使用GDB调试代码

## 使用GDB查看Qemu中的qom信息(gdb查看链表)

qemu代码中init_type_list是一个hash table
每个数组中的元素代表一个(槽, slot, 链表头)

	static ModuleTypeList init_type_list[MODULE_INIT_MAX];

使用[gdb脚本内容如下](qom.cmd)将该哈希表中注册的所有函数打印出来

```shell
set $x=4
while $x--
set $module_entry=init_type_list[$x].tqh_first
while $module_entry != 0x0
p $module_entry.init
set $module_entry=$module_entry.node.tqe_next
end
end
```

## 使用GDB查看handlers链表内容

查看代码中如下链表

static QTAILQ_HEAD(, QemuInputHandlerState) handlers =
    QTAILQ_HEAD_INITIALIZER(handlers);

```shell
set $Entry=handlers.tqh_first
while $Entry != 0
p $Entry->handler
p $Entry->handler->mask
set $Entry=$Entry.node.tqe_next
end
```
