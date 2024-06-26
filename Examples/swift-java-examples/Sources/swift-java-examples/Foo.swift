import Java
import SwiftJava

@JavaClass
public class Foo {

  @JavaMethod
  func getMessage() -> String {
    return "Hello From Swift XXX"
  }

  @JavaMethod
  func receiveMessage(_ msg: String) {    
    print("XXX: \(msg)")
  }
}
