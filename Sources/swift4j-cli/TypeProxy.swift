

protocol TypeProxy {
  var name: String { get }
  var source: String { get }

  func generate(in package: String, with imports: [String]) -> (filename: String, source: String)
}


struct JavaTypeProxy : TypeProxy {
  let name: String
  let source: String

  func generate(in package: String, with imports: [String]) -> (filename: String, source: String) {
    let content =
"""
package \(package);

import io.scade.swift4j.SwiftPtr; 

\(imports.map{"import \($0);"}.joined(separator: "\n"))

\(source)
"""
    return (filename: "\(name).java", content)
  }
}


struct KotlinTypeProxy : TypeProxy {
  let name: String
  let source: String

  func generate(in package: String, with imports: [String]) -> (filename: String, source: String) {
    let content =
"""
package \(package)

import io.scade.swift4j.SwiftPtr 

\(imports.map{"import \($0)"}.joined(separator: "\n"))

\(source)
"""
    return (filename: "\(name).kt", content)
  }
}
