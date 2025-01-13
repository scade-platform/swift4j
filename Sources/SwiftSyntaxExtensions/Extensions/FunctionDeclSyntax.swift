import SwiftSyntax


extension FunctionDeclSyntax: ExportableDeclSyntax {
  public var isStatic: Bool {
    modifiers.contains {
      $0.name.text == "static"
    }
  }
}


