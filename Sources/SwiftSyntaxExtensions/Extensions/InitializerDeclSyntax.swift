import SwiftSyntax


extension InitializerDeclSyntax: ExportableDeclSyntax {
  public var name: TokenSyntax { .identifier("init") }
}
