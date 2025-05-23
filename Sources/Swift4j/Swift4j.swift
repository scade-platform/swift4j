@_exported import Java

public enum Platform: Equatable {
    case macOS
    case Linux
    case Windows
    case Android
}

@attached(extension,
          conformances: JObjectConvertible,
          names: named(toJavaObject), named(fromJavaObject))
@attached(peer, names: suffixed(_class_init))
@attached(member,
          names: 
            named(jobj),
            named(javaClass),
            named(deinit_jni_t),
            named(deinit_jni),
            arbitrary)
public macro jvm() =
  #externalMacro(module: "Swift4jMacros", type: "JvmMacro")

/*
public macro jvm(_ platforms: Platform...,
                 implements: String? = nil) =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaClassMacro")
*/

@attached(peer)
public macro nonjvm() =
  #externalMacro(module: "Swift4jMacros", type: "NonjvmMacro")
