package swift_java_examples;

public class Foo {
  private long _ptr;

  static {
    Foo_class_init();
  }

  public Foo() {
     _ptr = Foo.init();
  }

  private Foo(long ptr) {
     _ptr = ptr;
  }

  @Override
  public void finalize() {
    Foo.deinit(_ptr);
  }

  private static native long init();
  private static native void deinit(long ptr);
  private static native void Foo_class_init();

  public String getMessage() {
    return this.getMessageImpl(_ptr);
  }
  private native String getMessageImpl(long ptr);

  public void receiveMessage(String msg) {
    this.receiveMessageImpl(_ptr, msg);
  }
  private native void receiveMessageImpl(long ptr, String msg);
}
