import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


protocol JvmValueTypeDeclSyntax: JvmTypeDeclSyntax {
  func expandToJavaObject(in context: some MacroExpansionContext) -> String
}


extension JvmValueTypeDeclSyntax {
  var selfExpr: String {
    "_self(ptr).pointee"
  }
  
  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String {
    return try expandJavaObjectDeclsAsClass(in: context)
  }

  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String {
    return try expandCtorDeclsAsClass(in: context)
  }

  func expandInitCall(params: String, throwing: Bool, initName: String) -> String {
"""
let ptr = UnsafeMutablePointer<\(name.text)>.allocate(capacity: 1)
ptr.initialize(to: \(throwing ? "try " : "").\(initName)(\(params)))
return JavaLong(Int(bitPattern: ptr))
"""
  }
}



extension JvmValueTypeDeclSyntax {
  func expandJavaObjectDeclsAsClass(in context: some MacroExpansionContext) throws -> String {
"""
private static func _self(_ obj: JavaObject?) -> UnsafeMutablePointer<\(typeName)> {
  let ptr: JavaLong = JObject(obj!).call(method: "_ptr")
  return _self(ptr) 
}

private static func _self(_ ptr: JavaLong) -> UnsafeMutablePointer<\(typeName)> {
  return UnsafeMutablePointer<\(typeName)>(bitPattern: Int(truncatingIfNeeded: ptr))! 
}

public static func fromJavaObject<R>(_ obj: JavaObject?, closure: (UnsafeMutablePointer<\(typeName)>) -> R) -> R {
  let _self = _self(obj)
  return closure(_self)
}

public static func fromJavaObject(_ obj: JavaObject?) -> Self {
  return _self(obj).pointee
}

public func toJavaObject() -> JavaObject? {
  \(expandToJavaObject(in: context))
}
"""
  }

  func expandCtorDeclsAsClass(in context: some MacroExpansionContext) throws -> String {
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
  UnsafeMutablePointer<\(typeName)>(bitPattern: Int(ptr))?.deallocate()
}
"""

    return
"""
\(initDecls)
\(deinitDecls)
"""
  }
}
