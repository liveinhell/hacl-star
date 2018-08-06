#include <stdio.h>
#include <string.h> // for memcmp
#include "gcc_compat.h"
#include "aes.h"
#include <stdint.h> // for uint?_t

const uint8_t  key[] = { 0xE8, 0xE9, 0xEA, 0xEB, 0xED, 0xEE, 0xEF, 0xF0, 0xF2, 0xF3, 0xF4, 0xF5, 0xF7, 0xF8, 0xF9, 0xFA };
const uint8_t in[]  =  { 0x01, 0x4B, 0xAF, 0x22, 0x78, 0xA6, 0x9D, 0x33, 0x1D, 0x51, 0x80, 0x10, 0x36, 0x43, 0xE9, 0x9A };
const uint8_t out[] =  { 0x67, 0x43, 0xC3, 0xD1, 0x51, 0x9A, 0xB4, 0xF2, 0xCD, 0x9A, 0x78, 0xAB, 0x09, 0xA5, 0x11, 0xBD};

void demo()
{
  uint8_t buffer[16];
  uint8_t expanded_key[176];

  KeyExpansionStdcall(key, expanded_key);
  AES128EncryptOneBlockStdcall(buffer, in, expanded_key);

  if (memcmp(out, buffer, sizeof(buffer)) == 0) {
      printf("AES128 success\n");
  } else {
      printf("AES128 failure\n");
  }
}

int __cdecl main(void)
{
  demo();
  return 0;
}

