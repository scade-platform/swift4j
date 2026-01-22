

///TODO: add full support of the JConvertible
extension Error {
  public func toJavaObject() -> JavaObject? {
    guard let cls = JClass(fqn: "io/scade/swift4j/SwiftError") else {
      fatalError("Cannot find SwiftError class")
    }
    return cls.create("")
  }

  public func throwAsJavaException() {
    guard let jobj = toJavaObject() else {
      fatalError("Cannot instantiate SwiftError exception")
    }

    guard jni.Throw(jobj) else {
      fatalError("Throwing an exception failed")
    }
  }
}

