import SwiftSyntax


public protocol TypeDeclSyntax: ExportableDeclSyntax, DeclGroupSyntax, SyntaxHashable { }

public extension TypeDeclSyntax {
  typealias ExportedDecls = (hasInitDecls: Bool,
                             initDecls: [InitializerDeclSyntax],
                             funcDecls: [FunctionDeclSyntax],
                             typeDecls: [any TypeDeclSyntax])

  var typeName: String { exportName }

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
    var decls: ExportedDecls = (false, [], [], [])

    guard isExported else { return decls }

    for m in memberBlock.members {
      if let initDecl = m.decl.as(InitializerDeclSyntax.self) {
        decls.hasInitDecls = true
        if initDecl.isExported {
          decls.initDecls.append(initDecl)
        }

      } else if let funcDecl = m.decl.as(FunctionDeclSyntax.self), funcDecl.isExported {
        decls.funcDecls.append(funcDecl)

      } else if let classDecl = m.decl.as(ClassDeclSyntax.self), classDecl.isExported {
        decls.typeDecls.append(classDecl)
      }
    }

    return decls
  }
}



extension ClassDeclSyntax: TypeDeclSyntax { }

extension EnumDeclSyntax: TypeDeclSyntax { }
