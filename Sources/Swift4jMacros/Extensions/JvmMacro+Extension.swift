import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension JvmMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                               providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                               conformingTo protocols: [SwiftSyntax.TypeSyntax],
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    let extSyntax =
"""
extension \(type.trimmed): JObjectRepresentable { }
"""
    return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: extSyntax))]
  }

}
