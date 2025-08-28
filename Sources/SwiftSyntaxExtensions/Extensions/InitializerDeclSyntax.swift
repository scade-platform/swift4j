import SwiftSyntax


extension InitializerDeclSyntax: MemberDeclSyntax {
  public var name: TokenSyntax { .identifier("init") }

  public var isVoid: Bool {
    true
  }

  public var isAsync: Bool {
    signature.effectSpecifiers?.asyncSpecifier != nil
  }

  public var isThrowing: Bool {
    signature.effectSpecifiers?.throwsClause != nil
  }
}
