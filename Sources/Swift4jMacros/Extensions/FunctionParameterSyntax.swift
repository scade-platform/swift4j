import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


typealias MappingRetType = (mapped: String, stmts: [String])


extension FunctionParameterSyntax {
  var name: String { (secondName ?? firstName).text }

  func toJava() throws -> MappingRetType {
    try type.toJava(name)
  }
  func fromJava() throws -> MappingRetType {
    let (mapped, stmts) = try type.fromJava(name)

    switch firstName.tokenKind {
    case .identifier(name):
      return ("\(name): \(mapped)", stmts)
    case .wildcard:
      return (mapped, stmts)
    default:
      throw JvmMacrosError.message("Unsupported function parameter syntax")
    }

  }
}
