import SwiftSyntax


extension ClassDeclSyntax: TypeDeclSyntax {
  public var typeName: String { name.text }
}



