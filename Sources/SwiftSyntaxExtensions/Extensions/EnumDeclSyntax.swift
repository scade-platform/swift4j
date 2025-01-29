import SwiftSyntax

public extension EnumDeclSyntax {

  func caseDecls() -> [EnumCaseElementSyntax] {
    self.memberBlock.members.flatMap { member in
      guard let elements = member.decl.as(EnumCaseDeclSyntax.self)?.elements else {
        return Array<EnumCaseElementSyntax>()
      }
      return Array<EnumCaseElementSyntax>(elements)
    }
  }

  func cases() -> [String] {
    caseDecls().map{
      $0.name.text
    }
  }

}
