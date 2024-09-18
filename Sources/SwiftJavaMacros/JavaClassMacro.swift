import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

import SwiftSyntaxExtensions


// MARK: JavaClassMacro

public struct JavaClassMacro {
  enum Error: Swift.Error { case message(String) }

  static func moduleName(from context: some SwiftSyntaxMacros.MacroExpansionContext, for classDecl: ClassDeclSyntax) -> String? {

    guard let segments = context.location(of: classDecl)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }
  
  static func assertClassDecl(_ decl: some SyntaxProtocol) throws -> ClassDeclSyntax {
    guard let classDecl = decl.as(ClassDeclSyntax.self) else {
      throw Error.message("Macro can only be applied to a class declaration")
    }

    return classDecl
  }

  static func exportedFuncDecls(from classDecl: ClassDeclSyntax) -> [FunctionDeclSyntax] {
    return classDecl.memberBlock.members.compactMap {
      guard let funcDecl = $0.decl.as(FunctionDeclSyntax.self),
              funcDecl.hasAttribute(name: "exported") else { return nil }
      return funcDecl
    }
  }
}



// MARK: +PeerMacro

extension JavaClassMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

    let classDecl = try assertClassDecl(declaration)
    let className = classDecl.name.text

    var fqnEscaped = className
    if let moduleName = moduleName(from: context, for: classDecl) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let nativeMethods = try exportedFuncDecls(from: classDecl)
      .map {
"""
JNINativeMethod(name: "\($0.name.text)Impl", sig: "\(try $0.jniSignature())", fn: \(className).\($0.name.text)_jni)
"""
      } + [
"""
JNINativeMethod(name: "init", sig: "()J", fn: \(className).init_jni),
JNINativeMethod(name: "deinit", sig: "(J)V", fn: \(className).deinit_jni)
"""
    ]

    return [
"""
@_cdecl("Java_\(raw: fqnEscaped)_\(raw: className)_1class_1init")
func \(raw: className)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {
  let natives = [
    \(raw: nativeMethods.joined(separator: ",\n"))
  ]
  let _ = jni.RegisterNatives(env, cls, natives, JavaInt(natives.count))
}
"""
    ]
  }
}

// MARK: +MemberMacro

extension JavaClassMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax, 
                               providingMembersOf declaration: some DeclGroupSyntax,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    let classDecl = try assertClassDecl(declaration)
    let className = classDecl.name.text
    
    var fqn = className
    if let moduleName = moduleName(from: context, for: classDecl) {
      fqn = "\(moduleName)/\(fqn)"
    }

    let initDecls: [DeclSyntax] = [
"""
private var jobj: JObject? = nil
public static var javaClass = JClass(fqn: \"\(raw: fqn)\")!

fileprivate typealias init_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>) -> JavaLong
fileprivate static let init_jni: init_jni_t = { _ in
  let obj = \(raw: className)()
  Refs.retain(obj)
  return unsafeBitCast(obj, to: JavaLong.self)
}

fileprivate typealias deinit_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaLong) -> Void
fileprivate static let deinit_jni: deinit_jni_t = { _, ptr in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: \(raw: className).self)
  Refs.release(_self)
}
"""
    ]
    
    let funcDecls = try exportedFuncDecls(from: classDecl).map {
      try $0.makeBridgingDecls(classDecl: classDecl)
      //DeclSyntax(.formatted())!
    }

    return initDecls + funcDecls
  }
}

// MARK: +ExtensionMacro

extension JavaClassMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                               attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                               providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                               conformingTo protocols: [SwiftSyntax.TypeSyntax],
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    return [try ExtensionDeclSyntax(
"""
extension \(type.trimmed): JObjectRepresentable {
  public func toJavaObject() -> JavaObject? {
    if jobj == nil {
      jobj = JObject(Self.javaClass.create(unsafeBitCast(self, to: JavaLong.self)), weak: true)
      Refs.retain(self)
    }
    return jobj?.ptr
  }
}
"""
    )]
  }

}


// MARK: SwiftSyntax Extensions


extension FunctionDeclSyntax {
  func jniSignature() throws -> String {
    let params = try ["J"] + signature.parameterClause.parameters
      .map{ try $0.type.jniSignature() }

    return "(\(params.joined()))\(try signature.returnClause?.type.jniSignature() ?? "V")"
  }

  func makeBridgingDecls(classDecl: ClassDeclSyntax) throws -> DeclSyntax {
    let paramTypes = try [
      "UnsafeMutablePointer<JNIEnv>", "JavaObject?", "JavaLong"
    ] + signature.parameterClause.parameters.map{ try $0.type.jniType() }
    
    let returnType = try signature.returnClause?.type.jniType() ?? "Void"
    
    let closureParams = [
      "_", "_", "ptr"
    ] + signature.parameterClause.parameters.map{ $0.name }
    
    let (call, stmts) = try makeBridgingFunctionBody()

    return
"""
fileprivate typealias \(raw: name.text)_jni_t = @convention(c)(\(raw: paramTypes.joined(separator: ", "))) -> \(raw: returnType)
fileprivate static let \(raw: name.text)_jni: \(raw: name.text)_jni_t = {\(raw: closureParams.joined(separator: ", ")) in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: \(raw: classDecl.name.text).self)
  \(raw: stmts.joined(separator: "\n  "))
  \(raw: call)
}
"""
  }

  func makeBridgingFunctionBody() throws -> (call: String, stmts: [String]) {
    let mapping = try signature.parameterClause.parameters
      .reduce(into: ([String](), [String]())) {
        let (param, stmts) = try $1.fromJava()
        $0.0.append(param)
        $0.1.append(contentsOf: stmts)
      }

    var call = "_self.\(name.text)(\(mapping.0.joined(separator: ",")))"
    var stmts = mapping.1

    if let retType = signature.returnClause?.type {
      let ret_mapping = try retType.toJava(call)

      call = "return \(ret_mapping.0)"
      stmts.append(contentsOf: ret_mapping.1)
    }

    return (call, stmts)
  }
}



typealias MappingRetType = (mapped: String, stmts: [String])


extension FunctionParameterSyntax {
  var name: String { (secondName ?? firstName).text }

  func toJava() throws -> MappingRetType {
    try type.toJava(name)
  }
  func fromJava() throws -> MappingRetType {
    try type.fromJava(name)
  }
}



protocol JavaMappedTypeSyntax: SyntaxProtocol {
  func jniSignature(primitivesAsObjects: Bool) -> String
  func jniType(primitivesAsObjects: Bool) -> String

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
    }

    throw JavaClassMacro.Error.message("Unsupported type")
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
  var isVoid: Bool { name.text == "Void" }

  var isPrimitive: Bool {
    switch self.name.text {
    case "Void", "Bool", "Int", "Int64", "Int32", "Int16", "Int8", "Float", "Double": true
    default: false
    }
  }

  func jniSignature(primitivesAsObjects: Bool) -> String {
    switch self.name.text {
    case "Void": "V"
    case "Bool": primitivesAsObjects ? "Ljava/lang/Boolean;" : "Z"
    case "Int", "Int64": primitivesAsObjects ? "Ljava/lang/Long;" : "J"
    case "Int32": primitivesAsObjects ? "Ljava/lang/Integer;" : "I"
    case "Int16": primitivesAsObjects ? "Ljava/lang/Short;" : "S"
    case "Int8": primitivesAsObjects ? "Ljava/lang/Byte;" : "B"
    case "Float": primitivesAsObjects ? "Ljava/lang/Float;" : "F"
    case "Double": primitivesAsObjects ? "Ljava/lang/Double;" : "D"
    case "String": "Ljava/lang/String;"
    default: self.name.text
    }
  }

  func jniType(primitivesAsObjects: Bool) -> String {
    switch self.name.text {
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
        return (expr, [])
      }
    } else {
      return ("\(name.text).fromJavaObject(\(expr))", [])
    }
  }
}


extension FunctionTypeSyntax: JavaMappedTypeSyntax {
  func paramName() throws -> String   {
    guard let paramName = typedEntityName else {
      throw JavaClassMacro.Error.message("Unknown function parameter name")
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
      "let params = [\(mapping.0.joined(separator: ","))]"
    ]

    let method = try javaCallMethod()

    let call = "_\(try paramName()).call(method: \"\(method.name)\", sig: \"\(method.sig)\", params)"
    let call_ret = try returnClause.type.fromJava(call, primitivesAsObjects: true)
    
    return ("return \(call_ret.0)", mapping.1 + params_stmts + call_ret.1)
  }
}
