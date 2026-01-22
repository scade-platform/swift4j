import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension IdentifierTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let mappedTypeName = Self.map(name: name.text, with: &ctx, primitivesAsObjects: primitivesAsObjects)

    if let genericArgs = genericArgumentClause?.arguments, !genericArgs.isEmpty {
      let mappedGenericArgs = genericArgs.map{ $0.argument.map(with: &ctx, primitivesAsObjects: true) }
      return "\(mappedTypeName)<\(mappedGenericArgs.joined(separator: ", "))>"
    } else {
      return mappedTypeName
    }

  }

  ///TODO: add suport for more flexibel mapping using some sort of external definitions
  private static func map(name: String, with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    switch name {
        // Primitives
      case "Bool": primitivesAsObjects ? "Boolean" : "boolean"
      case "Int", "Int64": primitivesAsObjects ? "Long" : "long"
      case "Int32": primitivesAsObjects ? "Integer" : "int"
      case "Int16": primitivesAsObjects ? "Short" : "short"
      case "Int8": primitivesAsObjects ? "Byte" : "byte"
      case "Float": primitivesAsObjects ? "Float" : "float"
      case "Double": primitivesAsObjects ? "Double" : "double"

        // Standard
      case "Void": "void"
      case "String": "String"

      case "Error": {
        ctx.imports.insert("io.scade.swift4j.SwiftError")
        return "SwiftError"
      }()

        // Foundation
      case "Date": {
        ctx.imports.insert("java.util.Date")
        return "Date"
      }()
      case "Result": {
        ctx.imports.insert("io.scade.swift4j.Result")
        return "Result"
      }()

      default: name
    }
  }
}
