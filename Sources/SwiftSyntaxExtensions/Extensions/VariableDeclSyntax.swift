import SwiftSyntax


extension VariableDeclSyntax: MemberDeclSyntax {
  public struct VarDecl {
    public let name: String
    public let type: TypeSyntax
    public let initialized: Bool
    public let readonly: Bool
  }

  public var decls: [VarDecl] {
    bindings.compactMap {
      guard let name = $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
        return nil
      }

      guard let type = $0.typeAnnotation?.type else {
        return nil
      }

      return VarDecl(name: name,
                     type: type,
                     initialized: $0.initializer != nil || $0.accessorBlock != nil,
                     readonly: bindingSpecifier.tokenKind == .keyword(.let) || !($0.accessorBlock?.hasSetter ?? true))
    }
  }

  public var isAsync: Bool {
    ///TODO: implement for computed properties
    return false
  }

  public var isThrowing: Bool {
    ///TODO: implement for computed properties
    return false
  }
}


fileprivate extension AccessorBlockSyntax {
  var hasSetter: Bool {
    guard case .accessors(let accessorDecls) = self.accessors else {
      return false
    }

    return accessorDecls.contains{ $0.accessorSpecifier.tokenKind == .keyword(.set) }

  }
}
