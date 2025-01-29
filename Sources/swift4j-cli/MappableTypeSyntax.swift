import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


protocol MappableTypeSyntax: TypeSyntaxProtocol {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String
}
