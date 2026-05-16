extern "C" {
#include "kernel/types.h"
#include "user/user.h"
}

#include "Counter.h"

Counter::Counter(int initialValue) :
    value(0) {
  // TODO: initialize value from initialValue.
}

void Counter::increment() {
  // TODO: increase value by one.
}

void Counter::add(int amount) {
  // TODO: add amount to value.
}

int Counter::getValue() const {
  // TODO: return the current value.
  return 0;
}

int main(int argc, char *argv[]) {
  // TODO: translate the Java test program to C++.
  // Expected final output:
  // 3
  // 4
  // 8
  // 6

  return 0;
}
