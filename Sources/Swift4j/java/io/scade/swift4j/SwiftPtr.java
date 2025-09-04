package io.scade.swift4j;

public class SwiftPtr {
  private final long _value;

  public SwiftPtr(long value) {
    _value = value;
  }

  public long get() { return _value; }
}
