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
. = 0xfff0
    ljmp    $0xf000, $start
