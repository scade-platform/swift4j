import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension IdentifierTypeSyntax: JvmMappedTypeSyntax {
  var isVoid: Bool {
    name.text == "Void"
  }

  var isPrimitive: Bool {
    switch name.text {
    case "Void", "Bool", "Int", "Int64", "Int32", "Int16", "Int8", "Float", "Double": true
    default: false
    }
  }

  func jniSignature(primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "Void": "V"
    case "Bool": primitivesAsObjects ? "Ljava/lang/Boolean;" : "Z"
    case "Int", "Int64": primitivesAsObjects ? "Ljava/lang/Long;" : "J"
    case "Int32": primitivesAsObjects ? "Ljava/lang/Integer;" : "I"
    case "Int16": primitivesAsObjects ? "Ljava/lang/Short;" : "S"
    case "Int8": primitivesAsObjects ? "Ljava/lang/Byte;" : "B"
    case "Float": primitivesAsObjects ? "Ljava/lang/Float;" : "F"
    case "Double": primitivesAsObjects ? "Ljava/lang/Double;" : "D"
    case "String": "Ljava/lang/String;"
    default: "L\\(\(name.text).javaName);" //"\\(\(name.text).javaSignature)"
    }
  }

  func jniType(primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "Void": "void"
    case "Bool": primitivesAsObjects ? "JavaObject" : "JavaBoolean"
    case "Int", "Int64": primitivesAsObjects ? "JavaObject" : "JavaLong"
    case "Int32": primitivesAsObjects ? "JavaObject" : "JavaInt"
    case "Int16": primitivesAsObjects ? "JavaObject" : "JavaShort"
    case "Int8": primitivesAsObjects ? "JavaObject" : "JavaByte"
    case "Float": primitivesAsObjects ? "JavaObject" : "JavaFloat"
    case "Double": primitivesAsObjects ? "JavaObject" : "JavaDouble"
    default: "JavaObject?"
    }
  }

  func jniTypeDefaultValue(primitivesAsObjects: Bool) throws -> String {
    if !isPrimitive || primitivesAsObjects {
      return "nil"
    } else {
      return "\(jniType(primitivesAsObjects: primitivesAsObjects))()"
    }
  }

  func toJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType {
    if isPrimitive && !primitivesAsObjects {
      return MappingRetType(mapped: name.text == "Int" ? "JavaLong(\(expr))" : expr)
    } else {
      return MappingRetType(mapped: "\(expr).toJavaObject()")
    }
  }

  func fromJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType {
    if isPrimitive && !primitivesAsObjects {
      return MappingRetType(mapped: name.text == "Int" ? "Int(\(expr))" : expr)
    } else if isInOut {
      return MappingRetType(mapped: "&$0.pointee") {
"""
\(name.text).fromJavaObject(\(expr)) {
  \($0)
}
"""
      }
    } else {
      let _expr = "\(name.text).fromJavaObject(\(expr))"

      guard let paramName = typedEntityName else {
        return MappingRetType(mapped: _expr)
      }

      return MappingRetType(mapped: "_\(paramName)",
                            stmts: ["let _\(paramName) = \(_expr)"])
    }
  }
}

