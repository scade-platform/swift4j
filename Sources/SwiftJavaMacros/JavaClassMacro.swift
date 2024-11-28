import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions



// MARK: - JavaClassMacro

public struct JavaClassMacro {
  static func classDecl(from decl: some SwiftSyntax.SyntaxProtocol) throws -> ClassDeclSyntax {
    return try decl.assert(as: ClassDeclSyntax.self, "Macros can be only applied to a class declaration")
  }

  static func addPlatformConditions(_ node: SwiftSyntax.AttributeSyntax, syntax: String) -> String {
    switch node.arguments {
    case .argumentList(let exprs):
      let conds = exprs.compactMap {
          guard let platform = $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else {
            return nil
          }
          return "os(\(platform))"
        }.joined(separator: " || ")
      
      if conds != "" {
        return
"""
#if \(conds)
\(syntax)
#endif
"""
      }
      return syntax

    default:
      return syntax
    }
  }


}



// MARK: - PeerMacro

extension JavaClassMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    

    let classDecl = try classDecl(from: declaration)
    let className = classDecl.name.text

    var fqnEscaped = className
    if let moduleName = classDecl.moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let exportedDecls = classDecl.exportedDecls

    let funcNatives: [String] = exportedDecls.funcDecls.compactMap {
      guard let jniSig = try? $0.jniSignature() else { return nil }
      return
"""
JNINativeMethod(name: "\($0.name.text)Impl", sig: "\(jniSig)", fn: \(className).\($0.name.text)_jni)
"""
      }

    let initNatives: [String]
    if exportedDecls.hasInitDecls {
      initNatives = exportedDecls.initDecls.enumerated().compactMap {
        guard let jniSig = try? $1.jniSignature() else { return nil }
        return
"""
JNINativeMethod(name: "init\($0)", sig: "\(jniSig)", fn: \(className).init\($0)_jni)
"""
      }
    } else {
      initNatives = [
"""
JNINativeMethod(name: "init", sig: "()J", fn: \(className).init_jni)
"""
      ]
    }

    let natives = initNatives + [
"""
JNINativeMethod(name: "deinit", sig: "(J)V", fn: \(className).deinit_jni)
"""
    ] + funcNatives


    let decl =
"""
@_cdecl("Java_\(fqnEscaped)_\(className)_1class_1init")
func \(className)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {
  guard let cls = cls else { return }
  let natives = [
    \(natives.joined(separator: ",\n"))
  ]
  let _ = jni.RegisterNatives(cls, natives)
}
"""
    return ["\(raw: addPlatformConditions(node, syntax: decl))"]
  }
}

// MARK: - MemberMacro

extension JavaClassMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax, 
                               providingMembersOf declaration: some DeclGroupSyntax,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    let classDecl = try classDecl(from: declaration)
    let className = classDecl.name.text
    
    var fqn = className
    if let moduleName = classDecl.moduleName(from: context) {
      fqn = "\(moduleName)/\(fqn)"
    }

    let varDecls =
"""
private var jobj: JObject? = nil

public static var javaClass = {
  guard let cls = JClass(fqn: \"\(fqn)\") else {
    fatalError("Could not find \(fqn) class")
  }
  return cls
} ()

public func toJavaObject() -> JavaObject? {
  if jobj == nil {
    jobj = JObject(Self.javaClass.create(unsafeBitCast(Unmanaged.passRetained(self), to: JavaLong.self)), weak: true)
  }
  return jobj?.ptr
}
"""

    let deinitDecls =
"""
fileprivate typealias deinit_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?, JavaLong) -> Void
fileprivate static let deinit_jni: deinit_jni_t = { _, _, ptr in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<\(className)>.self)
  _self.release()
}
"""

    let exportedDecls = classDecl.exportedDecls

    let initDecls: String
    if exportedDecls.hasInitDecls {
      initDecls = exportedDecls.initDecls.enumerated()
        .compactMap { i, decl in
          return context.executeAndWarnIfFails(at: decl) {
            return try decl.makeBridgingDecls(classDecl: classDecl, index: i)
          }
        }
        .joined(separator: "\n")

    } else {
      initDecls =
"""
fileprivate typealias init_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaClass?) -> JavaLong
fileprivate static let init_jni: init_jni_t = { _, _ in
  let obj = \(className)()
  return unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)
}
"""
    }

    let funcDecls = exportedDecls.funcDecls
      .compactMap { decl in
        return context.executeAndWarnIfFails(at: decl) {
          return try decl.makeBridgingDecls(classDecl: classDecl)
        }
      }
      .joined(separator: "\n")

    let syntax = 
"""
\(varDecls)
\(initDecls)
\(deinitDecls)
\(funcDecls)
"""

    return ["\(raw: addPlatformConditions(node, syntax: syntax))"]
  }
}

// MARK: - ExtensionMacro

extension JavaClassMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                               attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                               providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                               conformingTo protocols: [SwiftSyntax.TypeSyntax],
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    let extSyntax =
"""
extension \(type.trimmed): JObjectRepresentable { }
"""
    return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: extSyntax))]
  }

}


// MARK: - SwiftSyntax Extensions

extension AttributedDeclSyntax {

}

extension ClassDeclSyntax {

  typealias ExportedDecls = (hasInitDecls: Bool, 
                             initDecls: [InitializerDeclSyntax],
                             funcDecls: [FunctionDeclSyntax])

  var exportedDecls: ExportedDecls {
    var decls: ExportedDecls = (false, [], [])

    for m in memberBlock.members {
      if let initDecl = m.decl.as(InitializerDeclSyntax.self) {
        decls.hasInitDecls = true
        if initDecl.isExported {
          decls.initDecls.append(initDecl)
        }
      } else if let funcDecl = m.decl.as(FunctionDeclSyntax.self), funcDecl.isExported {
        decls.funcDecls.append(funcDecl)
      }
    }

    return decls
  }
  
  func moduleName(from context: some SwiftSyntaxMacros.MacroExpansionContext) -> String? {
    guard let segments = context.location(of: self)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }
}


extension FunctionSignatureSyntax {
  func jniParams() throws -> [String] {
    try parameterClause.parameters.map{ try $0.type.jniSignature() }
  }

  func paramsMapping() throws -> MappingRetType {
    let mapping = try parameterClause.parameters
      .reduce(into: ([String](), [String]())) {
        let (param, stmts) = try $1.fromJava()
        $0.0.append(param)
        $0.1.append(contentsOf: stmts)
      }
    return (mapping.0.joined(separator: ","), mapping.1)
  }
}


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


extension InitializerDeclSyntax {
  func jniSignature() throws -> String {
    try "(\(signature.jniParams().joined()))J"
  }

  func makeBridgingDecls(classDecl: ClassDeclSyntax, index: Int) throws -> String {
    let name = "init\(index)"
    let paramTypes = try ["UnsafeMutablePointer<JNIEnv>", "JavaClass?"] + signature.parameterClause.parameters.map{ try $0.type.jniType() }
    let closureParams = ["_", "_"] + signature.parameterClause.parameters.map{ $0.name }

    let (params, stmts) = try signature.paramsMapping()

    return
"""
fileprivate typealias \(name)_jni_t = @convention(c)(\(paramTypes.joined(separator: ", "))) -> JavaLong
fileprivate static let \(name)_jni: \(name)_jni_t = {\(closureParams.joined(separator: ", ")) in
  \(stmts.joined(separator: "\n  "))
  let obj = \(classDecl.name.text)(\(params))
  return unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)
}
"""
  }
}



typealias MappingRetType = (mapped: String, stmts: [String])


extension FunctionParameterSyntax {
  var name: String { (secondName ?? firstName).text }

  func toJava() throws -> MappingRetType {
    try type.toJava(name)
  }
  func fromJava() throws -> MappingRetType {
    let (mapped, stmts) = try type.fromJava(name)

    switch firstName.tokenKind {
    case .identifier(name):
      return ("\(name): \(mapped)", stmts)
    case .wildcard:
      return (mapped, stmts)
    default:
      throw JavaMacrosError.message("Unsupported function parameter syntax")
    }

  }
}



protocol JavaMappedTypeSyntax: SyntaxProtocol {
  func jniSignature(primitivesAsObjects: Bool) throws -> String
  func jniType(primitivesAsObjects: Bool) throws -> String

  func toJava(_: String, primitivesAsObjects: Bool) throws -> MappingRetType
  func fromJava(_: String, primitivesAsObjects: Bool) throws -> MappingRetType
}


extension JavaMappedTypeSyntax {
  var typedEntityName: String? {
    if let funcParam = parent?.as(FunctionParameterSyntax.self) {
      return funcParam.name
    }
    return nil
  }
}


extension TypeSyntax {
  func map() throws -> any JavaMappedTypeSyntax {
    if let typeSyntax = self.as(IdentifierTypeSyntax.self) {
      return typeSyntax

    } else if let typeSyntax = self.as(FunctionTypeSyntax.self) {
      return typeSyntax

    } else if let typeSyntax = self.as(ArrayTypeSyntax.self) {
      return typeSyntax
    }

    throw JavaMacrosError.message("Unsupported type", self)
  }

  func jniSignature(primitivesAsObjects: Bool = false) throws -> String {
    try map().jniSignature(primitivesAsObjects: primitivesAsObjects)
  }

  func jniType(primitivesAsObjects: Bool = false ) throws -> String {
    try map().jniType(primitivesAsObjects: primitivesAsObjects)
  }

  func toJava(_ expr: String, primitivesAsObjects: Bool = false) throws -> MappingRetType {
    try map().toJava(expr, primitivesAsObjects: primitivesAsObjects)
  }

  func fromJava(_ expr: String, primitivesAsObjects: Bool = false) throws -> MappingRetType {
    try map().fromJava(expr, primitivesAsObjects: primitivesAsObjects)
  }
}




extension IdentifierTypeSyntax: JavaMappedTypeSyntax {
  var isVoid: Bool {
    name.text == "Void"
  }

  var isPrimitive: Bool {
    switch name.text {
    case "Void", "Bool", "Int", "Int64", "Int32", "Int16", "Int8", "Float", "Double": true
    default: false
    }
  }

  func jniSignature(primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "Void": "V"
    case "Bool": primitivesAsObjects ? "Ljava/lang/Boolean;" : "Z"
    case "Int", "Int64": primitivesAsObjects ? "Ljava/lang/Long;" : "J"
    case "Int32": primitivesAsObjects ? "Ljava/lang/Integer;" : "I"
    case "Int16": primitivesAsObjects ? "Ljava/lang/Short;" : "S"
    case "Int8": primitivesAsObjects ? "Ljava/lang/Byte;" : "B"
    case "Float": primitivesAsObjects ? "Ljava/lang/Float;" : "F"
    case "Double": primitivesAsObjects ? "Ljava/lang/Double;" : "D"
    case "String": "Ljava/lang/String;"
    default: name.text
    }
  }

  func jniType(primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "Void": "void"
    case "Bool": primitivesAsObjects ? "JavaObject" : "JavaBoolean"
    case "Int", "Int64": primitivesAsObjects ? "JavaObject" : "JavaLong"
    case "Int32": primitivesAsObjects ? "JavaObject" : "JavaInt"
    case "Int16": primitivesAsObjects ? "JavaObject" : "JavaShort"
    case "Int8": primitivesAsObjects ? "JavaObject" : "JavaByte"
    case "Float": primitivesAsObjects ? "JavaObject" : "JavaFloat"
    case "Double": primitivesAsObjects ? "JavaObject" : "JavaDouble"
    default: "JavaObject?"
    }
  }

  func toJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType {
    return (isPrimitive && !primitivesAsObjects ? expr : "\(expr).toJavaObject()", [])
  }

  func fromJava(_ expr: String, primitivesAsObjects: Bool) -> MappingRetType {
    if isPrimitive {
      if primitivesAsObjects && !isVoid {
        let _expr = "(\(expr) as \(name.text).PrimitiveType).value"
        return (name.text == "Int" ? "Int(\(_expr))" : _expr, [])

      } else {
        return (name.text == "Int" ? "Int(\(expr))" : expr, [])
      }
    } else {
      let _expr = "\(name.text).fromJavaObject(\(expr))"

      guard let paramName = typedEntityName else {
        return (_expr, [])
      }

      return ("_\(paramName)", ["let _\(paramName) = \(_expr)"])
    }
  }
}


extension FunctionTypeSyntax: JavaMappedTypeSyntax {
  func paramName() throws -> String {
    guard let paramName = typedEntityName else {
      throw JavaMacrosError.message("Unknown function parameter name")
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

extension ArrayTypeSyntax: JavaMappedTypeSyntax {
  func jniSignature(primitivesAsObjects: Bool) throws -> String {
    return try "[" + element.jniSignature(primitivesAsObjects: primitivesAsObjects)
  }
  
  func jniType(primitivesAsObjects: Bool) -> String { "JavaObject?" }

  func toJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    return ("\(expr).toJavaObject()", [])
  }
  
  func fromJava(_ expr: String, primitivesAsObjects: Bool) throws -> MappingRetType {
    let _expr = "\(trimmedDescription).fromJavaObject(\(expr))"

    guard let paramName = typedEntityName else {
      return (_expr, [])
    }

    return ("_\(paramName)", ["let _\(paramName) = \(_expr)"])
  }
}
