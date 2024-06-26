import SwiftSyntax


public protocol AttributedDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
}


extension AttributedDeclSyntax {
  public func hasAttribute(name: String) -> Bool {
    self.attributes.contains {
      guard case .attribute(let attr) = $0,
            let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
              return false
            }
      return attrName == name
    }
  }
}


extension ClassDeclSyntax: AttributedDeclSyntax {}
extension FunctionDeclSyntax: AttributedDeclSyntax {}
