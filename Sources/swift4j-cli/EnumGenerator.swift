import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class EnumGenerator: TypeGenerator<EnumDeclSyntax> {
  private var varGens: [VarGenerator] = []
  private var methodGens: [MethodGenerator] = []

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      varGens.append(VarGenerator(node, className: name))
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


extension EnumGenerator: TypeGeneratorProtocol {
  var isRefType: Bool { return false }

  func generate(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    if typeDecl.bridgedAsClass {
      return ctx.with(language: .kotlin) { kotlinContext in
        generateSealedClass(with: &kotlinContext)
      }
    }
    return generateEnum(with: &ctx)
  }

  func generateSealedClass(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    let instanceVars = varGens.filter { !$0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let staticVars = varGens.filter { $0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let instanceMethods = methodGens.filter { !$0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let staticMethods = methodGens.filter { $0.isStatic }.map { $0.generate(with: &ctx) }.joined(separator: "\n\n")
    let nestedTypes = nestedTypeGens.compactMap { generator -> String? in
      let proxy = generator.generate(with: &ctx)
      return proxy is KotlinTypeProxy ? proxy.source : nil
    }.joined(separator: "\n\n")

    return KotlinTypeProxy(name: name, source:
"""
sealed class \(name)(protected val ptr: SwiftPtr) {

  private fun _ptr(): Long = ptr.get()

\(instanceVars)

\(instanceMethods)

\(typeDecl.caseDecls().map{$0.generateCaseType(with: &ctx, in: typeDecl.typeName)}.joined(separator: "\n\n"))

\(nestedTypes)

  companion object {
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

      @JvmStatic
      private external fun deinit(ptr: Long)
      
\(
  typeDecl.caseDecls().map{
    $0.generateCaseExtCtor(with: &ctx)
  }.joined(separator: "\n\n")
)

\(
  typeDecl.caseDecls().flatMap { c in
    c.parameters.map { p in
      p.generateExtGetter(with: &ctx, for: c.jvmName)
    }
  }.joined(separator: "\n\n")
)

\(staticVars)

\(staticMethods)
  }
}
"""
    )
  }

  func generateEnum(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    switch ctx.settings.language {
    case .java:
      return JavaTypeProxy(name: name, source:
"""
public enum \(name) {
  \(typeDecl.cases().joined(separator: ", "));
}
"""
      )
    case .kotlin:
      return KotlinTypeProxy(name: name, source:
"""
enum class \(name) {
  \(typeDecl.cases().joined(separator: ", "))
}
"""
      )
    }
  }
}


fileprivate extension EnumCaseElementSyntax {
  var jvmName: String { name.text }
  var jvmExtCtorName: String { jvmName + "Impl" }

  func generateCaseExtCtor(with ctx: inout ProxyGenerator.Context) -> String {
    let paramDecls = ctx.with(language: .kotlin) { ctx in
      paramsMapping(with: &ctx).map{ "\($0.name): \($0.type)" }.joined(separator: ", ")
    }

    return
"""
      @JvmStatic
      external fun \(jvmExtCtorName)(\(paramDecls)): Long
"""
  }

  func generateCaseType(with ctx: inout ProxyGenerator.Context, in enumName: String) -> String {
    if parameters.isEmpty {
      return
"""
  object \(jvmName) : \(enumName)(SwiftPtr(\(jvmExtCtorName)()))
"""
    }

    let paramsMapping = ctx.with(language: .kotlin) { self.paramsMapping(with: &$0) }

    let params = paramsMapping.map{ $0.name }.joined(separator: ", ")
    let paramDecls = paramsMapping.map{ "\($0.name): \($0.type)" }.joined(separator: ", ")

    return
"""
  class \(jvmName) internal constructor(ptr: SwiftPtr): \(enumName)(ptr) {
\(parameters.map{$0.generateGetter(with: &ctx, for: jvmName)}.joined(separator: "\n\n"))

    constructor(\(paramDecls)): this(SwiftPtr(\(jvmExtCtorName)(\(params)), \(enumName)::deinit))

    private companion object {
      @JvmStatic
      fun fromPtr(ptr: Long): \(jvmName) {
        return \(jvmName)(SwiftPtr(ptr, \(enumName)::deinit))
      }      
    }
  }
"""
  }
}


fileprivate extension ParameterSyntax {
  func extGetterName(name: String, in enumCaseName: String) -> String {
    "get\(enumCaseName.capitalized)\(name.capitalized)Impl"
  }

  func generateGetter(with ctx: inout ProxyGenerator.Context, for enumCaseName: String) -> String {
    let mapping = ctx.with(language: .kotlin){ map(with: &$0) }
    return
"""
    val \(mapping.name): \(mapping.type)
      get() = \(extGetterName(name: mapping.name, in: enumCaseName))(ptr.get())
"""
  }
  
  func generateExtGetter(with ctx: inout ProxyGenerator.Context, for enumCaseName: String) -> String {
    let mapping = ctx.with(language: .kotlin){ map(with: &$0) }

    return
"""
      @JvmStatic
      external fun \(extGetterName(name: mapping.name, in: enumCaseName))(ptr: Long): \(mapping.type)
"""
  }
}
