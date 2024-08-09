@_exported import Java

public enum Platform: Equatable {
    case android
    case darwin
    case linux
    case windows
}


@attached(peer, names: suffixed(_class_init))
@attached(member,
          names: named(jobj), named(javaClass), named(init_jni_t), named(init_jni), named(deinit_jni_t), named(deinit_jni), arbitrary)
@attached(extension, conformances: JObjectRepresentable, names: named(toJavaObject))
public macro exported(_ platforms: Platform...) =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaClassMacro")


@attached(peer, names: prefixed(__))
public macro exported() =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaMethodMacro")
