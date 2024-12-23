import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension JvmMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {


    let classDecl = try classDecl(from: declaration)
    let className = classDecl.name.text

    var fqnEscaped = className
    if let moduleName = classDecl.moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let exportedDecls = classDecl.exportedDecls

    let funcNatives: [String] = exportedDecls.funcDecls.compactMap {
      guard let jniSig = try? $0.jniSignature() else { return nil }
      return
"""
JNINativeMethod(name: "\($0.name.text)Impl", sig: "\(jniSig)", fn: \(className).\($0.name.text)_jni)
"""
      }

    let initNatives: [String]
    if exportedDecls.hasInitDecls {
      initNatives = exportedDecls.initDecls.enumerated().compactMap {
        guard let jniSig = try? $1.jniSignature() else { return nil }
        return
"""
JNINativeMethod(name: "init\($0)", sig: "\(jniSig)", fn: \(className).init\($0)_jni)
"""
      }
    } else {
      initNatives = [
"""
JNINativeMethod(name: "init", sig: "()J", fn: \(className).init_jni)
"""
      ]
    }

    let natives = initNatives + [
"""
JNINativeMethod(name: "deinit", sig: "(J)V", fn: \(className).deinit_jni)
"""
    ] + funcNatives


    let decl =
"""
@_cdecl("Java_\(fqnEscaped)_\(className)_1class_1init")
func \(className)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {
  guard let cls = cls else { return }
  let natives = [
    \(natives.joined(separator: ",\n"))
  ]
  let _ = jni.RegisterNatives(cls, natives)
}
"""
    return ["\(raw: addPlatformConditions(node, syntax: decl))"]
  }
}
