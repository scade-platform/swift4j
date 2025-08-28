import SwiftSyntaxExtensions


extension MemberDeclSyntax {
  func wrapBody(_ body: String, in typeDecl: any JvmTypeDeclSyntax) -> String {
    if let isolated = isMainActorIsolated, !isolated {
      return body
    }

    if let parentIsolated = typeDecl.isMainActorIsolated, !parentIsolated {
      return body
    }

    return
"""
assert(Thread.isMainThread)
\(body)
"""
  }
}

