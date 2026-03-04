import SwiftSyntax

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension EnumDeclSyntax: JvmValueTypeDeclSyntax {
  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    let caseGetters = try caseDecls().compactMap {
      try $0.makeBridgingGetterDecls(typeDecl: self)
    }.joined(separator: "\n")

    return try expandMembersDefault(in: context) + ["\(raw: caseGetters)"]
  }

  func expandJavaClassDecl(in context: some MacroExpansionContext) -> String {
    let caseJClassDecls: String
    if withAssociatedValues {
      let fqn = fqn(from: context)
      caseJClassDecls = caseDecls().map {
        let caseName = $0.name.text
        let caseClass = fqn + "$" + caseName
        return
"""
private static let \(caseName)_javaClass: JClass = {
  guard let cls = JClass(fqn: "\(caseClass)") else {
    fatalError("Could not find \(caseClass) class")
  }
  return cls
}()
"""
      }.joined(separator: "\n")
    }
    else {
        caseJClassDecls = ""
    }

    return
"""
\(expandJavaClassDeclDefault(in: context))
\(caseJClassDecls)
"""
  }

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String {
    if withAssociatedValues {
      return try expandJavaObjectDeclsAsClass(in: context)
    } else {
      return try expandJavaObjectDeclsAsEnum(in: context)
    }
  }

  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String {
    if withAssociatedValues {
      let caseCtors = try caseDecls().map {
        try $0.makeBridgingDecls(typeDecl: self)
      }.joined(separator: "\n")

      return
"""
\(try expandCtorDeclsAsClass(in: context))

\(caseCtors)
"""

    } else {
      return ""
    }
  }

  func expandToJavaObject(in context: some MacroExpansionContext) -> String {
    let fqn = fqn(from: context)
    let toJavaCases = caseDecls().map {
      let caseName = $0.name.text
      let caseClass = fqn + "$" + caseName
      let caseJClass = "Self.\(caseName)_javaClass"

      if $0.parameters.isEmpty {
        return
"""
case .\(caseName):  
  return \(caseJClass).getStatic(field: "INSTANCE", sig: "L\(caseClass);")
"""
      } else {
        return
"""
case .\(caseName):  
  let ptr = UnsafeMutablePointer<\(typeName)>.allocate(capacity: 1)
  ptr.initialize(to: self)
  return \(caseJClass).create(Int(bitPattern: ptr), signature: "(J)V") 
"""
      }
    }.joined(separator: "\n")

    return
"""
switch self {
  \(toJavaCases)
}
"""
  }

  func expandRegisterNatives(in context: some MacroExpansionContext, parents: [any TypeDeclSyntax]) throws -> String {
    guard withAssociatedValues else { return "" }
    return try expandRegisterNativesDefault(in: context, parents: parents)
  }

  func expandCreateNativeMethods(parents: [any TypeDeclSyntax]) throws -> [String] {
    let fqn = fqn(with: parents)

    let caseNatives = try caseDecls().flatMap { c in
      let caseJavaName = c.name.text + "Impl"
      let caseJniSig = try c.jniSignature()
      let caseFn = "\(fqn).\(c.jniName)"

      let caseCtorNatives = expandCreateNativeMethod(name: caseJavaName, sig: caseJniSig, fn: caseFn)

      let caseParamNatives = try c.parameters.map{ p in
        let paramJavaName =  try "get" + c.name.text.capitalized + p.name.capitalized  + "Impl"
        let paramJniSig = "(J)\(try p.type.jniSignature())"
        let paramFn = "\(fqn).\(try c.jniName(of: p))"

        return expandCreateNativeMethod(name: paramJavaName, sig: paramJniSig, fn: paramFn)
      }

      return [caseCtorNatives] + caseParamNatives
    }

    return try expandCreateNativeMethodsDefault(parents: parents) + caseNatives
  }

  func expandJavaObjectDeclsAsEnum(in context: some MacroExpansionContext) throws -> String {
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


}

