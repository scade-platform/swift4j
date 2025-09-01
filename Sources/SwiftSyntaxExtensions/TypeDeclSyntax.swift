import SwiftSyntax


public protocol TypeDeclSyntax: ExportableDeclSyntax, DeclGroupSyntax, SyntaxHashable {
  var name: TokenSyntax { get }

  var exportedInitializers: [InitializerDeclSyntax] { get }
}


public extension TypeDeclSyntax {
  var exportedInitializers: [InitializerDeclSyntax] { [] }
}


public extension TypeDeclSyntax {
  typealias ExportedDecls = (initDecls: [InitializerDeclSyntax],
                             varDecls: [VariableDeclSyntax],
                             funcDecls: [FunctionDeclSyntax],
                             typeDecls: [any TypeDeclSyntax])

  var typeName: String { name.text }

  var isExported: Bool { !exportAttributes.isEmpty }

  var isMainActorIsolated: Bool? { hasAttribute("MainActor") }

  var exportAttributes: AttributeListSyntax {
    let attrs = attributes.findAttributes("jvm")
    return AttributeListSyntax(attrs)
  }

  var parents: [any TypeDeclSyntax] {
    var parents: [any TypeDeclSyntax] = []
    var cur: any TypeDeclSyntax = self

    while let parent = cur.parentDecl {
      parents.append(parent)
      cur = parent
    }

    return parents.reversed()
  }

  var initializers: [InitializerDeclSyntax] {
    memberBlock.members.compactMap {
      guard let initDecl = $0.decl.as(InitializerDeclSyntax.self) else { return nil }
      return initDecl
    }
  }

  var exportedDecls: ExportedDecls {
    var decls: ExportedDecls = (exportedInitializers, [], [], [])

    guard isExported else { return decls }

    for m in memberBlock.members {
      if let decl = m.decl.as(VariableDeclSyntax.self), decl.isExported {
        decls.varDecls.append(decl)

      } else if let decl = m.decl.as(FunctionDeclSyntax.self), decl.isExported {
        decls.funcDecls.append(decl)

      } else if let decl = m.decl.as(ClassDeclSyntax.self), decl.isExported {
        decls.typeDecls.append(decl)

      } else if let decl = m.decl.as(StructDeclSyntax.self), decl.isExported {
        decls.typeDecls.append(decl)

      } else if let decl = m.decl.as(EnumDeclSyntax.self), decl.isExported {
        decls.typeDecls.append(decl)
      }
    }

    return decls
  }

  func createInitializer(parameters: [FunctionParameterSyntax]) -> InitializerDeclSyntax {
    let paramsClause = FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax(parameters))
    return InitializerDeclSyntax(signature: FunctionSignatureSyntax(parameterClause: paramsClause))
  }
}



extension ClassDeclSyntax: TypeDeclSyntax {
  public var exportedInitializers: [InitializerDeclSyntax] {
    let initializers = initializers

    if initializers.isEmpty {
      return [createInitializer(parameters: [])]

    } else {
      return initializers.filter { $0.isExported }
    }
  }
}

extension StructDeclSyntax: TypeDeclSyntax {
  public var exportedInitializers: [InitializerDeclSyntax] {
    let initializers = initializers

    if initializers.isEmpty {
      var varDecls: [VariableDeclSyntax] = []

      for member in memberBlock.members {
        if let varDecl = member.decl.as(VariableDeclSyntax.self) {
          if varDecl.isExported {
            varDecls.append(varDecl)
          } else if (varDecl.bindings.contains {$0.initializer == nil}) {
            // If there is a non-exported and non-initialized var in the struct,
            // do not generate any default init as it would need to expose such var
            return []
          }
        }
      }

      let params = varDecls.flatMap {
        $0.decls
      }.filter {
        !$0.initialized
      }.map {
        let name = TokenSyntax(.identifier($0.name), presence: .present)
        return FunctionParameterSyntax(firstName: name, type: $0.type)
      }

      return [createInitializer(parameters: params)]

    } else {
      return initializers.filter { $0.isExported }
    }
  }
}

extension EnumDeclSyntax: TypeDeclSyntax { }

