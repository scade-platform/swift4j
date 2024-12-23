import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension ClassDeclSyntax {

  typealias ExportedDecls = (hasInitDecls: Bool,
                             initDecls: [InitializerDeclSyntax],
                             funcDecls: [FunctionDeclSyntax])

  var exportedDecls: ExportedDecls {
    var decls: ExportedDecls = (false, [], [])

    for m in memberBlock.members {
      if let initDecl = m.decl.as(InitializerDeclSyntax.self) {
        decls.hasInitDecls = true
        if initDecl.isExported {
          decls.initDecls.append(initDecl)
        }
      } else if let funcDecl = m.decl.as(FunctionDeclSyntax.self), funcDecl.isExported {
        decls.funcDecls.append(funcDecl)
      }
    }

    return decls
  }

  func moduleName(from context: some SwiftSyntaxMacros.MacroExpansionContext) -> String? {
    guard let segments = context.location(of: self)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }
}
