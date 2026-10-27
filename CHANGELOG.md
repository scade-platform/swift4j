# Changelog

Notable changes to swift4j, newest first. Historical entries summarize the local
Git tags and commit history, cross-checked against
[swift4j-examples](https://github.com/scade-platform/swift4j-examples).
Dates are those of the tagged source commits; early tag creation dates can differ.
Features are grouped by the first tagged version containing them.

## Unreleased

### Added

- Opt-in Kotlin source generation for class and struct bridges using
  `swift4j-cli --kotlin`. The flag can also be passed through the
  `generate-java-bridging` command plugin. Java remains the default.
- Kotlin generation for constructors, instance and static properties and methods,
  and observation-tracking accessors.
- Exported properties, methods, and nested types inside enums. Enums with exported
  members or nested declarations are represented as Kotlin sealed classes, even
  when their cases have no associated values.
- Mapping of qualified Swift member types such as `Appearance.Colors` in method
  and property signatures, allowing nested structs to be returned to JVM callers.

### Fixed

- JVM class names and native registration for nested types use the enclosing type
  names and JVM `$` separators.
- Swift concurrency warnings in the `CompletableFuture` wrapper.

### Upgrade notes

- An enum that previously generated a Java enum can now generate a Kotlin sealed
  class if it has exported members or nested types. Such bridges require Kotlin
  compilation, including when `--kotlin` is omitted; callers using Java enum APIs
  may need adjustments.

## 1.5.0 — 2026-06-03

- Added compatibility with the standalone Swift SDK for Android, including its
  `jni` module and JNI pointer types, while retaining the existing CJNI fallback.

## 1.4.0 — 2026-04-02

- Added enums with associated values, represented as Kotlin sealed classes.
  Introduced Kotlin bridge generation for these enums.
- Exposed completion and results of Swift `async` methods through Java
  `CompletableFuture`.
- Added Swift `Result` and error bridging, with JVM `Result` and `SwiftError`
  helpers, and generic type-argument mapping in generated signatures.
- Expanded optional parameter and optional callback support, and added mapping of
  single-element tuple syntax to its element type.
- Fixed Kotlin primitive array type names.
- Improved Swift object lifetime management using JVM phantom references and
  simplified thread-safe class initialization.

## 1.3.2 — 2025-12-17

- Added observation tracking for computed properties.
- Allowed generated Android ViewModels to be created without a ViewModel store
  owner.
- Propagated exceptions from throwing Swift initializers.
- Stopped generating setters for properties whose setters are private.

## 1.3.1 — 2025-10-29

- Made generated class bridge initialization functions public so they are retained
  in release builds.

## 1.3.0 — 2025-10-02

- Added throwing and overloaded function support.
- Added Swift Observation tracking and Kotlin Android ViewModel generation for
  observable Swift classes.
- Added support for `@MainActor` classes, computed properties, and Foundation
  `Date` bridging.
- Added copying of Java source resources through the bridge-generation command
  plugin.
- Fixed computed-property accessors, primitive and enum conversions, class
  initialization, and JVM object reference handling.
- Introduced pointer wrappers in generated Java constructors to avoid overload
  conflicts, and adjusted compatibility with older OS versions.

## 1.2.1 — 2025-07-10

- Fixed imports and declaration issues in the code generators.

## 1.2.0 — 2025-04-08

- Added Swift struct and stored-property bridging.
- Added `inout` parameters, mutating methods, and optional types.
- Fixed primitive conversions when values are represented as Java objects.

## 1.1.0 — 2025-02-07

- Added enums without associated values, represented as Java enums.
- Added nested class exports inside exposed classes, requiring Swift 6 or newer.
- Added compatibility with Swift 6 concurrency checks.
- Fixed macro generation inside conditional compilation blocks, primitive
  conversions, and JVM thread attachment.

## 1.0.0 — 2024-12-15

- Introduced the macro-based Swift-to-JVM toolkit: `@jvm` exports Swift classes,
  initializers, and instance and static methods; `@nonjvm` excludes members.
- Added primitive, string, array, callback, and asynchronous method bridging.
- Added the bridge-generation CLI and Swift package plugins, with Gradle-based
  integration for desktop JVM and Android applications.
- Renamed the SwiftJava product and module to `Swift4j`.
- Added documentation and moved Kotlin and Android samples into the separate
  swift4j-examples repository.

## 0.2.1 — 2022-10-06

- Added Java `URL` and `URI` wrappers.
- Simplified generated abstract-class protocols by removing requirements already
  covered by default implementations.

## 0.2.0 — 2022-05-23

- Added Java NIO buffer wrappers.
- Made generated Java wrapper classes and overridable members `open` in Swift.
- Improved Java class lookup and JNI local-reference cleanup.

## 0.1.0 — 2021-07-07

- Established the initial Java support library for Swift, with JNI access,
  generated Java core and collection wrappers, and value conversions.
- Added a workaround for crashes when converting Swift arrays to Java objects.

The repository began with the Java support library beta in May 2021; the first
version tag was 0.1.0.
