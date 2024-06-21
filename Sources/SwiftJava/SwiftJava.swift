import Java

@attached(peer, names: prefixed(__))
//@attached(member, names: named(javaObject))
@attached(extension, conformances: JObjectConvertible, names: named(javaClass))
public macro JavaClass() =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaClassMacro")


@attached(peer, names: prefixed(__))
//@attached(member, names: named(javaObject))
public macro JavaMethod() =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaMethodMacro")
