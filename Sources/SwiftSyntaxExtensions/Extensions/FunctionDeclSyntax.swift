import SwiftSyntax


extension FunctionDeclSyntax: ExportableDeclSyntax {
  public var isStatic: Bool {
    modifiers.contains {
      $0.name.text == "static"
    }
  }

  public var isAsync: Bool {
    signature.effectSpecifiers?.asyncSpecifier != nil
  }

  public var isThrowing: Bool {
    signature.effectSpecifiers?.throwsClause != nil
  }
}


