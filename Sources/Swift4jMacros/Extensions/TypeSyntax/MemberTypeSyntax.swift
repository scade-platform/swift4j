//
//  MemberTypeSyntax.swift
//  Java
//
//  Created by Grigory Markin on 24.07.26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension MemberTypeSyntax: JvmMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    "L\\(\(description).javaName);"
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

  func fromJava(_ expr: String, primitivesAsObjects: Bool, optional: Bool) throws -> MappingRetType {
    if isInOut {
      return MappingRetType(mapped: "&$0.pointee") {
"""
\(name.text).fromJavaObject(\(expr)) {
  \($0)
}
"""
      }
    } else {
      let _type = _syntaxNode.trimmedDescription + (optional ? "?" : "")
      let _expr = "\(_type).fromJavaObject(\(expr))"

      guard let paramName = typedEntityName else {
        return MappingRetType(mapped: _expr)
      }

      return MappingRetType(mapped: "_\(paramName)",
                            stmts: ["let _\(paramName) = \(_expr)"])
    }
  }

}
