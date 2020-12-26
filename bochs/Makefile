all: hello.bin c05.bin

hello.bin:hello.asm
	nasm -f bin -o $@ $^
	dd if=$@ of=hello.img bs=512 count=1 conv=notrunc

c05.bin:c05_mbr.asm
	nasm -f bin -o $@ $^
	dd if=$@ of=c05.img bs=512 count=1 conv=notrunc

clean:
	rm *.bin *.img
