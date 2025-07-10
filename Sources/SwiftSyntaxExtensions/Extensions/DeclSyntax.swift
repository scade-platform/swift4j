import SwiftSyntax

public extension DeclSyntaxProtocol {
  var parentDeclSyntax: (any DeclSyntaxProtocol)? {
    self.parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self)
  }
}

