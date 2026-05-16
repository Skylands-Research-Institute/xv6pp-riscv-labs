#pragma once

class Counter {
private:
  int value;

public:
  Counter(int initialValue);

  void increment();

  void add(int amount);

  int getValue() const;
};
