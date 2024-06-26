import Java

@attached(peer, names: suffixed(_class_init))
@attached(member, 
          names: named(jobj), named(javaClass), named(init_jni_t), named(init_jni), named(deinit_jni_t), named(deinit_jni), arbitrary)
@attached(extension, conformances: JObjectRepresentable, names: named(toJavaObject))
public macro JavaClass() =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaClassMacro")


@attached(peer, names: prefixed(__))
//@attached(member, names: named(javaObject))
public macro JavaMethod() =
  #externalMacro(module: "SwiftJavaMacros", type: "JavaMethodMacro")
