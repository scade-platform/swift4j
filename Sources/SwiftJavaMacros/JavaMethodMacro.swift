import SwiftSyntax
import SwiftSyntaxMacros


public struct JavaMethodMacro { }

extension JavaMethodMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

    return []
  }
}