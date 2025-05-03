import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension OptionalTypeSyntax: JvmMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    try wrappedType.jniSignature(primitivesAsObjects: true)
  }
  
  func jniType(primitivesAsObjects: Bool) throws -> String {
    "JavaObject?"
  }

  func jniTypeDefaultValue(primitivesAsObjects: Bool) throws -> String {
    "nil"
  }

  func toJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    MappingRetType(mapped: "\(expr).toJavaObject()")
  }
  
  func fromJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    MappingRetType(mapped: "\(_syntaxNode.trimmedDescription).fromJavaObject(\(expr))")
  }

}
