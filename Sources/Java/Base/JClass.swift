//
//  JClass.swift
//  JavaSupport
//
//  Created by Grigory Markin on 01.06.18.
//

import CJNI


public final class JClass: JObject, @unchecked Sendable {
  private let _fqn: String?

  public var fqn: String {
    if let fqn = _fqn {
      return fqn
    }

    return call(method: Class__getName)
  }

  private init(_ ptr: JavaObject, fqn: String) {
    self._fqn = fqn
    super.init(ptr)
  }

  public override init(_ ptr: JavaObject, weak: Bool = false) {
    self._fqn = nil
    super.init(ptr, weak: weak)
  }

  public convenience init?(fqn: String) {
    guard let jcls = jni.FindClass(fqn) else {
      jni.checkExceptionAndClear()
      return nil
    }

    self.init(jcls, fqn: fqn)
  }

  public func getFieldID(name: String, sig: String) -> JavaFieldID? {
    defer {
      jni.checkExceptionAndClear()
    }
    return jni.GetFieldID(self.ptr, name, sig)
  }
  
  public func getStaticFieldID(name: String, sig: String) -> JavaFieldID? {
    defer {
      jni.checkExceptionAndClear()
    }
    return jni.GetStaticFieldID(self.ptr, name, sig)
  }
  
  
  
  
  public func getMethodID(name: String, sig: String)  -> JavaMethodID? {
    defer {
      jni.checkExceptionAndClear()
    }
    return jni.GetMethodID(self.ptr, name, sig)
  }
  
  public func getStaticMethodID(name: String, sig: String)  -> JavaMethodID? {
    defer {
      jni.checkExceptionAndClear()
    }
    return jni.GetStaticMethodID(self.ptr, name, sig)
  }
  
  
  
  public func create(ctor: JavaMethodID, _ args: [JavaParameter]) -> JavaObject {
    guard let obj = jni.NewObject(self.ptr, ctor, args) else {
      //TODO: check and output exception
      fatalError("Cannot instantiate Java object")
    }
    return obj
  }
  
  public func create(_ args: [JConvertible], signature: String? = nil) -> JavaObject {
    let sig = signature ?? "(\(args.reduce("", { $0 + type(of: $1).javaSignature})))V"
    guard let ctorId = getMethodID(name: "<init>", sig: sig) else {
      fatalError("Cannot find constructor with signature (\(sig))V")
    }
    return create(ctor: ctorId, args.map{$0.toJavaParameter()})
  }
  
  public func create(ctor: JavaMethodID, _ params: JavaParameter...) -> JavaObject {
    return create(ctor: ctor, params)
  }
  
  public func create(ctor: JavaMethodID, _ args: JParameterConvertible...) -> JavaObject {
    return create(ctor: ctor, args.map{$0.toJavaParameter()})
  }
  
  public func create(_ args: JConvertible..., signature: String? = nil) -> JavaObject {
    return create(args, signature: signature)
  }
  
  public func create<T>(_ args: JConvertible..., signature: String? = nil) -> T where T: ObjectProtocol {
    return T(create(args, signature: signature))
  }


  public func getStatic<T: JConvertible>(field: JavaFieldID) -> T {
    return T.fromStaticField(field, of: ptr)
  }
  
  public func getStatic<T: JConvertible>(field: String) -> T {
    guard let fieldId = getStaticFieldID(name: field, sig: T.javaSignature) else {
      fatalError("Cannot find static field \(field) with signature \(T.javaSignature)")
    }
    return self.getStatic(field: fieldId)
  }

  public func getStatic(field: JavaFieldID) -> JObject? {
    guard let obj = jni.GetStaticObjectField(ptr, field) else {
      return nil
    }
    return JObject(obj)
  }

  public func getStatic(field: String, sig: String) -> JObject? {
    guard let fieldId = getStaticFieldID(name: field, sig: sig) else {
      fatalError("Cannot find static field \(field) with signature \(sig)")
    }
    return self.getStatic(field: fieldId)
  }



  public func setStatic<T: JConvertible>(field: JavaFieldID, value: T) {
    value.toStaticField(field, of: self.ptr)
  }
  
  public func setStatic<T: JConvertible>(field: String, value: T) {
    guard let fieldId = getStaticFieldID(name: field, sig: T.javaSignature) else {
      fatalError("Cannot find static field \(field) with signature \(T.javaSignature)")
    }
    setStatic(field: fieldId, value: value)
  }
  
  public func setStatic(field: JavaFieldID, value: JObject?) {
    jni.SetStaticObjectField(self.ptr, field, value?.ptr)
  }

  public func setStatic(field: String, sig: String, value: JObject?) {
    guard let fieldId = getStaticFieldID(name: field, sig: sig) else {
      fatalError("Cannot find static field \(field) with signature \(sig)")
    }
    setStatic(field: fieldId, value: value)
  }


  
  public func callStatic(method: JavaMethodID, _ args : [JavaParameter]) -> Void {
    jni.CallStaticVoidMethod(self.ptr, method, args)
  }

  public func callStatic(method: JavaMethodID, _ args : JParameterConvertible...) -> Void {
    callStatic(method:method, args.map{$0.toJavaParameter()})
  }

  public func callStatic(method: String, _ args : JConvertible...) -> Void {
    callStatic(method: method, args: args)
  }
  
  public func callStatic(method: String, args: [JConvertible]) -> Void {
     let sig = "(\(args.reduce("", { $0 + type(of: $1).javaSignature})))V"
    callStatic(method: method, sig: sig, args: args) as Void
  }
       
  public func callStatic(method: String, sig: String, _ args : JConvertible...) -> Void {
    callStatic(method: method, sig: sig, args: args)
  }
    
  public func callStatic(method: String, sig: String, args : [JConvertible]) -> Void {
    guard let methodId = getStaticMethodID(name: method, sig: sig) else  {
      fatalError("Cannot find static method \(method) with signature \(sig)")
    }
    callStatic(method: methodId, args.map{$0.toJavaParameter()}) as Void      
  }
      


  
  public func callStatic<T: JConvertible>(method: JavaMethodID, _ args: [JavaParameter]) -> T {
    return T.fromStaticMethod(method, on: self.ptr, args: args)
  }

  public func callStatic<T: JConvertible>(method: JavaMethodID, _ args: JParameterConvertible...) -> T {
    return callStatic(method: method, args.map{$0.toJavaParameter()})
  }

  public func callStatic<T>(method: String, _ args : JConvertible...) -> T where T: JConvertible {
    return callStatic(method: method, args: args)
  }
      
  public func callStatic<T>(method: String, args: [JConvertible]) -> T where T: JConvertible {
    let sig = "(\(args.reduce("", { $0 + type(of: $1).javaSignature})))\(T.javaSignature)"
    return callStatic(method: method, sig: sig, args: args)
  }
  
  public func callStatic<T>(method: String, sig: String, _ args : JConvertible...) -> T where T: JConvertible {    
    return callStatic(method: method, sig: sig, args: args)
  }
    
  public func callStatic<T>(method: String, sig: String, args : [JConvertible]) -> T where T: JConvertible {
    guard let methodId = getStaticMethodID(name: method, sig: sig) else  {
      fatalError("Cannot find static method \(method) with signature \(sig)")
    }
    return callStatic(method: methodId, args.map{$0.toJavaParameter()})        
  }


  public func callStaticObjectMethod(method: JavaMethodID, _ args : [JavaParameter]) -> JavaObject? {
    return jni.CallStaticObjectMethod(ptr, method, args)
  }

  public func callStaticObjectMethod(method: String, sig: String, _ args : [JavaParameter]) -> JavaObject? {
    guard let methodId = getStaticMethodID(name: method, sig: sig) else  {
      fatalError("Cannot find static method \"\(method)\" with signature \"\(sig)\"")
    }
    return callStaticObjectMethod(method: methodId, args) as JavaObject?
  }


  // Natives

  public func registerNatives(_ natives: JNINativeMethod...) throws {
    let _ = jni.RegisterNatives(self.ptr, natives)
    try jni.checkExceptionAndThrow()
  }
  
  public func unregisterNatives() {
    let _ = jni.UnregisterNatives(self.ptr)
  }
  
}

//@available(*, deprecated, renamed: "JClass.init", message: "Use the JClass initializer instead")
public func findJavaClass(fqn: String) -> JClass? {
  return JClass(fqn: fqn)
}


fileprivate let Class__class = JClass(fqn: "java/lang/Class")!
fileprivate let Class__getName = Class__class.getMethodID(name: "getName", sig: "()Ljava/lang/String;")!

