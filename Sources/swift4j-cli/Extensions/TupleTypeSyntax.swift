import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

extension TupleTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    if elements.count == 1 {
      return elements.first!.type.map(with: &ctx, primitivesAsObjects: primitivesAsObjects)
    }

    //TODO: add error processing
    return ""
  }
}

