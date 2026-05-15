#include "memlayout.h"
#include "types.h"
#include "riscv.h"
#include "page_allocator.h"
#include "lock_guard.h"

extern char end[];  // first address after kernel, defined by kernel.ld

page_allocator::page_allocator(const char *name) :
    kernel_module(name), lock(name) {
  char *p = (char*) PGROUNDUP((uint64 )end);
  while (p + PGSIZE <= (char*) PHYSTOP) {
    free(p);
    p += PGSIZE;
  }
}

void page_allocator::init() {
  log(log_level::INFO, "init, size=%ld\n", sizeof(*this));
}

uint64 page_allocator::get_free_count() {
  lock_guard<spin_lock> g(lock);
  return free_list.get_count();
}

static int append_char(char *buf, int sz, int n, char c) {
  if (n < sz)
    buf[n] = c;
  return n + 1;
}

static int append_str(char *buf, int sz, int n, const char *s) {
  while (*s)
    n = append_char(buf, sz, n, *s++);
  return n;
}

static int append_uint(char *buf, int sz, int n, uint64 x) {
  char digits[20];
  int i = 0;
  do {
    digits[i++] = '0' + x % 10;
    x /= 10;
  } while (x);
  while (i > 0)
    n = append_char(buf, sz, n, digits[--i]);
  return n;
}

int page_allocator::statistics(char *buf, int sz) {
  uint64 test_and_set = lock.get_test_and_set_count();
  uint64 acquire = lock.get_acquire_count();

  int n = 0;
  n = append_str(buf, sz, n, "--- lock kmem stats\n");
  n = append_str(buf, sz, n, "lock: kmem: #test-and-set ");
  n = append_uint(buf, sz, n, test_and_set);
  n = append_str(buf, sz, n, " #acquire() ");
  n = append_uint(buf, sz, n, acquire);
  n = append_char(buf, sz, n, '\n');
  n = append_str(buf, sz, n, "tot= ");
  n = append_uint(buf, sz, n, test_and_set);
  n = append_str(buf, sz, n, " acquire= ");
  n = append_uint(buf, sz, n, acquire);
  n = append_char(buf, sz, n, '\n');

  if (sz > 0)
    buf[n < sz ? n : sz - 1] = '\0';
  return n;
}

void* page_allocator::alloc() {
  lock_guard<spin_lock> g(lock);
  return free_list.pop();
}

void page_allocator::free(void *p) {
  if ((uint64) p % PGSIZE != 0)
    panic("free: unaligned page");
  if ((char*) p < end || (uint64) p >= PHYSTOP)
    panic("free: out of range");
  lock_guard<spin_lock> g(lock);
  free_list.push((page*) p);
}
