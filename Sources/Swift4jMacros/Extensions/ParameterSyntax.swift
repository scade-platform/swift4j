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


extension ParameterSyntax {
  var name: String {
    get throws {
      guard let name = self.name else {
        throw JvmMacrosError.message("Unsupported function parameter syntax")
      }
      return name
    }
  }

  func toJava() throws -> MappingRetType {
    try type.toJava(name)
  }

  func fromJava() throws -> MappingRetType {
    let mapping = try type.fromJava(name)

    if let passedName = passedName {
      return MappingRetType(mapped: "\(passedName): \(mapping.mapped)",
                            stmts: mapping.stmts,
                            post: mapping.post)
    } else {
      return mapping
    }
  }
}
