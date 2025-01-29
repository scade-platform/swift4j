import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension TypeSyntax {
  var supportedMappings: [any MappableTypeSyntax.Type] {[
    IdentifierTypeSyntax.self,
    FunctionTypeSyntax.self,
    ArrayTypeSyntax.self,
    AttributedTypeSyntax.self
  ]}

  func map() -> (any MappableTypeSyntax)? {
    for s in supportedMappings {
      if let typeSyntax = self.as(s) {
        return typeSyntax
      }
    }
    return nil
  }

  func map(with ctx: inout ProxyGenerator.Context) -> String {
    return map(with: &ctx, primitivesAsObjects: false)
  }

  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    return map()?.map(with: &ctx, primitivesAsObjects: primitivesAsObjects) ?? ""
  }
}


extension AttributedTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    return baseType.map(with: &ctx, primitivesAsObjects: primitivesAsObjects)
  }
}
