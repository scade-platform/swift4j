import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions


extension StructDeclSyntax: JvmValueTypeDeclSyntax {
  func expandToJavaObject(in context: some MacroExpansionContext) -> String {
    let fqn = fqn(from: context)
    return
"""
  let ptr = UnsafeMutablePointer<\(name.text)>.allocate(capacity: 1)
  ptr.initialize(to: self)  
  return \(typeName).javaClass.callStaticObjectMethod(method: "fromPtr", sig: "(J)L\(fqn);", Int(bitPattern: ptr))      
"""
  }
  

}


