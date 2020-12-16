all: kvmsample test.bin

kvmsample: main.o
	gcc main.c -o kvmsample -lpthread

test.bin: test.o
	ld -m elf_x86_64 --oformat binary -N -e _start -Ttext 0x10000 -o test.bin test.o

test.o: test.S
	as test.S -o test.o

clean:
	rm *.o kvmsample test.bin
