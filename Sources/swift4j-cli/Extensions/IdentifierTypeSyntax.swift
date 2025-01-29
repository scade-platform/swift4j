import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension IdentifierTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "String": "String"
    case "Bool": primitivesAsObjects ? "Boolean" : "boolean"
    case "Int", "Int64": primitivesAsObjects ? "Long" : "long"
    case "Int32": primitivesAsObjects ? "Integer" : "int"
    case "Int16": primitivesAsObjects ? "Short" : "short"
    case "Int8": primitivesAsObjects ? "Byte" : "byte"
    case "Float": primitivesAsObjects ? "Float" : "float"
    case "Double": primitivesAsObjects ? "Double" : "double"
    case "Void": "void"
    default: name.text
    }
  }
}
