//
//  Base.swift
//  JavaLang
//
//  Created by Grigory Markin on 14.11.18.
//

public protocol ObjectProtocol: AnyObject, JObjectConvertible {
  init(_ obj: JavaObject)
  var javaObject: JObject { get }
}

public extension ObjectProtocol {    
  func toJavaObject() -> JavaObject? {
    return javaObject.ptr
  }
  
  func box<T>() -> T where T: ObjectProtocol {
    return T.fromJavaObject(self.toJavaObject())
  }
  
  static func fromJavaObject(_ obj: JavaObject?) -> Self {
    guard let _obj = obj else { fatalError("Cannot instantiate non-null object from nil") }
    return mapJavaObject(_obj)
  }
}

//public extension ObjectProtocol {
//  public static var JavaClass: Class<Self> {
//    return Class<Self>(self.javaClass.ptr)
//  }
//}


open class ObjectBase: ObjectProtocol {
  public let javaObject: JObject
  
  open class var javaClass: JClass {
    return getJavaClass(from: self)
  }
  
  public required init(_ obj: JavaObject) {
    javaObject = JObject(obj)
  }
  
  public required init(ctor: JavaMethodID, _ args: [JavaParameter]) {
    //TODO: add checks
    let obj = type(of: self).javaClass.create(ctor: ctor, args)
    javaObject = JObject(obj)
    
    if let ptr_field = javaObject.cls.getFieldID(name: "_ptr", sig: "J") {
      let ptr = unsafeBitCast(self, to: Int.self)
      javaObject.set(field: ptr_field, value: Int64(ptr))
    }
  }
}


extension ObjectBase: Equatable {
  public static func == (lhs: ObjectBase, rhs: ObjectBase) -> Bool {
    return jni.IsSameObject(lhs.javaObject.ptr, rhs.javaObject.ptr) != 0
  }
}



fileprivate func mapJavaObject<T: ObjectProtocol>(_ obj: JavaObject) -> T {
  guard let jcls = jni.GetObjectClass(obj) else {
    fatalError("Cannot get Java class from Java object")
  }

  let cls = JClass(jcls)
  let fqn = String(cls.fqn.map{($0 == ".") ? "/" : $0})

  if let clazz = __classnameToSwiftClass[fqn] {
    return (clazz as! T.Type).init(obj)
  } else {
    return T.init(obj)
  }
}


fileprivate func getJavaClass<T: ObjectProtocol>(from type: T.Type) -> JClass {
  let typeId = ObjectIdentifier(type)
  guard let fqn = __swiftClassToClassname[typeId] else {
    var fqn = String(String(reflecting: type).map {
      $0 == "." ? "/" : $0
    })

    var cls = findJavaClass(fqn: fqn)

    if cls == nil {
      fqn = "com/\(fqn)"
      cls = findJavaClass(fqn: fqn)
    }

    guard let _cls = cls else {
      fatalError("Cannot find Java class '\(fqn)'")
    }

    __swiftClassToClassname[typeId] = fqn
    __classnameToSwiftClass[fqn] = type

    return _cls
  }

  guard let cls = findJavaClass(fqn: fqn) else {
    fatalError("Cannot find Java class '\(fqn)'")
  }

  return cls
}


public func registerJavaClass<T: ObjectProtocol>(_ type: T.Type, fqn: String) -> Void {
  __classnameToSwiftClass[fqn] = type
  __swiftClassToClassname[ObjectIdentifier(type)] = fqn
}

fileprivate var __classnameToSwiftClass = Dictionary<String, AnyClass>()
fileprivate var __swiftClassToClassname = Dictionary<ObjectIdentifier, String>()
