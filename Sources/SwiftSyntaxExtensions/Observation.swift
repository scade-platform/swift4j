import SwiftSyntax


extension TypeDeclSyntax {
  public var isObservable: Bool {
    !findAttributes(name: "Observable").isEmpty
  }
}

extension VariableDeclSyntax {
  public var isObservable: Bool {
    findAttributes(name: "ObservationIgnored").isEmpty
  }
}

