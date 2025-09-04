//
//  JObjectRef.swift
//  Java
//
//  Created by Grigory Markin on 04.02.25.
//

#if os(Linux) || os(Android)
  import Glibc
#else
  import Darwin
#endif

public final class JObjectRef<T: JObjectConvertible & AnyObject>: @unchecked Sendable {
  private var jobj: JObject?

  private var mutex = pthread_mutex_t()

  public init(jobj: JObject? = nil) {
    self.jobj = jobj
    pthread_mutex_init(&self.mutex, nil)
  }

  deinit {
    pthread_mutex_destroy(&self.mutex)
  }

  public func from(_ obj: T) -> JavaObject {
    return withLock { jobj in
      if let jobj = jobj {
        return jobj.ptr
      }

      //jobj = JObject(T.javaClass.create(unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self)), weak: true)

      let params = [unsafeBitCast(Unmanaged.passRetained(obj), to: JavaLong.self).toJavaParameter()]
      jobj = JObject(T.javaClass.callStaticObjectMethod(method: "fromPtr", sig: "(J)\(T.javaSignature)", params)!)


      return jobj!.ptr
    }
  }

  public func release() {
    withLock {
      $0 = nil
    }
  }

  private func withLock<R>(_ body: (inout JObject?) -> R) -> R {
    pthread_mutex_lock(&self.mutex); defer { pthread_mutex_unlock(&self.mutex) }
    return body(&jobj)
  }
}
