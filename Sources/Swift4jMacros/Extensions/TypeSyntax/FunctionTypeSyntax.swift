import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension FunctionTypeSyntax: JvmMappedTypeSyntax {
  func paramName() throws -> String {
    guard let paramName = typedEntityName else {
      throw JvmMacrosError.message("Unknown function parameter name")
    }
    return paramName
  }

  func javaCallMethod() throws -> (name: String, sig: String) {
    let name: String
    if parameters.count == 0 && !isVoid {
      name = "get"
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

  func jniSignature(primitivesAsObjects: Bool) -> String {
    "L\(javaFunctionalInterface.replacingOccurrences(of: ".", with: "/"));"
  }

  func jniType(primitivesAsObjects: Bool) -> String { "JavaObject?" }

  func toJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType { ("nil", []) }

  func fromJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    let paramName = try paramName()

    let stmts: [String] = [
      "guard let \(paramName) = \(paramName) else { fatalError(\"Cannot call a null closure\") }",
      "let _\(paramName) = JObject(\(paramName))"
    ]

    let (closure_call, closure_stmts) = try makeBridgingClosureBody()


    let closure_param =
"""
{
  \(closure_stmts.joined(separator: "\n  "))
  \(closure_call)
}
"""
    return (closure_param, stmts)
  }

  func makeBridgingClosureBody() throws -> (call: String, stmts: [String]) {
    let mapping = try parameters.enumerated()
      .reduce(into: ([String](), [String]())) {
        let (param, stmts) = try $1.1.type.toJava("$\($1.0)", primitivesAsObjects: true)
        $0.0.append("JavaParameter(object: \(param))")
        $0.1.append(contentsOf: stmts)
      }

    let params_stmts = [
      "let params: [JavaParameter] = [\(mapping.0.joined(separator: ","))]"
    ]

    let method = try javaCallMethod()

    let call = "_\(try paramName()).call(method: \"\(method.name)\", sig: \"\(method.sig)\", params)"
    let call_ret = try returnClause.type.fromJava(call, primitivesAsObjects: true)

    return ("return \(call_ret.0)", mapping.1 + params_stmts + call_ret.1)
  }
}

