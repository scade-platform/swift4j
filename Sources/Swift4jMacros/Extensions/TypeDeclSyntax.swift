import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxExtensions


extension TypeDeclSyntax {

  func moduleName(from context: some MacroExpansionContext) -> String? {
    guard let segments = context.location(of: self)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }

  func expandRegisterNatives(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax] = []) -> String {
    let exportedDecls = exportedDecls

    let fqn = parents.isEmpty ? typeName : parents.map{$0.typeName}.joined(separator: ".") + "." + typeName

    let funcNatives: [String] = exportedDecls.funcDecls.compactMap {
      guard let jniSig = try? $0.jniSignature() else { return nil }
      return
"""
JNINativeMethod(name: "\($0.name.text)Impl", sig: "\(jniSig)", fn: \(fqn).\($0.name.text)_jni)
"""
      }

    let initNatives: [String]
    if exportedDecls.hasInitDecls {
      initNatives = exportedDecls.initDecls.enumerated().compactMap {
        guard let jniSig = try? $1.jniSignature() else { return nil }
        return
"""
JNINativeMethod(name: "init\($0)", sig: "\(jniSig)", fn: \(fqn).init\($0)_jni)
"""
      }
    } else {
      initNatives = [
"""
JNINativeMethod(name: "init", sig: "()J", fn: \(fqn).init_jni)
"""
      ]
    }

    let natives = initNatives + [
"""
JNINativeMethod(name: "deinit", sig: "(J)V", fn: \(fqn).deinit_jni)
"""
    ] + funcNatives

    let cls_expr: String
    if parents.isEmpty {
      cls_expr = "cls"
    } else {
      var jfqn = fqn.replacingOccurrences(of: ".", with: "$")
      if let moduleName = moduleName(from: context) {
        jfqn = moduleName + "/" + jfqn
      }
      cls_expr = "jni.FindClass(\"\(jfqn)\")"
    }

    return
"""
  guard let \(typeName)_cls = \(cls_expr) else { return }
  let \(typeName)_natives = [
    \(natives.joined(separator: ",\n"))
  ]
  let _ = jni.RegisterNatives(\(typeName)_cls, \(typeName)_natives)

  \(exportedDecls.typeDecls.map{$0.expandRegisterNatives(in: context, parents: parents + [self])}.joined(separator: "\n"))
"""
  }
}
