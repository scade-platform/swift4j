import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension InitializerDeclSyntax {
  func jniSignature() throws -> String {
    try "(\(signature.jniSignatures().joined()))J"
  }

  func makeBridgingDecls(typeDecl: any JvmTypeDeclSyntax, index: Int) throws -> String {
    let name = "init\(index)"
    let paramTypes = try ["UnsafeMutablePointer<JNIEnv>", "JavaClass?"] + signature.jniTypes()
    let closureParams = try ["_", "_"] + signature.jniParams()

    let mapping = try signature.paramsMapping()

    var call = try typeDecl.expandInitCall(params: mapping.mapped, throwing: isThrowing, initName: "init")
    if isThrowing {
      call =
"""
  do { 
    \(call) 
  } catch { 
    jni.throwException(error)
    return 0
  }
"""
    }

    let body =
"""
  \(mapping.stmts.joined(separator: "\n  "))  
  \(call)
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
