# Swift4j

Swift4j exposes Swift libraries to Java and Kotlin through JNI. Annotate Swift
types with `@jvm`, build a shared library, and call it through generated JVM
classes. Application logic stays in Swift; Java and Kotlin callers use typed
constructors, properties, methods, callbacks, and asynchronous results.

The toolkit includes Swift macros, a JNI runtime, and a bridge generator.
[SwiftPM Gradle plugins](https://github.com/scade-platform/spm-gradle-plugin)
integrate generation, native compilation, and packaging into JVM and Android
builds.

This README describes the current source. Full Kotlin generation and enum members
and nested types are **unreleased**; see the [changelog](CHANGELOG.md) for version
history and upgrade notes.

## A first example

Swift arrays and closures can be used directly across the boundary:

```swift
import Swift4j

@jvm
public class ArrayTools {
    public static func mapReversed(_ values: [Int], mapping: (Int) -> Int) -> [Int] {
        values.reversed().map(mapping)
    }
}
```

After building the library and generating its bridges:

```kotlin
import SharedKit.ArrayTools

fun main() {
    System.loadLibrary("SharedKit")

    val result = ArrayTools.mapReversed(longArrayOf(1, 2, 3)) { it + 1 }
    println(result.joinToString()) // 4, 3, 2
}
```

`SharedKit` is the Swift target and dynamic library product used in the setup
below. Swift `Int` maps to JVM `long` / Kotlin `Long`.

## Supported features

| Swift | JVM representation or behavior |
| --- | --- |
| Classes and structs | Generated classes with constructors and member access |
| Stored and computed properties | Java accessors or Kotlin properties; writable when the Swift setter is exposed |
| Instance and static methods | Typed methods, including supported overloads |
| `throws` methods and initializers | JVM exceptions |
| `async` methods | `CompletableFuture<T>`, usable with Kotlin coroutine `await()` |
| Enums without associated values or exported members | Java enums, or Kotlin enums in Kotlin generation mode |
| Enums with associated values | Kotlin sealed classes with typed case payloads |
| Enum properties, methods, and nested types | Kotlin sealed classes; unreleased |
| Nested types and qualified member types | Nested JVM classes; nested enum declarations and qualified type mapping are unreleased |
| `@Observable` classes | Observation-tracking accessors; optional Android ViewModels with `StateFlow` properties |
| Optionals | Nullable references and boxed primitive values |
| `Bool`, signed integers, `Float`, `Double`, and `String` | Corresponding JVM values; Swift `Int` is 64-bit |
| Arrays and closures | JVM arrays and Java functional interfaces callable with Kotlin lambdas |
| Mutating struct methods and `inout` parameters | Updates to the Swift value held by the bridge |
| Foundation `Date` | `java.util.Date` |
| Swift `Result` | `io.scade.swift4j.Result` with success and error values |

Exported signatures must use supported types. Generic arguments in mapped
signatures are supported; exporting arbitrary generic Swift declarations,
protocols, or extension members is not generally supported. Overloads must remain
distinct after JVM type mapping: Swift argument labels do not distinguish JVM
methods.

Structs are held behind JVM wrappers, rather than generated as Kotlin data
classes. Property writes and mutating methods update the wrapped Swift value.

## Getting started

### Requirements

- A Swift 6 toolchain for the current SwiftSyntax-based macros.
- A JDK and a JVM build configured to compile the generated Java and, when needed,
  Kotlin sources. The generator defaults to Java 11 source compatibility.
- For Android, a matching Swift SDK/toolchain, Android SDK, and NDK. Swift4j 1.5.0
  added standalone Swift SDK for Android compatibility. Use the
  [Gradle plugin documentation](https://github.com/scade-platform/spm-gradle-plugin#readme)
  for the toolchain and packaging configuration supported by your plugin version.
- AndroidX Lifecycle and Kotlin coroutines for generated Android ViewModels;
  Compose is needed only if your UI uses it.

`--java-version` controls generated source compatibility. It does not backport
runtime APIs such as `CompletableFuture`; configure Android API levels or
applicable desugaring separately.

### Define a Swift library

Create a dynamic library product and add the `Swift4j` dependency to each target
that exports types:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedKit",
    products: [
        .library(name: "SharedKit", type: .dynamic, targets: ["SharedKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/scade-platform/swift4j.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "SharedKit",
            dependencies: [.product(name: "Swift4j", package: "swift4j")]
        )
    ]
)
```

This dependency selects published releases. To try unreleased features before
publication, use a local checkout with `.package(path: "../swift4j")` instead.

Add `import Swift4j` and `@jvm` to the classes, structs, and enums you want to
expose. Eligible members are exported automatically, including internal members;
use `private` or `@nonjvm` to exclude implementation details. Each nested type
must also be annotated, and its enclosing types must be exposed.

```swift
@jvm
public class LibraryService {
    public func title() -> String { "Shared library" }

    @nonjvm
    public func rebuildInternalIndex() { /* Swift-only implementation */ }
}
```

### Integrate with Gradle

Apply the plugin for your platform to the module's `build.gradle.kts`, alongside
your Java/Kotlin or Android plugins. Replace `<plugin-version>` with the version
you use for your build.

For a JVM application:

```kotlin
plugins {
    id("io.scade.gradle.plugins.swiftpm") version "<plugin-version>"
}
```

For an Android application:

```kotlin
plugins {
    id("io.scade.gradle.plugins.android.swiftpm") version "<plugin-version>"
}
```

Both use the same basic configuration:

```kotlin
swiftpm {
    path = file("../SharedKit") // Directory containing Package.swift
    product = "SharedKit"      // Dynamic library product
}
```

The plugins build the native library and integrate generated bridge sources into
the application. Pin the plugin version for reproducible builds. See the
[example projects](https://github.com/scade-platform/swift4j-examples) for complete
Gradle configurations, dependencies, and native library setup.

Load the library once, before constructing or accessing exported types:

```kotlin
System.loadLibrary("SharedKit")
```

The command plugin derives the JVM package from the Swift target name, replacing
hyphens with underscores. `System.loadLibrary` uses the native library's base
name, without a `lib` prefix or platform extension.

## Async/await

A Swift `async` method returns a JVM `CompletableFuture`. The call starts Swift
asynchronous work and returns the future; Kotlin can suspend until the Swift
result is available without blocking its calling thread.

This example preserves the delayed-result behavior in the
[async sample](https://github.com/scade-platform/swift4j-examples/blob/main/Packages/swift4j-examples/Sources/swift4j-examples/Async.swift):

```swift
import Swift4j

@jvm
public struct AsyncGreeting {
    public func message() async throws -> String {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "Swift greets Kotlin from an async function"
    }
}
```

From Kotlin, call it inside a coroutine:

```kotlin
import SharedKit.AsyncGreeting
import kotlinx.coroutines.future.await

suspend fun printGreeting() {
    val message = AsyncGreeting().message().await()
    println(message)
}
```

Use the JVM `kotlinx-coroutines-core` dependency for
[`kotlinx.coroutines.future.await`](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.future/await.html).
Java callers can use the same future with `thenAccept`, `thenCompose`, and other
`CompletableFuture` operations.

Successful Swift results complete the future; a method returning no value yields
`CompletableFuture<Void>`. Swift errors complete it exceptionally, and Kotlin
`await()` throws the exception. The exceptional-completion fix is unreleased.

Cancelling a JVM future does not currently cancel its underlying Swift task.
`@MainActor` annotations also do not automatically dispatch synchronous calls to
the main thread: call such APIs from the appropriate UI thread.

## Throwing methods and initializers

Swift errors from synchronous `throws` methods and initializers become JVM
exceptions. For a useful message, errors can implement `LocalizedError`:

```swift
import Foundation
import Swift4j

private enum StoreError: LocalizedError {
    case unavailable

    var errorDescription: String? { "The store is unavailable" }
}

@jvm
public struct Store {
    public static func open() throws {
        throw StoreError.unavailable
    }
}
```

```kotlin
import SharedKit.Store

fun openStore() {
    try {
        Store.open()
    } catch (error: Exception) {
        println(error.message)
    }
}
```

For `async throws`, put the `await()` call inside `try`/`catch` in the same way.
Swift error cases are represented by the runtime's `SwiftError` exception;
export an enum or a `Result` value when callers need typed domain outcomes.

## Swift Observation on Android

A Swift `@Observable` class can serve both Swift UI code and an Android UI.
Swift4j generates observation-tracking accessors, and its Android ViewModel
generator exposes observable properties as Kotlin `StateFlow` values.

```swift
import Observation
import Swift4j

@jvm
@Observable
public final class Counter {
    public var count: Int = 0
    public var title: String { "Count: \(count)" }

    public func increment() { count += 1 }
}
```

Generate with `--generate-android-view-models` (the Android Gradle plugin requests
this automatically). The output includes `CounterViewModel`, a factory, and a
`viewModel` extension in `SharedKit.viewmodel`. The wrapper tracks Swift reads,
re-registers observation after changes, and updates its flows on the main
dispatcher. Computed properties can be observed too; use `@ObservationIgnored` to
exclude a property from tracking.

For example, create the wrapper through an Activity's ViewModel store after the
native library has been loaded:

```kotlin
import SharedKit.Counter
import SharedKit.viewmodel.CounterViewModel
import SharedKit.viewmodel.CounterViewModelFactory
import androidx.activity.viewModels

// Members of your ComponentActivity:
private val counter: CounterViewModel by viewModels {
    CounterViewModelFactory(Counter())
}
```

Then consume its state in Compose:

```kotlin
import SharedKit.viewmodel.CounterViewModel
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue

@Composable
fun CounterContent(viewModel: CounterViewModel) {
    val title by viewModel.title.collectAsState()
    Text(title)
    Button(onClick = { viewModel.model.increment() }) {
        Text("Increment")
    }
}
```

Changes made through Swift methods also update the observed state. Generated
`updateCount(value)` methods write mutable properties back to Swift. For custom
integration without Android ViewModels, call accessors such as
`getCountWithObservationTracking(onChange)` directly; Swift observation callbacks
are one-shot and must be registered again for subsequent changes.

## Enums and Kotlin generation

Enums with associated values become sealed Kotlin classes. Cases retain their
Swift names, and associated values become typed Kotlin properties:

```swift
import Swift4j

@jvm
public enum RequestState {
    case success(value: String)
    case error(code: Int, message: String)
    case loading
}

@jvm
public struct RequestService {
    public static func load() -> RequestState {
        .error(code: 404, message: "Not found")
    }
}
```

```kotlin
import SharedKit.RequestService
import SharedKit.RequestState

fun describeRequest(): String = when (val state = RequestService.load()) {
    is RequestState.success -> "Success: ${state.value}"
    is RequestState.error -> "Error ${state.code}: ${state.message}"
    RequestState.loading -> "Loading"
}
```

Plain enums generate Java enums by default. Enums with associated values generate
Kotlin sources even in the default Java mode, so the consuming build needs Kotlin
compilation.

**Unreleased:** `--kotlin` generates class and struct bridges as Kotlin sources as
well. It preserves the same JNI runtime and exposes members as Kotlin properties
and functions. Enums can also export properties, methods, and nested types; those
enums use sealed classes even when their cases have no payload.

For example, a theme can return a nested value type:

```swift
import Swift4j

@jvm
public enum Appearance {
    case light
    case dark

    @jvm
    public struct Colors {
        public var text: String
        public var card: String
    }

    public var colors: Appearance.Colors {
        switch self {
        case .light: return .init(text: "#111111", card: "#F2F2F5")
        case .dark: return .init(text: "#F2F2F5", card: "#1F2937")
        }
    }
}
```

```kotlin
import SharedKit.Appearance

fun printTheme() {
    val colors = Appearance.dark.colors
    println(colors.card) // #1F2937
}
```

## Generate bridges manually

Build the generator from a swift4j checkout:

```sh
swift build --product swift4j-cli
```

Run it on the Swift files you want to expose. Create the output directory first:

```sh
mkdir -p generated
swift run swift4j-cli --package SharedKit --java-version 11 \
    -o generated path/to/SharedKit/*.swift
```

Or run the command plugin from the package that depends on Swift4j:

```sh
swift package plugin generate-java-bridging --product SharedKit \
    --java-version 11 --copy-java-sources
```

| Option | Purpose |
| --- | --- |
| `--package <name>` | Required JVM package name for the CLI; derived per target by the command plugin |
| `-o`, `--outdir <directory>` | CLI output directory; omitted to print sources to standard output |
| `--java-version <version>` | Java source compatibility, default `11` |
| `--kotlin` | Generate Kotlin bridges; unreleased |
| `--generate-android-view-models` | Also generate Android ViewModel wrappers for observable classes |
| `--product <name>` | Select a product when using the command plugin |
| `--copy-java-sources` | Copy Java runtime source resources when using the command plugin |

The CLI reads source files; the command plugin visits source targets of the
selected product. Its default output is under
`.build/plugins/generate-java-bridging/outputs/<product>/main/java` (the exact
build location depends on SwiftPM).

Add the generated sources to your JVM build. When using the CLI alone, also
include the runtime Java sources from `Sources/Swift4j/java`. Nullable Java
signatures use JetBrains annotations. Compile and package the Swift shared
library and its native dependencies for the destination platform; generation
alone does not build the library.

## Examples

[swift4j-examples](https://github.com/scade-platform/swift4j-examples) contains
complete JVM and Android projects:

- **SwiftExamples:** callbacks, arrays, nested classes, enums, properties,
  exceptions, observation, Foundation values, and async results.
- **ObservationDemo:** a Swift observable model connected to a Compose UI through
  a generated Android ViewModel.
- **WeatherApp:** a Swift networking service used from Android, with Foundation,
  Alamofire, and SwiftyJSON variants.
- **SimpleDBApp:** shared SQLite logic using GRDB.
- **SalesforceDemo:** a larger asynchronous service integration.

## License and contact

Licensed under [Apache 2.0](LICENSE).
For questions and discussion, [join Discord](https://discord.gg/seAYea9r).
