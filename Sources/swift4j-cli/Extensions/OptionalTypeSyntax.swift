import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

extension OptionalTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let wrappedMap = wrappedType.map(with: &ctx, primitivesAsObjects: true)

    switch ctx.settings.language {
      case .java:
        ctx.imports.insert("org.jetbrains.annotations.*")
        return "@Nullable \(wrappedMap)"
      case .kotlin:
        return "\(wrappedMap)?"
    }

  }
  

}
