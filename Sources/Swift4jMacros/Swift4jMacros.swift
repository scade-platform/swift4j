import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxExtensions
import SwiftCompilerPlugin

@main
struct SwiftJavaPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JvmMacro.self,
        JvmExportedMacro.self,
        NonjvmMacro.self
    ]
}


public struct NonjvmMacro : PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    try JvmMacro.assert(context: context)
    return []
  }
}
