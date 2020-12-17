# https://www.linuxjournal.com/article/10251

CC=gcc

# -nostdlib avoids linking the standard system startup files and libraries
CFLAGS=-nostdlib -ffreestanding -Wl,-verbose,-T,kernel.lds

all: kvmsample test.bin kernel1.bin kernel2.bin

kvmsample: main.o
	gcc main.c -o kvmsample -lpthread

test.bin: test.o
	ld -m elf_x86_64 --oformat binary -N -e _start -Ttext 0x10000 -o $@ $^

test.o: test.S
	as $^ -o $@

# run top command on another console will see 100% cpu usage
kernel1.bin: kernel1.S
	$(CC) $(CFLAGS) $^ -o $@

kernel2.bin: kernel2.S
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm *.o kvmsample *.bin
