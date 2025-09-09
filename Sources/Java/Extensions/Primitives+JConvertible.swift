//
//  Primitives+JConvertible.swift
//  Java
//
//  Created by Grigory Markin on 24.08.18.
//

import CJNI


// MARK: - JPrimitiveObjectProtocol

public protocol JPrimitiveObjectProtocol: ObjectProtocol {
  associatedtype ConvertibleType: JConvertible

  static var javaValue: JavaMethodID { get }
  static var javaInitWithValue: JavaMethodID { get }
}


public extension JPrimitiveObjectProtocol {
  var value: ConvertibleType {
    return self.javaObject.call(method: Self.javaValue)
  }
  
  init(_ value: ConvertibleType) {
    self.init(Self.javaClass.create(ctor: Self.javaInitWithValue, value))
  }
}


// MARK: - JPrimitiveConvertable

public protocol JPrimitiveConvertible : JNullInitializable {
  associatedtype PrimitiveType: JPrimitiveObjectProtocol
}

extension JPrimitiveConvertible where PrimitiveType.ConvertibleType == Self {
  public func toJavaObject() -> JavaObject? {
    return PrimitiveType.javaClass.create(ctor: PrimitiveType.javaInitWithValue, self)
  }
  
  public static func fromJavaObject(_ obj: JavaObject) -> Self {
    return JObject(obj).call(method: PrimitiveType.javaValue)
  }
}




// MARK: - Bool

final public class JBoolean: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Bool

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Boolean")!

  public final override class var javaClass: JClass { return __class }

  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(Z)V")!
  
  public static let javaValue = __class.getMethodID(name: "booleanValue", sig: "()Z")!
}

extension Bool: JPrimitiveConvertible {
  public typealias PrimitiveType = JBoolean
  
  public static let javaSignature = "Z"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Bool {
    return jni.CallBooleanMethod(obj, method, args) == JNI_TRUE
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Bool {
    return jni.CallStaticBooleanMethod(cls, method, args) == JNI_TRUE
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Bool {
    return jni.GetBooleanField(obj, field) == JNI_TRUE
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) -> Void {
    jni.SetBooleanField(obj, field, (self) ? 1 : 0)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Bool {
    return jni.GetStaticBooleanField(cls, field) == JNI_TRUE
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Void {
    jni.SetBooleanField(cls, field, (self) ? 1 : 0)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(bool: (self) ? 1 : 0)
  }
}


// MARK: - Byte

final public class JByte: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Int8

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Byte")!

  public final override class var javaClass: JClass { return __class }

  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(B)V")!
  
  public static let javaValue = __class.getMethodID(name: "byteValue", sig: "()B")!
}


extension Int8: JPrimitiveConvertible {
  public typealias PrimitiveType = JByte
  
  public static let javaSignature = "B"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int8 {
    return jni.CallByteMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int8 {
    return jni.CallStaticByteMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int8 {
    return jni.GetByteField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetByteField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int8 {
    return jni.GetStaticByteField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticByteField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(byte: self)
  }
}

// MARK: - Char

final public class JChar: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = UInt16

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Character")!

  public final override class var javaClass: JClass { return __class }

  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(C)V")!
  
  public static let javaValue = __class.getMethodID(name: "charValue", sig: "()C")!
}


extension UInt16: JPrimitiveConvertible {
  public typealias PrimitiveType = JChar
  
  public static let javaSignature = "C"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> UInt16 {
    return jni.CallCharMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> UInt16 {
    return jni.CallStaticCharMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> UInt16 {
    return jni.GetCharField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetCharField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> UInt16 {
    return jni.GetStaticCharField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticCharField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(char: self)
  }
}

// MARK: - Short

final public class JShort: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Int16

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Short")!

  public final override class var javaClass: JClass { return __class }

  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(S)V")!
  
  public static let javaValue = __class.getMethodID(name: "shortValue", sig: "()S")!
}


extension Int16: JPrimitiveConvertible {
  public typealias PrimitiveType = JShort
  
  public static let javaSignature = "S"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int16 {
    return jni.CallShortMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int16 {
    return jni.CallStaticShortMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int16 {
    return jni.GetShortField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetShortField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int16 {
    return jni.GetStaticShortField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticShortField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(short: self)
  }
}


// MARK: - Integer

final public class JInteger: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Int32

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Integer")!

  public final override class var javaClass: JClass { return __class }
  
  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(I)V")!
  
  public static let javaValue = __class.getMethodID(name: "intValue", sig: "()I")!
}


extension Int32: JPrimitiveConvertible {
  public typealias PrimitiveType = JInteger

  public static let javaSignature = "I"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int32 {
    return jni.CallIntMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int32 {
    return jni.CallStaticIntMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int32 {
    return jni.GetIntField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetIntField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int32 {
    return jni.GetStaticIntField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticIntField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(int: self)
  }
}


// MARK: - Long

final public class JLong: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Int64

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Long")!

  public final override class var javaClass: JClass { return __class }

  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(J)V")!
  
  public static let javaValue = __class.getMethodID(name: "longValue", sig: "()J")!
}


extension Int64: JPrimitiveConvertible {
  public typealias PrimitiveType = JLong

  public static let javaSignature = "J"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Int64 {
    return jni.CallLongMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Int64 {
    return jni.CallStaticLongMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Int64 {
    return jni.GetLongField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetLongField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Int64 {
    return jni.GetStaticLongField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticLongField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(long: self)
  }
}


// MARK: - Int

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
#if arch(x86_64) || arch(arm64)
    return Int(jni.GetStaticLongField(cls, field))
#else
    return Int(jni.GetStaticIntField(cls, field))
#endif
    //return Int(Convertible.fromStaticField(field, of: cls))
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    Convertible(self).toStaticField(field, of: cls)
  }
  
  public func toJavaObject() -> JavaObject? {
    return Convertible(self).toJavaObject()
  }
  
  public func toJavaParameter() -> JavaParameter {
    return Convertible(self).toJavaParameter()
  }
}


// MARK: - Float

final public class JFloat: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Float

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Float")!

  public final override class var javaClass: JClass { return __class }
  
  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(F)V")!
  
  public static let javaValue = __class.getMethodID(name: "floatValue", sig: "()F")!
}

extension Float: JPrimitiveConvertible {
  public typealias PrimitiveType = JFloat
  
  public static let javaSignature = "F"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Float {
    return jni.CallFloatMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Float {
    return jni.CallStaticFloatMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Float {
    return jni.GetFloatField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetFloatField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Float {
    return jni.GetStaticFloatField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticFloatField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(float: self)
  }
}


// MARK: - Double

final public class JDouble: Object, JPrimitiveObjectProtocol {
  public typealias ConvertibleType = Double

  fileprivate static let __class = findJavaClass(fqn: "java/lang/Double")!

  public final override class var javaClass: JClass { return __class }
  
  public static let javaInitWithValue = __class.getMethodID(name: "<init>", sig: "(D)V")!
  
  public static let javaValue = __class.getMethodID(name: "doubleValue", sig: "()D")!
}

extension Double: JPrimitiveConvertible {
  public typealias PrimitiveType = JDouble
  
  public static let javaSignature = "D"
  
  public static func fromMethod(_ method: JavaMethodID, on obj: JavaObject, args: [JavaParameter]) -> Double {
    return jni.CallDoubleMethod(obj, method, args)
  }
  
  public static func fromStaticMethod(_ method: JavaMethodID, on cls: JavaClass, args: [JavaParameter]) -> Double {
    return jni.CallStaticDoubleMethod(cls, method, args)
  }
  
  public static func fromField(_ field: JavaFieldID, of obj: JavaObject) -> Double {
    return jni.GetDoubleField(obj, field)
  }
  
  public func toField(_ field: JavaFieldID, of obj: JavaObject) {
    jni.SetDoubleField(obj, field, self)
  }
  
  public static func fromStaticField(_ field: JavaFieldID, of cls: JavaClass) -> Double {
    return jni.GetStaticDoubleField(cls, field)
  }
  
  public func toStaticField(_ field: JavaFieldID, of cls: JavaClass) {
    jni.SetStaticDoubleField(cls, field, self)
  }
  
  public func toJavaParameter() -> JavaParameter {
    return JavaParameter(double: self)
  }
}



// MARK: - String

extension String: JObjectConvertible, JNullInitializable {
  fileprivate static let __class = findJavaClass(fqn: "java/lang/String")!
  
  public static var javaClass: JClass {
    return __class
  }
  
  public static func fromJavaObject(_ obj: JavaObject) -> String {
    let chars = jni.GetStringUTFChars(obj)
    let ret = String(cString: chars)
    jni.ReleaseStringUTFChars(obj, chars)
    return ret
  }
  
  public func toJavaObject() -> JavaObject? {
    return jni.NewStringUTF(self)
  }
}


