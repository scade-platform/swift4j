import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class MethodGenerator {
  typealias Context = ProxyGenerator.Context

  private let funcDecl: FunctionDeclSyntax
  private let className: String

  var name: String { funcDecl.name.text }
  var isStatic: Bool { funcDecl.isStatic }

  init(_ funcDecl: FunctionDeclSyntax, className: String) {
    self.funcDecl = funcDecl
    self.className = className
  }

  func generate(with ctx: inout Context) -> String {
    switch ctx.settings.language {
    case .java:
      return generateJava(with: &ctx)
    case .kotlin:
      return generateKotlin(with: &ctx)
    }
  }

  private func generateJava(with ctx: inout Context) -> String {
    let params = funcDecl.signature.paramsMapping(with: &ctx)

    var retType = funcDecl.signature.returnClause?.type.map(with: &ctx) ?? (funcDecl.isAsync ? "Void" : "void")
    if funcDecl.isAsync {
      retType = "CompletableFuture<\(retType)>"
      ctx.imports.insert("java.util.concurrent.CompletableFuture")
    }

    let callParams = (funcDecl.isStatic ? [] : ["_ptr()"]) + params.map{$0.name}

    var call = (funcDecl.isStatic ? className : "this") +  ".\(name)Impl(\(callParams.joined(separator: ", ")))"
    call = funcDecl.isAsync || funcDecl.signature.returnClause != nil ? "return \(call)" : call

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

  private func generateKotlin(with ctx: inout Context) -> String {
    let params = funcDecl.signature.paramsMapping(with: &ctx)

    var retType = funcDecl.signature.returnClause?.type.map(with: &ctx) ?? (funcDecl.isAsync ? "Void" : "Unit")
    if funcDecl.isAsync {
      if retType == "Unit" {
        retType = "Void"
      }
      retType = "CompletableFuture<\(retType)>"
      ctx.imports.insert("java.util.concurrent.CompletableFuture")
    }

    let callParams = (funcDecl.isStatic ? [] : ["_ptr()"]) + params.map { $0.name }
    let invocation = "\(name)Impl(\(callParams.joined(separator: ", ")))"
    let call = funcDecl.isAsync || funcDecl.signature.returnClause != nil
      ? "return \(invocation)"
      : invocation

    let paramDecls = params.map { "\($0.name): \($0.type)" }
    let paramDeclsImpl = (funcDecl.isStatic ? [] : ["ptr: Long"]) + paramDecls
    let staticAnnotation = funcDecl.isStatic ? "@JvmStatic\n  " : ""
    let openModifier = funcDecl.isStatic ? "" : "open "
    let throwsAnnotation = funcDecl.isThrowing ? "@Throws(Exception::class)\n  " : ""

    return
"""
  \(staticAnnotation)\(throwsAnnotation)\(openModifier)fun \(name)(\(paramDecls.joined(separator: ", "))): \(retType) {
    \(call)
  }
  \(staticAnnotation)\(throwsAnnotation)private external fun \(name)Impl(\(paramDeclsImpl.joined(separator: ", "))): \(retType)
"""
  }
}
