.PHONY: all
all: prog
	./prog
main.o: main.asm
	nasm -f elf64 -o main.o main.asm
prog: main.o
	ld -o prog main.o
