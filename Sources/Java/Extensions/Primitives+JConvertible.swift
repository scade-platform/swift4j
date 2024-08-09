//
//  String.swift
//  JavaUtil
//
//  Created by Grigory Markin on 24.08.18.
//

import CJNI

public protocol JPrimitiveObjectProtocol: ObjectProtocol {
  associatedtype ConvertibleType: JConvertible
  
  var value: ConvertibleType { get }
  
  init(_ value: ConvertibleType)
  
  init(_ obj: JavaObject)
}

//------------------------------------------------------------------------

fileprivate protocol JPrimitiveObjectInternalProtocol: JPrimitiveObjectProtocol {
  static var __method__init : JavaMethodID { get }
  static var __method__value : JavaMethodID { get }
}


extension JPrimitiveObjectInternalProtocol {
  public init(_ value: ConvertibleType) {
    self.init(Self.javaClass.create(ctor: Self.__method__init, value))
  }
  
  public var value: ConvertibleType {
    return self.javaObject.call(method: Self.__method__value)
  }
}

//------------------------------------------------------------------------

public protocol JPrimitiveConvertible : JNullInitializable {
  associatedtype PrimitiveType: JPrimitiveObjectProtocol
}

extension JPrimitiveConvertible where PrimitiveType.ConvertibleType == Self {
  public func toJavaObject() -> JavaObject? {
    return PrimitiveType(self).javaObject.ptr
  }
  
  public static func fromJavaObject(_ obj: JavaObject) -> Self {
    return PrimitiveType(obj).value
  }
}




// ----------- Boolean -----------

final public class JBoolean: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Bool
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Boolean")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(Z)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "booleanValue", sig: "()Z")!
}

extension Bool: JPrimitiveConvertible {
  public typealias PrimitiveType = JBoolean
  
  public static let javaSignature = "Z"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Bool {
    return jni.CallBooleanMethod(env, obj, method, args) == JNI_TRUE
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Bool {
    return jni.CallStaticBooleanMethodA(env, cls, method, args) == JNI_TRUE
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Bool {
    return jni.GetBooleanField(env, obj, field) == JNI_TRUE
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) -> Void {
    jni.SetBooleanField(env, obj, field, (self) ? 1 : 0)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Bool {
    return jni.GetStaticBooleanField(env, cls, field) == JNI_TRUE
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Void {
    jni.SetBooleanField(env, cls, field, (self) ? 1 : 0)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(bool: (self) ? 1 : 0)
  }
}


// ----------- Byte -----------

final public class JByte: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Int8
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Byte")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(B)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "byteValue", sig: "()B")!
}


extension Int8: JPrimitiveConvertible {
  public typealias PrimitiveType = JByte
  
  public static let javaSignature = "B"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int8 {
    return jni.CallByteMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int8 {
    return jni.CallStaticByteMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int8 {
    return jni.GetByteField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetByteField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int8 {
    return jni.GetStaticByteField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticByteField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(byte: self)
  }
}

// ----------- Char -----------

final public class JChar: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = UInt16
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Character")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(C)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "charValue", sig: "()C")!
}


extension UInt16: JPrimitiveConvertible {
  public typealias PrimitiveType = JChar
  
  public static let javaSignature = "C"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> UInt16 {
    return jni.CallCharMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> UInt16 {
    return jni.CallStaticCharMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> UInt16 {
    return jni.GetCharField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetCharField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> UInt16 {
    return jni.GetStaticCharField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticCharField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(char: self)
  }
}

// ----------- Short -----------

final public class JShort: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Int16
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Short")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(S)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "shortValue", sig: "()S")!
}


extension Int16: JPrimitiveConvertible {
  public typealias PrimitiveType = JShort
  
  public static let javaSignature = "S"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int16 {
    return jni.CallShortMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int16 {
    return jni.CallStaticShortMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int16 {
    return jni.GetShortField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetShortField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int16 {
    return jni.GetStaticShortField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticShortField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(short: self)
  }
}


// ----------- Integer -----------

final public class JInteger: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Int32
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Integer")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(I)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "intValue", sig: "()I")!
}


extension Int32: JPrimitiveConvertible {
  public typealias PrimitiveType = JInteger

  public static let javaSignature = "I"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int32 {
    return jni.CallIntMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int32 {
    return jni.CallStaticIntMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int32 {
    return jni.GetIntField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetIntField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int32 {
    return jni.GetStaticIntField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticIntField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(int: self)
  }
}


// ----------- Long -----------

final public class JLong: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Int64
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Long")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(J)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "longValue", sig: "()J")!
}


extension Int64: JPrimitiveConvertible {
  public typealias PrimitiveType = JLong

  public static let javaSignature = "J"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int64 {
    return jni.CallLongMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int64 {
    return jni.CallStaticLongMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int64 {
    return jni.GetLongField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetLongField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int64 {
    return jni.GetStaticLongField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticLongField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(long: self)
  }
}


// ----------- Int -----------

extension Int: JPrimitiveConvertible {
  #if arch(x86_64) || arch(arm64)
  public typealias PrimitiveType = JLong
  private typealias Convertible = Int64
  public static let javaSignature = "J"
  #else
  public typealias PrimitiveType = JInteger
  private typealias Convertible = Int32
  public static let javaSignature = "I"
  #endif
  
  public static func fromJavaObject(_ obj: JavaObject) -> Int {
    return Int(Convertible.fromJavaObject(obj))
  }
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int {
    return Int(Convertible.fromMethod(method, on: obj, args: args))
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int {
    return Int(Convertible.fromStaticMethod(method, on: cls, args: args))
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int {
    return Int(Convertible.fromField(field, of: obj))
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    Convertible(self).toField(field, of: obj)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int {
    return Int(Convertible.fromStaticField(field, of: cls))
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    Convertible(self).toStaticField(field, of: cls)
  }
  
  public func toJavaObject() -> JavaObject? {
    return PrimitiveType(PrimitiveType.ConvertibleType(self)).javaObject.ptr
  }
  
  public func toJavaParameter() -> JavaParameter {
    return Convertible(self).toJavaParameter()
  }
}


// ----------- Float -----------

final public class JFloat: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Float
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Float")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(F)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "floatValue", sig: "()F")!
}

extension Float: JPrimitiveConvertible {
  public typealias PrimitiveType = JFloat
  
  public static let javaSignature = "F"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Float {
    return jni.CallFloatMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Float {
    return jni.CallStaticFloatMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Float {
    return jni.GetFloatField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetFloatField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Float {
    return jni.GetStaticFloatField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticFloatField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(float: self)
  }
}


// ----------- Double -----------

final public class JDouble: Object, JPrimitiveObjectInternalProtocol {
  public typealias ConvertibleType = Double
  
  public final override class var javaClass: JClass { return __class }
  
  fileprivate static let __class = findJavaClass(fqn: "java/lang/Double")!
  
  fileprivate static let __method__init = __class.getMethodID(name: "<init>", sig: "(D)V")!
  
  fileprivate static let __method__value = __class.getMethodID(name: "doubleValue", sig: "()D")!
}

extension Double: JPrimitiveConvertible {
  public typealias PrimitiveType = JDouble
  
  public static let javaSignature = "D"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Double {
    return jni.CallDoubleMethod(env, obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Double {
    return jni.CallStaticDoubleMethodA(env, cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Double {
    return jni.GetDoubleField(env, obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetDoubleField(env, obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Double {
    return jni.GetStaticDoubleField(env, cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticDoubleField(env, cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(double: self)
  }
}



// ----------- String -----------

extension String: JObjectConvertible, JNullInitializable {
  fileprivate static let __class = findJavaClass(fqn: "java/lang/String")!
  
  public static var javaClass: JClass {
    return __class
  }
  
  public static func fromJavaObject(_ obj: JavaObject) -> String {
    let chars = jni.GetStringUTFChars(env, obj, nil)
    let ret = String(cString: chars)
    jni.ReleaseStringUTFChars(env, obj, chars)
    return ret
  }
  
  public func toJavaObject() -> JavaObject? {
    return jni.NewStringUTF(env, self)
  }
}


