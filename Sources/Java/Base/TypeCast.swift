//
//  TypeCast.swift
//  Java
//
//  Created by Grigory Markin on 08.02.19.
//


public func cast<T: JInterfaceProxy>(_ obj: ObjectBase?, to: T.Type) -> T.Proto? {
  guard let _obj = obj else { return nil}
  
  guard let proto = _obj as? T.Proto else  {
    return T.init(_obj.javaObject.ptr) as? T.Proto
  }
  
  return proto  
}


public func cast<T: JInterfaceProxy>(_ objs: [ObjectBase?], to type: T.Type) -> [T.Proto?] {
  return objs.map{cast($0, to: type)}
}
