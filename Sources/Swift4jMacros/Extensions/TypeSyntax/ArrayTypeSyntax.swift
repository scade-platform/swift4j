import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension ArrayTypeSyntax: JvmMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    return try "[" + element.jniSignature(primitivesAsObjects: primitivesAsObjects)
  }

  func jniType(primitivesAsObjects: Bool) -> String { "JavaObject?" }

  func jniTypeDefaultValue(primitivesAsObjects: Bool) throws -> String { "[]" }

  func toJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    return MappingRetType(mapped: "\(expr).toJavaObject()")
  }

  func fromJava(_ expr: String, primitivesAsObjects: Bool, optional: Bool) throws -> MappingRetType {
    let _type = _syntaxNode.trimmedDescription + (optional ? "?" : "")
    let _expr = "\(_type).fromJavaObject(\(expr))"

    guard let paramName = typedEntityName else {
      return MappingRetType(mapped: _expr)
    }

    return MappingRetType(mapped: "_\(paramName)", stmts: ["let _\(paramName) = \(_expr)"])
  }
}
