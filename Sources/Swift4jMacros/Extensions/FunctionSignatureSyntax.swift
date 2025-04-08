import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension FunctionSignatureSyntax {
  func jniParams() throws -> [String] {
    try parameterClause.parameters.map{ try $0.type.jniSignature() }
  }

  func paramsMapping() throws -> MappingRetType {
    let mapping = try parameterClause.parameters
      .reduce(into: (mapped: [String](), stmts: [String](), post: [MappingRetType.PostFunc]())) {
        let mapping = try $1.fromJava()

        $0.mapped.append(mapping.mapped)
        $0.stmts.append(contentsOf: mapping.stmts)

        if let post = mapping.post {
          $0.post.append(post)
        }
      }

    let post: MappingRetType.PostFunc?
    if let head = mapping.post.first {      
      post = mapping.post.dropFirst().reduce(head) { pre, cur in
        { cur(pre($0)) }
      }
    } else {
      post = nil
    }

    return MappingRetType(mapped: mapping.mapped.joined(separator: ","),
                          stmts: mapping.stmts,
                          post: post)
  }
}
