#include <stdio.h>
#include <unistd.h>

void *setup_brk(){
  return sbrk(0);
}

int main(){
  printf("Current top of the heap: %p\n", setup_brk());

  return 0;
}