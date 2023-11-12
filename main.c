#include "memalloc.h"

extern void *init_heap;

int main(){
  setup_brk();

  printf("init heap: %p\n", init_heap);

  void *pointer = memory_alloc(100);

  printf("&pointer: %p\n", pointer);

  printf("state %ld\n", *((unsigned long int *)(pointer - 16)));

  memory_free(pointer);

  printf("state %ld\n", *((unsigned long int *)(pointer - 16)));

  void *pointer_two = memory_alloc(83);

  printf("&pointer_two: %p\n", pointer_two);
  printf("state %ld\n", *((unsigned long int *)(pointer_two - 16)));
  printf("qnt %ld\n", *((unsigned long int *)(pointer_two - 8)));

  printf("&pointer new: %p\n", pointer_two + 83 + 16);
  printf("state new %ld\n", *((unsigned long int *)(pointer_two + 83)));
  printf("qnt new %ld\n", *((unsigned long int *)(pointer_two  + 83 + 8)));

  void *pointer_three = memory_alloc(1);

  printf("&pointer_two: %p\n", pointer_three);
  printf("state %ld\n", *((unsigned long int *)(pointer_three - 16)));
  printf("qnt %ld\n", *((unsigned long int *)(pointer_three - 8)));

  printf("init heap: %p\n", init_heap);

  dismiss_brk();

  return 0;
}