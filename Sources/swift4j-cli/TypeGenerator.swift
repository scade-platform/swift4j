import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


protocol TypeGeneratorProtocol {
  var name: String { get }

  var isRefType: Bool { get }

  func generate(with ctx: inout ProxyGenerator.Context) -> String
}


extension TypeGeneratorProtocol {
  var isRefType: Bool { return true }
}


class TypeGenerator<T: TypeDeclSyntax>: SyntaxVisitor {
  typealias Context = ProxyGenerator.Context

  let typeDecl: T
  let settings: ProxyGenerator.GeneratorSettings

  var nestedTypeGens: [any TypeGeneratorProtocol] = []

  var name: String { typeDecl.typeName }

  var nested: Bool { typeDecl.parentDecl != nil }

  init(_ typeDecl: T, settings: ProxyGenerator.GeneratorSettings) {
    self.typeDecl = typeDecl
    self.settings = settings

    super.init(viewMode: .fixedUp)

    walk(typeDecl)
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hashValue != typeDecl.hashValue && node.isExported {
      nestedTypeGens.append(ClassGenerator(node, settings: settings))
      return .skipChildren
    }
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hashValue != typeDecl.hashValue && node.isExported {
      nestedTypeGens.append(EnumGenerator(node, settings: settings))
      return .skipChildren
    }
    return .visitChildren
  }
}
