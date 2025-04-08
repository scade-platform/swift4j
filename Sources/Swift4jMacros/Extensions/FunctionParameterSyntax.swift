import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


struct MappingRetType {
  typealias PostFunc = (String) -> String

  let mapped: String
  let stmts: [String]
  let post: PostFunc?

  init(mapped: String, stmts: [String] = [], post: PostFunc? = nil) {
    self.mapped = mapped
    self.stmts = stmts
    self.post = post
  }

  /*
  func join(post: PostFunc?) -> PostFunc? {
    guard let post = post else { return self.post }
    guard let pre_post = self.post else { return post }
    
    return { post(pre_post($0)) }
  }
  */
}


extension FunctionParameterSyntax {
  var name: String { (secondName ?? firstName).text }

  func toJava() throws -> MappingRetType {
    try type.toJava(name)
  }

  func fromJava() throws -> MappingRetType {
    let mapping = try type.fromJava(name)

    switch firstName.tokenKind {
    case .identifier(name):
      return MappingRetType(mapped: "\(name): \(mapping.mapped)",
                            stmts: mapping.stmts,
                            post: mapping.post)

    case .wildcard:
      return mapping

    default:
      throw JvmMacrosError.message("Unsupported function parameter syntax")
    }

  }
}
