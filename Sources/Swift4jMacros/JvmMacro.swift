import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


public struct JvmMacro {
  static func classDecl(from decl: some SwiftSyntax.SyntaxProtocol) throws -> ClassDeclSyntax {
    return try decl.assert(as: ClassDeclSyntax.self, "Macros can be only applied to a class declaration")
  }

  static func addPlatformConditions(_ node: SwiftSyntax.AttributeSyntax, syntax: String) -> String {
    switch node.arguments {
    case .argumentList(let exprs):
      let conds = exprs.compactMap {
          guard let platform = $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else {
            return nil
          }
          return "os(\(platform))"
        }.joined(separator: " || ")
      
      if conds != "" {
        return
"""
#if \(conds)
\(syntax)
#endif
"""
      }
      return syntax

    default:
      return syntax
    }
  }
}





