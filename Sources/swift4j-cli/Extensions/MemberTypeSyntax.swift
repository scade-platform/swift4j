import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

extension MemberTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    description
  }

}
