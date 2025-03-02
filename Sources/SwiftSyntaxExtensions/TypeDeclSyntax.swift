import SwiftSyntax


public protocol TypeDeclSyntax: ExportableDeclSyntax, DeclGroupSyntax, SyntaxHashable {
  var name: TokenSyntax { get }

  var initializers: [InitializerDeclSyntax] { get }
}


public extension TypeDeclSyntax {
  var initializers: [InitializerDeclSyntax] { [] }
}


public extension TypeDeclSyntax {
  typealias ExportedDecls = (initDecls: [InitializerDeclSyntax],
                             varDecls: [VariableDeclSyntax],
                             funcDecls: [FunctionDeclSyntax],
                             typeDecls: [any TypeDeclSyntax])

  var typeName: String { name.text }

  var isExported: Bool { !exportAttributes.isEmpty }

  var exportAttributes: AttributeListSyntax {
    let attrs = findAttributes(name: "jvm")
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

  var exportedDecls: ExportedDecls {
    var decls: ExportedDecls = (initializers, [], [], [])

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

  var exportedInitializers: [InitializerDeclSyntax] {
    memberBlock.members.compactMap {
      guard let initDecl = $0.decl.as(InitializerDeclSyntax.self), initDecl.isExported else {
        return nil
      }
      return initDecl
    }
  }

  func createInitializer(parameters: [FunctionParameterSyntax]) -> InitializerDeclSyntax {
    let paramsClause = FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax(parameters))
    return InitializerDeclSyntax(signature: FunctionSignatureSyntax(parameterClause: paramsClause))
  }
}



extension ClassDeclSyntax: TypeDeclSyntax {
  public var initializers: [InitializerDeclSyntax] {
    let exported = exportedInitializers

    if exported.isEmpty {
      return [createInitializer(parameters: [])]

    } else {
      return exported
    }
  }
}

extension StructDeclSyntax: TypeDeclSyntax {
  public var initializers: [InitializerDeclSyntax] {
    let exported = exportedInitializers

    if exported.isEmpty {
      let varDecls: [VariableDeclSyntax] = memberBlock.members.compactMap {
        guard let varDecl = $0.decl.as(VariableDeclSyntax.self) else { return nil }
        return varDecl
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
      return exported
    }
  }
}

extension EnumDeclSyntax: TypeDeclSyntax { }

