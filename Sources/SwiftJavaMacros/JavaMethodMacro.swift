import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxExtensions

public struct JavaMethodMacro { 
  enum Error: Swift.Error { case message(String) }
}


// MARK: + PeerMacro

extension JavaMethodMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    
    guard declaration.is(FunctionDeclSyntax.self) || declaration.is(InitializerDeclSyntax.self) else {
      throw JavaMacrosError.message("Macros can be only applied to a function or to an initializer")
    }

    return []
  }
}
