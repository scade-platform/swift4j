import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension InitializerDeclSyntax {
  func jniSignature() throws -> String {
    try "(\(signature.jniParams().joined()))J"
  }

  func makeBridgingDecls(typeDecl: any JvmTypeDeclSyntax, index: Int) throws -> String {
    let name = "init\(index)"
    let paramTypes = try ["UnsafeMutablePointer<JNIEnv>", "JavaClass?"] + signature.parameterClause.parameters.map{ try $0.type.jniType() }
    let closureParams = ["_", "_"] + signature.parameterClause.parameters.map{ $0.name }

    let mapping = try signature.paramsMapping()

    let body =
"""
  \(mapping.stmts.joined(separator: "\n  "))
  \(typeDecl.expandInitCall(params: mapping.mapped))
"""

    return
"""
fileprivate typealias \(name)_jni_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> JavaLong
fileprivate static let \(name)_jni: \(name)_jni_t = {\(closureParams.joined(separator: ", ")) in
\(mapping.post == nil ? body : mapping.post!(body) )
}
"""
  }
}
