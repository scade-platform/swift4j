import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions

extension OptionalTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    ctx.imports.insert("org.jetbrains.annotations.*")
    return "@Nullable \(wrappedType.map(with: &ctx, primitivesAsObjects: true))"
  }
  

}
