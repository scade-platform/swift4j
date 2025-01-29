import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class EnumGenerator: TypeGenerator<EnumDeclSyntax> {
  
}


extension EnumGenerator: TypeGeneratorProtocol {
  var isRefType: Bool { return false }

  func generate(with ctx: inout ProxyGenerator.Context) -> String {
    
    return
"""
public enum \(name) {
  \(typeDecl.cases().joined(separator: ", "));
}
"""
  }
  
}
