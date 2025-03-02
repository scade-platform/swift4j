import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class VarGenerator {
  typealias Context = ProxyGenerator.Context

  private let varDecl: VariableDeclSyntax
  private let className: String

  private var modifiers: String {
    varDecl.isStatic ? "static" : ""
  }

  private var callee: String {
    varDecl.isStatic ? className : "this"
  }

  init(_ varDecl: VariableDeclSyntax, className: String) {
    self.varDecl = varDecl
    self.className = className
  }

  func generate(with ctx: inout Context) -> String {
    return varDecl.decls.map {
"""
\(generateGetter(from: $0, with: &ctx))
\(varDecl.isReadonly ? "" : generateSetter(from: $0, with: &ctx))
"""
    }.joined(separator: "\n")
  }

  private func generateGetter(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "get\(decl.name.capitalized)"
    let retType = decl.type.map(with: &ctx)

    let implParam: String,
        implParamDecl: String

    if varDecl.isStatic {
      implParam = ""
      implParamDecl = ""

    } else {
      implParam = "_ptr"
      implParamDecl = "long ptr"
    }

    return
"""
  public \(modifiers) \(retType) \(name)() {
    return \(callee).\(name)Impl(\(implParam));
  }
  private \(modifiers) native \(retType) \(name)Impl(\(implParamDecl));
"""
  }

  private func generateSetter(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "set\(decl.name.capitalized)"
    let valType = decl.type.map(with: &ctx)

    let implParam: String,
        implParamDecl: String

    if varDecl.isStatic {
      implParam = "value"
      implParamDecl = "\(valType) value"

    } else {
      implParam = "_ptr, value"
      implParamDecl = "long ptr, \(valType) value"
    }

    return
"""
  public \(modifiers) void \(name)(\(valType) value) {
    \(callee).\(name)Impl(\(implParam));
  }
  private \(modifiers) native void \(name)Impl(\(implParamDecl));
"""
  }
}

