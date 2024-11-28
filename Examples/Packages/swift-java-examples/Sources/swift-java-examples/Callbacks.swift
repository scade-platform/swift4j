import SwiftJava


@jvm public class GreetingService {
  func greet(name: String, _ response: (Greeting) -> Void) {
    
    let greeting = Greeting(name: name)
    response(greeting)

  }

  func greetAsync(name: String, delayInSeconds: Int, _ response: (Greeting) -> Void) async {
    
    try? await Task.sleep(nanoseconds: UInt64(delayInSeconds*1_000_000_000))

    let greeting = Greeting(name: name)
    response(greeting)
  }
}



@jvm public class Greeting {
  let name: String

  init(name: String) {
    self.name = name
  }

  func getMessage() -> String { "Swift runtime is greeting \(name)" }
}
