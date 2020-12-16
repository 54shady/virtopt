# A test code for kvmsample

.globl _start
    .code16
_start:
    xorw %ax, %ax
    mov  $0x0a,%al
    out %ax, $0x10
    inc %ax
    hlt
