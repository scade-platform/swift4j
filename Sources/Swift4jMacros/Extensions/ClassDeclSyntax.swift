import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension ClassDeclSyntax: JvmTypeDeclSyntax {

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String {
"""
private let jref: JObjectRef<\(typeName)> = .init()

private static func _self(_ obj: JavaObject?) -> Self {
  let ptr: JavaLong = JObject(obj!).get(field: "_ptr")
  return _self(ptr)
}

private static func _self(_ ptr: JavaLong) -> Self {  
  return unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<Self>.self).takeUnretainedValue()
}

public static func fromJavaObject<R>(_ obj: JavaObject?, closure: (UnsafeMutablePointer<\(typeName)>) -> R) -> R {
  var _self = _self(obj)
  return closure(&_self)
}

public static func fromJavaObject(_ obj: JavaObject?) -> Self {
  return _self(obj)  
}

public func toJavaObject() -> JavaObject? {
  return jref.from(self)
}
"""
  }
  
  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String {
    let initDecls = exportedDecls.initDecls.enumerated()
      .compactMap { i, decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(typeDecl: self, index: i)
        }
      }
      .joined(separator: "\n")
    
    let deinitDecls =
"""
fileprivate typealias deinit_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?, JavaLong) -> Void
fileprivate static let deinit_jni: deinit_jni_t = { _, _, ptr in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<\(typeName)>.self)
  _self.takeUnretainedValue().jref.release()
  _self.release()  
}
"""

    return
"""
\(initDecls)
\(deinitDecls)
"""

  }

  func expandInitCall(params: String) -> String {
"""
let obj = \(name.text)(\(params))
return unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)
"""
  }
}


