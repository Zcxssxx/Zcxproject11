#include <stdlib.h>
#include <stdint.h>

#include "moonbit.h"

MOONBIT_FFI_EXPORT
int32_t moon_ninja_execute_command(moonbit_bytes_t command) {
  return (int32_t)system((const char *)command);
}
