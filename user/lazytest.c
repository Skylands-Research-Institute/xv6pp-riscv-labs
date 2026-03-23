#include "kernel/types.h"
#include "kernel/riscv.h"
#include "user/user.h"

#define BIG (1024 * 1024 * 1024)

int
main(int argc, char *argv[])
{
  char *p;

  p = sbrk(BIG);
  if (p == (char *)-1) {
    printf("lazybigtest: sbrk failed\n");
    exit(1);
  }

  p[0] = 1;
  p[PGSIZE] = 2;
  p[2 * PGSIZE] = 3;
  p[3 * PGSIZE] = 4;

  printf("lazybigtest: success\n");
  printf("%d %d %d %d\n", p[0], p[PGSIZE], p[2 * PGSIZE], p[3 * PGSIZE]);

  exit(0);
}
