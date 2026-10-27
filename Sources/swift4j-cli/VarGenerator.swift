import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class VarGenerator {
  typealias Context = ProxyGenerator.Context

  private let varDecl: VariableDeclSyntax
  private let className: String
  private let observationTracking: Bool

  var isStatic: Bool { varDecl.isStatic }

  private var modifiers: String {
    varDecl.isStatic ? "static" : ""
  }

  private var callee: String {
    varDecl.isStatic ? className : "this"
  }

  init(_ varDecl: VariableDeclSyntax, className: String, observationTracking: Bool = false) {
    self.varDecl = varDecl
    self.className = className
    self.observationTracking = observationTracking
  }

  func generate(with ctx: inout Context) -> String {
    switch ctx.settings.language {
    case .java:
      return generateJava(with: &ctx)
    case .kotlin:
      return generateKotlin(with: &ctx)
    }
  }

  private func generateJava(with ctx: inout Context) -> String {
    return varDecl.decls.map {
"""
\(generateGetter(from: $0, with: &ctx))
\($0.readonly ? "" : generateSetter(from: $0, with: &ctx))
\($0.observable(varDecl) && observationTracking ? generateGetterWithObservationTracking(from: $0, with: &ctx) : "")
"""
    }.joined(separator: "\n")
  }

  private func generateKotlin(with ctx: inout Context) -> String {
    return varDecl.decls.map {
"""
\(generateKotlinProperty(from: $0, with: &ctx))
\($0.observable(varDecl) && observationTracking ? generateKotlinGetterWithObservationTracking(from: $0, with: &ctx) : "")
"""
    }.joined(separator: "\n")
  }

  private func generateGetter(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "get\(decl.capitalizedName)"
    let retType = decl.type.map(with: &ctx)

    let implParam: String,
        implParamDecl: String

    if varDecl.isStatic {
      implParam = ""
      implParamDecl = ""

    } else {
      implParam = "_ptr()"
      implParamDecl = "long ptr"
    }

    return
"""
  public \(modifiers) \(retType) \(name)() {
    return \(callee).\(name)Impl(\(implParam));
  }
  private \(modifiers) native \(retType) \(name)Impl(\(implParamDecl));
"""
  }

  private func generateSetter(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "set\(decl.capitalizedName)"
    let valType = decl.type.map(with: &ctx)

    let implParam: String,
        implParamDecl: String

    if varDecl.isStatic {
      implParam = "value"
      implParamDecl = "\(valType) value"

    } else {
      implParam = "_ptr(), value"
      implParamDecl = "long ptr, \(valType) value"
    }

    return
"""
  public \(modifiers) void \(name)(\(valType) value) {
    \(callee).\(name)Impl(\(implParam));
  }
  private \(modifiers) native void \(name)Impl(\(implParamDecl));
"""
  }

  private func generateGetterWithObservationTracking(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "get\(decl.capitalizedName)WithObservationTracking"
    let retType = decl.type.map(with: &ctx)

    return
"""
  public \(retType) \(name)(java.lang.Runnable onChange) {
    return \(callee).\(name)Impl(_ptr(), onChange);
  }
  private native \(retType) \(name)Impl(long ptr, java.lang.Runnable onChange);
"""
  }

  private func generateKotlinProperty(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let getterName = "get\(decl.capitalizedName)Impl"
    let setterName = "set\(decl.capitalizedName)Impl"
    let valueType = decl.type.map(with: &ctx)
    let getterParam = varDecl.isStatic ? "" : "_ptr()"
    let getterParamDecl = varDecl.isStatic ? "" : "ptr: Long"
    let setterParams = varDecl.isStatic ? "value" : "_ptr(), value"
    let setterParamDecls = varDecl.isStatic ? "value: \(valueType)" : "ptr: Long, value: \(valueType)"
    let propertyKind = decl.readonly ? "val" : "var"
    let openModifier = varDecl.isStatic ? "" : "open "
    let getterAnnotation = varDecl.isStatic ? "  @get:JvmStatic\n" : ""
    let setterAnnotation = varDecl.isStatic && !decl.readonly ? "  @set:JvmStatic\n" : ""
    let nativeAnnotation = varDecl.isStatic ? "  @JvmStatic\n" : ""

    let setter: String
    let setterNative: String
    if decl.readonly {
      setter = ""
      setterNative = ""
    } else {
      setter =
"""
    set(value) {
      \(setterName)(\(setterParams))
    }
"""
      setterNative =
"""
\(nativeAnnotation)  private external fun \(setterName)(\(setterParamDecls))
"""
    }

    return
"""
\(getterAnnotation)\(setterAnnotation)  \(openModifier)\(propertyKind) \(decl.name): \(valueType)
    get() = \(getterName)(\(getterParam))
\(setter)

\(nativeAnnotation)  private external fun \(getterName)(\(getterParamDecl)): \(valueType)
\(setterNative)
"""
  }

  private func generateKotlinGetterWithObservationTracking(from decl: VariableDeclSyntax.VarDecl, with ctx: inout Context) -> String {
    let name = "get\(decl.capitalizedName)WithObservationTracking"
    let retType = decl.type.map(with: &ctx)

    return
"""
  open fun \(name)(onChange: java.lang.Runnable): \(retType) {
    return \(name)Impl(_ptr(), onChange)
  }
  private external fun \(name)Impl(ptr: Long, onChange: java.lang.Runnable): \(retType)
"""
  }
}
