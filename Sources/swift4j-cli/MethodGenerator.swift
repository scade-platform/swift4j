import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class MethodGenerator {
  typealias Context = ProxyGenerator.Context

  private let funcDecl: FunctionDeclSyntax
  private let className: String

  var name: String { funcDecl.name.text }

  init(_ funcDecl: FunctionDeclSyntax, className: String) {
    self.funcDecl = funcDecl
    self.className = className
  }

  func generate(with ctx: inout Context) -> String {
    let params = funcDecl.signature.paramsMapping(with: &ctx)
    let retType = funcDecl.signature.returnClause?.type.map(with: &ctx) ?? "void"

    let callParams = (funcDecl.isStatic ? [] : ["_ptr"]) + params.map{$0.name}

    var call = (funcDecl.isStatic ? className : "this") +  ".\(name)Impl(\(callParams.joined(separator: ", ")))"
    call = funcDecl.signature.returnClause != nil ? "return \(call)" : call

    let paramDecls = params.map {"\($0.type) \($0.name)"}
    let paramDeclsImpl = (funcDecl.isStatic ? [] : ["long ptr"]) + paramDecls

    let modifiers = funcDecl.isStatic ? "static" : ""

    let throwsClause = funcDecl.isThrowing ? " throws Exception" : ""


    return
"""
  public \(modifiers) \(retType) \(name)(\(paramDecls.joined(separator: ", "))) \(throwsClause) {
    \(call);
  }
  private \(modifiers) native \(retType) \(name)Impl(\(paramDeclsImpl.joined(separator: ", "))) \(throwsClause);
"""
  }
}
