import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension OptionalTypeSyntax: JvmMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    return try wrappedType.jniSignature(primitivesAsObjects: true)
  }
  
  func jniType(primitivesAsObjects: Bool) throws -> String {
    return "JavaObject?"
  }
  
  func toJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    return MappingRetType(mapped: "\(expr).toJavaObject()")
  }
  
  func fromJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    return MappingRetType(mapped: "\(_syntaxNode.trimmedDescription).fromJavaObject(\(expr))")
  }

}
