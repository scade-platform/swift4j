
struct JCompletableFuture {
  private let jobj: JObject

  init(_ ptr: JavaObject) {
    jobj = JObject(ptr)
  }

  func complete<T: JConvertible>(_ value: T) -> Bool {
    return complete(value.toJavaObject())
  }

  func complete<T: Error>(_ error: T) -> Bool {
    return jobj.call(method: "completeExceptionally",
                     sig: "Ljava/lang/Throwable;",
                     [JavaParameter(object: error.toJavaObject())])
  }

  func complete(_ value: JavaObject?) -> Bool {
    return jobj.call(method: "complete", sig: "(Ljava/lang/Object;)Z",
                     [JavaParameter(object: value)])
  }

  func complete() -> Bool {
    return jobj.call(method: "complete", sig: "(Ljava/lang/Object;)Z",
                     [JavaParameter(object: nil)])
  }
}

public func execWithFuture<T: JObjectConvertible & Sendable> (_ cl: @Sendable @escaping () async throws -> T) -> JavaObject {
  return execWithFuture {
    return await try cl().toJavaObject()
  }
}

public func execWithFuture(_ cl: @Sendable @escaping () async throws -> JavaObject?) -> JavaObject {
  guard let javaObject = JCompletableFuture__class?.create() else {
    fatalError("CompletableFuture class is not available")
  }

  let future = JCompletableFuture(javaObject)

  Task.detached {
    let res: Result<JavaObject?, Error>

    do {
      res = .success(try await cl())
    } catch {
      res = .failure(error)
    }

    await MainActor.run {
      switch res {
        case .success(let val): _ = future.complete(val)
        case .failure(let err): _ = future.complete(err)
      }
    }
  }

  return javaObject
}

public func execWithFuture(_ cl: @Sendable @escaping () async throws -> Void) -> JavaObject {
  guard let javaObject = JCompletableFuture__class?.create() else {
    fatalError("CompletableFuture class is not available")
  }

  let future = JCompletableFuture(javaObject)

  Task.detached {
    let res: Result<Void, Error>

    do {
      res = .success(try await cl())
    } catch {
      res = .failure(error)
    }

    await MainActor.run {
      switch res {
        case .success(let val): _ = future.complete()
        case .failure(let err): _ = future.complete(err)
      }
    }
  }

  return javaObject
}


private let JCompletableFuture__class = JClass(fqn: "java/util/concurrent/CompletableFuture")
