#include "memalloc.h"

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

void try_to_alloc_new_block(void *block, unsigned long int bytes){
  unsigned long int *block_data_bytes_qnt = (unsigned long int *) (block + 8);

  if(*block_data_bytes_qnt - bytes <= 16) return;

  void *block_data = block + 16;

  unsigned long int *new_block_state = (unsigned long int *) (block_data + bytes);
  unsigned long int *new_block_data_bytes_qnt = (unsigned long int *) (block_data + bytes + 8);

  *new_block_state = FREE;
  *new_block_data_bytes_qnt = *block_data_bytes_qnt - bytes - 16;
  *block_data_bytes_qnt = bytes;
}

void *memory_alloc(unsigned long int bytes){
  void *new_block, *pointer, *free_block;

  free_block = find_free_block(bytes);

  if(free_block != NULL){
    try_to_alloc_new_block(free_block, bytes);

    pointer = free_block + 16;
  } else {
    new_block = create_new_block(bytes);

    pointer = new_block + 16;
  }

  return pointer;
}

int memory_free(void *pointer){
  unsigned long int *state = (unsigned long int *) (pointer - 16);

  *state = FREE;

  return 0;
}