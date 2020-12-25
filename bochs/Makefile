all: hello.bin

hello.bin:hello.asm
	nasm -f bin -o $@ $^
	dd if=$@ of=hello.img bs=512 count=1 conv=notrunc

clean:
	rm *.bin *.img
