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

  func makeBridgingDecls(classDecl: ClassDeclSyntax) throws -> String {
    let paramTypes = try
      ["UnsafeMutablePointer<JNIEnv>"]
        + (isStatic ? ["JavaClass?"] : ["JavaObject?", "JavaLong"])
        + signature.parameterClause.parameters.map{ try $0.type.jniType() }

    let returnType = try signature.returnClause?.type.jniType() ?? "Void"

    let closureParams = ["_", "_"]
        + (isStatic ? [] : ["ptr"])
        +  signature.parameterClause.parameters.map{ $0.name }

    let _self = isStatic
      ? "\(classDecl.name.text).self"
      : "unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<\(classDecl.name.text)>.self).takeUnretainedValue()"

    let (call, stmts) = try makeBridgingFunctionBody()

    return
"""
fileprivate typealias \(name.text)_jni_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(name.text)_jni: \(name.text)_jni_t = {\(closureParams.joined(separator: ", ")) in
  let _self = \(_self)
  \(stmts.joined(separator: "\n  "))
  \(call)
}
"""
  }

  func makeBridgingFunctionBody() throws -> (call: String, stmts: [String]) {
    let mapping = try signature.paramsMapping()
    var call = "_self.\(name.text)(\(mapping.0))"

    if signature.effectSpecifiers?.asyncSpecifier != nil {
      call = "Task { await \(call) }"
    }

    var stmts = mapping.1

    if let retType = signature.returnClause?.type {
      let ret_mapping = try retType.toJava(call)

      call = "return \(ret_mapping.0)"
      stmts.append(contentsOf: ret_mapping.1)
    }

    return (call, stmts)
  }
}
