import Foundation

extension Result where Success: JConvertible {
  public nonisolated static var javaName: String { "io/scade/swift4j/Result" }
  public nonisolated static var javaClass: JClass {
    guard let cls = JClass(fqn: javaName) else {
      fatalError("Could not find \(javaName) class")
    }
    return cls
  }

  public func toJavaObject() -> JavaObject? {
    switch self {
      case .success(let v):
        return Self.javaClass.callStaticObjectMethod(method: "ok",
                                                     sig: "(Ljava/lang/Object;)L\(Self.javaName);",
                                                     v)
      case .failure(let err):
        return Self.javaClass.callStaticObjectMethod(method: "err",
                                                     sig: "(Ljava/lang/Throwable;)L\(Self.javaName);",
                                                     [JavaParameter(object: err.toJavaObject())])
    }
  }
}
