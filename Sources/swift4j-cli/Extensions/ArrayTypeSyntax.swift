import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


extension ArrayTypeSyntax: MappableTypeSyntax {
  private static let primitives: Set<String> = ["Boolean", "Long", "Int", "Short", "Byte", "Float", "Double"]

  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let elementMap = element.map(with: &ctx, primitivesAsObjects: primitivesAsObjects)
    switch ctx.settings.language {
      case .java:
        return elementMap + "[]"

      case .kotlin:
        if ArrayTypeSyntax.primitives.contains(elementMap) {
          return "\(elementMap.prefix(1).uppercased() + elementMap.dropFirst())Array"
        } else {
          return "Array<\(elementMap)>"
        }
    }

  }
}
