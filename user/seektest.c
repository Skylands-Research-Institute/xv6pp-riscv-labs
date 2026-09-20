#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
  int fd;
  if ((fd = open("seektest.txt", O_CREATE | O_TRUNC | O_RDWR)) < 0) {
    fprintf(2, "seektest: cannot open seektest.txt\n");
    exit(1);
  }
  if (write(fd, "ABCDEFGHIJKLMNOP", 16) != 16) {
    fprintf(2, "seektest: cannot write seektest.txt\n");
    exit(1);
  }
  if (seek(fd, 4, SEEK_SET) < 0) {
    fprintf(2, "seektest: seek(fd, 4, SEEK_SET) failed\n");
    exit(1);
  }
  char c;
  if (read(fd, &c, 1) != 1 || c != 'E') {
    fprintf(2, "seektest: read failed or character mismatch\n");
    exit(1);
  }
  if (seek(fd, 2, SEEK_CUR) < 0) {
    fprintf(2, "seektest: seek(fd, 2, SEEK_CUR) failed\n");
    exit(1);
  }
  if (read(fd, &c, 1) != 1 || c != 'H') {
    fprintf(2, "seektest: read failed or character mismatch\n");
    exit(1);
  }
  if (seek(fd, -2, SEEK_END) < 0) {
    fprintf(2, "seektest: seek(fd, -2, SEEK_END) failed\n");
    exit(1);
  }
  if (read(fd, &c, 1) != 1 || c != 'O') {
    fprintf(2, "seektest: read failed or character mismatch\n");
    exit(1);
  }
  int pfds[2];
  if (pipe(pfds) == -1) {
    fprintf(2, "seektest: failed to create pipe\n");
    exit(1);
  }
  if (seek(pfds[0], 0, SEEK_SET) != -1) {
    fprintf(2, "seektest: seek on pipe allowed\n");
    exit(1);
  }
  close(pfds[0]);
  close(pfds[1]);
  if (seek(fd, -1, SEEK_SET) != -1) {
    fprintf(2, "seektest: seek to negative offset allowed\n");
    exit(1);
  }
  if (seek(fd, 20, SEEK_SET) != -1) {
    fprintf(2, "seektest: seek past EOF allowed\n");
    exit(1);
  }
  if (seek(fd, 0, 3) != -1) {
    fprintf(2, "seektest: seek whence 3 allowed\n");
    exit(1);
  }
  if (seek(fd, 2, SEEK_SET) == -1) {
    fprintf(2, "seektest: seek(fd, 2, SEEK_SET) failed\n");
    exit(1);
  }
  c = 'Z';
  if (write(fd, &c, 1) != 1) {
    fprintf(2, "seektest: write failed\n");
    exit(1);
  }
  close(fd);
  if ((fd = open("seektest.txt", O_RDWR)) < 0) {
    fprintf(2, "seektest: cannot reopen seektest.txt\n");
    exit(1);
  }
  if (seek(fd, 2, SEEK_SET) == -1) {
    fprintf(2, "seektest: seek(fd, 2, SEEK_SET) failed\n");
    exit(1);
  }
  if (read(fd, &c, 1) != 1 || c != 'Z') {
    fprintf(2, "seektest: read failed or character mismatch\n");
    exit(1);
  }
  if (seek(fd, 1, SEEK_END) != -1) {
    fprintf(2, "seektest: seek beyond EOF allowed\n");
    exit(1);
  }
  if (seek(fd, -17, SEEK_END) != -1) {
    fprintf(2, "seektest: seek to negative offset allowed\n");
    exit(1);
  }
  close(fd);
  printf("seek test: ok\n");
  exit(0);
}
