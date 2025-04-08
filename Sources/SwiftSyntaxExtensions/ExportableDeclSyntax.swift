import SwiftSyntax


public protocol ExportableDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
  var modifiers: DeclModifierListSyntax { get }
}

public enum Visibility: String {
  case `private`
  case `internal`
  case `public`
  case `open`
}

extension ExportableDeclSyntax {
  public var visibility: Visibility {
    for mod in modifiers {
      if let visibility = Visibility(rawValue: mod.name.text) {
        return visibility
      }
    }
    return .internal
  }

  public var isExported: Bool {
    switch visibility {
    case .private:
      return false
    default:
      return findAttributes(name: "nonjvm").isEmpty
    }
  }

  public var parentDecl: (any TypeDeclSyntax)? {
    guard let parent = parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self) else { return nil }
    return parent as? any TypeDeclSyntax
  }

  public func findAttributes(name: String) -> [AttributeListSyntax.Element] {
    return attributes.findAttributes{$0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == name}
  }
}




