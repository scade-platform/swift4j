import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions

class EnumGenerator: TypeGenerator<EnumDeclSyntax> { }


extension EnumGenerator: TypeGeneratorProtocol {
  var isRefType: Bool { return false }

  func generate(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    return typeDecl.withAssociatedValues
      ? generateSealedClass(with: &ctx)
      : generateEnum(with: &ctx)
  }

  func generateSealedClass(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    return KotlinTypeProxy(name: name, source:
"""
sealed class \(name)(protected val ptr: SwiftPtr) {
  constructor(ptr: Long, owns: Boolean = true): this(SwiftPtr(ptr, owns))

  private companion object {
      val class_initialized: Boolean
      init {          
          \(name)_class_init()          
          class_initialized = true
      }

      @JvmStatic      
      external fun \(name)_class_init()

      @JvmStatic
      external fun deinit(ptr: Long)
      
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
  }

  private fun ptr(): Long {
      return ptr.get()
  }

\(typeDecl.caseDecls().map{$0.generateCaseType(with: &ctx, in: typeDecl.typeName)}.joined(separator: "\n\n"))
}
"""
    )
  }

  func generateEnum(with ctx: inout ProxyGenerator.Context) -> TypeProxy {
    return JavaTypeProxy(name: name, source:
"""
public enum \(name) {
  \(typeDecl.cases().joined(separator: ", "));
}
"""
    )
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
  object \(jvmName) : \(enumName)(\(jvmExtCtorName)(), false)
"""
    }

    let paramsMapping = ctx.with(language: .kotlin) { self.paramsMapping(with: &$0) }

    let params = paramsMapping.map{ $0.name }.joined(separator: ", ")
    let paramDecls = paramsMapping.map{ "\($0.name): \($0.type)" }.joined(separator: ", ")

    return
"""
  class \(jvmName) internal constructor(ptr: Long): \(enumName)(ptr) {
\(parameters.map{$0.generateGetter(with: &ctx, for: jvmName)}.joined(separator: "\n\n"))

    constructor(\(paramDecls)): this(\(jvmExtCtorName)(\(params)))
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
