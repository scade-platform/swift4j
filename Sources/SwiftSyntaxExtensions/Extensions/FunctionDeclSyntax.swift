import SwiftSyntax


extension FunctionDeclSyntax: MemberDeclSyntax {  
  public var isAsync: Bool {
    signature.effectSpecifiers?.asyncSpecifier != nil
  }

  public var isThrowing: Bool {
    signature.effectSpecifiers?.throwsClause != nil
  }
}


