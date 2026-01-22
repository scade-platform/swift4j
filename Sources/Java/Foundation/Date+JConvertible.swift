import Foundation

extension Date: JObjectConvertible, JNullInitializable {
  private enum __JClass__ {
    static let name = "java/util/Date"
    static let shared = {
      guard let cls = JClass(fqn: javaName) else {
        fatalError("Could not find \(javaName) class")
      }
      return cls
    } ()
  }

  public nonisolated static var javaName: String { __JClass__.name }
  public nonisolated static var javaClass: JClass { __JClass__.shared }

  public static func fromJavaObject(_ obj: JavaObject) -> Date {
    let jtime: Int64 = JObject(obj).call(method: "getTime")
    return Date(timeIntervalSince1970: TimeInterval(jtime))
  }

  public func toJavaObject() -> JavaObject? {
    // from seconds since 1970 to milliseconds
    return Date.javaClass.create(Int64(timeIntervalSince1970) * 1000)
  }
}

