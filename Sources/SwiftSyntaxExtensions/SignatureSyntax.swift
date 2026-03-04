import SwiftSyntax

public protocol SignatureSyntax {
  var parameters: [ParameterSyntax] { get }
}


extension FunctionSignatureSyntax: SignatureSyntax {
  public var parameters: [any ParameterSyntax] {
    parameterClause.parameters.map {$0}
  }
}


extension EnumCaseElementSyntax: SignatureSyntax {
  public var parameters: [any ParameterSyntax] {
    parameterClause?.parameters.map{ $0 } ?? []
  }
  

}
