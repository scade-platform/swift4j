import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension EnumCaseElementSyntax {
  var jniName: String {
    name.text + "_jni"
  }

  func jniName(of param: ParameterSyntax) throws -> String {
    try name.text + "_" + param.name + "_jni"
  }

  func jniSignature() throws -> String {
    try "(\(jniSignatures().joined()))J"
  }

  func makeBridgingDecls(typeDecl: any JvmTypeDeclSyntax) throws -> String {
    let name = name.text

    let paramTypes = try ["UnsafeMutablePointer<JNIEnv>", "JavaClass?"] + jniTypes()
    let closureParams = try ["_", "_"] + jniParams()
    let mapping = try paramsMapping()
    
    let call = !parameters.isEmpty
      ? try typeDecl.expandInitCall(params: mapping.mapped, throwing: false, initName: name)
      :
"""
  struct Ptr {
    nonisolated(unsafe)    
    private static var lock = os_unfair_lock_s()
    
    nonisolated(unsafe)
    private static let _ptr: UnsafeMutablePointer<\(typeDecl.name.text)> = {
      let ptr = UnsafeMutablePointer<\(typeDecl.name.text)>.allocate(capacity: 1)
      ptr.initialize(to: .\(name))
      return ptr      
    }()

    static var value: JavaLong {
      os_unfair_lock_lock(&lock)
      defer { os_unfair_lock_unlock(&lock) }
      return JavaLong(Int(bitPattern: _ptr))
    } 
  }
  return Ptr.value
"""

    let body =
"""
  \(mapping.stmts.joined(separator: "\n  "))  
  \(call)
"""

    return
"""
fileprivate typealias \(jniName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> JavaLong
fileprivate static let \(jniName): \(jniName)_t = {\(closureParams.joined(separator: ", ")) in
\(mapping.post == nil ? body : mapping.post!(body) )
}
"""
  }

  func makeBridgingGetterDecls(typeDecl: any JvmTypeDeclSyntax) throws -> String? {
    guard parameters.count > 0 else {
      return nil
    }

    let paramsMatchExpr = Array(repeating: "_", count: parameters.count)
    return try parameters.enumerated().map {i, param in
      var caseMatchExpr: [String] = paramsMatchExpr
      caseMatchExpr[i] = "let val"
      return try makeBridgingGetter(for: param, in: typeDecl, caseMatchExpr: caseMatchExpr.joined(separator: ", "))
    }.joined(separator: "\n")
  }


  private func makeBridgingGetter(for param: ParameterSyntax, in typeDecl: any JvmTypeDeclSyntax, caseMatchExpr: String) throws -> String {
    let caseName = name.text
    let bridgeName = try jniName(of: param)
    let params = "UnsafeMutablePointer<JNIEnv>, JavaObject?, JavaLong"
    let returnType = try param.type.jniType()

    let mapping = try param.type.toJava("val")
    let body =
"""
\(mapping.stmts.joined(separator: "\n  "))
return \(mapping.mapped)
"""

    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(params)) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {_, _, ptr in    
  switch(\(typeDecl.selfExpr)){
  case .\(caseName)(\(caseMatchExpr)):
    \(body)
  default:
    fatalError("Expected .\(caseName) case")
  }
}
"""
  }
}
