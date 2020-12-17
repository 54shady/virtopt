.globl _start
    .code16 // Generate 16 bit code
_start:		// Kernel's main routine
    xor %ax, %ax
1:
	jmp 1b // Loop forever

# using hexdump -C to check this value
. = 0xfff0	// Entry point
	ljmp $0xf000, $_start
