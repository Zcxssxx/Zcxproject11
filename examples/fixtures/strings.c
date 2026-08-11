#include <stddef.h>

int moon_ninja_string_length(const char *text) {
  size_t length = 0;
  while (text[length] != 0) {
    length += 1;
  }
  return (int)length;
}
