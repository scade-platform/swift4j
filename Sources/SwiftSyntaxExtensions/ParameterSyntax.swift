import SwiftSyntax

public protocol ParameterSyntax {
  var name: String? { get }

  var passedName: String? { get }

  var type: TypeSyntax { get }
}


extension FunctionParameterSyntax: ParameterSyntax {
  public var name: String? {
    if case .identifier(let name) = (secondName ?? firstName).tokenKind {
      return name
    }

    if let elements = parent?.as(FunctionParameterListSyntax.self) {
      for (i, p) in elements.enumerated() {
        if p == self {
          return "_\(i)"
        }
      }
    }
    //throw JvmMacrosError.message("Unsupported function parameter syntax")
    return nil
  }

  public var passedName: String? {
    guard case .identifier(let firstName) = firstName.tokenKind else {
      return nil
    }

    return firstName
  }
}

extension EnumCaseParameterSyntax: ParameterSyntax {
  public var name: String? {
    if let name = (secondName ?? firstName), case .identifier(let name) = name.tokenKind {
      return name
    }

    if let elements = parent?.as(EnumCaseParameterListSyntax.self) {
      for (i, p) in elements.enumerated() {
        if p == self {
          return "_\(i)"
        }
      }
    }

    //throw JvmMacrosError.message("Unsupported function parameter syntax")
    return nil
  }

  public var passedName: String? {
    guard case .identifier(let firstName) = firstName?.tokenKind else {
      return nil
    }

    return firstName
  }
}




