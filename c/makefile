CFLAGS =  -Wall -O2
OBJECTS = memalloc.o

all: mem_manager

mem_manager: $(OBJECTS) main.c
	gcc $(CFLAGS) $(OBJECTS) main.c -o mem_manager

memalloc.o: memalloc.c
	gcc -c memalloc.c

clean:
	rm -rf *.o

purge: clean
	rm -rf mem_manager