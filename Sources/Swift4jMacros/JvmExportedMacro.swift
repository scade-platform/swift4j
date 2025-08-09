import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


public struct JvmExportedMacro {

}



// MARK: - + MemberMacro

extension JvmExportedMacro: PeerMacro {
  public static func expansion(of node: AttributeSyntax,
                               providingPeersOf declaration: some DeclSyntaxProtocol,
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    guard let enclosingDeclType = context.enclosingDeclType, enclosingDeclType.isExported,
          let decl = declaration.as(VariableDeclSyntax.self) else {

      throw JvmMacrosError.message(
        "@jvm_exported macro can only be applied to a variable declaration inside an @jvm exported type"
      )
    }

    let syntax = context.executeAndWarnIfFails(at: decl) {
      return try decl.makeBridgingDecls(typeDecl: enclosingDeclType)
    }


    //return try typeDecl(from: declaration).expandMembers(in: context)

    return ["\(raw: syntax ?? "")"]
  }
}
