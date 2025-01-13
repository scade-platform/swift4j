import SwiftSyntax


public extension AttributeSyntax {
  var attachedDecl: DeclSyntaxProtocol? {
    self.parent?.as(AttributeListSyntax.self)?.parent?.asProtocol(DeclSyntaxProtocol.self)
  }
}
