import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


public struct JvmMacro {
  static func typeDecl(from decl: some DeclSyntaxProtocol) throws -> any JvmTypeDeclSyntax {
    if let classDecl = decl.as(ClassDeclSyntax.self) {
      return classDecl

    } else if let structDecl = decl.as(StructDeclSyntax.self) {
      return structDecl

    } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
      return enumDecl

    } else {
      throw JvmMacrosError.message("@jvm macro can only be applied to a class, struct or enum declaration")
    }
  }

  static func assert(context: some MacroExpansionContext) throws {
    if let enclosingDeclType = context.enclosingDeclType {
      if !enclosingDeclType.isExported {
        throw JvmMacrosError.message(
          "Enclosing type '\(enclosingDeclType.typeName)' is not exported. Add the @jvm attribute to the parent."
        )
      }
    }
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


// MARK: - + MemberMacro

extension JvmMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf declaration: some DeclGroupSyntax,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    try assert(context: context)

    return try typeDecl(from: declaration).expandMembers(in: context)
  }
}


// MARK: - + MemberAttributeMacro

extension JvmMacro: MemberAttributeMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                               providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {

    if let decl = member.as(VariableDeclSyntax.self), decl.isExported {
      return [AttributeSyntax(stringLiteral: "@jvm_exported")]
    }

    return []
  }
}


// MARK: - + PeerMacro

extension JvmMacro: PeerMacro {
  public static func expansion(of node: AttributeSyntax,
                               providingPeersOf declaration: some DeclSyntaxProtocol,
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    guard context.lexicalContext.isEmpty else {
      return []
    }

    return try typeDecl(from: declaration).expandPeer(in: context)
  }
}


// MARK: - + ExtensionMacro

extension JvmMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                               providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                               conformingTo protocols: [SwiftSyntax.TypeSyntax],
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    try assert(context: context)

    let extSyntax =
"""
extension \(type.trimmed): JObjectConvertible { }
"""
    return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: extSyntax))]
  }

}
