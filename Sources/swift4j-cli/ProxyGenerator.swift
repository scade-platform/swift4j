import Foundation

import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class ProxyGenerator: SyntaxVisitor {
  struct Context {
    let package: String
    let settings: Settings

    var imports: Set<String> = []
  }
  
  struct Settings {
    enum Language {
      case java(version: Int)
      case kotlin
    }

    let language: Language
  }

  private let package: String
  private let settings: Settings

  private var typeGens: [TypeGeneratorProtocol] = []

  init(package: String, javaVersion: Int) {
    self.package = package
    self.settings = Settings(language: .java(version: javaVersion))

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

  func run(path: String) throws -> [(filename: String, source: String)] {
    let url = URL(fileURLWithPath: path)
    let source = try String(contentsOf: url, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)

    walk(sourceFile)

    return typeGens.map { generate($0) }
  }

  func generate(_ typeGen: TypeGeneratorProtocol) -> (filename: String, source: String) {
    var ctx = Context(package: package, settings: settings)

    let typeProxy = typeGen.generate(with: &ctx)

    var imports = [String](ctx.imports)

    if typeGen.isRefType {
      if case .java(let version) = settings.language, version >= 9 {
        imports.append("java.lang.ref.Cleaner")
      }
    }

    return typeProxy.generate(in: package, with: imports)
  }

  func generatePackageClass() -> String {
"""
package \(self.package);

"""
  }
}


extension ProxyGenerator.Context {
  mutating func with<R>(language: ProxyGenerator.Settings.Language, _ body: (inout ProxyGenerator.Context) -> R) -> R {
    var tmpCtx = ProxyGenerator.Context(package: self.package,
                                        settings: .init(language: language),
                                        imports: self.imports)
    let res = body(&tmpCtx)
    self.imports = tmpCtx.imports

    return res
  }
}
