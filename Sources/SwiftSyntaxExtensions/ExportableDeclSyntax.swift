import SwiftSyntax


public protocol ExportableDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
}


extension ExportableDeclSyntax {
  public var isExported: Bool { findAttributes(name: "nonjvm").isEmpty }

  public var parentDecl: (any TypeDeclSyntax)? {
    guard let parent = self.parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self) else { return nil }
    return parent as? any TypeDeclSyntax
  }

  public func findAttributes(name: String) -> [AttributeListSyntax.Element] {
    return attributes.findAttributes{$0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == name}
  }
}




