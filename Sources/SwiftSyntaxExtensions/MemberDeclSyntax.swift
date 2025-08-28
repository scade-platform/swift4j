import SwiftSyntax


public protocol MemberDeclSyntax: ExportableDeclSyntax {
  var isVoid: Bool { get }
  var isStatic: Bool { get }
  var isAsync: Bool { get }
  var isThrowing: Bool { get }
}


public extension MemberDeclSyntax {
  var isMainActorIsolated: Bool? {
    return hasAttribute("MainActor") ? false : nil
  }

  var isStatic: Bool {
    modifiers.contains {
      $0.name.text == "static"
    }
  }
}


