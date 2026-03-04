import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension SignatureSyntax {
  func paramsMapping(with ctx: inout ProxyGenerator.Context) -> [(name: String, type: String)] {
    parameters.map { $0.map(with: &ctx) }
  }
}


extension ParameterSyntax {
  func map(with ctx: inout ProxyGenerator.Context) -> (name: String, type: String) {
    (name: name ?? "", type: type.map(with: &ctx))
  }
}
