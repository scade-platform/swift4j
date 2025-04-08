//
//  Optional+JConvertible.swift
//  Java
//
//  Created by Grigory Markin on 07.02.19.
//


extension Optional: JObjectConvertible, JConvertible, JParameterConvertible where Wrapped: JObjectConvertible {
  public static var javaClass: JClass {
    return Wrapped.javaClass
  }
  
  public static func fromJavaObject(_ obj: JavaObject?) -> Optional<Wrapped> {
    if let _obj = obj {
      return Wrapped.fromJavaObject(_obj)
    }
    return nil
  }
  
  public func toJavaObject() -> JavaObject? {
    if let this = self {
      return this.toJavaObject()
    }
    return nil
  }
}


extension Optional where Wrapped: JPrimitiveConvertible {
  public static func fromJavaObject(_ obj: JavaObject?) -> Optional<Wrapped> {
    if let _obj = obj {
      return Wrapped.fromJavaObject(_obj)
    }
    return nil
  }

  public func toJavaObject() -> JavaObject? {
    if let this = self {
      return this.toJavaObject()
    }
    return nil
  }
}
