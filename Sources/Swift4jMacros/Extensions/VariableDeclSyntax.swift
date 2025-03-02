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

  var bridgings: [(javaName: String, bridgeName: String, sig: String)] {
    get throws {
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

        return decls
      }
    }
  }

  func makeBridgingDecls(typeDecl: any TypeDeclSyntax) throws -> String {
    let _self = isStatic
      ? "\(typeDecl.typeName).self"
      : "_cast(ptr)"

    return try decls.flatMap {
      [try makeBridgingGetter(for: $0, _self: _self)]
        + (isReadonly ? [] : [try makeBridgingSetter(for: $0, _self: _self)])
    }.joined(separator: "\n")
  }

  private func makeBridgingSetter(for varDecl: VarDecl, _self: String) throws -> String {
    let bridgeName = "\(varDecl.name)_set_jni"
    let paramTypes = defaultParamTypes + [try varDecl.type.jniType()]
    let returnType = "Void"
    let varParamName = "value"
    let closureParams = defaultClosureParams + [varParamName]
    
    let (mapped, stmts) = try varDecl.type.fromJava(varParamName)

    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in
  var _self = \(_self)
  \(stmts.joined(separator: "\n  "))
  _self.\(varDecl.name) = \(mapped)
}
"""
  }

  private func makeBridgingGetter(for varDecl: VarDecl, _self: String) throws -> String {
    let bridgeName = "\(varDecl.name)_get_jni"
    let paramTypes = defaultParamTypes
    let returnType = try varDecl.type.jniType()
    let closureParams = defaultClosureParams
    
    let (mapped, stmts) = try varDecl.type.toJava("_self.\(varDecl.name)")
    
    return
"""
fileprivate typealias \(bridgeName)_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> \(returnType)
fileprivate static let \(bridgeName): \(bridgeName)_t = {\(closureParams.joined(separator: ", ")) in  
  let _self = \(_self)
  \(stmts.joined(separator: "\n  "))
  return \(mapped)
}
"""
  }
}
