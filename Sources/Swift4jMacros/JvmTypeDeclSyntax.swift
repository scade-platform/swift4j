import SwiftSyntax
import SwiftSyntaxMacros

import SwiftSyntaxExtensions


protocol JvmTypeDeclSyntax: TypeDeclSyntax {
  var shouldExpandMemberDecls: Bool { get }

  func expandJavaObjectDecls(in context: some MacroExpansionContext) throws -> String
  func expandCtorDecls(in context: some MacroExpansionContext) throws -> String
}



extension JvmTypeDeclSyntax {
  var shouldExpandMemberDecls: Bool { true }
  
  func expandPeer(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    guard shouldExpandMemberDecls else { return [] }

    var fqnEscaped = typeName
    if let moduleName = moduleName(from: context) {
      fqnEscaped = moduleName.replacingOccurrences(of: "_", with: "_1") + "_" + fqnEscaped
    }

    let decl =
"""
@_cdecl("Java_\(fqnEscaped)_\(typeName)_1class_1init")
func \(typeName)_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {    
  \(expandRegisterNatives(in: context))
}
"""
    return ["\(raw: decl)"]
  }

  func expandMembers(in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    let syntax =
"""
\(expandJavaClassDecl(in: context))
\(try expandJavaObjectDecls(in: context))
\(try expandCtorDecls(in: context))
\(expandFuncDecls(in: context))
\(expandVarDecls(in: context))
"""

    return ["\(raw: syntax)"]
  }
}



