import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension TypeSyntax {
  func map() throws -> any JvmMappedTypeSyntax {
    if let typeSyntax = self.as(IdentifierTypeSyntax.self) {
      return typeSyntax

    } else if let typeSyntax = self.as(FunctionTypeSyntax.self) {
      return typeSyntax

    } else if let typeSyntax = self.as(ArrayTypeSyntax.self) {
      return typeSyntax

    } else if let attributedTypeSyntax = self.as(AttributedTypeSyntax.self) {
      return try attributedTypeSyntax.baseType.map()
    }


    throw JvmMacrosError.message("Unsupported type", self)
  }

  func jniSignature(primitivesAsObjects: Bool = false) throws -> String {
    try map().jniSignature(primitivesAsObjects: primitivesAsObjects)
  }

  func jniType(primitivesAsObjects: Bool = false ) throws -> String {
    try map().jniType(primitivesAsObjects: primitivesAsObjects)
  }

  func toJava(_ expr: String, primitivesAsObjects: Bool = false) throws -> MappingRetType {
    try map().toJava(expr, primitivesAsObjects: primitivesAsObjects)
  }

  func fromJava(_ expr: String, primitivesAsObjects: Bool = false) throws -> MappingRetType {
    try map().fromJava(expr, primitivesAsObjects: primitivesAsObjects)
  }
}


protocol JvmMappedTypeSyntax: SyntaxProtocol {
  func jniSignature(primitivesAsObjects: Bool) throws -> String
  func jniType(primitivesAsObjects: Bool) throws -> String

  func toJava(_: String, primitivesAsObjects: Bool) throws -> MappingRetType
  func fromJava(_: String, primitivesAsObjects: Bool) throws -> MappingRetType
}


extension JvmMappedTypeSyntax {
  var typedEntityName: String? {
    if let funcParam = parent?.as(FunctionParameterSyntax.self) {
      return funcParam.name

    } else if let attrFuncParam = parent?.as(AttributedTypeSyntax.self),
                let funcParam = attrFuncParam.parent?.as(FunctionParameterSyntax.self) {
      return funcParam.name
    }
    return nil
  }
}
