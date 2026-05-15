#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if (fork()) {
    wait(0);
    printf("parent: pid=%d\n", getpid());
  } else {
    printf("child: ppid=%d\n", getppid());
  }
  exit(0);
}
