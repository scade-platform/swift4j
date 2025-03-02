import SwiftSyntax


extension VariableDeclSyntax: ExportableDeclSyntax {
  public struct VarDecl {
    public let name: String
    public let type: TypeSyntax
    public let initialized: Bool
  }

  public var decls: [VarDecl] {
    bindings.compactMap {
      guard let name = $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
        return nil
      }

      guard let type = $0.typeAnnotation?.type else {
        return nil
      }

      return VarDecl(name: name, type: type, initialized: $0.initializer != nil)
    }
  }

  public var isStatic: Bool {
    modifiers.contains {
      $0.name.text == "static"
    }
  }

  public var isReadonly: Bool {    
    return bindingSpecifier.tokenKind == .keyword(.let)
  }
}
