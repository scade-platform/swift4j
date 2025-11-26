import SwiftSyntax


extension VariableDeclSyntax: MemberDeclSyntax {
  public struct VarDecl {
    public let name: String
    public let type: TypeSyntax
    public let initialized: Bool
    public let readonly: Bool
    public let computed: Bool

    public var capitalizedName: String {
      name.first!.uppercased() + name.dropFirst()
    }
  }

  public var decls: [VarDecl] {
    bindings.compactMap {
      guard let name = $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
        return nil
      }

      guard let type = $0.typeAnnotation?.type else {
        return nil
      }

      let hasComputedGet: Bool
      let hasComputedSet: Bool

      if let accessorBlock = $0.accessorBlock {
        hasComputedGet = accessorBlock.hasGetter
        hasComputedSet = accessorBlock.hasSetter && (accessorVisibility("set") != .private)
      } else {
        hasComputedGet = false
        hasComputedSet = false
      }

      return VarDecl(name: name,
                     type: type,
                     initialized: $0.initializer != nil || $0.accessorBlock != nil,
                     readonly: bindingSpecifier.tokenKind == .keyword(.let) || (hasComputedGet && !hasComputedSet),
                     computed: hasComputedGet)
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

  func accessorVisibility(_ acc: String) -> Visibility? {
    for mod in modifiers {
      if let modDetail = mod.detail?.detail.tokenKind, modDetail == .identifier(acc) {
        if let visibility = Visibility(rawValue: mod.name.text) {
          return visibility
        }
      }
    }
    return nil
  }
}


fileprivate extension AccessorBlockSyntax {
  var hasSetter: Bool {
    guard case .accessors(let accessorDecls) = self.accessors else {
      return false
    }

    return accessorDecls.contains{ $0.accessorSpecifier.tokenKind == .keyword(.set) }
  }

  var hasGetter: Bool {
    switch accessors {
      case .accessors(let accessorDecls):
        return accessorDecls.contains{ $0.accessorSpecifier.tokenKind == .keyword(.get) }
      case .getter:
        return true
    }
  }
}
