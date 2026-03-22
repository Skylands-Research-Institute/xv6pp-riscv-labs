#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

static void fail(char *msg) {
  printf("FAIL: %s\n", msg);
  exit(1);
}

int main(void) {
  int fd;
  char buf[4];

  unlink("/a");
  unlink("/b");

  fd = open("/a", O_CREATE | O_RDWR);
  if (fd < 0)
    fail("open /a");

  if (write(fd, "abc", 3) != 3)
    fail("write /a");
  close(fd);

  if (symlink("/a", "/b") < 0)
    fail("symlink /b -> /a");

  fd = open("/b", O_RDONLY);
  if (fd < 0)
    fail("open /b");

  memset(buf, 0, sizeof(buf));
  if (read(fd, buf, 3) != 3)
    fail("read /b");
  close(fd);

  if (strcmp(buf, "abc") != 0)
    fail("wrong contents through symlink");

  unlink("/a");

  fd = open("/b", O_RDONLY);
  if (fd >= 0)
    fail("dangling symlink should not open");

  printf("symlink test: ok\n");
  exit(0);
}
