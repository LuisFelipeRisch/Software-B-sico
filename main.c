#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#define BUSY 1
#define FREE 0

void *init_heap;
void *top_heap;

void setup_brk(){
  init_heap = sbrk(0);
  top_heap  = sbrk(0);
}

void dismiss_brk(){
  brk(init_heap);
}

void *find_free_block(unsigned long int bytes){
  void *free_block    = NULL;
  void *current_block = init_heap;

  while (current_block < top_heap && free_block == NULL)
  {
    unsigned long int *state       = (unsigned long int *) current_block;
    unsigned long int *bytes_qnt   = (unsigned long int *) (current_block + 8);

    if(*state == FREE && *bytes_qnt >= bytes){
      *state = BUSY;
      free_block = current_block;
    }

    current_block += (16 + *bytes_qnt);
  }

  return free_block;
}

void *create_new_block(unsigned long int bytes){
  unsigned long int displacement = 16 + bytes;
  unsigned long int *state       = (unsigned long int *) top_heap;
  unsigned long int *bytes_qnt   = (unsigned long int *) (top_heap + 8);
  void *new_block                = top_heap;

  *state = BUSY;
  *bytes_qnt = bytes;

  top_heap += displacement;

  return new_block;
}

void *memory_alloc(unsigned long int bytes){
  void *new_block, *pointer, *free_block;

  free_block = find_free_block(bytes);

  if(free_block != NULL){
    pointer = free_block + 16;
  } else {
    new_block = create_new_block(bytes);

    pointer = new_block + 16;
  }

  return pointer;
}

void memory_free(void *pointer){
  unsigned long int *state = (unsigned long int *) (pointer - 16);

  *state = FREE;
}

int main(){
  setup_brk();

  printf("init heap: %p\n", init_heap);

  void *pointer = memory_alloc(100);

  printf("&pointer: %p\n", pointer);

  printf("state %ld\n", *((unsigned long int *)(pointer - 16)));

  memory_free(pointer);

  printf("state %ld\n", *((unsigned long int *)(pointer - 16)));

  void *pointer_two = memory_alloc(100);

  printf("&pointer_two: %p\n", pointer_two);

  printf("state %ld\n", *((unsigned long int *)(pointer_two - 16)));

  printf("init heap: %p\n", init_heap);

  dismiss_brk();

  return 0;
}