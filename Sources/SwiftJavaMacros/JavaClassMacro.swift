import SwiftSyntax
import SwiftSyntaxMacros

import SwiftSyntaxExtensions

public struct JavaClassMacro { 

  static func moduleName(from context: some SwiftSyntaxMacros.MacroExpansionContext, for classDecl: ClassDeclSyntax) -> String? {
    guard let segments = context.location(of: classDecl)?.file.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1, case .stringSegment(let literalSegment)? = segments.first,
          let moduleNameSep = literalSegment.content.text.firstIndex(of: "/") else { return nil }

    return String(literalSegment.content.text[literalSegment.content.text.startIndex ..< moduleNameSep])
  }
  
  static func assertClassDecl(_ decl: some SyntaxProtocol) throws -> ClassDeclSyntax {
    guard let classDecl = decl.as(ClassDeclSyntax.self) else {
      throw MacroError.message("Macro can only be applied to a class declaration")
    }

    return classDecl
  }

  static func javaFuncDecls(from classDecl: ClassDeclSyntax) -> [FunctionDeclSyntax] {
    return classDecl.memberBlock.members.compactMap {
      guard let funcDecl = $0.decl.as(FunctionDeclSyntax.self),
              funcDecl.hasAttribute(name: "JavaMethod") else { return nil }
      return funcDecl
    }
  }
}


extension JavaClassMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    
    let classDecl = try assertClassDecl(declaration)
    let className = classDecl.name.text

    var fqnEscaped = className
    if let moduleName = moduleName(from: context, for: classDecl) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }
    
    let javaFuncDecls = javaFuncDecls(from: classDecl)

    let nativeMethods = try javaFuncDecls
      .map {
"""
JNINativeMethod(name: "\($0.name.text)", sig: "\(try $0.jniSignature())", fn: \(className).\($0.name.text)_jni)
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
func \(raw: className)_class_init() {
  try! \(raw: className).javaClass.registerNatives(
    \(raw: nativeMethods.joined(separator: ",\n"))
  )
}
"""
    ]
  }
}


extension JavaClassMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {


    let classDecl = try assertClassDecl(declaration)
    let className = classDecl.name.text
    
    var fqn = className
    if let moduleName = moduleName(from: context, for: classDecl) {
      fqn = "\(moduleName)/\(fqn)"
    }
    
    let javaFuncDecls = javaFuncDecls(from: classDecl)

    return try [
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
    ] + javaFuncDecls.map { try $0.bridgeDecls(classDecl: classDecl) }
  }
}


extension JavaClassMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

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


enum MacroError: Error { case message(String) }


extension FunctionDeclSyntax {

  func jniSignature() throws -> String {
    let params = try signature.parameterClause.parameters
      .map{ try $0.type.jniSignature() }
      .joined(separator: ", ")
    
    return "(\(params))\(try signature.returnClause?.type.jniSignature() ?? "V")"
  }

  func bridgeDecls(classDecl: ClassDeclSyntax) throws -> DeclSyntax {
    let paramTypes = try [
      "UnsafeMutablePointer<JNIEnv>", "JavaObject?", "JavaLong"
    ] + signature.parameterClause.parameters.map{ try $0.type.jniType() }
    
    let returnType = try signature.returnClause?.type.jniType() ?? "Void"
    
    let closureParams = [
      "_", "_", "ptr"
    ] + signature.parameterClause.parameters.map{ $0.name }

    return
"""
fileprivate typealias \(raw: name.text)_jni_t = @convention(c)(\(raw: paramTypes.joined(separator: ", "))) -> \(raw: returnType)
fileprivate static let \(raw: name.text)_jni: \(raw: name.text)_jni_t = {\(raw: closureParams.joined(separator: ", ")) in
  let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: \(raw: classDecl.name.text).self)
  \(raw: try implCall())
}
"""
  }

  func implCall() throws -> String {
    let params = try signature.parameterClause.parameters
      .map { try $0.fromJava() }
      .joined(separator: ", ")

    let call = "_self.\(name.text)(\(params))"

    if let retType = signature.returnClause?.type {
      return try "return \(retType.toJava(expr: call))"
    } else {
      return call
    }
  }
}

extension FunctionParameterSyntax {
  var name: String { (secondName ?? firstName).text }

  func toJava() throws -> String {
    try type.toJava(expr: name)
  }
  func fromJava() throws -> String {
    try type.fromJava(expr: name)
  }
}

extension TypeSyntax {
  func jniSignature() throws -> String {
    if let identTypeSyntax = self.as(IdentifierTypeSyntax.self) {
      return identTypeSyntax.jniSignature()
    }

    throw MacroError.message("Unsupported type")
  }

  func jniType() throws -> String {
    if let identTypeSyntax = self.as(IdentifierTypeSyntax.self) {
      return identTypeSyntax.jniType()
    }

    throw MacroError.message("Unsupported type")
  }

  func toJava(expr: String) throws -> String {
    if let identTypeSyntax = self.as(IdentifierTypeSyntax.self) {
      return identTypeSyntax.isPrimitive ? expr : "\(expr).toJavaObject()"
    }

    throw MacroError.message("Unsupported type")
  }

  func fromJava(expr: String) throws -> String {
    if let identTypeSyntax = self.as(IdentifierTypeSyntax.self) {
      return identTypeSyntax.isPrimitive ? expr : "\(identTypeSyntax.name.text).fromJavaObject(\(expr))"
    }

    throw MacroError.message("Unsupported type")
  }
}

extension IdentifierTypeSyntax {
  var isPrimitive: Bool {
    switch self.name.text {
    case "Bool", "Int", "Int64", "Int32", "Int16", "Int8", "Float", "Double": true
    default: false
    }
  }

  func jniSignature() -> String {
    switch self.name.text {
    case "Bool": "Z"
    case "Int", "Int64": "J"
    case "Int32": "I"
    case "Int16": "S"
    case "Int8": "B"
    case "Float": "F"
    case "Double": "D"
    case "String": "Ljava/lang/String;"
    default: self.name.text
    }
  }

  func jniType() -> String {
    switch self.name.text {
    case "Bool": "JavaBoolean"
    case "Int", "Int64": "JavaLong"
    case "Int32": "JavaInt"
    case "Int16": "JavaShort"
    case "Int8": "JavaByte"
    case "Float": "JavaFloat"
    case "Double": "JavaDouble"
    default: "JavaObject?"
    }
  }
}
