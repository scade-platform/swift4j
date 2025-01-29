import SwiftSyntax
import SwiftSyntaxMacros

import SwiftSyntaxExtensions


protocol JvmTypeDeclSyntax: TypeDeclSyntax {

  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax]

  func expandPeer(in context: some MacroExpansionContext) throws -> [DeclSyntax]
}
