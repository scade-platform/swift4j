import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum JavaMacrosError: Swift.Error {
  case message(String, Optional<SyntaxProtocol> = nil)
}

struct JavaMacrosWarnDiagnostic: DiagnosticMessage {
  let message: String

  var severity: DiagnosticSeverity = .warning

  var diagnosticID: MessageID {
    .init(domain: "SwiftJavaMacros", id: "JavaMacrosErrorDiagnostic")
  }
}

public extension SyntaxProtocol {
  @discardableResult
  func assert<S: SyntaxProtocol>(as syntaxType: S.Type, _ msg: String) throws -> S {
    guard let decl = self.as(syntaxType) else {
      throw JavaMacrosError.message(msg)
    }
    return decl
  }
}

extension MacroExpansionContext {
  func executeAndWarnIfFails<T>(at node: some SyntaxProtocol, _ f: () throws -> T) -> T? {
    do {
      return try f()
    } catch {
      if let err = error as? JavaMacrosError {
        switch err {
        case .message(let msg, .some(let errNode)):

          self.diagnose(Diagnostic(node: Syntax(errNode),
                                   message: JavaMacrosWarnDiagnostic(message: msg),
                                   fixIts: disableJavaMappingFixIt(at: node)))
          return nil
        default:
          break
        }
      }
      self.addDiagnostics(from: error, node: node)
      return nil
    }
  }

  func disableJavaMappingFixIt(at node: some SyntaxProtocol) -> [FixIt] {
    var newNode: Syntax? = nil
    
    var nonjvmAttr: AttributeListSyntax.Element = .attribute("@nonjvm")
    nonjvmAttr.trailingTrivia = .newline

    if let funcDecl = node.as(FunctionDeclSyntax.self) {
      var newFuncDecl = funcDecl.trimmed
      newFuncDecl.attributes.append(nonjvmAttr)
      newNode = Syntax(newFuncDecl)

    } else if let initDecl = node.as(InitializerDeclSyntax.self) {
      var newInitDecl = initDecl.trimmed
      newInitDecl.attributes.append(nonjvmAttr)
      newNode = Syntax(newInitDecl)
    }

    guard let newNode = newNode else {
      return []
    }
    
    return [FixIt(message: DisableJavaMappingFixItMessage(),
                  changes: [
                    FixIt.Change.replace(oldNode: Syntax(node),
                                         newNode: Syntax(newNode))
                 ])]
  }
}

struct DisableJavaMappingFixItMessage: FixItMessage {
  var message = "Add @nonjvm attribute to disable mapping for the given class member"

  var fixItID: MessageID {
    .init(domain: "SwiftJavaMacros", id: "DisableJavaMappingFixIt")
  }


}
