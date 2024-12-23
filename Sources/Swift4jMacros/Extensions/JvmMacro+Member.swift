import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions

extension JvmMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf declaration: some DeclGroupSyntax,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    let classDecl = try classDecl(from: declaration)
    let className = classDecl.name.text

    var fqn = className
    if let moduleName = classDecl.moduleName(from: context) {
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
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<\(className)>.self)
  _self.release()
}
"""

    let exportedDecls = classDecl.exportedDecls

    let initDecls: String
    if exportedDecls.hasInitDecls {
      initDecls = exportedDecls.initDecls.enumerated()
        .compactMap { i, decl in
          return context.executeAndWarnIfFails(at: decl) {
            return try decl.makeBridgingDecls(classDecl: classDecl, index: i)
          }
        }
        .joined(separator: "\n")

    } else {
      initDecls =
"""
fileprivate typealias init_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?) -> JavaLong
fileprivate static let init_jni: init_jni_t = { _, _ in
  let obj = \(className)()
  return unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)
}
"""
    }

    let funcDecls = exportedDecls.funcDecls
      .compactMap { decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(classDecl: classDecl)
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

    return ["\(raw: addPlatformConditions(node, syntax: syntax))"]
  }
}
