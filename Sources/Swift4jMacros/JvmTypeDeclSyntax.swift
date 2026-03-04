import SwiftSyntax
import SwiftSyntaxMacros

import SwiftSyntaxExtensions


protocol JvmTypeDeclSyntax: TypeDeclSyntax {
  var selfExpr: String { get }

  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax]

  func expandJavaClassDecl(in context: some MacroExpansionContext) -> String

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String

  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String

  func expandInitCall(params: String, throwing: Bool, initName: String) throws -> String

  func expandRegisterNatives(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax]) throws -> String

  func expandCreateNativeMethods(parents: [any TypeDeclSyntax]) throws -> [String]
}

extension JvmTypeDeclSyntax {
  var selfExpr: String { "_self(ptr)" }

  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    return try expandMembersDefault(in: context)
  }

  func expandJavaClassDecl(in context: some MacroExpansionContext) -> String {
    return try expandJavaClassDeclDefault(in: context)
  }

  func expandRegisterNatives(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax]) throws -> String {
    return try expandRegisterNativesDefault(in: context, parents: parents)
  }

  func expandCreateNativeMethods(parents: [any TypeDeclSyntax]) throws -> [String] {
    return try expandCreateNativeMethodsDefault(parents: parents)
  }
}

extension JvmTypeDeclSyntax {
  // Expand JVM class init function
  func expandPeer(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    let jniTypeName = typeName.replacingOccurrences(of: "_", with: "_1")

    var fqnEscaped = jniTypeName
    if let moduleName = moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let decl =
"""
\( (isMainActorIsolated ?? false) ? "@MainActor" : "")
@_cdecl("Java_\(fqnEscaped)_\(jniTypeName)_1class_1init")
public func \(typeName)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {    
  \(try expandRegisterNatives(in: context, parents: []))
}
"""
    return ["\(raw: decl)"]
  }
  
  // Expand members
  func expandMembersDefault(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
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
  func fqn(with parents: [any TypeDeclSyntax]) -> String {
    parents.isEmpty ? typeName : parents.map{$0.typeName}.joined(separator: ".") + "." + typeName
  }

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
  func expandJavaClassDeclDefault(in context: some MacroExpansionContext) -> String {
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
  func expandCreateNativeMethodsDefault(parents: [any TypeDeclSyntax]) throws -> [String] {
    let fqn = fqn(with: parents)
    let exportedDecls = exportedDecls

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

    return initNatives + deinitNatives + varNatives + funcNatives
  }

  func expandRegisterNativesDefault(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax] = []) throws -> String {
    let fqn = parents.isEmpty ? typeName : parents.map{$0.typeName}.joined(separator: ".") + "." + typeName

    let natives = try expandCreateNativeMethods(parents: parents)

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

  \(try exportedDecls.typeDecls
    .compactMap { $0 as? (any JvmTypeDeclSyntax) }
    .map { try $0.expandRegisterNatives(in: context, parents: parents + [self]) }
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
