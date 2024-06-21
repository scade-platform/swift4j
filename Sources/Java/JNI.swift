//
//  Java.swift
//  Java
//
//  Created by Grigory Markin on 29.11.18.
//

@_exported import CJNI

fileprivate var __jvm: UnsafeMutablePointer<JavaVM>!

public var env: UnsafeMutablePointer<JNIEnv> {
  let jvm = __jvm.pointee.pointee
  
  var tmp: UnsafeMutableRawPointer?
  let status = jvm.GetEnv(__jvm, &tmp, JavaInt(JNI_VERSION_1_6))
  var env = tmp?.bindMemory(to: JNIEnv.self, capacity: 1)
  
  switch status {
    case JNI_OK: break
    case JNI_EDETACHED:
      _ = jvm.AttachCurrentThread(__jvm, &env, nil)
    case JNI_EVERSION:
      fatalError("This version of JNI is not supported")
    default: break
  }
  
  return env!
}

/// TODO: wrap to a Swift structure to avoid double access to the 'env' 
public var jni: JNINativeInterface {
  return env.pointee.pointee
}

@_silgen_name("JNI_OnLoad")
public func JNI_OnLoad(jvm: UnsafeMutablePointer<JavaVM>, reserved: UnsafeMutableRawPointer) -> JavaInt {  
  __jvm = jvm  
  Java_init()
  return JNI_VERSION_1_6
}

public func checkExceptionAndThrow() throws {
  if jni.ExceptionCheck(env) == true {
    throw JNIError()
  }
}

public func checkExceptionAndClear() {
  if jni.ExceptionCheck(env) == true {
    jni.ExceptionClear(env)
  }
}

struct JNIError: Error {
  init() {
    jni.ExceptionDescribe(env)
    jni.ExceptionClear(env)
  }
}

extension JavaBoolean : ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = value ? JavaBoolean(JNI_TRUE) : JavaBoolean(JNI_FALSE)
  }
}

public extension JNINativeMethod {
  init<T>(name: StaticString, sig: StaticString, fn: T) {
    let name_ptr = UnsafeRawPointer(name.utf8Start).assumingMemoryBound(to: Int8.self)
    let sig_ptr = UnsafeRawPointer(sig.utf8Start).assumingMemoryBound(to: Int8.self)
    let fn_ptr = unsafeBitCast(fn, to: UnsafeMutableRawPointer.self)
    
    self.init(name: name_ptr, signature: sig_ptr, fnPtr: fn_ptr)
  }
}
