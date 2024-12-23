import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension FunctionSignatureSyntax {
  func jniParams() throws -> [String] {
    try parameterClause.parameters.map{ try $0.type.jniSignature() }
  }

  func paramsMapping() throws -> MappingRetType {
    let mapping = try parameterClause.parameters
      .reduce(into: ([String](), [String]())) {
        let (param, stmts) = try $1.fromJava()
        $0.0.append(param)
        $0.1.append(contentsOf: stmts)
      }
    return (mapping.0.joined(separator: ","), mapping.1)
  }
}
