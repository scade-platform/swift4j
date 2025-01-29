import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension FunctionSignatureSyntax {
  func paramsMapping(with ctx: inout ProxyGenerator.Context) -> [(name: String, type: String)] {
    parameterClause.parameters.map {
      (name: ($0.secondName ?? $0.firstName).text, type: $0.type.map(with: &ctx))
    }
  }
}
