
class SwiftArray {
  private protocol SwiftArrayWrapper {
    func get(index: Int) -> any JObjectConvertible
    func size() -> Int
  }

  private struct Wrapper<T: JObjectConvertible>: SwiftArrayWrapper {
    let arr: [T]

    func get(index: Int) -> any JObjectConvertible { return arr[index] }
    func size() -> Int { return arr.count}
  }

  private let wrapper: any SwiftArrayWrapper

  init<T: JObjectConvertible>(_ arr: [T]) {
    wrapper = Wrapper(arr: arr)
  }

  func get(index: Int) -> any JObjectConvertible { return wrapper.get(index: index) }

  func size() -> Int { return wrapper.size()}

  // -----------------

  private var jobj: JObject? = nil

  public static var javaClass = {
    guard let cls = JClass(fqn: "io/scade/swift/util/SwiftArray") else {
      fatalError("Could not find io/scade/swift/util/SwiftArray class")
    }
    return cls
  } ()

  fileprivate typealias deinit_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaLong) -> Void
  fileprivate static let deinit_jni: deinit_jni_t = { _, ptr in
    let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<SwiftArray>.self)
    _self.release()
  }

  fileprivate typealias get_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaObject?, JavaLong, JavaInt) -> JavaObject?
  fileprivate static let get_jni: get_jni_t = {_, _, ptr, index in
    let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<SwiftArray>.self).takeUnretainedValue()

    return _self.get(index: Int(index)).toJavaObject()
  }

  fileprivate typealias size_jni_t = @convention(c)(UnsafeMutablePointer<JNIEnv>, JavaObject?, JavaLong) -> JavaInt
  fileprivate static let size_jni: size_jni_t = {_, _, ptr in
    let _self = unsafeBitCast(Int(truncatingIfNeeded: ptr), to: Unmanaged<SwiftArray>.self).takeUnretainedValue()

    return JavaInt(_self.size())
  }
}

extension SwiftArray: JObjectRepresentable {
  public func toJavaObject() -> JavaObject? {
    if jobj == nil {
      jobj = JObject(Self.javaClass.create(unsafeBitCast(Unmanaged.passRetained(self), to: JavaLong.self)), weak: true)
    }
    return jobj?.ptr
  }
}

@_cdecl("Java_io_scade_swift_util_SwiftArray_SwiftArray_1class_1init")
func SwiftArray_class_init(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass?) {
  guard let cls = cls else {
      return
  }
  let natives = [
    JNINativeMethod(name: "deinit", sig: "(J)V", fn: SwiftArray.deinit_jni),
    JNINativeMethod(name: "get", sig: "(J)Ljava/lang/Object;", fn: SwiftArray.get_jni),
    JNINativeMethod(name: "size", sig: "(J)I", fn: SwiftArray.size_jni)
  ]
  let _ = jni.RegisterNatives(cls, natives)
}
