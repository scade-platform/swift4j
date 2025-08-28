import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension VariableDeclSyntax {
  private var defaultParamTypes: [String] {
    ["UnsafeMutablePointer<JNIEnv>"] + (isStatic ? ["JavaClass?"] : ["JavaObject?", "JavaLong"])
  }

  private var defaultClosureParams: [String] {
    ["_", "_"] + (isStatic ? [] : ["ptr"])
  }

  func bridgings(typeDecl: any JvmTypeDeclSyntax) throws -> [(javaName: String, bridgeName: String, sig: String)] {
    let _self = isStatic ? "" : "J"

    return try decls.flatMap {
      let jniType = try $0.type.jniSignature()
      var decls = [(
        javaName: "get\($0.name.capitalized)Impl",
        bridgeName: "\($0.name)_get_jni",
        sig: "(\(_self))\(jniType)"
      )]

      if !isReadonly {
        decls.append((
          javaName: "set\($0.name.capitalized)Impl",
          bridgeName: "\($0.name)_set_jni",
          sig: "(\(_self)\(jniType))V"
        ))
      }

      if isObservable && typeDecl.isObservable {
        decls.append((
            javaName: "get\($0.name.capitalized)WithObservationTrackingImpl",
            bridgeName: "\($0.name)_get_with_observation_tracking_jni",
            sig: "(\(_self)Ljava/lang/Runnable;)\(jniType)"
          ))
      }

      return decls
    }
  }

  func makeBridgingDecls(typeDecl: any JvmTypeDeclSyntax) throws -> String {
    try decls.flatMap {
      [try makeBridgingGetter(for: $0, in: typeDecl)]
        + (isReadonly ? [] : [try makeBridgingSetter(for: $0, in: typeDecl)])
        + (isObservable && typeDecl.isObservable ? [try makeBridgingGetterWithObservationTracking(for: $0, in: typeDecl)] : [])
    }.joined(separator: "\n")
  }

  //MARK: - Setter

  private func makeBridgingSetter(for varDecl: VarDecl, in typeDecl: any JvmTypeDeclSyntax) throws -> String {
    let _self = isStatic ? "\(typeDecl.typeName).self" : typeDecl.selfExpr

    let bridgeName = "\(varDecl.name)_set_jni"
    let paramTypes = defaultParamTypes + [try varDecl.type.jniType()]
    let returnType = "Void"
    let varParamName = "value"
    let closureParams = defaultClosureParams + [varParamName]
    
    let mapping = try varDecl.type.fromJava(varParamName)
    let body =
"""
\(mapping.stmts.joined(separator: "\n  "))
\(_self).\(varDecl.name) = \(mapping.mapped)
"""

    return makeDecl(bridgeName,
                    in: typeDecl,
                    paramTypes: paramTypes,
                    returnType: returnType,
                    closureParams: closureParams,
                    body: body,
                    isReturning: false)
  }

  //MARK: - Getter

  private func makeBridgingGetter(for varDecl: VarDecl, in typeDecl: any JvmTypeDeclSyntax) throws -> String {
    let _self = isStatic ? "\(typeDecl.typeName).self" : typeDecl.selfExpr

    let bridgeName = "\(varDecl.name)_get_jni"
    let paramTypes = defaultParamTypes
    let returnType = try varDecl.type.jniType()
    let closureParams = defaultClosureParams
    
    let mapping = try varDecl.type.toJava("\(_self).\(varDecl.name)")
    let body =
"""
\(mapping.stmts.joined(separator: "\n  "))
return \(mapping.mapped)
"""

    return makeDecl(bridgeName,
                    in: typeDecl,
                    paramTypes: paramTypes,
                    returnType: returnType,
                    closureParams: closureParams,
                    body: body,
                    isReturning: true)
  }

  //MARK: - Getter + Observation

  private func makeBridgingGetterWithObservationTracking(for varDecl: VarDecl, in typeDecl: any JvmTypeDeclSyntax) throws -> String {
    let _self = isStatic ? "\(typeDecl.typeName).self" : typeDecl.selfExpr

    let bridgeName = "\(varDecl.name)_get_with_observation_tracking_jni"
    let paramTypes = defaultParamTypes + ["JavaObject"]
    let returnType = try varDecl.type.jniType()
    let closureParams = defaultClosureParams + ["onChange"]

    let mapping = try varDecl.type.toJava("\(_self).\(varDecl.name)")
    let body =
"""
let _onChange = JObject(onChange) 
return withObservationTracking {
  \(mapping.stmts.joined(separator: "\n  "))
  return \(mapping.mapped)
} onChange: {
  _onChange.call(method: "run")
}
"""

    return makeDecl(bridgeName,
                    in: typeDecl,
                    paramTypes: paramTypes,
                    returnType: returnType,
                    closureParams: closureParams,
                    body: body,
                    isReturning: true)
  }

  private func makeDecl(_ bridgeName: String,
                        in typeDecl: any JvmTypeDeclSyntax,
                        paramTypes: [String],
                        returnType: String,
                        closureParams: [String],
                        body: String,
                        isReturning: Bool) -> String {
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in    
  \(wrapBody(body, in: typeDecl))  
}
"""
  }

}
