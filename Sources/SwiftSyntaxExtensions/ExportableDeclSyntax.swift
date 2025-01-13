import SwiftSyntax


public protocol ExportableDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
}


extension ExportableDeclSyntax {
  public var isExported: Bool { !hasAttribute(name: "nonjvm") }


  public var parentDecl: (any TypeDeclSyntax)? {
    guard let parent = self.parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self) else { return nil }
    return parent as? any TypeDeclSyntax
  }

  public func hasAttribute(name: String) -> Bool {
    attributes.hasAttribute(name: name)
  }
}


fileprivate extension AttributeListSyntax {
  func hasAttribute(name: String) -> Bool {
    self.contains {
      switch $0 {
      case .attribute(let attr):
        return attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == name
      case .ifConfigDecl(let decl):
        return decl.clauses.contains { clause in
          clause.elements?.as(AttributeListSyntax.self)?.hasAttribute(name: name) ?? false
        }
      }
    }
  }
}




