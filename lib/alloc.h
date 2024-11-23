#pragma once

#include <stddef.h>
#include <stdint.h>

bool heap_init(uint8_t *address, size_t size);
void *malloc(size_t size);
void free(void *ptr);
