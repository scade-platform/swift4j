import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension InitializerDeclSyntax {
  func jniSignature() throws -> String {
    try "(\(signature.jniParams().joined()))J"
  }

  func makeBridgingDecls(typeDecl: any TypeDeclSyntax, index: Int) throws -> String {
    let name = "init\(index)"
    let paramTypes = try ["UnsafeMutablePointer<JNIEnv>", "JavaClass?"] + signature.parameterClause.parameters.map{ try $0.type.jniType() }
    let closureParams = ["_", "_"] + signature.parameterClause.parameters.map{ $0.name }

    let (params, stmts) = try signature.paramsMapping()

    return
"""
fileprivate typealias \(name)_jni_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> JavaLong
fileprivate static let \(name)_jni: \(name)_jni_t = {\(closureParams.joined(separator: ", ")) in
  \(stmts.joined(separator: "\n  "))
  let obj = \(typeDecl.name.text)(\(params))
  return obj._cast()
}
"""
  }
}
