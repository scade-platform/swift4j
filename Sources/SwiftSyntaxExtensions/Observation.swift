import SwiftSyntax


extension TypeDeclSyntax {
  public var isObservable: Bool { hasAttribute("Observable") }
}

extension VariableDeclSyntax {
  public var isObservable: Bool { !hasAttribute("ObservationIgnored") }
}

