import Foundation

import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class ProxyGenerator: SyntaxVisitor {
  struct Context {
    var imports: Set<String> = []
  }
  
  struct GeneratorSettings {
    let javaVersion: Int
  }

  private let package: String
  private let settings: GeneratorSettings

  private var classGens: [ClassGenerator] = []

  init(package: String, javaVersion: Int) {
    self.package = package
    self.settings = GeneratorSettings(javaVersion: javaVersion)

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
    if node.isExported  {
      classGens.append(ClassGenerator(node, settings: settings))
    }
    return .skipChildren
  }

  func generate(_ classGen: ClassGenerator) -> String {
    var ctx = Context()

    let classDecl = classGen.generate(with: &ctx)
    
    var imports = [String](ctx.imports)

    if settings.javaVersion >= 9 {
      imports.append("java.lang.ref.Cleaner")
    }

    return
"""
package \(self.package);

\(imports.map{"import \($0);"}.joined(separator: "\n"))

\(classDecl)
"""
  }

  func generatePackageClass() -> String {
"""
package \(self.package);

"""
  }
}

class TypeGenerator<T: TypeDeclSyntax>: SyntaxVisitor {
  typealias Context = ProxyGenerator.Context

  let typeDecl: T
  let settings: ProxyGenerator.GeneratorSettings

  var nestedTypeGens: [ClassGenerator] = []

  var name: String { typeDecl.typeName }

  var nested: Bool { typeDecl.parentDecl != nil }

  init(_ typeDecl: T, settings: ProxyGenerator.GeneratorSettings) {
    self.typeDecl = typeDecl
    self.settings = settings

    super.init(viewMode: .fixedUp)

    walk(typeDecl)
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hashValue != typeDecl.hashValue && node.isExported {
      nestedTypeGens.append(ClassGenerator(node, settings: settings))
      return .skipChildren
    }
    return .visitChildren
  }

}


class ClassGenerator: TypeGenerator<ClassDeclSyntax> {
  private var ctorGens: [CtorGenerator] = []
  private var hasCtors: Bool = false
  private var methodGens: [MethodGenerator] = []


  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      methodGens.append(MethodGenerator(node, className: name))
    }
    return .skipChildren
  }
  
  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      ctorGens.append(CtorGenerator(node, className: name))
    }
    hasCtors = true
    return .skipChildren
  }

  func generate(with ctx: inout Context) -> String {
    let ctors: String
    if hasCtors {
      ctors = ctorGens.enumerated().map{$1.generate(with: &ctx, index: $0)}.joined(separator: "\n\n")
    } else {
      ctors =
"""
  public \(name)() {
    this(\(name).init());
  }
  private static native long init();
"""
    }
    
    let std_ctor_dtor: String
    if settings.javaVersion >= 9 {
      std_ctor_dtor =
"""
  private static final Cleaner cleaner = Cleaner.create();

  private static class Deinit implements Runnable {
      private final long _ptr;

      Deinit(long ptr) {
        _ptr = ptr;
      }

      public void run() {
        \(name).deinit(_ptr);
      }
  }

  private \(name)(long ptr) {
     _ptr = ptr;
     cleaner.register(this, new Deinit(_ptr));
  }
"""

    } else {
      std_ctor_dtor =
"""
  private \(name)(long ptr) {
     _ptr = ptr;
  }

  @Override
  public void finalize() {
    \(name).deinit(_ptr);
  }
"""
    }

    var class_init =
"""
  static {
    \((typeDecl.parents.first ?? typeDecl).typeName).class_init();
  }
"""

    if !nested {
      class_init +=
"""

  private static void class_init() {
    if(!class_initialized) {
      \(name)_class_init(\(name).class);
      class_initialized = true;
    }
  }
  private static boolean class_initialized = false;
  private static native void \(name)_class_init(Class<?> cls);
"""
    }

    return
"""
public \(nested ? "static" : "") class \(name) {

\(class_init)

  private final long _ptr;

\(std_ctor_dtor)

  private static native void deinit(long ptr);

\(ctors)

\(methodGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))

  \(nestedTypeGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))
}
"""
  }
}


class MethodGenerator {
  typealias Context = ProxyGenerator.Context

  private let funcDecl: FunctionDeclSyntax
  private let className: String

  var name: String { funcDecl.name.text }

  init(_ funcDecl: FunctionDeclSyntax, className: String) {
    self.funcDecl = funcDecl
    self.className = className
  }

  func generate(with ctx: inout Context) -> String {
    let params = funcDecl.signature.paramsMapping(with: &ctx)
    let retType = funcDecl.signature.returnClause?.type.map(with: &ctx) ?? "void"

    let callParams = (funcDecl.isStatic ? [] : ["_ptr"]) + params.map{$0.name}

    var call = (funcDecl.isStatic ? className : "this") +  ".\(name)Impl(\(callParams.joined(separator: ", ")))"
    call = funcDecl.signature.returnClause != nil ? "return \(call)" : call

    let paramDecls = params.map {"\($0.type) \($0.name)"}
    let paramDeclsImpl = (funcDecl.isStatic ? [] : ["long ptr"]) + paramDecls
    
    let modifiers = funcDecl.isStatic ? "static" : ""

    return
"""
  public \(modifiers) \(retType) \(name)(\(paramDecls.joined(separator: ", "))) {
    \(call);
  }
  private \(modifiers) native \(retType) \(name)Impl(\(paramDeclsImpl.joined(separator: ", ")));
"""
  }
}


class CtorGenerator {
  private let initDecl: InitializerDeclSyntax
  private let className: String

  init(_ initDecl: InitializerDeclSyntax, className: String) {
    self.initDecl = initDecl
    self.className = className
  }

  func generate(with ctx: inout MethodGenerator.Context, index: Int) -> String {
    let params = initDecl.signature.paramsMapping(with: &ctx)

    let callParams = params.map { $0.name }.joined(separator: ", ")
    let paramDecls = params.map { "\($0.type) \($0.name)" }.joined(separator: ", ")

    return
"""
  public \(className)(\(paramDecls)) {
    this(\(className).init\(index)(\(callParams)));
  }
  private static native long init\(index)(\(paramDecls));
"""
  }
}



protocol MappableTypeSyntax: TypeSyntaxProtocol {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String
}


// MARK: - Extensions


extension FunctionSignatureSyntax {
  func paramsMapping(with ctx: inout ProxyGenerator.Context) -> [(name: String, type: String)] {
    parameterClause.parameters.map {
      (name: ($0.secondName ?? $0.firstName).text, type: $0.type.map(with: &ctx))
    }
  }
}


extension TypeSyntax {
  var supportedMappings: [any MappableTypeSyntax.Type] {[
    IdentifierTypeSyntax.self,
    FunctionTypeSyntax.self,
    ArrayTypeSyntax.self
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



extension IdentifierTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    switch name.text {
    case "String": "String"
    case "Bool": primitivesAsObjects ? "Boolean" : "boolean"
    case "Int", "Int64": primitivesAsObjects ? "Long" : "long"
    case "Int32": primitivesAsObjects ? "Integer" : "int"
    case "Int16": primitivesAsObjects ? "Short" : "short"
    case "Int8": primitivesAsObjects ? "Byte" : "byte"
    case "Float": primitivesAsObjects ? "Float" : "float"
    case "Double": primitivesAsObjects ? "Double" : "double"
    case "Void": "void"
    default: name.text
    }
  }
}



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


extension ArrayTypeSyntax: MappableTypeSyntax {
  func map(with ctx: inout ProxyGenerator.Context, primitivesAsObjects: Bool) -> String {
    return element.map(with: &ctx, primitivesAsObjects: primitivesAsObjects) + "[]"
  }
}






