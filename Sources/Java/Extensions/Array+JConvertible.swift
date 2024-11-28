
import CJNI


extension Array: JParameterConvertible, JConvertible, JNullInitializable, JObjectConvertible where Element: JConvertible {

  public static var javaSignature : String {
    return "[\(Element.javaSignature)"
  }
  
  
  public static var javaClass: JClass {
    return findJavaClass(fqn: javaSignature)!
  }

  
  public func toJavaObject() -> JavaObject? {
    if Element.self == Bool.self {
      guard let arr = jni.NewBooleanArray(count) else { return nil }
      let elements = (self as! [Bool]).map { JavaBoolean($0 ? 1 : 0) }
      jni.SetArrayRegion(arr, 0, count, elements)
      return arr

    } else if Element.self == Int8.self {
      guard let arr = jni.NewByteArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Int8])
      return arr

    } else if Element.self == Int16.self {
      guard let arr = jni.NewShortArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Int16])
      return arr

    } else if Element.self == Int32.self {
      guard let arr = jni.NewIntArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Int32])
      return arr

    } else if Element.self == Int64.self {
      guard let arr = jni.NewLongArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Int64])
      return arr

    } else if Element.self == Int.self {
#if _pointerBitWidth(_64)
      guard let arr = jni.NewLongArray(count) else { return nil }
      self.withUnsafeBufferPointer { buffer in
        buffer.baseAddress!.withMemoryRebound(to: Int64.self, capacity: buffer.count) {
          jni.SetArrayRegion(arr, 0, count, $0)
        }
      }
#else
      guard let arr = jni.NewIntArray(count) else { return nil }
      self.withUnsafeBufferPointer { buffer in
        buffer.baseAddress!.withMemoryRebound(to: Int32.self, capacity: buffer.count) {
          jni.SetArrayRegion(arr, 0, count, $0)
        }
      }
#endif
      return arr

    } else if Element.self == Float.self {
      guard let arr = jni.NewFloatArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Float])
      return arr

    } else if Element.self == Double.self {
      guard let arr = jni.NewDoubleArray(count) else { return nil }
      jni.SetArrayRegion(arr, 0, count, self as! [Double])
      return arr

    } else if let elementClass = (Element.self as? JObjectConvertible.Type)?.javaClass {
      guard let res = jni.NewObjectArray(count, elementClass.ptr, nil) else { return nil }
      for (index, element) in self.enumerated() {
        if let obj = element.toJavaObject() {
          jni.SetObjectArrayElement(res, index, obj)
          if jni.GetObjectRefType(obj).rawValue == 1 {
            jni.DeleteLocalRef(obj)
          }
        }
      }
      return res
      
    } else {
      fatalError("Unsupported array element type")
    }
  }
  
  public static func fromJavaObject(_ obj: JavaObject) -> Array<Element> {
    let count = Int(jni.GetArrayLength(obj))
    
    if Element.self == Bool.self {
      var arr = [JavaBoolean](repeating: 0, count: count)
      jni.GetBooleanArrayRegion(obj, 0, count, &arr)
      return arr.map { Bool($0 != 0) } as! [Element]
      
    } else if Element.self == Int8.self {
      var arr = [Int8](repeating: 0, count: count)
      jni.GetByteArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self == Int16.self {
      var arr = [Int16](repeating: 0, count: count)
      jni.GetShortArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self == Int32.self {
      var arr = [Int32](repeating: 0, count: count)
      jni.GetIntArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self == Int64.self {
      var arr = [Int64](repeating: 0, count: count)
      jni.GetLongArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self == Int.self {
#if _pointerBitWidth(_64)
      var arr = [Int64](repeating: 0, count: count)
      jni.GetLongArrayRegion(obj, 0, count, &arr)
#else
      var arr = [Int32](repeating: 0, count: count)
      jni.GetIntArrayRegion(obj, 0, count, &arr)
#endif
      return arr.withUnsafeBufferPointer { buffer -> [Element] in
        buffer.baseAddress!.withMemoryRebound(to: Element.self, capacity: buffer.count) {
          [Element](UnsafeBufferPointer(start: $0, count: buffer.count))
        }
      }

    } else if Element.self == Float.self {
      var arr = [Float](repeating: 0, count: count)
      jni.GetFloatArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self == Double.self {
      var arr = [Double](repeating: 0, count: count)
      jni.GetDoubleArrayRegion(obj, 0, count, &arr)
      return arr as! [Element]

    } else if Element.self is JObjectConvertible.Type {
      var arr: [Element] = []
      let count = Int(jni.GetArrayLength(obj))
      
      arr.reserveCapacity(count)
      
      for i in 0 ..< count{
        let _obj = jni.GetObjectArrayElement(obj, i)
        arr.append(Element.fromJavaObject(_obj))
        if let _obj = _obj {
          if jni.GetObjectRefType(_obj).rawValue == 1 {
            jni.DeleteLocalRef(_obj)
          }
        }
      }
      
      return arr

    } else {
      fatalError("Unsupported array element type")
    }
  }
  
}

