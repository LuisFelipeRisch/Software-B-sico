all:
	as memalloc.s -o memalloc.o -g
	gcc -c main.c -g
	gcc main.o memalloc.o -o program -g


clear:
	rm  *.o

purge: clear
	rm program