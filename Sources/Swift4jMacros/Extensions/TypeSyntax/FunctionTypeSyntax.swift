import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension FunctionTypeSyntax: JvmMappedTypeSyntax {

  func jniSignature(primitivesAsObjects: Bool) -> String {
    "L\(javaFunctionalInterface.replacingOccurrences(of: ".", with: "/"));"
  }

  func jniType(primitivesAsObjects: Bool) -> String { "JavaObject?" }

  func jniTypeDefaultValue(primitivesAsObjects: Bool) throws -> String { "nil" }

  func toJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType { MappingRetType(mapped: "nil") }

  func fromJava(_ expr: String, primitivesAsObjects: Bool, optional: Bool) throws -> MappingRetType {
    let paramName = (try? paramName) ?? expr
    
    let closureVar = "_\(paramName)"
    let closureObj = "\(paramName)Obj"
    let closureType = "@Sendable \(_syntaxNode.trimmedDescription)"
    
    let closureBody = try makeBridgingClosureBody(closureName: closureObj)

    let stmts: [String]
    if !optional {
      stmts = [
"""
  guard let \(paramName) = \(paramName) else { fatalError(\"Cannot call a null closure\") }
  let \(closureObj) = JObject(\(paramName))
  let \(closureVar): \(closureType) = {
    \(closureBody)
  }
"""
      ]
    } else {
      stmts = [
"""
  let \(closureVar): (\(closureType))?
  if let \(paramName) = \(paramName) {
    let \(closureObj) = JObject(\(paramName))
    \(closureVar) = {
      \(closureBody)
    }  
  } else {
    \(closureVar) = nil
  }
"""
      ]
    }

    return MappingRetType(mapped: closureVar, stmts: stmts)
  }

  private var paramName: String {
    get throws {
      guard let paramName = typedEntityName else {
        throw JvmMacrosError.message("Unknown function parameter name")
      }
      return paramName
    }
  }

  private func javaCallMethod() throws -> (name: String, sig: String) {
    let name: String
    if parameters.count == 0 {
      name = isVoid ? "run" : "get"
    } else {
      name = isVoid ? "accept" : "apply"
    }

    let params = Array<String>(repeating: "Ljava/lang/Object;", count: parameters.count)
    let sig = "(\(params.joined()))\(isVoid ? "V" : "Ljava/lang/Object;")"

    /*
     let params = try parameters.map{ try $0.type.jniSignature(primitivesAsObjects: true) }
     let sig = "(\(params.joined()))\(try returnClause.type.jniSignature(primitivesAsObjects: true))"
     */

    return (name, sig)
  }

  private func makeBridgingClosureBody(closureName: String) throws -> String {
    let mapping = try parameters.enumerated()
      .reduce(into: ([String](), [String]())) {
        let mapping = try $1.1.type.toJava("$\($1.0)", primitivesAsObjects: true)
        $0.0.append("JavaParameter(object: \(mapping.mapped))")
        $0.1.append(contentsOf: mapping.stmts)
      }

    var stmts = mapping.1

    stmts.append(
      "let params: [JavaParameter] = [\(mapping.0.joined(separator: ","))]"
    )

    let method = try javaCallMethod()

    let call: String
    if isVoid {
      call = "\(closureName).call(method: \"\(method.name)\", sig: \"\(method.sig)\", params)"

    } else {
      stmts.append(
        "let res: JavaObject? = \(closureName).callObjectMethod(method: \"\(method.name)\", sig: \"\(method.sig)\", params)"
      )
      let call_ret = try returnClause.type.fromJava("res", primitivesAsObjects: true)
      
      call = "return \(call_ret.mapped)"
      stmts.append(contentsOf: call_ret.stmts)
    }

    return
"""
\(stmts.joined(separator: "\n  "))
\(call)
"""
  }
}

