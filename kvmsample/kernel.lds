OUTPUT_FORMAT(binary)

SECTIONS {
		. = 0;
		.text : { *(.init) *(.text) }
		. = ALIGN(4K);
		.data : { *(.data) }
		. = ALIGN(16);
		.bss : { *(.bss) }
		. = ALIGN(4K);
		.edata = .;
	}
