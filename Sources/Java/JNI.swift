//
//  JNI.swift
//  Java
//
//  Created by Grigory Markin on 29.11.18.
//

@_exported import CJNI


@_cdecl("JNI_OnLoad")
public func JNI_OnLoad(jvm: UnsafeMutablePointer<JavaVM>, reserved: UnsafeMutableRawPointer) -> JavaInt {
  _jni = JNI(jvm)

  Foundation_init()

  return JNI_VERSION_1_6
}

fileprivate var _jni: JNI? = nil

public var jni: JNI {
  guard let jni = _jni else {
    fatalError("JVM not loaded")
  }
  return jni
}


public struct JNI {
  private let jvm_ptr: UnsafeMutablePointer<JavaVM>
#if os(Android)
  private var classLoader: JavaObject? = nil
  private var loadClassMethod: JavaMethodID? = nil
#endif
  
  private var jvm: JNIInvokeInterface {
    jvm_ptr.pointee.pointee
  }

  private var env_ptr: UnsafeMutablePointer<JNIEnv>? {
    var tmp: UnsafeMutableRawPointer?
    let status = jvm.GetEnv(jvm_ptr, &tmp, JavaInt(JNI_VERSION_1_6))
    var env = tmp?.bindMemory(to: JNIEnv.self, capacity: 1)

    switch status {
    case JNI_EDETACHED:
      _ = jvm.AttachCurrentThreadAsDaemon(jvm_ptr, &env, nil)
    case JNI_EVERSION:
      fatalError("This version of JNI is not supported")
    default: break
    }

    return env
  }

  fileprivate init(_ jvm: UnsafeMutablePointer<JavaVM>) {
    self.jvm_ptr = jvm

#if os(Android)
    guard let SwiftFoundation_cls = FindClass("org/swift/swiftfoundation/SwiftFoundation"),
          let ClassLoader_cls = FindClass("java/lang/ClassLoader"),
          let ClassClass = GetObjectClass(SwiftFoundation_cls),
          let getClassLoaderMethod = GetMethodID(ClassClass, "getClassLoader", "()Ljava/lang/ClassLoader;"),
          let classLoader = CallObjectMethod(SwiftFoundation_cls, getClassLoaderMethod, []) else {
      return
    }

    self.classLoader = NewGlobalRef(classLoader)
    self.loadClassMethod = GetMethodID(ClassLoader_cls, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;")
#endif
  }

  private func env<T>(_ closure: (JNINativeInterface, UnsafeMutablePointer<JNIEnv>) -> T) -> T {
    guard let env = env_ptr else {
      fatalError("JNI environment is not available")
    }
    return closure(env.pointee.pointee, env)
  }


  public func FindClass(_ cls: String) -> JavaClass? {
    func do_find() -> JavaClass? { env { $0.FindClass($1, cls) } }
#if os(Android)
  guard let classLoader = classLoader,
        let loadClassMethod = loadClassMethod else { return do_find() }
  return jni.CallObjectMethod(classLoader, loadClassMethod, [cls.toJavaParameter()])
#else
    return do_find()
#endif
  }

  public func NewGlobalRef(_ obj: JavaObject) -> JavaObject? { env { $0.NewGlobalRef($1, obj) } }
  public func NewLocalRef(_ obj: JavaObject) -> JavaObject? { env { $0.NewLocalRef($1, obj) } }
  public func NewWeakGlobalRef(_ obj: JavaObject) -> JavaObject? { env { $0.NewWeakGlobalRef($1, obj) } }

  public func DeleteGlobalRef(_ obj: JavaObject) { env { $0.DeleteGlobalRef($1, obj) } }
  public func DeleteLocalRef(_ obj: JavaObject) { env { $0.DeleteLocalRef($1, obj) } }
  public func DeleteWeakGlobalRef(_ obj: JavaObject) { env { $0.DeleteWeakGlobalRef($1, obj) } }

  public func IsSameObject(_ obj1: JavaObject, _ obj2: JavaObject) -> JavaBoolean { env { $0.IsSameObject($1, obj1, obj2) } }

  public func NewObject(_ cls: JavaClass, _ ctor: JavaMethodID, _ params: [JavaParameter]) -> JavaObject? { env { $0.NewObject($1, cls, ctor, params) } }
  public func GetObjectClass(_ obj: JavaObject) -> JavaClass? { env { $0.GetObjectClass($1, obj) } }


  public func GetFieldID(_ cls: JavaClass, _ name: String, _ sig: String) -> JavaFieldID? { env { $0.GetFieldID($1, cls, name, sig) } }

  public func GetObjectField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaObject? { env { $0.GetObjectField($1, obj, fieldID) } }
  public func GetBooleanField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaBoolean { env { $0.GetBooleanField($1, obj, fieldID) } }
  public func GetByteField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaByte { env { $0.GetByteField($1, obj, fieldID) } }
  public func GetCharField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaChar { env { $0.GetCharField($1, obj, fieldID) } }
  public func GetShortField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaShort { env { $0.GetShortField($1, obj, fieldID) } }
  public func GetIntField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaInt { env { $0.GetIntField($1, obj, fieldID) } }
  public func GetLongField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaLong { env { $0.GetLongField($1, obj, fieldID) } }
  public func GetFloatField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaFloat { env { $0.GetFloatField($1, obj, fieldID) } }
  public func GetDoubleField(_ obj: JavaObject, _ fieldID: JavaFieldID) -> JavaDouble { env { $0.GetDoubleField($1, obj, fieldID) } }

  public func SetObjectField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaObject?) { env { $0.SetObjectField($1, obj, fieldID, value) } }
  public func SetBooleanField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaBoolean) { env { $0.SetBooleanField($1, obj, fieldID, value) } }
  public func SetByteField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaByte) { env { $0.SetByteField($1, obj, fieldID, value) } }
  public func SetCharField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaChar) { env { $0.SetCharField($1, obj, fieldID, value) } }
  public func SetShortField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaShort) { env { $0.SetShortField($1, obj, fieldID, value) } }
  public func SetIntField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaInt) { env { $0.SetIntField($1, obj, fieldID, value) } }
  public func SetLongField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaLong) { env { $0.SetLongField($1, obj, fieldID, value) } }
  public func SetFloatField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaFloat) { env { $0.SetFloatField($1, obj, fieldID, value) } }
  public func SetDoubleField(_ obj: JavaObject, _ fieldID: JavaFieldID, _ value: JavaDouble) { env { $0.SetDoubleField($1, obj, fieldID, value) } }


  public func GetStaticFieldID(_ cls: JavaClass, _ name: String, _ sig: String) -> JavaFieldID? { env { $0.GetFieldID($1, cls, name, sig) } }

  public func GetStaticObjectField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaObject? { env { $0.GetStaticObjectField($1, cls, fieldID) } }
  public func GetStaticBooleanField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaBoolean { env { $0.GetStaticBooleanField($1, cls, fieldID) } }
  public func GetStaticByteField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaByte { env { $0.GetStaticByteField($1, cls, fieldID) } }
  public func GetStaticCharField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaChar { env { $0.GetStaticCharField($1, cls, fieldID) } }
  public func GetStaticShortField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaShort { env { $0.GetStaticShortField($1, cls, fieldID) } }
  public func GetStaticIntField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaInt { env { $0.GetStaticIntField($1, cls, fieldID) } }
  public func GetStaticLongField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaLong { env { $0.GetStaticLongField($1, cls, fieldID) } }
  public func GetStaticFloatField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaFloat { env { $0.GetStaticFloatField($1, cls, fieldID) } }
  public func GetStaticDoubleField(_ cls: JavaClass, _ fieldID: JavaFieldID) -> JavaDouble { env { $0.GetStaticDoubleField($1, cls, fieldID) } }

  public func SetStaticObjectField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaObject?) { env { $0.SetStaticObjectField($1, cls, fieldID, value) } }
  public func SetStaticBooleanField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaBoolean) { env { $0.SetStaticBooleanField($1, cls, fieldID, value) } }
  public func SetStaticByteField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaByte) { env { $0.SetStaticByteField($1, cls, fieldID, value) } }
  public func SetStaticCharField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaChar) { env { $0.SetStaticCharField($1, cls, fieldID, value) } }
  public func SetStaticShortField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaShort) { env { $0.SetStaticShortField($1, cls, fieldID, value) } }
  public func SetStaticIntField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaInt) { env { $0.SetStaticIntField($1, cls, fieldID, value) } }
  public func SetStaticLongField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaLong) { env { $0.SetStaticLongField($1, cls, fieldID, value) } }
  public func SetStaticFloatField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaFloat) { env { $0.SetStaticFloatField($1, cls, fieldID, value) } }
  public func SetStaticDoubleField(_ cls: JavaClass, _ fieldID: JavaFieldID, _ value: JavaDouble) { env { $0.SetStaticDoubleField($1, cls, fieldID, value) } }

  public func GetMethodID(_ cls: JavaClass, _ name: String, _ sig: String) -> JavaMethodID? { env { $0.GetMethodID($1, cls, name, sig) } }

  public func CallVoidMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) { env { $0.CallVoidMethod($1, obj, methodID, params) } }
  public func CallObjectMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaObject? { env { $0.CallObjectMethod($1, obj, methodID, params) } }
  public func CallBooleanMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaBoolean { env { $0.CallBooleanMethod($1, obj, methodID, params) } }
  public func CallByteMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaByte { env { $0.CallByteMethod($1, obj, methodID, params) } }
  public func CallCharMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaChar { env { $0.CallCharMethod($1, obj, methodID, params) } }
  public func CallShortMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaShort { env { $0.CallShortMethod($1, obj, methodID, params) } }
  public func CallIntMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaInt { env { $0.CallIntMethod($1, obj, methodID, params) } }
  public func CallLongMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaLong { env { $0.CallLongMethod($1, obj, methodID, params) } }
  public func CallFloatMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaFloat { env { $0.CallFloatMethod($1, obj, methodID, params) } }
  public func CallDoubleMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaDouble { env { $0.CallDoubleMethod($1, obj, methodID, params) } }

  public func GetStaticMethodID(_ cls: JavaClass, _ name: String, _ sig: String) -> JavaMethodID? { env { $0.GetStaticMethodID($1, cls, name, sig) } }

  public func CallStaticVoidMethod(_ obj: JavaObject, _ methodID: JavaMethodID, _ params: [JavaParameter]) { env { $0.CallStaticVoidMethodA($1, obj, methodID, params) } }
  public func CallStaticObjectMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaClass? { env { $0.CallStaticObjectMethodA($1, cls, methodID, params) } }
  public func CallStaticBooleanMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaBoolean { env { $0.CallStaticBooleanMethodA($1, cls, methodID, params) } }
  public func CallStaticByteMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaByte { env { $0.CallStaticByteMethodA($1, cls, methodID, params) } }
  public func CallStaticCharMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaChar { env { $0.CallStaticCharMethodA($1, cls, methodID, params) } }
  public func CallStaticShortMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaShort { env { $0.CallStaticShortMethodA($1, cls, methodID, params) } }
  public func CallStaticIntMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaInt { env { $0.CallStaticIntMethodA($1, cls, methodID, params) } }
  public func CallStaticLongMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaLong { env { $0.CallStaticLongMethodA($1, cls, methodID, params) } }
  public func CallStaticFloatMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaFloat { env { $0.CallStaticFloatMethodA($1, cls, methodID, params) } }
  public func CallStaticDoubleMethod(_ cls: JavaClass, _ methodID: JavaMethodID, _ params: [JavaParameter]) -> JavaDouble { env { $0.CallStaticDoubleMethodA($1, cls, methodID, params) } }


  public func NewStringUTF(_ str: String) -> JavaString? { env { $0.NewStringUTF($1, str) } }
  public func GetStringUTFChars(_ str: JavaString) -> UnsafePointer<CChar> { env { $0.GetStringUTFChars($1, str, nil) } }
  public func GetStringUTFChars(_ str: JavaString, _ isCopy: inout Bool) -> UnsafePointer<CChar> { env { $0.GetStringUTFChars($1, str, &isCopy) } }
  public func ReleaseStringUTFChars( _ str: JavaString, _ chars: UnsafePointer<CChar>) { env { $0.ReleaseStringUTFChars($1, str, chars) } }
  public func GetStringUTFLength( _ str: JavaString) -> Int { Int(env { $0.GetStringUTFLength($1, str) }) }

  public func GetArrayLength( _ arr: JavaArray) -> Int { Int(env { $0.GetArrayLength($1, arr) }) }

  public func NewObjectArray(_ length: Int, _ elementClass: JavaClass, _ initialElement: JavaObject? = nil) -> JavaObjectArray? {
    env { $0.NewObjectArray($1, JavaInt(length), elementClass, initialElement) }
  }

  public func GetObjectArrayElement(_ arr: JavaObjectArray, _ index: Int) -> JavaObject? {
    env { $0.GetObjectArrayElement($1, arr, JavaInt(index)) }
  }

  public func SetObjectArrayElement(_ arr: JavaObjectArray, _ index: Int, _ obj: JavaObject?) {
    env { $0.SetObjectArrayElement($1, arr, JavaInt(index), obj) }
  }

  public func NewBooleanArray(_ length: Int) -> JavaBooleanArray? { env { $0.NewBooleanArray($1, JavaInt(length)) } }
  public func NewByteArray(_ length: Int) -> JavaByteArray? { env { $0.NewByteArray($1, JavaInt(length)) } }
  public func NewCharArray(_ length: Int) -> JavaCharArray? { env { $0.NewCharArray($1, JavaInt(length)) } }
  public func NewShortArray(_ length: Int) -> JavaShortArray? { env { $0.NewShortArray($1, JavaInt(length)) } }
  public func NewIntArray(_ length: Int) -> JavaIntArray? { env { $0.NewIntArray($1, JavaInt(length)) } }
  public func NewLongArray(_ length: Int) -> JavaLongArray? { env { $0.NewLongArray($1, JavaInt(length)) } }
  public func NewFloatArray(_ length: Int) -> JavaFloatArray? { env { $0.NewFloatArray($1, JavaInt(length)) } }
  public func NewDoubleArray(_ length: Int) -> JavaDoubleArray? { env { $0.NewDoubleArray($1, JavaInt(length)) } }

  public func GetBooleanArrayElements(_ arr: JavaBooleanArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaBoolean>? {
    env { $0.GetBooleanArrayElements($1, arr, &isCopy) }
  }
  public func GetByteArrayElements(_ arr: JavaByteArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaByte>? {
    env { $0.GetByteArrayElements($1, arr, &isCopy) }
  }
  public func GetCharArrayElements(_ arr: JavaCharArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaChar>? {
    env { $0.GetCharArrayElements($1, arr, &isCopy) }
  }
  public func GetShortArrayElements(_ arr: JavaShortArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaShort>? {
    env { $0.GetShortArrayElements($1, arr, &isCopy) }
  }
  public func GetIntArrayElements(_ arr: JavaIntArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaInt>? {
    env { $0.GetIntArrayElements($1, arr, &isCopy) }
  }
  public func GetLongArrayElements(_ arr: JavaLongArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaLong>? {
    env { $0.GetLongArrayElements($1, arr, &isCopy) }
  }
  public func GetFloatArrayElements(_ arr: JavaFloatArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaFloat>? {
    env { $0.GetFloatArrayElements($1, arr, &isCopy) }
  }
  public func GetDoubleArrayElements(_ arr: JavaDoubleArray, isCopy: inout Bool) ->  UnsafeMutablePointer<JavaDouble>? {
    env { $0.GetDoubleArrayElements($1, arr, &isCopy) }
  }



  public func ReleaseArrayElements(_ arr: JavaBooleanArray, _ elems: UnsafeMutablePointer<JavaBoolean>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaByteArray, _ elems: UnsafeMutablePointer<JavaByte>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaCharArray, _ elems: UnsafeMutablePointer<JavaChar>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaShortArray, _ elems: UnsafeMutablePointer<JavaShort>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaIntArray, _ elems: UnsafeMutablePointer<JavaInt>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaLongArray, _ elems: UnsafeMutablePointer<JavaLong>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaFloatArray, _ elems: UnsafeMutablePointer<JavaFloat>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }
  public func ReleaseArrayElements(_ arr: JavaDoubleArray, _ elems: UnsafeMutablePointer<JavaDouble>) {
    env { $0.ReleaseArrayElements($1, arr, elems, 0) }
  }


  public func GetBooleanArrayRegion(_ arr: JavaBooleanArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaBoolean>) {
    env { $0.GetBooleanArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetByteArrayRegion(_ arr: JavaByteArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaByte>) {
    env { $0.GetByteArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetCharArrayRegion(_ arr: JavaCharArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaChar>) {
    env { $0.GetCharArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetShortArrayRegion(_ arr: JavaShortArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaShort>) {
    env { $0.GetShortArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetIntArrayRegion(_ arr: JavaIntArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaInt>) {
    env { $0.GetIntArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetLongArrayRegion(_ arr: JavaLongArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaLong>) {
    env { $0.GetLongArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetFloatArrayRegion(_ arr: JavaFloatArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaFloat>) {
    env { $0.GetFloatArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func GetDoubleArrayRegion(_ arr: JavaDoubleArray, _ start: Int, _ length: Int, _ buf: UnsafeMutablePointer<JavaDouble>) {
    env { $0.GetDoubleArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }



  public func SetArrayRegion(_ arr: JavaBooleanArray, _ start: Int, _ length: Int, _ buf: [JavaBoolean]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaByteArray, _ start: Int, _ length: Int, _ buf: [JavaByte]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaCharArray, _ start: Int, _ length: Int, _ buf: [JavaChar]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaShortArray, _ start: Int, _ length: Int, _ buf: [JavaShort]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }

  public func SetArrayRegion(_ arr: JavaIntArray, _ start: Int, _ length: Int, _ buf: [JavaInt]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaIntArray, _ start: Int, _ length: Int, _ ptr: UnsafePointer<JavaInt>) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), ptr) }
  }

  public func SetArrayRegion(_ arr: JavaLongArray, _ start: Int, _ length: Int, _ buf: [JavaLong]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaLongArray, _ start: Int, _ length: Int, _ ptr: UnsafePointer<JavaLong>) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), ptr) }
  }

  public func SetArrayRegion(_ arr: JavaFloatArray, _ start: Int, _ length: Int, _ buf: [JavaFloat]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }
  public func SetArrayRegion(_ arr: JavaDoubleArray, _ start: Int, _ length: Int, _ buf: [JavaDouble]) {
    env { $0.SetArrayRegion($1, arr, JavaInt(start), JavaInt(length), buf) }
  }

  public func ExceptionCheck() -> Bool { env { $0.ExceptionCheck($1) } == JNI_TRUE }
  public func ExceptionClear() { env { $0.ExceptionClear($1) } }
  public func ExceptionDescribe() { env { $0.ExceptionDescribe($1) } }

  public func Throw(_ ex: JavaThrowable) -> Bool { env { $0.Throw($1, ex) } == 0 }
  public func ThrowNew(_ cls: JavaClass, _ msg: String) -> Bool { env { $0.ThrowNew($1, cls, msg) } == 0 }

  public func RegisterNatives(_ cls: JavaClass, _ methods: [JNINativeMethod]) -> JavaInt { env { $0.RegisterNatives($1, cls, methods, JavaInt(methods.count)) } }

  public func UnregisterNatives(_ cls: JavaClass) -> JavaInt { env { $0.UnregisterNatives($1, cls) } }

  public func GetObjectRefType(_ obj: JavaObject) -> JavaObjectRefType { env { $0.GetObjectRefType($1, obj) } }  
}


// MARK: - Extensions

extension JNI {
  struct JNIError: Error {
    init() {
      jni.ExceptionDescribe()
      jni.ExceptionClear()
    }
  }

  public func checkExceptionAndThrow() throws {
    if ExceptionCheck() {
      throw JNIError()
    }
  }

  public func checkExceptionAndClear() {
    if ExceptionCheck() {
      ExceptionClear()
    }
  }

  public func throwException(_ error: Error) {
    guard let cls = FindClass("java/lang/Exception") else {
      fatalError("Cannot find exception class")
    }
    guard ThrowNew(cls, "\(error)") else {
      fatalError("Throwing an exception failed")
    }
  }
}

public extension JNINativeMethod {
  init<T>(name: StaticString, sig: StaticString, fn: T) {
    let fn_ptr = unsafeBitCast(fn, to: UnsafeMutableRawPointer.self)
    self.init(name: name, sig: sig, fnPtr: fn_ptr)
  }

  init(name: StaticString, sig: StaticString, fnPtr: UnsafeMutableRawPointer) {
    let name_ptr = UnsafeRawPointer(name.utf8Start).assumingMemoryBound(to: Int8.self)
    let sig_ptr = UnsafeRawPointer(sig.utf8Start).assumingMemoryBound(to: Int8.self)

    self.init(name: name_ptr, signature: sig_ptr, fnPtr: fnPtr)
  }
}


public typealias JNINativeMethod2 = (name: String, sig: String, fn: UnsafeMutableRawPointer)


public extension JNI {
  func RegisterNatives(_ cls: JavaClass,
                              _ methods: [JNINativeMethod2],
                              _ nativeMethods: [JNINativeMethod] = []) -> JavaInt {

    if let m = methods.first {
      return m.name.withCString { name_ptr in
        m.sig.withCString { sig_ptr in
          return RegisterNatives(cls,
                                 [JNINativeMethod2](methods.dropFirst()),
                                 nativeMethods + [JNINativeMethod(name: name_ptr, signature: sig_ptr, fnPtr: m.fn)])
        }
      }

    } else {
      return RegisterNatives(cls, nativeMethods)
    }
  }
}


extension JavaObject : JParameterConvertible {
  public func toJavaParameter()  -> JavaParameter { JavaParameter(object: self) }
}
