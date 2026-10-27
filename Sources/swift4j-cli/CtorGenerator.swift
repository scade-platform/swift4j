import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class CtorGenerator {
  private let initDecl: InitializerDeclSyntax
  private let className: String

  init(_ initDecl: InitializerDeclSyntax, className: String) {
    self.initDecl = initDecl
    self.className = className
  }

  func generate(with ctx: inout MethodGenerator.Context, index: Int) -> String {
    switch ctx.settings.language {
    case .java:
      return generateJava(with: &ctx, index: index)
    case .kotlin:
      return generateKotlin(with: &ctx, index: index)
    }
  }

  private func generateJava(with ctx: inout MethodGenerator.Context, index: Int) -> String {
    let params = initDecl.signature.paramsMapping(with: &ctx)

    let callParams = params.map { $0.name }.joined(separator: ", ")
    let paramDecls = params.map { "\($0.type) \($0.name)" }.joined(separator: ", ")
    
    let throwsClause = initDecl.isThrowing ? " throws Exception" : ""

    return
"""
  public \(className)(\(paramDecls)) \(throwsClause) {
    this(new SwiftPtr(\(className).init\(index)(\(callParams)), \(className)::deinit));
  }
  private static native long init\(index)(\(paramDecls));
"""
  }

  private func generateKotlin(with ctx: inout MethodGenerator.Context, index: Int) -> String {
    let params = initDecl.signature.paramsMapping(with: &ctx)
    let callParams = params.map { $0.name }.joined(separator: ", ")
    let paramDecls = params.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
    let throwsAnnotation = initDecl.isThrowing ? "  @Throws(Exception::class)\n" : ""

    return
"""
\(throwsAnnotation)  constructor(\(paramDecls)): this(SwiftPtr(init\(index)(\(callParams)), \(className)::deinit))
"""
  }

  func generateKotlinNativeInitializer(with ctx: inout MethodGenerator.Context, index: Int) -> String {
    let params = initDecl.signature.paramsMapping(with: &ctx)
    let paramDecls = params.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
    let throwsAnnotation = initDecl.isThrowing ? "  @Throws(Exception::class)\n" : ""

    return
"""
\(throwsAnnotation)  @JvmStatic
  private external fun init\(index)(\(paramDecls)): Long
"""
  }
}
