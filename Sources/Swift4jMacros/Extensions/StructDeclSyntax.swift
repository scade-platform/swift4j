import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension StructDeclSyntax: JvmTypeDeclSyntax {
  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String {
    return
"""
private static func _cast(_ ptr: JavaLong) -> Self {
  return UnsafeMutablePointer<\(typeName)>(bitPattern: Int(truncatingIfNeeded: ptr))!.pointee
}

private func _cast() -> JavaLong {
  let ptr = UnsafeMutablePointer<\(typeName)>.allocate(capacity: 1)
  ptr.initialize(to: self)
  return JavaLong(Int(bitPattern: ptr))
}

public static func fromJavaObject(_ obj: JavaObject?) -> Self {
  let ptr: JavaLong = JObject(obj!).get(field: "_ptr")
  return _cast(ptr)
}

public func toJavaObject() -> JavaObject? {
  return \(typeName).javaClass.create(self._cast())  
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


