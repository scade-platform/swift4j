import SwiftJava


@exported(.android)
public class Response {
  @exported
  func getMessage() -> String { "Swift" }
}

@exported(.android)
public class Service {
  @exported
  func request(_ response: (Response) -> Void) {
    let resp = Response()
    response(resp)
  }

}
