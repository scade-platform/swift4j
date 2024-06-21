import Foundation

import SwiftSyntax
import SwiftParser


class ProxyGenerator: SyntaxVisitor {
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
    if node.hasAttribute(name: "JavaClass")  {
      classGens.append(ClassGenerator(node))
    }
    return .skipChildren
  }

  func generate(_ classGen: ClassGenerator) -> String {
"""
package \(self.package);

\(classGen.generate())
"""
  }

  func generatePackageClass() -> String {
"""
package \(self.package);

"""
  }
}

class ClassGenerator: SyntaxVisitor {
  private let classDecl: ClassDeclSyntax

  private var methodsGens: [MethodGenerator] = []

  var name: String { classDecl.name.text }

  init(_ classDecl: ClassDeclSyntax) {
    self.classDecl = classDecl
    super.init(viewMode: .fixedUp)

    walk(classDecl)
  }
  
  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.hasAttribute(name: "JavaMethod")  {
      methodsGens.append(MethodGenerator(node))
    }
    return .skipChildren
  }

  func generate() -> String {
"""
class \(name) {
  private long _ptr;

  static {
    \(name)_class_init();
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
  private static native void \(name)_class_init();

\(generateMethods())
}
"""
  }

  private func generateMethods() -> String {
    methodsGens.map{$0.generate()}.joined(separator: "\n\n")
  }
}


class MethodGenerator {
  private let funcDecl: FunctionDeclSyntax
  
  var name: String { funcDecl.name.text }
  
  var parameters: [(name: String, type: String)] {
    funcDecl.signature.parameterClause.parameters.map{
      (($0.secondName ?? $0.firstName).text, $0.type.map())
    }
  }

  init(_ funcDecl: FunctionDeclSyntax) {
    self.funcDecl = funcDecl
  }

  func generate() -> String {
"""
  public \(returnType) \(name)(\(paramDecls)) {
    return \(implCall);
  }
  private native \(returnType) \(name)Impl(\(paramDeclsImpl));
"""
  }

  private var paramDecls: String {
    parameters.map {"\($0.type) \($0.name)"}.joined(separator: ", ")
  }
  
  private var paramDeclsImpl: String {
    let params = ["long ptr"] + parameters.map {"\($0.type) \($0.name)"}
    return params.joined(separator: ", ")
  }

  private var implCall: String {
    let params = ["_ptr"] + parameters.map{$0.name}
    return "this.\(name)Impl(\(params.joined(separator: ", ")))"
  }

  private var returnType: String {
    funcDecl.signature.returnClause?.type.map() ?? "void"
  }
}



protocol AttributedDeclSyntax: DeclSyntaxProtocol {
  var attributes: AttributeListSyntax { get }
}


extension AttributedDeclSyntax {
  func hasAttribute(name: String) -> Bool {
    self.attributes.contains {
      guard case .attribute(let attr) = $0,
            let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
              return false
            }
      return attrName == name
    }
  }
}


extension ClassDeclSyntax: AttributedDeclSyntax {}
extension FunctionDeclSyntax: AttributedDeclSyntax {}


extension TypeSyntax {
  func map() -> String {
    if let identTypeSyntax = self.as(IdentifierTypeSyntax.self) {
      return identTypeSyntax.map()
    }
    
    return ""
  }
}

extension IdentifierTypeSyntax {
  func map() -> String {
    switch self.name.text {
    case "String": "String"
    case "Bool": "boolean"
    case "Int", "Int64": "long"
    case "Int32": "int"
    case "Int16": "short"
    case "Int8": "byte"
    case "Float": "float"
    case "Double": "double"
    default: self.name.text
    }
  }
}
