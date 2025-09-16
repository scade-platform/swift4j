import SwiftSyntax

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension EnumDeclSyntax: JvmTypeDeclSyntax {
  var shouldExpandMemberDecls: Bool { false }

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String {
    let toJavaCases = cases().map{
"""
case .\($0): return Self.javaClass.getStatic(field: "\($0)", sig: "L\(fqn(from: context));")?.ptr
"""
    }.joined(separator: "\n")

    let fromJavaCases = cases().enumerated().map{
"""
case \($0.offset): return .\($0.element)
"""
    }.joined(separator: "\n")

    return
"""
public static func fromJavaObject(_ obj: JavaObject?) -> \(typeName) {
  let ordinal: Int32 = JObject(obj!).call(method: "ordinal")
  switch ordinal {
  \(fromJavaCases)
  default:
  fatalError("Cannot create an enum case")
  }
}

public func toJavaObject() -> JavaObject? {
  switch self {
  \(toJavaCases)
  }
}

"""
  }
  
  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String {
    ""
  }

  func expandInitCall(params: String) -> String {
    ""
  }
}

