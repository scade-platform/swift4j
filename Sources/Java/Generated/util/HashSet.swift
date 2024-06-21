

open class HashSet<E: JObjectConvertible>: Object, AbstractSet, Java.Set {
  public typealias T = E

  override public init() {
    super.init(ctor: HashSet__method__0, [])
  }

  public init<T0, T1>(c: T1?) where T0: Object, T1: Java.Collection, T1.E == T0 {
    super.init(ctor: HashSet__method__1, [c.toJavaParameter()])
  }

  public init(initialCapacity: Int32, loadFactor: Float) {
    super.init(ctor: HashSet__method__2, [initialCapacity.toJavaParameter(), loadFactor.toJavaParameter()])
  }

  public init(initialCapacity: Int32) {
    super.init(ctor: HashSet__method__3, [initialCapacity.toJavaParameter()])
  }

  open func iterator<R>() -> R? where R: Java.Iterator, R.E == E {
    self.javaObject.call(method: HashSet__method__4, [])
  }

  open func size() -> Int32 {
    self.javaObject.call(method: HashSet__method__5, [])
  }

  public required init(_ obj: JavaObject) {
    super.init(obj)
  }

  public required init(ctor: JavaMethodID, _ args: [JavaParameter]) {
    super.init(ctor: ctor, args)
  }
}

extension HashSet {
  public func iterator() -> Java.IteratorProxy<E>? {
    self.javaObject.call(method: HashSet__method__4, [])
  }
}

// ------------------------------------------------------------------------------------

private let HashSet__class = findJavaClass(fqn: "java/util/HashSet")!

private let HashSet__method__0 = HashSet__class.getMethodID(name: "<init>", sig: "()V")!
private let HashSet__method__1 = HashSet__class.getMethodID(name: "<init>", sig: "(Ljava/util/Collection;)V")!
private let HashSet__method__2 = HashSet__class.getMethodID(name: "<init>", sig: "(IF)V")!
private let HashSet__method__3 = HashSet__class.getMethodID(name: "<init>", sig: "(I)V")!
private let HashSet__method__4 = HashSet__class.getMethodID(name: "iterator", sig: "()Ljava/util/Iterator;")!
private let HashSet__method__5 = HashSet__class.getMethodID(name: "size", sig: "()I")!
