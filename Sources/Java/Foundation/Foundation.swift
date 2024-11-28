#if os(Android)
import CAndroid
#endif

func Foundation_init() {
  #if os(Android)
  Foundation_init_android()
  #endif
}

#if os(Android)
public func logcat_log(_ msg: String) {
  msg.withCString {
    let _ = __android_log_write(4, "swift-java", $0);
  }
}

fileprivate func Foundation_init_android() {
  let threadClass = findJavaClass(fqn: "android/app/ActivityThread")
  let app: Object? = threadClass?.callStatic(method: "currentApplication",
                                             sig: "()Landroid/app/Application;")

  let swiftFoundationClass = findJavaClass(fqn: "org/swift/swiftfoundation/SwiftFoundation")
  swiftFoundationClass?.callStatic(method: "Initialize", sig: "(Landroid/content/Context;Z)V", app, false)
}
#endif
