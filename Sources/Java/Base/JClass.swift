//
//  JClass.swift
//  JavaSupport
//
//  Created by Grigory Markin on 01.06.18.
//

import CJNI


public final class JClass : JObject {
  private static var _javaClasses: [String: JavaClass] = [:]

  private var _fqn: String?

  public var fqn: String {
    if let fqn = _fqn {
      return fqn
    }
    
    let fqn: String = call(method: Class__getName)
    self._fqn = fqn

    return fqn
  }

  public convenience init?(fqn: String) {
    if let jcls = JClass._javaClasses[fqn] {
      self.init(jcls)

    } else if let jcls = jni.FindClass(env, fqn) {
      JClass._javaClasses[fqn] = jcls
      self.init(jcls)

    } else {
      checkExceptionAndClear()
      return nil
    }
    
    self._fqn = fqn
  }



  public func getFieldID(name: String, sig: String) -> JavaFieldID? {
    defer {
      checkExceptionAndClear()
    }
    return jni.GetFieldID(env, self.ptr, name, sig)
  }
  
  public func getStaticFieldID(name: String, sig: String) -> JavaFieldID? {
    defer {
      checkExceptionAndClear()
    }
    return jni.GetStaticFieldID(env, self.ptr, name, sig)
  }
  
  
  
  
  public func getMethodID(name: String, sig: String)  -> JavaMethodID? {
    defer {
      checkExceptionAndClear()
    }    
    return jni.GetMethodID(env, self.ptr, name, sig)
  }
  
  public func getStaticMethodID(name: String, sig: String)  -> JavaMethodID? {
    defer {
      checkExceptionAndClear()
    }
    return jni.GetStaticMethodID(env, self.ptr, name, sig)
  }
  
  
  
  public func create(ctor: JavaMethodID, _ args: [JavaParameter]) -> JavaObject {
    guard let obj = jni.NewObject(env, self.ptr, ctor, args) else {
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
  
  
  
  
  public func setStatic<T: JConvertible>(field: JavaFieldID, value: T) {
    value.toStaticField(field, of: self.ptr)
  }
  
  public func setStatic<T: JConvertible>(field: String, value: T) {
    guard let fieldId = getStaticFieldID(name: field, sig: T.javaSignature) else {
      fatalError("Cannot find static field \(field) with signature \(T.javaSignature)")
    }
    value.toStaticField(fieldId, of: self.ptr)
  }
  
  
  
  
  public func callStatic(method: JavaMethodID, _ args : [JavaParameter]) -> Void {
    jni.CallStaticVoidMethodA(env, self.ptr, method, args)
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
  

  // Natives

  public func registerNatives(_ natives: JNINativeMethod...) throws {
    let _ = jni.RegisterNatives(env, self.ptr, natives, JavaInt(natives.count))
    try checkExceptionAndThrow()
  }
  
  public func unregisterNatives() {
    let _ = jni.UnregisterNatives(env, self.ptr)
  }
  
}

//@available(*, deprecated, renamed: "JClass.init", message: "Use the JClass initializer instead")
public func findJavaClass(fqn: String) -> JClass? {
  return JClass(fqn: fqn)
}


fileprivate let Class__class = JClass(fqn: "java/lang/Class")!
fileprivate let Class__getName = Class__class.getMethodID(name: "getName", sig: "()Ljava/lang/String;")!


fileprivate var __javaClasses = Dictionary<String, JClass>()

