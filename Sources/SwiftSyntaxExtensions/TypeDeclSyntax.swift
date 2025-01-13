import SwiftSyntax


public protocol TypeDeclSyntax: ExportableDeclSyntax, DeclGroupSyntax, SyntaxHashable {
  var typeName: String { get }
}

public extension TypeDeclSyntax {
  typealias ExportedDecls = (hasInitDecls: Bool,
                             initDecls: [InitializerDeclSyntax],
                             funcDecls: [FunctionDeclSyntax],
                             typeDecls: [any TypeDeclSyntax])

  var isExported: Bool { hasAttribute(name: "jvm") }

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
