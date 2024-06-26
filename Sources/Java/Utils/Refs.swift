
public struct Refs {
  private static var __refs = Swift.Set<Ref>()

  public static func retain<T: JObjectRepresentable>(_ obj: T) {
    __refs.insert(Ref(obj: obj))
  }

  public static func release<T: JObjectRepresentable>(_ obj: T) {
    __refs.remove(Ref(obj: obj))
  }
}


private struct Ref {
  let obj: any JObjectRepresentable
}

extension Ref: Hashable {
  public static func == (lhs: Ref, rhs: Ref) -> Bool {
    return ObjectIdentifier(lhs.obj) == ObjectIdentifier(rhs.obj)
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(obj).hash(into: &hasher)
  }
}
