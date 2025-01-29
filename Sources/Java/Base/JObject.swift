//
//  JObject.swift
//  JavaSupport
//
//  Created by Grigory Markin on 01.06.18.
//

import CJNI

#if os(Linux) || os(Android)
  import Glibc
#else
  import Darwin
#endif



public class JObject: @unchecked Sendable {
  public let ptr: JavaObject
  public let weak: Bool

  public lazy var cls: JClass = {
    JClass(jni.CallObjectMethod(ptr, Object__getClass, [])!)
  }()
  
  public init(_ ptr: JavaObject, weak: Bool = false) {
    self.ptr = weak ? ptr : jni.NewGlobalRef(ptr)!
    self.weak = weak
  }
    
  deinit {
    if !self.weak {
      jni.DeleteGlobalRef(self.ptr)
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
    jni.CallVoidMethod(ptr, method, args)
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


public final class JObjectRef<T: JObjectConvertible & AnyObject>: @unchecked Sendable {
  private var jobj: JObject?
  // private var mutex = pthread_mutex_t()

  public init(jobj: JObject? = nil) {
    self.jobj = jobj
    //pthread_mutex_init(&self.mutex, nil)
  }

  deinit {
    //pthread_mutex_destroy(&self.mutex)
  }

  public func from(_ obj: T) -> JavaObject {
    if let jobj = jobj {
      return jobj.ptr
    }

    jobj = JObject(T.javaClass.create(unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)), weak: true)
    return jobj!.ptr

    /*
    return withLock { jobj in
      if let jobj = jobj {
        return jobj.ptr
      }

      jobj = JObject(T.javaClass.create(unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)), weak: true)
      return jobj!.ptr
    }
    */
  }

  public func release() {
    self.jobj = nil
    
    /*
    withLock {
      $0 = nil
    }
    */
  }

  /*
  private func withLock<R>(_ body: @Sendable (inout JObject?) -> R) -> R {
    pthread_mutex_lock(&self.mutex); defer { pthread_mutex_unlock(&self.mutex) }
    return body(&jobj)
  }
  */
}



fileprivate let Object__class = JClass(jni.FindClass("java/lang/Object")!)
fileprivate let Object__getClass = Object__class.getMethodID(name: "getClass", sig: "()Ljava/lang/Class;")!

