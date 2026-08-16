#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "moonbit.h"

#if defined(_WIN32)
#include <windows.h>

typedef volatile LONG moon_ninja_atomic_int;

static void moon_ninja_atomic_init(moon_ninja_atomic_int *value, int initial) {
  *value = (LONG)initial;
}

static int moon_ninja_atomic_load(const moon_ninja_atomic_int *value) {
  return (int)InterlockedCompareExchange((volatile LONG *)value, 0, 0);
}

static int moon_ninja_atomic_fetch_add(moon_ninja_atomic_int *value, int delta) {
  return (int)InterlockedExchangeAdd(value, (LONG)delta);
}

static int moon_ninja_atomic_compare_exchange(
    moon_ninja_atomic_int *value, int *expected, int desired) {
  LONG observed = InterlockedCompareExchange(value, (LONG)desired, (LONG)*expected);
  if (observed == (LONG)*expected) {
    return 1;
  }
  *expected = (int)observed;
  return 0;
}
#else
#include <pthread.h>
#include <stdatomic.h>

typedef atomic_int moon_ninja_atomic_int;

static void moon_ninja_atomic_init(moon_ninja_atomic_int *value, int initial) {
  atomic_init(value, initial);
}

static int moon_ninja_atomic_load(const moon_ninja_atomic_int *value) {
  return atomic_load(value);
}

static int moon_ninja_atomic_fetch_add(moon_ninja_atomic_int *value, int delta) {
  return atomic_fetch_add(value, delta);
}

static int moon_ninja_atomic_compare_exchange(
    moon_ninja_atomic_int *value, int *expected, int desired) {
  return atomic_compare_exchange_weak(value, expected, desired);
}
#endif

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

typedef struct {
  const char *commands;
  int32_t count;
  moon_ninja_atomic_int next_index;
  moon_ninja_atomic_int failure_index;
} moon_ninja_parallel_state;

static const char *moon_ninja_command_at(
    const char *commands,
    int32_t count,
    int32_t wanted) {
  const char *cursor = commands;
  for (int32_t index = 0; index < count; ++index) {
    if (index == wanted) {
      return cursor;
    }
    cursor += strlen(cursor) + 1;
  }
  return NULL;
}

static void moon_ninja_record_failure(
    moon_ninja_parallel_state *state,
    int32_t index) {
  int desired = -(index + 1);
  int current = moon_ninja_atomic_load(&state->failure_index);
  while ((current == 0 || desired > current) &&
         !moon_ninja_atomic_compare_exchange(
             &state->failure_index, &current, desired)) {
  }
}

static void moon_ninja_run_worker(moon_ninja_parallel_state *state) {
  for (;;) {
    int32_t index = moon_ninja_atomic_fetch_add(&state->next_index, 1);
    if (index >= state->count) {
      return;
    }
    const char *command =
        moon_ninja_command_at(state->commands, state->count, index);
    if (command == NULL || system(command) != 0) {
      moon_ninja_record_failure(state, index);
    }
  }
}

#if defined(_WIN32)
static DWORD WINAPI moon_ninja_windows_worker(void *raw_state) {
  moon_ninja_run_worker((moon_ninja_parallel_state *)raw_state);
  return 0;
}
#else
static void *moon_ninja_posix_worker(void *raw_state) {
  moon_ninja_run_worker((moon_ninja_parallel_state *)raw_state);
  return NULL;
}
#endif

MOONBIT_FFI_EXPORT
int32_t moon_ninja_run_parallel_commands(
    moonbit_bytes_t commands,
    int32_t command_count,
    int32_t worker_count) {
  if (commands == NULL || command_count < 0 || worker_count < 1) {
    return -1;
  }
  moon_ninja_parallel_state state = {
      .commands = (const char *)commands,
      .count = command_count,
  };
  if (state.count < 1) {
    return 0;
  }
  if (worker_count > state.count) {
    worker_count = state.count;
  }
  if (worker_count > 8) {
    worker_count = 8;
  }
  moon_ninja_atomic_init(&state.next_index, 0);
  moon_ninja_atomic_init(&state.failure_index, 0);

#if defined(_WIN32)
  HANDLE handles[8];
  int32_t created = 0;
  for (int32_t index = 0; index < worker_count; ++index) {
    HANDLE handle = CreateThread(
        NULL,
        0,
        moon_ninja_windows_worker,
        &state,
        0,
        NULL);
    if (handle == NULL) {
      moon_ninja_record_failure(&state, 0);
      break;
    }
    handles[created++] = handle;
  }
  if (created > 0) {
    WaitForMultipleObjects((DWORD)created, handles, TRUE, INFINITE);
    for (int32_t index = 0; index < created; ++index) {
      CloseHandle(handles[index]);
    }
  }
#else
  pthread_t threads[8];
  int32_t created = 0;
  for (int32_t index = 0; index < worker_count; ++index) {
    if (pthread_create(
            &threads[created],
            NULL,
            moon_ninja_posix_worker,
            &state) != 0) {
      moon_ninja_record_failure(&state, 0);
      break;
    }
    created += 1;
  }
  for (int32_t index = 0; index < created; ++index) {
    pthread_join(threads[index], NULL);
  }
#endif
  return moon_ninja_atomic_load(&state.failure_index);
}
