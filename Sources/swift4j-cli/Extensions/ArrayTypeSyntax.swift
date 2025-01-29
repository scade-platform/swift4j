import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension ArrayTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    return element.map(with: &ctx, primitivesAsObjects: primitivesAsObjects) + "[]"
  }
}
