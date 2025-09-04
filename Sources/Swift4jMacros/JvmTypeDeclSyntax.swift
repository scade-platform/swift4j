import SwiftSyntax
import SwiftSyntaxMacros

import SwiftSyntaxExtensions


protocol JvmTypeDeclSyntax: TypeDeclSyntax {
  var selfExpr: String { get }
  var shouldExpandMemberDecls: Bool { get }

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String
  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String

  func expandInitCall(params: String) -> String
}



extension JvmTypeDeclSyntax {
  var selfExpr: String { "_self(ptr)" }

  var shouldExpandMemberDecls: Bool { true }

  // Expand JVM class init function

  func expandPeer(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    guard shouldExpandMemberDecls else { return [] }

    let jniTypeName = typeName.replacingOccurrences(of: "_", with: "_1")

    var fqnEscaped = jniTypeName
    if let moduleName = moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let decl =
"""
\( (isMainActorIsolated ?? false) ? "@MainActor" : "")
@_cdecl("Java_\(fqnEscaped)_\(jniTypeName)_1class_1init")
func \(typeName)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {    
  \(expandRegisterNatives(in: context))
}
"""
    return ["\(raw: decl)"]
  }
  
  // Expand members

  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    let syntax =
"""
\(expandJavaClassDecl(in: context))
\(try expandJavaObjectDecls(in: context))
\(try expandCtorDecls(in: context))
\(expandFuncDecls(in: context))
"""
    
//\(expandVarDecls(in: context))

    return ["\(raw: syntax)"]
  }
}


extension JvmTypeDeclSyntax {
  func fqn(from context: some MacroExpansionContext) -> String {
    var fqn = typeName
    if let moduleName = moduleName(from: context) {
      fqn = "\(moduleName)/\(fqn)"
    }
    return fqn
  }

  func moduleName(from context: some MacroExpansionContext) -> String? {
    guard let segments = context.location(of: self)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }
}



extension JvmTypeDeclSyntax {
  func expandJavaClassDecl(in context: some MacroExpansionContext) -> String {
    let fqn = fqn(from: context)
    return
"""
private enum __JClass__ {
  static let name = "\(fqn)"
  static let shared = {
    guard let cls = JClass(fqn: javaName) else {
      fatalError("Could not find \\(javaName) class")
    }
    return cls
  } ()
}

public nonisolated static var javaName: String { __JClass__.name }
public nonisolated static var javaClass: JClass { __JClass__.shared }
"""
  }

  func expandVarDecls(in context: some MacroExpansionContext) -> String {
    return exportedDecls.varDecls
      .compactMap { decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(typeDecl: self)
        }
      }
      .joined(separator: "\n")
  }

  func expandFuncDecls(in context: some MacroExpansionContext) -> String {
    return exportedDecls.funcDecls
      .enumerated()
      .compactMap { i, decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(typeDecl: self, num: i)
        }
      }
      .joined(separator: "\n")
  }
}


extension JvmTypeDeclSyntax {
  func expandRegisterNatives(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax] = []) -> String {
    let exportedDecls = exportedDecls

    let fqn = parents.isEmpty ? typeName : parents.map{$0.typeName}.joined(separator: ".") + "." + typeName

    let varNatives: [String] = exportedDecls.varDecls.flatMap { decl in
      guard let bridgings = try? decl.bridgings(typeDecl: self) else { return [String]() }
      return bridgings.map { expandCreateNativeMethod(name: $0.javaName, sig: $0.sig, fn: "\(fqn).\($0.bridgeName)") }
    }

    let funcNatives: [String] = exportedDecls.funcDecls.enumerated().compactMap {
      guard let jniSig = try? $1.jniSignature() else { return nil }
      return expandCreateNativeMethod(name: "\($1.name.text)Impl", sig: jniSig, fn: "\(fqn).\($1.name.text)_\($0)_jni")
      }

    let initNatives: [String] = exportedDecls.initDecls.enumerated().compactMap {
      guard let jniSig = try? $1.jniSignature() else { return nil }
      return expandCreateNativeMethod(name: "init\($0)", sig: jniSig, fn: "\(fqn).init\($0)_jni")
    }

    let deinitNatives = [ expandCreateNativeMethod(name: "deinit", sig: "(J)V", fn: "\(fqn).deinit_jni")]

    let natives = initNatives + deinitNatives + varNatives + funcNatives

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

    let registerNatives =
"""
  guard let \(typeName)_cls = \(cls_expr) else { return }
  let \(typeName)_natives = [
    \(natives.joined(separator: ",\n"))
  ]
  let _ = jni.RegisterNatives(\(typeName)_cls, \(typeName)_natives)

  \(exportedDecls.typeDecls
    .compactMap { $0 as? (any JvmTypeDeclSyntax) }
    .map { $0.expandRegisterNatives(in: context, parents: parents + [self]) }
    .joined(separator: "\n")
  )
"""
    return exportAttributes.replaceAll(by: registerNatives)
  }

  func expandCreateNativeMethod(name: String, sig: String, fn: String) -> String {
    return
"""
JNINativeMethod2(name: "\(name)", sig: "\(sig)", fn: unsafeBitCast(\(fn), to: UnsafeMutableRawPointer.self))
"""
  }
}



fileprivate extension AttributeListSyntax {
  func replaceAll(by syntax: String) -> String {
    return self.map { $0.replace(by: syntax) }.joined(separator: "\n")
  }
}

fileprivate extension AttributeListSyntax.Element {
  func replace(by syntax: String) -> String {
    switch self {
    case .attribute(_):
      return syntax
    case .ifConfigDecl(let decl):
      let clauses = decl.clauses.map {
"""
\($0.poundKeyword.text) \($0.condition?.trimmedDescription ?? "")
\($0.elements?.as(AttributeListSyntax.self)?.replaceAll(by: syntax) ?? "" )
"""
      }
      return
"""
\(clauses.joined(separator: "\n"))
#endif 
"""
    }
  }
}
