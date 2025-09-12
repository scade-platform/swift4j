import Foundation

import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class ProxyGenerator: SyntaxVisitor {
  struct Context {
    var package: String
    var settings: GeneratorSettings
    var imports: Set<String> = []
  }
  
  struct GeneratorSettings {
    enum Language {
      case java(version: Int)
      case kotlin
    }

    let language: Language
  }

  private let package: String
  private let settings: GeneratorSettings

  private var typeGens: [TypeGeneratorProtocol] = []

  init(package: String, javaVersion: Int) {
    self.package = package
    self.settings = GeneratorSettings(language: .java(version: javaVersion))

    super.init(viewMode: .fixedUp)
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported  {
      typeGens.append(ClassGenerator(node, settings: settings))
    }
    return .skipChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported  {
      typeGens.append(ClassGenerator(node, settings: settings))
    }
    return .skipChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported  {
      typeGens.append(EnumGenerator(node, settings: settings))
    }
    return .skipChildren
  }

  func run(path: String) throws -> [(classname: String, content: String)] {
    let url = URL(fileURLWithPath: path)
    let source = try String(contentsOf: url, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)

    walk(sourceFile)

    return typeGens.map { ($0.name, generate($0)) }
  }

  func generate(_ typeGen: TypeGeneratorProtocol) -> String {
    var ctx = Context(package: package, settings: settings)

    let typeDecl = typeGen.generate(with: &ctx)

    var imports = [String](ctx.imports)

    if typeGen.isRefType {
      if case .java(let version) = settings.language, version >= 9 {
        imports.append("java.lang.ref.Cleaner")
      }
    }

    return
"""
package \(self.package);

import io.scade.swift4j.SwiftPtr; 

\(imports.map{"import \($0);"}.joined(separator: "\n"))

\(typeDecl)
"""
  }

  func generatePackageClass() -> String {
"""
package \(self.package);

"""
  }
}
