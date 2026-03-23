#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
  sbrk(16 * PGSIZE);
  vmprint();
  exit(0);
}
