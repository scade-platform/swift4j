import SwiftSyntax

public extension FunctionTypeSyntax {
  var isVoid: Bool {
    guard let retType = returnClause.type.as(IdentifierTypeSyntax.self)?.name.text else {
      return false
    }
    return retType == "Void"
  }
  
  

  var javaFunctionalInterface: String {
    switch parameters.count {
    case 0 where !isVoid: "java.util.function.Supplier"
    case 1: !isVoid ? "java.util.function.Function" : "java.util.function.Consumer"
    case 2: !isVoid ? "java.util.function.BiFunction" : "java.util.function.BiConsumer"
    default: "" //TODO: create own interface
    }
  }
}
