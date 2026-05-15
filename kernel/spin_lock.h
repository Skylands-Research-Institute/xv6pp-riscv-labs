#pragma once

#include "types.h"
#include "lock_base.h"

class spin_lock: public lock_base {
private:
  int cpuid = -1;
  uint64 test_and_set_count = 0;
  uint64 acquire_count = 0;

public:
  explicit spin_lock(const char *name = "");

  void acquire();
  void release();
  bool holding() const;

  int get_cpuid() const {
    return cpuid;
  }

  uint64 get_test_and_set_count() const {
    return test_and_set_count;
  }

  uint64 get_acquire_count() const {
    return acquire_count;
  }

  spin_lock(const spin_lock&) = delete;
  spin_lock& operator=(const spin_lock&) = delete;
};
