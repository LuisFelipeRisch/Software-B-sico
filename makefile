CFLAGS =  -Wall -O2
# OBJECTS = queue.o utils.o sort.o

all: mem_manager

# mem_manager: $(OBJECTS) main.c
# 	gcc $(CFLAGS) $(OBJECTS) main.c -o mem_manager

mem_manager: main.c
	gcc $(CFLAGS) main.c -o mem_manager

# queue.o: queue.c
# 	gcc -c queue.c

# utils.o: utils.c
# 	gcc -c utils.c

# sort.o: sort.c
# 	gcc -c sort.c

clean:
	rm -rf *.o

purge: clean
	rm -rf mem_manager