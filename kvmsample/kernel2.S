#include "runtime.h"

.code16
start:
    mov    $0x48,%al    // H
    outb   %al,$IO_PORT_PSEUDO_SERIAL
    mov    $0x65,%al    // e
    outb   %al,$IO_PORT_PSEUDO_SERIAL
    mov    $0x6c,%al    // l
    outb   %al,$IO_PORT_PSEUDO_SERIAL
    mov    $0x6c,%al    // l
    outb   %al,$IO_PORT_PSEUDO_SERIAL
    mov    $0x6f,%al    // o
    outb   %al,$IO_PORT_PSEUDO_SERIAL
    mov    $0x0a,%al    // new_line
    outb   %al,$IO_PORT_PSEUDO_SERIAL

    hlt                 // halt the processor

# using hexdump -C to check this value
# 在main.c中将这个程序加载到内存的0xF0000地址
# 所以这里的地址就时0xF0000 + 0xfff0 = 0xFFFF0
# 0xFFFF0对于8086来说是执行第一条指令的地址,一般在这里执行跳转指令
# Note that unlike many processors, the x86 processor does not have a reset vector.
# It does not use the value at 0xFFFF0 as the location of the reset code
# rather, it begins executing the code that is at 0xFFFF0
# Therefore, the normal code to place at 0xFFFF0 is a jump to the actual reset code
. = 0xfff0 # 当前地址0xfff0
	# let's do a test, whether the first insctuct run from here
    mov    $0x48,%al    // H
    outb   %al,$IO_PORT_PSEUDO_SERIAL

	# do a jump to the real work
    ljmp    $0xf000, $start
