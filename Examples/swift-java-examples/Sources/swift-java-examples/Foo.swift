import SwiftJava


@exported(.android)
public class Bar {
  @exported
  func getMessage() -> String { "Swift" }
}


@exported(.android)
public class Foo {
  @exported
  func request(_ response: (Bar) -> Int) {
    let bar = Bar()
    print("Response code: \(response(bar))")
  }

}
