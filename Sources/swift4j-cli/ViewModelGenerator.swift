import Foundation

import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class ViewModelsGenerator: SyntaxVisitor {
  private let package: String

  private var viewModelGens: [ViewModelGenerator] = []

  init(package: String) {
    self.package = package
    super.init(viewMode: .fixedUp)
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.isObservable  {
      viewModelGens.append(ViewModelGenerator(node))
    }
    return .skipChildren
  }

  func run(path: String) throws -> [(classname: String, content: String)] {
    let url = URL(fileURLWithPath: path)
    let source = try String(contentsOf: url, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)

    walk(sourceFile)

    return viewModelGens.map { ($0.name, generate($0)) }
  }

  func generate(_ viewModelGen: ViewModelGenerator) -> String {
    var ctx = ProxyGenerator.Context(package: package,
                                     settings: .init(language: .kotlin))

    let viewModel = viewModelGen.generate(with: &ctx)

    return
"""
package \(self.package).viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStoreOwner

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

\(ctx.imports.map{"import \($0)"}.joined(separator: "\n"))

\(viewModel)
"""
  }
}


class ViewModelGenerator: SyntaxVisitor {
  private let classDecl: ClassDeclSyntax

  private var varDecls: [VariableDeclSyntax] = []

  var name: String {
    return classDecl.typeName + "ViewModel"
  }

  init(_ classDecl: ClassDeclSyntax) {
    self.classDecl = classDecl
    super.init(viewMode: .fixedUp)

    walk(classDecl)
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.isObservable {
      varDecls.append(node)
    }
    return .skipChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    return .skipChildren
  }

  func generate(with ctx: inout ProxyGenerator.Context) -> String {
    //ctx.imports.insert("\(ctx.package).\(classDecl.typeName)")
    ctx.imports.insert("\(ctx.package).*")

    let decls = varDecls.flatMap { varDecl in
      varDecl.decls
        .filter{ $0.observable(varDecl) }
        .map{ generate($0, with: &ctx)}
    }

    return
"""
class \(name)(
    val model: \(classDecl.typeName)
) : ViewModel() {
  \(decls.joined(separator: "\n"))
}

class \(name)Factory(
    private val model: \(classDecl.typeName)
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(\(name)::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return \(name)(model) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

fun \(classDecl.typeName).viewModel(owner: ViewModelStoreOwner): \(name) {
    return ViewModelProvider(owner, object : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            if (modelClass.isAssignableFrom(\(name)::class.java)) {
                return \(name)(this@viewModel) as T
            }
            throw IllegalArgumentException("Unknown ViewModel class")
        }
    })[\(name)::class.java]
}
"""
  }

  private func generate(_ decl: VariableDeclSyntax.VarDecl, with ctx: inout ProxyGenerator.Context) -> String {
    let name = decl.name
    let nameCap = decl.capitalizedName

    let type = decl.type.map(with: &ctx, primitivesAsObjects: true)

    return
"""
    private val _\(name) = MutableStateFlow(get\(nameCap)WithTracking())
    val \(name): StateFlow<\(type)> = _\(name).asStateFlow()

    private fun get\(nameCap)WithTracking(): \(type) {
        return model.get\(nameCap)WithObservationTracking {
            viewModelScope.launch(Dispatchers.Main) {
              _\(name).value = get\(nameCap)WithTracking()               
            }
        }
    }

    fun update\(nameCap)(value: \(type)) {
        model.\(name) = value
    }
"""
  }
}
