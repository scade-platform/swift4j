import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension ClassDeclSyntax: JvmTypeDeclSyntax {
  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    var fqn = typeName

    if let moduleName = moduleName(from: context) {
      fqn = "\(moduleName)/\(fqn)"
    }

    let varDecls =
"""
private var jobj: JObject? = nil

public static var javaClass = {
  guard let cls = JClass(fqn: \"\(fqn)\") else {
    fatalError("Could not find \(fqn) class")
  }
  return cls
} ()

public func toJavaObject() -> JavaObject? {
  if jobj == nil {
    jobj = JObject(Self.javaClass.create(unsafeBitCast(Unmanaged.passRetained(self), to: JavaLong.self)), weak: true)
  }
  return jobj?.ptr
}
"""

    let deinitDecls =
"""
fileprivate typealias deinit_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?, JavaLong) -> Void
fileprivate static let deinit_jni: deinit_jni_t = { _, _, ptr in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<\(typeName)>.self)
  _self.release()
}
"""

    let exportedDecls = exportedDecls

    let initDecls: String
    if exportedDecls.hasInitDecls {
      initDecls = exportedDecls.initDecls.enumerated()
        .compactMap { i, decl in
          return context.executeAndWarnIfFails(at: decl) {
            return try decl.makeBridgingDecls(classDecl: self, index: i)
          }
        }
        .joined(separator: "\n")

    } else {
      initDecls =
"""
fileprivate typealias init_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?) -> JavaLong
fileprivate static let init_jni: init_jni_t = { _, _ in
  let obj = \(typeName)()
  return unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)
}
"""
    }

    let funcDecls = exportedDecls.funcDecls
      .compactMap { decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(classDecl: self)
        }
      }
      .joined(separator: "\n")

    let syntax =
"""
\(varDecls)
\(initDecls)
\(deinitDecls)
\(funcDecls)
"""

    return ["\(raw: syntax)"]
  }

  func expandPeer(in context: some MacroExpansionContext) -> [DeclSyntax] {
    var fqnEscaped = typeName
    if let moduleName = moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let decl =
"""
@_cdecl("Java_\(fqnEscaped)_\(typeName)_1class_1init")
func \(typeName)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {    
  \(expandRegisterNatives(in: context))
}
"""
    return ["\(raw: decl)"]
  }

}


