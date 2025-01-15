import SwiftSyntax

extension AttributeListSyntax {
  func findAttributes(cond: (AttributeSyntax) -> Bool) -> [AttributeListSyntax.Element] {
    let attrMap: (AttributeListSyntax.Element) -> AttributeListSyntax.Element? = {
      switch $0 {
      case .attribute(let attr):
        guard cond(attr) else { return nil }
        return $0

      case .ifConfigDecl(let decl):
        let clauseMap: (IfConfigClauseListSyntax.Element) -> IfConfigClauseListSyntax.Element? = { clause in
          guard let attrs = clause.elements?.as(AttributeListSyntax.self)?.findAttributes(cond: cond), !attrs.isEmpty else { return nil }
          return IfConfigClauseSyntax(
            poundKeyword: clause.poundKeyword,
            condition: clause.condition,
            elements: .attributes(AttributeListSyntax(attrs)))
        }
        let clauses = decl.clauses.compactMap(clauseMap)
        return !clauses.isEmpty ? .ifConfigDecl(IfConfigDeclSyntax(clauses: IfConfigClauseListSyntax(clauses))) : nil
      }
    }
    return self.compactMap(attrMap)
  }
}
