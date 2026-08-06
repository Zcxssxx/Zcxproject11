#include <stdint.h>
#include <stdio.h>
#include <sys/stat.h>

#include "moonbit.h"

static const char *moon_ninja_path(moonbit_bytes_t path) {
  return (const char *)path;
}

int64_t moon_ninja_file_mtime_seconds(moonbit_bytes_t path) {
  struct stat info;
  if (stat(moon_ninja_path(path), &info) != 0) {
    return -1;
  }
  return (int64_t)info.st_mtime;
}

int32_t moon_ninja_file_mtime_nanos(moonbit_bytes_t path) {
  struct stat info;
  if (stat(moon_ninja_path(path), &info) != 0) {
    return -1;
  }
#if defined(_WIN32)
  return 0;
#elif defined(__APPLE__)
  return (int32_t)info.st_mtimespec.tv_nsec;
#else
  return (int32_t)info.st_mtim.tv_nsec;
#endif
}

int32_t moon_ninja_file_size(moonbit_bytes_t path) {
  struct stat info;
  if (stat(moon_ninja_path(path), &info) != 0) {
    return -1;
  }
  if (info.st_size > INT32_MAX) {
    return INT32_MAX;
  }
  return (int32_t)info.st_size;
}

uint64_t moon_ninja_file_hash(moonbit_bytes_t path) {
  FILE *file = fopen(moon_ninja_path(path), "rb");
  if (file == NULL) {
    return 0;
  }
  uint64_t hash = UINT64_C(14695981039346656037);
  unsigned char buffer[4096];
  size_t count;
  while ((count = fread(buffer, 1, sizeof(buffer), file)) != 0) {
    for (size_t i = 0; i < count; ++i) {
      hash = (hash ^ (uint64_t)buffer[i]) * UINT64_C(1099511628211);
    }
  }
  fclose(file);
  return hash;
}
