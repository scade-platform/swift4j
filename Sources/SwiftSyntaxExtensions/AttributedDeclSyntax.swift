import SwiftSyntax


public protocol AttributedDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
}


extension AttributedDeclSyntax {
  public var isExported: Bool { !hasAttribute(name: "nonjvm") }

  public func hasAttribute(name: String) -> Bool {
    attributes.contains {
      guard case .attribute(let attr) = $0,
            let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
              return false
            }
      return attrName == name
    }
  }
}


extension ClassDeclSyntax: AttributedDeclSyntax {
  public var isExported: Bool { hasAttribute(name: "jvm") }
}

extension FunctionDeclSyntax: AttributedDeclSyntax {
  public var isStatic: Bool {
    modifiers.contains {
      $0.name.text == "static"
    }
  }
}

extension InitializerDeclSyntax: AttributedDeclSyntax {}
