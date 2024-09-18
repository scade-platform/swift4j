import Foundation

import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class ProxyGenerator: SyntaxVisitor {
  struct Context {
    var imports: Set<String> = []
    var nestedClasses: Set<String> = []
  }

  private let package: String
  private var classGens: [ClassGenerator] = []

  init(package: String) {
    self.package = package
    super.init(viewMode: .fixedUp)
  }

  func run(path: String) throws -> [(classname: String, content: String)] {
    let url = URL(fileURLWithPath: path)
    let source = try String(contentsOf: url, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)

    walk(sourceFile)

    return classGens.map { ($0.name, generate($0)) }
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hasAttribute(name: "exported")  {
      classGens.append(ClassGenerator(node))
    }
    return .skipChildren
  }

  func generate(_ classGen: ClassGenerator) -> String {
    var ctx = Context()

    let classDecl = classGen.generate(with: &ctx)

    return
"""
package \(self.package);

\(ctx.imports.map{"import \($0);"}.joined(separator: "\n"))

\(classDecl)
"""
  }

  func generatePackageClass() -> String {
"""
package \(self.package);

"""
  }
}

class ClassGenerator: SyntaxVisitor {
  typealias Context = ProxyGenerator.Context

  private let classDecl: ClassDeclSyntax

  private var methodsGens: [MethodGenerator] = []

  var name: String { classDecl.name.text }

  init(_ classDecl: ClassDeclSyntax) {
    self.classDecl = classDecl
    super.init(viewMode: .fixedUp)

    walk(classDecl)
  }
  
  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hasAttribute(name: "exported")  {
      methodsGens.append(MethodGenerator(node))
    }
    return .skipChildren
  }

  func generate(with ctx: inout Context) -> String {
"""
public class \(name) {
  private final long _ptr;

  static {
    \(name)_class_init(\(name).class);
  }
  
  public \(name)() {
    this(\(name).init());
  }

  private \(name)(long ptr) {
     _ptr = ptr;
  }

  @Override
  public void finalize() {
    \(name).deinit(_ptr);
  }

  private static native long init();
  private static native void deinit(long ptr);
  private static native void \(name)_class_init(Class<?> cls);

\(methodsGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))
}
"""
  }
}


class MethodGenerator {
  typealias Context = ProxyGenerator.Context

  private let funcDecl: FunctionDeclSyntax
  
  var name: String { funcDecl.name.text }

  init(_ funcDecl: FunctionDeclSyntax) {
    self.funcDecl = funcDecl
  }

  func generate(with ctx: inout Context) -> String {
    let params = funcDecl.signature.parameterClause.parameters.map {
      (name: ($0.secondName ?? $0.firstName).text, type: $0.type.map(with: &ctx))
    }

    let retType = funcDecl.signature.returnClause?.type.map(with: &ctx) ?? "void"

    let callParams = ["_ptr"] + params.map{$0.name}
    
    var call = "this.\(name)Impl(\(callParams.joined(separator: ", ")))"
    call = funcDecl.signature.returnClause != nil ? "return \(call)" : call

    let paramDecls = params.map {"\($0.type) \($0.name)"}
    let paramDeclsImpl = ["long ptr"] + paramDecls

    return
"""
  public \(retType) \(name)(\(paramDecls.joined(separator: ", "))) {
    \(call);
  }
  private native \(retType) \(name)Impl(\(paramDeclsImpl.joined(separator: ", ")));
"""
  }
}


protocol MappableTypeSyntax: TypeSyntaxProtocol {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String
}


// MARK: TypeSyntax

extension TypeSyntax {
  var supportedMappings: [any MappableTypeSyntax.Type] {[
    IdentifierTypeSyntax.self,
    FunctionTypeSyntax.self
  ]}

  func map() -> (any MappableTypeSyntax)? {
    for s in supportedMappings {
      if let typeSyntax = self.as(s) {
        return typeSyntax
      }
    }
    return nil
  }
  
  func map(with ctx: inout ProxyGenerator.Context) -> String {
    return map(with: &ctx, primitivesAsObjects: false)
  }

  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    return map()?.map(with: &ctx, primitivesAsObjects: primitivesAsObjects) ?? ""
  }
}


// MARK: IdentifierTypeSyntax

extension IdentifierTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    switch self.name.text {
    case "String": "String"
    case "Bool": primitivesAsObjects ? "Boolean" : "boolean"
    case "Int", "Int64": primitivesAsObjects ? "Long" : "long"
    case "Int32": primitivesAsObjects ? "Integer" : "int"
    case "Int16": primitivesAsObjects ? "Short" : "short"
    case "Int8": primitivesAsObjects ? "Byte" : "byte"
    case "Float": primitivesAsObjects ? "Float" : "float"
    case "Double": primitivesAsObjects ? "Double" : "double"
    case "Void": "void"
    default: self.name.text
    }
  }
}

// MARK: FunctionTypeSyntax

extension FunctionTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    let retType = returnClause.type.map(with: &ctx, primitivesAsObjects: true)

    var funcInterfaceFqn = javaFunctionalInterface.split(separator: ".")
    var funcType = funcInterfaceFqn.popLast() ?? ""

    if funcType != "" {
      if funcInterfaceFqn.count > 0 {
        ctx.imports.insert(javaFunctionalInterface)
      }

      var paramTypes = parameters.map{ $0.type.map(with: &ctx, primitivesAsObjects: true) }

      if !isVoid {
        paramTypes.append(retType)
      }

      funcType += "<\(paramTypes.joined(separator: ", "))>"
    }

    return String(funcType)
  }
}
