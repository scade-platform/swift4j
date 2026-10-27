import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class ClassGenerator<T: TypeDeclSyntax>: TypeGenerator<T> {
  private var varGens: [VarGenerator] = []
  private var methodGens: [MethodGenerator] = []

  private var ctorGens: [CtorGenerator] {
    typeDecl.exportedInitializers.map { CtorGenerator($0, className: name) }
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      varGens.append(VarGenerator(node, className: name, observationTracking: typeDecl.isObservable))
    }
    return .skipChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      methodGens.append(MethodGenerator(node, className: name))
    }
    return .skipChildren
  }
}


extension ClassGenerator: TypeGeneratorProtocol {
  func generate(with ctx: inout Context) -> TypeProxy {
    switch ctx.settings.language {
    case .java:
      return generateJava(with: &ctx)
    case .kotlin:
      return generateKotlin(with: &ctx)
    }
  }

  private func generateJava(with ctx: inout Context) -> TypeProxy {
    let ctors = ctorGens.enumerated().map{$1.generate(with: &ctx, index: $0)}.joined(separator: "\n\n")

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
      \(name)_class_init();
      class_initialized = true;
    }
  }
  private static boolean class_initialized = false;
  private static native void \(name)_class_init();
"""
    }

    let source =
"""
public \(nested ? "static" : "") class \(name) {

\(class_init)

  private final SwiftPtr _ptr;
    
  private long _ptr() {
    return _ptr.get();
  }
  
  private static \(name) fromPtr(long ptr) {
    return new \(name)(new SwiftPtr(ptr, \(name)::deinit));
  }
  
  private static native void deinit(long ptr);
  
  private \(name)(SwiftPtr ptr) {
    _ptr = ptr;
  }

\(ctors)

\(varGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))

\(methodGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))

\(nestedTypeGens.compactMap {
    let proxy = $0.generate(with: &ctx)
    guard proxy is JavaTypeProxy else { return nil }
    return proxy.source
  }
  .joined(separator: "\n\n")
)
}
"""
    return JavaTypeProxy(name: name, source: source)
  }

  private func generateKotlin(with ctx: inout Context) -> TypeProxy {
    let ctors = ctorGens.enumerated().map { $1.generate(with: &ctx, index: $0) }.joined(separator: "\n\n")
    let ctorNatives = ctorGens.enumerated().map {
      $1.generateKotlinNativeInitializer(with: &ctx, index: $0)
    }.joined(separator: "\n\n")

    let instanceVars = varGens.filter { !$0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let staticVars = varGens.filter { $0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let instanceMethods = methodGens.filter { !$0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let staticMethods = methodGens.filter { $0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let nestedTypes = nestedTypeGens.compactMap { generator -> String? in
      let proxy = generator.generate(with: &ctx)
      return proxy is KotlinTypeProxy ? proxy.source : nil
    }.joined(separator: "\n\n")

    let classInitialization: String
    if nested {
      classInitialization =
"""
    init {
      \((typeDecl.parents.first ?? typeDecl).typeName).class_init()
    }
"""
    } else {
      classInitialization =
"""
    private var classInitialized = false

    init {
      class_init()
    }

    @JvmStatic
    private fun class_init() {
      if (!classInitialized) {
        \(name)_class_init()
        classInitialized = true
      }
    }

    @JvmStatic
    private external fun \(name)_class_init()
"""
    }

    let source =
"""
\(nested ? "" : "public ")open class \(name) private constructor(private val _ptr: SwiftPtr) {

  private fun _ptr(): Long = _ptr.get()

\(ctors)

\(instanceVars)

\(instanceMethods)

\(nestedTypes)

  companion object {
\(classInitialization)

    @JvmStatic
    private fun fromPtr(ptr: Long): \(name) = \(name)(SwiftPtr(ptr, \(name)::deinit))

    @JvmStatic
    private external fun deinit(ptr: Long)

\(ctorNatives)

\(staticVars)

\(staticMethods)
  }
}
"""
    return KotlinTypeProxy(name: name, source: source)
  }
}
