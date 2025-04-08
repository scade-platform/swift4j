import SwiftSyntax

public extension DeclSyntaxProtocol {
  public var parentDeclSyntax: (any DeclSyntaxProtocol)? {
    self.parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self)
  }
}

