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
    let params = initDecl.signature.paramsMapping(with: &ctx)

    let callParams = params.map { $0.name }.joined(separator: ", ")
    let paramDecls = params.map { "\($0.type) \($0.name)" }.joined(separator: ", ")

    return
"""
  public \(className)(\(paramDecls)) {
    this(\(className).init\(index)(\(callParams)));
  }
  private static native long init\(index)(\(paramDecls));
"""
  }
}
