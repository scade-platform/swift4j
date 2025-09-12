import SwiftSyntax


extension TypeDeclSyntax {
  public var isObservable: Bool { hasAttribute("Observable") }
}

extension VariableDeclSyntax {
  public var isObservable: Bool {
    !isStatic && !hasAttribute("ObservationIgnored")
  }
}

extension VariableDeclSyntax.VarDecl {
  public func observable(_ varDecl: VariableDeclSyntax) -> Bool {
    !computed && varDecl.isObservable
  }
}
