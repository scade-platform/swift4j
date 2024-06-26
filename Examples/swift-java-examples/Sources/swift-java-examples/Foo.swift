import Java
import SwiftJava

@JavaClass
public class Foo {

  @JavaMethod
  func getMessage() -> String {
    return "Hello From Swift"
  }

  @JavaMethod
  func receiveMessage(_ msg: String) {    
    print(msg)
  }
}
