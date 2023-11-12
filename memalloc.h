#ifndef __MEMALLOC_H__
#define __MEMALLOC_H__

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void setup_brk();
void dismiss_brk();
void *memory_alloc(unsigned long int bytes);
int memory_free(void *pointer);

#endif