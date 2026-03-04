package io.scade.swift4j;

public class SwiftPtr {
  private final long _value;
  private final boolean _owns;

  public SwiftPtr(long value) {
    _value = value;
    _owns = true;
  }

  public SwiftPtr(long value, boolean owns) {
    _value = value;
    _owns = owns;
  }

  public long get() { return _value; }
}
