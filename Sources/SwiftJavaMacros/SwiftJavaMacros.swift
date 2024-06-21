import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct SwiftJavaPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JavaClassMacro.self,
        JavaMethodMacro.self
    ]
}
