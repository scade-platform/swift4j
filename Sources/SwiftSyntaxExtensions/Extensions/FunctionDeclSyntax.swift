import SwiftSyntax


extension FunctionDeclSyntax: MemberDeclSyntax {
  public var isVoid: Bool {
    signature.returnClause == nil
  }
  
  public var isAsync: Bool {
    signature.effectSpecifiers?.asyncSpecifier != nil
  }

  public var isThrowing: Bool {
    signature.effectSpecifiers?.throwsClause != nil
  }
}


