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
    try wrappedType.toJava(expr, primitivesAsObjects: true)
  }
  
  func fromJava(_ expr: String, primitivesAsObjects: Bool, optional: Bool) throws -> MappingRetType {
    try wrappedType.fromJava(expr, primitivesAsObjects: true, optional: true)
  }

}
