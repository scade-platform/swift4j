import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions



extension FunctionTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let retType = returnClause.type.map(with: &ctx, primitivesAsObjects: true)

    var funcInterfaceFqn = javaFunctionalInterface.split(separator: ".")
    var funcType = funcInterfaceFqn.popLast() ?? ""

    if funcType != "" {
      if funcInterfaceFqn.count > 0 {
        ctx.imports.insert(javaFunctionalInterface)
      }

      var paramTypes = parameters.map{ $0.type.map(with: &ctx, primitivesAsObjects: true) }

      if !isVoid {
        paramTypes.append(retType)
      }

      funcType += "<\(paramTypes.joined(separator: ", "))>"
    }

    return String(funcType)
  }
}
