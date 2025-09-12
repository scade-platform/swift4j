import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension ArrayTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let elementMap = element.map(with: &ctx, primitivesAsObjects: primitivesAsObjects)
    switch ctx.settings.language {
      case .java:
        return elementMap + "[]"
      case .kotlin:
        return "Array<\(elementMap)>"
    }

  }
}
