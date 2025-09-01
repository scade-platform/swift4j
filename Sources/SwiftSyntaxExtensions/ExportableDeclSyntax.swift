import SwiftSyntax


public protocol ExportableDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
  var modifiers: DeclModifierListSyntax { get }

  // Optional to represent 'unknown' for members where isolation is implied by the isolation on the class level
  // when the member is not explicitely marked as nonisolated
  var isMainActorIsolated: Bool? { get }
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
      return !hasAttribute("nonjvm")
    }
  }

  public var parentDecl: (any TypeDeclSyntax)? {
    guard let parent = parent?.parent?.parent?.parent?.asProtocol(DeclSyntaxProtocol.self) else { return nil }
    return parent as? any TypeDeclSyntax
  }

  public func hasAttribute(_ name: String) -> Bool {
    return !attributes.findAttributes(name).isEmpty
  }
}




