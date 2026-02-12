import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


extension TupleTypeSyntax: JvmMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    if elements.count == 1 {
      return try elements.first!.type.jniSignature(primitivesAsObjects: primitivesAsObjects)
    }

    throw JvmMacrosError.message("Unsupported type", self)
  }
  
  func jniType(primitivesAsObjects: Bool) throws -> String {
    if elements.count == 1 {
      return try elements.first!.type.jniType(primitivesAsObjects: primitivesAsObjects)
    }

    throw JvmMacrosError.message("Unsupported type", self)
  }
  
  func jniTypeDefaultValue(primitivesAsObjects: Bool) throws -> String {
    if elements.count == 1 {
      return try elements.first!.type.jniTypeDefaultValue(primitivesAsObjects: primitivesAsObjects)
    }

    throw JvmMacrosError.message("Unsupported type", self)
  }
  
  func toJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    if elements.count == 1 {
      return try elements.first!.type.toJava(expr, primitivesAsObjects: primitivesAsObjects)
    }

    throw JvmMacrosError.message("Unsupported type", self)
  }
  
  func fromJava(_ expr: String, primitivesAsObjects: Bool, optional: Bool) throws -> MappingRetType {
    if elements.count == 1 {
      return try elements.first!.type.fromJava(expr, primitivesAsObjects: primitivesAsObjects, optional: optional)
    }

    throw JvmMacrosError.message("Unsupported type", self)
  }
}

