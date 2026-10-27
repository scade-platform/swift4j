# Swift4j

Swift4j makes Swift libraries callable from Java and Kotlin. Annotate Swift types
with `@jvm` and use generated classes to access their methods, properties, and
asynchronous results from JVM and Android applications.

Share application logic, networking, and data models in Swift while keeping the
UI native to each platform. Swift4j provides the macros, JNI runtime, and bridge
generator; the [SwiftPM Gradle plugins](https://github.com/scade-platform/spm-gradle-plugin)
handle native builds and packaging.

[Documentation](https://swift-android.com/docs/swift4j/overview/) ·
[Examples](https://github.com/scade-platform/swift4j-examples) ·
[Changelog](CHANGELOG.md)

## Call Swift from Kotlin

Arrays and closures cross the boundary through typed, generated APIs:

```swift
import Swift4j

@jvm
public class ArrayTools {
    public static func mapReversed(_ values: [Int], mapping: (Int) -> Int) -> [Int] {
        values.reversed().map(mapping)
    }
}
```

```kotlin
val result = ArrayTools.mapReversed(longArrayOf(1, 2, 3)) { it + 1 }
println(result.joinToString()) // 4, 3, 2
```

The following examples show calls through generated bridges, with imports and
library initialization omitted. Complete projects are in
[swift4j-examples](https://github.com/scade-platform/swift4j-examples).

## Async results and errors

Swift `async` methods return `CompletableFuture` values. Kotlin callers can
`await()` the result inside a coroutine without blocking a thread; Java callers
use the standard future API.

```swift
@jvm
public struct AsyncGreeting {
    public func message() async throws -> String {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "Swift greets Kotlin"
    }
}
```

```kotlin
import kotlinx.coroutines.future.await

// Inside a coroutine:
try {
    println(AsyncGreeting().message().await())
} catch (error: Exception) {
    println(error.message)
}
```

Swift `throws` methods and initializers propagate errors as JVM exceptions.
For asynchronous calls, errors complete the future exceptionally and are thrown
by `await()`. Cancelling a JVM future does not currently cancel the Swift task.

## Swift Observation on Android

Expose a Swift observable model as an Android ViewModel with `StateFlow`
properties. Changes made in Swift update the state consumed by the Android UI,
including computed properties.

```swift
import Observation

@jvm
@Observable
public final class Counter {
    public var count: Int = 0
    public var title: String { "Count: \(count)" }

    public func increment() { count += 1 }
}
```

In Compose, using the generated `CounterViewModel`:

```kotlin
val title by viewModel.title.collectAsState()
Text(title)
Button(onClick = { viewModel.model.increment() }) {
    Text("Increment")
}
```

The same Swift model can be observed by SwiftUI. Observation-tracking accessors
are also available for custom JVM integrations.

## Enums with associated values

Swift enums with payloads become Kotlin sealed classes. Case names and named
associated values are preserved:

```swift
@jvm
public enum RequestState {
    case success(value: String)
    case error(code: Int, message: String)
    case loading
}
```

For a `RequestState` returned by Swift:

```kotlin
val description = when (state) {
    is RequestState.success -> state.value
    is RequestState.error -> "Error ${state.code}: ${state.message}"
    RequestState.loading -> "Loading"
}
```

Enums can also expose properties, methods, and nested types—for example, an
`Appearance` enum returning an `Appearance.Colors` struct.

## Supported features

| Swift API | Java / Kotlin API |
| --- | --- |
| Classes, structs, and nested types | Generated classes and constructors |
| Stored and computed properties | Java accessors or Kotlin properties |
| Instance and static methods | Typed methods, including supported overloads |
| `async` / `async throws` | `CompletableFuture`, usable with Kotlin `await()` |
| Throwing methods and initializers | JVM exceptions |
| Plain enums | Java or Kotlin enums |
| Enums with payloads or exported members | Kotlin sealed classes |
| `@Observable` classes | Observation accessors and Android ViewModels with `StateFlow` |
| Primitives, strings, optionals, and arrays | Corresponding JVM values and nullable types |
| Closures | Functional interfaces usable with Kotlin lambdas |
| Mutating methods and `inout` parameters | Updates to wrapped Swift values |
| Foundation `Date` and Swift `Result` | JVM date and result types |

Java is the default output language. `--kotlin` selects Kotlin generation for
classes and structs as well; sealed enum bridges use Kotlin in either mode.
Use `@nonjvm` to exclude members from an exported type.

Exported signatures must use supported types. Arbitrary generic declarations,
protocol exports, and extension members are not generally supported. Overloads
must remain distinct after JVM type mapping; Swift argument labels do not
distinguish JVM methods. Swift `Int` maps to JVM `long` / Kotlin `Long`.

This README covers Swift4j 1.6.0. See the [changelog](CHANGELOG.md) for release
history and upgrade notes.

## Documentation and examples

Swift4j uses Swift 6 macros and builds Swift code as a shared library for the
target platform. It can be integrated through Gradle or used with its standalone
CLI and Swift package command plugin.

See the [Swift4j documentation](https://swift-android.com/docs/swift4j/overview/) for installation,
project configuration, and integration guides.

The [examples repository](https://github.com/scade-platform/swift4j-examples)
includes JVM and Android applications covering:

- **SwiftExamples:** callbacks, arrays, nested types, enums, properties,
  exceptions, observation, and async results.
- **ObservationDemo:** a Swift observable model connected to a Compose UI.
- **WeatherApp:** Swift networking with Foundation, Alamofire, and SwiftyJSON.
- **SimpleDBApp:** shared SQLite logic using GRDB.
- **SalesforceDemo:** asynchronous service integration.

## License and contact

Licensed under [Apache 2.0](LICENSE).
For questions and discussion, [join Discord](https://discord.gg/seAYea9r).
