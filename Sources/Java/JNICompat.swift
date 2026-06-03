#if canImport(jni)
import jni

// MARK: - Type aliases matching CJNI's CF_SWIFT_NAME annotations

public typealias JavaBoolean = jboolean
public typealias JavaByte = jbyte
public typealias JavaChar = jchar
public typealias JavaShort = jshort
public typealias JavaInt = jint
public typealias JavaLong = jlong
public typealias JavaFloat = jfloat
public typealias JavaDouble = jdouble

public typealias JavaObject = jobject
public typealias JavaClass = jclass
public typealias JavaString = jstring
public typealias JavaArray = jarray
public typealias JavaObjectArray = jobjectArray
public typealias JavaBooleanArray = jbooleanArray
public typealias JavaByteArray = jbyteArray
public typealias JavaCharArray = jcharArray
public typealias JavaShortArray = jshortArray
public typealias JavaIntArray = jintArray
public typealias JavaLongArray = jlongArray
public typealias JavaFloatArray = jfloatArray
public typealias JavaDoubleArray = jdoubleArray
public typealias JavaThrowable = jthrowable
public typealias JavaWeakReference = jweak

public typealias JavaFieldID = jfieldID
public typealias JavaMethodID = jmethodID
public typealias JavaParameter = jvalue
public typealias JavaObjectRefType = jobjectRefType

// MARK: - jvalue initializers with Swift-friendly labels matching CJNI's CF_SWIFT_NAME field renames

extension jvalue {
    public init(object val: jobject?) {
        var v = jvalue(); v.l = val; self = v
    }
    public init(bool val: jboolean) {
        var v = jvalue(); v.z = val; self = v
    }
    public init(byte val: jbyte) {
        var v = jvalue(); v.b = val; self = v
    }
    public init(char val: jchar) {
        var v = jvalue(); v.c = val; self = v
    }
    public init(short val: jshort) {
        var v = jvalue(); v.s = val; self = v
    }
    public init(int val: jint) {
        var v = jvalue(); v.i = val; self = v
    }
    public init(long val: jlong) {
        var v = jvalue(); v.j = val; self = v
    }
    public init(float val: jfloat) {
        var v = jvalue(); v.f = val; self = v
    }
    public init(double val: jdouble) {
        var v = jvalue(); v.d = val; self = v
    }
}

// MARK: - JNINativeInterface extensions providing CJNI-compatible renamed method wrappers
//
// In CJNI, variadic CallXxx/NewObject methods are SWIFT_UNAVAILABLE and the *A variants
// are CF_SWIFT_NAME-renamed to the short forms. The NDK jni.h has no such renames, so we
// provide them here as Swift extension methods.

extension JNINativeInterface {

    public func NewObject(_ env: UnsafeMutablePointer<JNIEnv?>, _ cls: jclass, _ ctor: jmethodID, _ params: [jvalue]) -> jobject? {
        NewObjectA!(env, cls, ctor, params)
    }

    public func CallObjectMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jobject? {
        CallObjectMethodA!(env, obj, method, params)
    }
    public func CallBooleanMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jboolean {
        CallBooleanMethodA!(env, obj, method, params)
    }
    public func CallByteMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jbyte {
        CallByteMethodA!(env, obj, method, params)
    }
    public func CallCharMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jchar {
        CallCharMethodA!(env, obj, method, params)
    }
    public func CallShortMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jshort {
        CallShortMethodA!(env, obj, method, params)
    }
    public func CallIntMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jint {
        CallIntMethodA!(env, obj, method, params)
    }
    public func CallLongMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jlong {
        CallLongMethodA!(env, obj, method, params)
    }
    public func CallFloatMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jfloat {
        CallFloatMethodA!(env, obj, method, params)
    }
    public func CallDoubleMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) -> jdouble {
        CallDoubleMethodA!(env, obj, method, params)
    }
    public func CallVoidMethod(_ env: UnsafeMutablePointer<JNIEnv?>, _ obj: jobject, _ method: jmethodID, _ params: [jvalue]) {
        CallVoidMethodA!(env, obj, method, params)
    }

    // MARK: ReleaseArrayElements overloads (CJNI CF_SWIFT_NAME(ReleaseArrayElements) per type)

    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jbooleanArray, _ elems: UnsafeMutablePointer<jboolean>?, _ mode: jint) {
        ReleaseBooleanArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jbyteArray, _ elems: UnsafeMutablePointer<jbyte>?, _ mode: jint) {
        ReleaseByteArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jcharArray, _ elems: UnsafeMutablePointer<jchar>?, _ mode: jint) {
        ReleaseCharArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jshortArray, _ elems: UnsafeMutablePointer<jshort>?, _ mode: jint) {
        ReleaseShortArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jintArray, _ elems: UnsafeMutablePointer<jint>?, _ mode: jint) {
        ReleaseIntArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jlongArray, _ elems: UnsafeMutablePointer<jlong>?, _ mode: jint) {
        ReleaseLongArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jfloatArray, _ elems: UnsafeMutablePointer<jfloat>?, _ mode: jint) {
        ReleaseFloatArrayElements!(env, arr, elems, mode)
    }
    public func ReleaseArrayElements(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jdoubleArray, _ elems: UnsafeMutablePointer<jdouble>?, _ mode: jint) {
        ReleaseDoubleArrayElements!(env, arr, elems, mode)
    }

    // MARK: SetArrayRegion overloads (CJNI CF_SWIFT_NAME(SetArrayRegion) per type)

    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jbooleanArray, _ start: jint, _ len: jint, _ buf: [jboolean]) {
        SetBooleanArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jbyteArray, _ start: jint, _ len: jint, _ buf: [jbyte]) {
        SetByteArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jcharArray, _ start: jint, _ len: jint, _ buf: [jchar]) {
        SetCharArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jshortArray, _ start: jint, _ len: jint, _ buf: [jshort]) {
        SetShortArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jintArray, _ start: jint, _ len: jint, _ buf: [jint]) {
        SetIntArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jintArray, _ start: jint, _ len: jint, _ ptr: UnsafePointer<jint>) {
        SetIntArrayRegion!(env, arr, start, len, ptr)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jlongArray, _ start: jint, _ len: jint, _ buf: [jlong]) {
        SetLongArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jlongArray, _ start: jint, _ len: jint, _ ptr: UnsafePointer<jlong>) {
        SetLongArrayRegion!(env, arr, start, len, ptr)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jfloatArray, _ start: jint, _ len: jint, _ buf: [jfloat]) {
        SetFloatArrayRegion!(env, arr, start, len, buf)
    }
    public func SetArrayRegion(_ env: UnsafeMutablePointer<JNIEnv?>, _ arr: jdoubleArray, _ start: jint, _ len: jint, _ buf: [jdouble]) {
        SetDoubleArrayRegion!(env, arr, start, len, buf)
    }
}

#endif
