//
//  JObject.swift
//  JavaSupport
//
//  Created by Grigory Markin on 01.06.18.
//

import CJNI


public class JObject {
  public let ptr: JavaObject
  public let weak: Bool

  public lazy var cls: JClass = {
    let obj = jni.CallObjectMethod(env, ptr, Object__getClass, [])!
    return JClass(obj)
  }()
  
  public init(_ ptr: JavaObject, weak: Bool = false) {
    self.ptr = weak ? ptr : jni.NewGlobalRef(env, ptr)!
    self.weak = weak
  }
    
  deinit {
    if self.weak {
      jni.DeleteGlobalRef(env, self.ptr)
    }
  }
  

  public func get<T: JConvertible>(field: JavaFieldID) -> T {
    return T.fromField(field, of: ptr)
  }
    
  public func get<T: JConvertible>(field: String, sig: String) -> T {
    guard let fieldId = cls.getFieldID(name: field, sig: sig) else {
      fatalError("Cannot find field \(field) with signature \(sig)")
    }
    return self.get(field: fieldId)
  }
  
  public func get<T: JConvertible>(field: String) -> T {
    return self.get(field: field, sig: T.javaSignature)  
  }
  
  
  
  public func set<T: JConvertible>(field: JavaFieldID, value: T) {
    value.toField(field, of: ptr)
  }
    
  public func set<T: JConvertible>(field: String, sig: String, value: T) {
    guard let fieldId = cls.getFieldID(name: field, sig: sig) else {
      fatalError("Cannot find field \(field) with signature \(sig)")
    }
    value.toField(fieldId, of: ptr)
  }
  
  public func set<T: JConvertible>(field: String, value: T) {
    self.set(field: field, sig: T.javaSignature, value: value)
  }
  


  public func call(method: JavaMethodID, _ args : [JavaParameter]) -> Void {
    jni.CallVoidMethod(env, ptr, method, args)
  }
  
  public func call(method: String, sig: String, _ args : [JavaParameter]) -> Void {
    guard let methodId = cls.getMethodID(name: method, sig: sig) else  {
      fatalError("Cannot find method \"\(method)\" with signature \"\(sig)\"")
    }
    return call(method: methodId, args) as Void
  }

  public func call(method: JavaMethodID, _ args : JParameterConvertible...) -> Void {
    call(method: method, args.map{$0.toJavaParameter()}) as Void
  }

  public func call(method: String, sig: String, _ args : JParameterConvertible...) -> Void {
    call(method: method, sig: sig, args.map{$0.toJavaParameter()}) as Void
  }

  public func call(method: String, _ args : JConvertible...) -> Void {
    let sig = "(\(args.reduce("", { $0 + type(of: $1).javaSignature})))V"
    return call(method: method, sig: sig, args.map{$0.toJavaParameter()}) as Void
  }
  
  


  public func call<T>(method: JavaMethodID, _ args: [JavaParameter]) -> T where T: JConvertible {
    return T.fromMethod(method, on: ptr, args: args)
  }
  
  public func call<T>(method: String, sig: String, _ args: [JavaParameter]) -> T where T: JConvertible {
    guard let methodId = cls.getMethodID(name: method, sig: sig) else  {
      let methods = cls.call(method: "getMethods", sig: "()[Ljava/lang/reflect/Method;") as [Object]
      let methods_sigs: [String] = methods.map{$0.javaObject.call(method: "toGenericString")}

      fatalError("Cannot find method \"\(method)\" with signature \"\(sig)\". Available methods: \n \(methods_sigs.joined(separator: "\n"))")
    }
    return call(method: methodId, args)
  }

  public func call<T>(method: JavaMethodID, _ args: JParameterConvertible...) -> T where T: JConvertible {
    return call(method: method, args.map{$0.toJavaParameter()})
  }
  
  public func call<T>(method: String, sig: String, _ args: JParameterConvertible...) -> T where T: JConvertible {
    return call(method: method, sig: sig, args.map{$0.toJavaParameter()})
  }

  public func call<T>(method: String, _ args : JConvertible...) -> T where T: JConvertible {
    let sig = "(\(args.reduce("", { $0 + type(of: $1).javaSignature})))\(T.javaSignature)"
    return call(method: method, sig: sig, args.map{$0.toJavaParameter()})
  }
}



fileprivate let Object__class = JClass(jni.FindClass(env, "java/lang/Object")!)
fileprivate let Object__getClass = Object__class.getMethodID(name: "getClass", sig: "()Ljava/lang/Class;")!

//fileprivate let Object__hashcode = jni.GetMethodID(env, Object__class, "hashCode", "()I")!


//fileprivate func hashCode(_ obj: JavaObject) -> Int32 {
//  return Int32.fromMethod(Object__hashcode, on: obj, args: [])
//}







