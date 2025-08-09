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
    let _self = isStatic
      ? "\(typeDecl.typeName).self"
      : typeDecl.selfExpr

    return try decls.flatMap {
      [try makeBridgingGetter(for: $0, selfExpr: _self)]
        + (isReadonly ? [] : [try makeBridgingSetter(for: $0, selfExpr: _self)])
        + (isObservable && typeDecl.isObservable ? [try makeBridgingGetterWithObservationTracking(for: $0, selfExpr: _self)] : [])
    }.joined(separator: "\n")
  }

  private func makeBridgingSetter(for varDecl: VarDecl, selfExpr: String) throws -> String {
    let bridgeName = "\(varDecl.name)_set_jni"
    let paramTypes = defaultParamTypes + [try varDecl.type.jniType()]
    let returnType = "Void"
    let varParamName = "value"
    let closureParams = defaultClosureParams + [varParamName]
    
    let mapping = try varDecl.type.fromJava(varParamName)

    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in  
  \(mapping.stmts.joined(separator: "\n  "))
  \(selfExpr).\(varDecl.name) = \(mapping.mapped)
}
"""
  }

  private func makeBridgingGetter(for varDecl: VarDecl, selfExpr: String) throws -> String {
    let bridgeName = "\(varDecl.name)_get_jni"
    let paramTypes = defaultParamTypes
    let returnType = try varDecl.type.jniType()
    let closureParams = defaultClosureParams
    
    let mapping = try varDecl.type.toJava("\(selfExpr).\(varDecl.name)")

    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in    
  \(mapping.stmts.joined(separator: "\n  "))
  return \(mapping.mapped)
}
"""
  }

  private func makeBridgingGetterWithObservationTracking(for varDecl: VarDecl, selfExpr: String) throws -> String {
    let bridgeName = "\(varDecl.name)_get_with_observation_tracking_jni"
    let paramTypes = defaultParamTypes + ["JavaObject"]
    let returnType = try varDecl.type.jniType()
    let closureParams = defaultClosureParams + ["onChange"]

    let mapping = try varDecl.type.toJava("\(selfExpr).\(varDecl.name)")

    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in    
  let _onChange = JObject(onChange) 
  return withObservationTracking {
    \(mapping.stmts.joined(separator: "\n  "))
    return \(mapping.mapped)
  } onChange: {
    _onChange.call(method: "run")
  }
}
"""
  }
}
