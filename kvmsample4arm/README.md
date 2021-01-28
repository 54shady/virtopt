# Hello World for bare metal ARMv8 using QEMU

This repo is fork form https://github.com/jserv/armv8-hello

## Run and test

	qemu-system-aarch64 -machine virt -cpu cortex-a57 -smp 4 -m 1024 -nographic -kernel kernel.elf
