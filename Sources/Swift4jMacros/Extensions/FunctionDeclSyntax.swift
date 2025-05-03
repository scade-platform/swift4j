import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension FunctionDeclSyntax {
  func jniSignature() throws -> String {
    let params = try (isStatic ? [] : ["J"]) + signature.jniParams()
    return "(\(params.joined()))\(try signature.returnClause?.type.jniSignature() ?? "V")"
  }

  func makeBridgingDecls(typeDecl: any JvmTypeDeclSyntax) throws -> String {
    let paramTypes = try
      ["UnsafeMutablePointer<JNIEnv>"]
        + (isStatic ? ["JavaClass?"] : ["JavaObject?", "JavaLong"])
        + signature.parameterClause.parameters.map{ try $0.type.jniType() }

    let returnType = try signature.returnClause?.type.jniType() ?? "Void"

    let closureParams = ["_", "_"]
        + (isStatic ? [] : ["ptr"])
        +  signature.parameterClause.parameters.map{ $0.name }

    let _self = isStatic
      ? "\(typeDecl.typeName).self"
      : typeDecl.selfExpr

    return
"""
fileprivate typealias \(name.text)_jni_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(name.text)_jni: \(name.text)_jni_t = {\(closureParams.joined(separator: ", ")) in
\(try makeBridgingFunctionBody(selfExpr: _self))
}
"""
  }

  func makeBridgingFunctionBody(selfExpr: String) throws -> String {
    let mapping = try signature.paramsMapping()
    var call = "\(selfExpr).\(name.text)(\(mapping.mapped))"

    if isAsync {
      call = "await \(call)"
    }

    if isThrowing {
      call = "try \(call)"
    }

    var stmts = mapping.stmts
    var post = mapping.post

    if let retType = signature.returnClause?.type {
      let ret_mapping = try retType.toJava(call)

      call = "return \(ret_mapping.mapped)"
      stmts.append(contentsOf: ret_mapping.stmts)

      if let ret_post = ret_mapping.post {
        post = (post == nil) ? ret_post : { ret_post(post!($0)) }
      }
    }

    if isThrowing {
      call =
"""
  do { 
    \(call) 
  } catch { 
    jni.throwException(error) 
  }
"""
      if let retDefault = try signature.returnClause?.type.jniTypeDefaultValue() {
        call =
"""
  \(call)
  return \(retDefault)
"""
      }
    }

    if isAsync {
      call =
"""
  Task { 
    \(call)
  }
"""
    }


    let body =
"""
  \(stmts.joined(separator: "\n  "))
  \(call)
"""

    return (post == nil) ? body : post!(body)
  }
}
