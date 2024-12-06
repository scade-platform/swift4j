# Swift4j Toolkit

The **swift4j** toolkit is a set of libraries and tools making possible a seamless interoperability between Swift and Java/Kotlin. Besides the **swift4j** Swift package presented in this repository there are also a set of Gradle plugins and the Swift Toolchain for Android allowing smooth integration of the Swift libraries into the desktop and mobile applications written in Java/Kotlin.       

## Description

The **swift4j** packages contains of a set of libraries and tools drastically simplifying interoperability between Swift and JVM. The central part of the package is built around the Swift macro system and the Swift package plugins, both are based on the library abstracting away the details of the Java Native Interfaces (JNI), that is used for the communication between JVM and the native code. The structure of the package is as following:

- `Sources/CJNI` and `Sources/Java` - abstraction layer over the JNI
- `Sources/SwiftJava` and `Sources/SwiftJavaMacros` - macros generating the bridging code on the Swift side
- `Sources/swift4j` - CLI tool generating the Java bridging code on the Java side 
- `Plugins/generate-java-bridging` - SPM command line plugin around the CLI tool 

The main goal of the **swift4j** package is to annotate the Swift code and generate bridgings for the Swift/JVM interoperability. In order to simplify the integration into the native Java/Kotlin development enviroments there are two **[SwiftPM Gradle plugins]([GitHub - scade-platform/spm-gradle-plugin: Swift Package Manager Plugin for Gradle](https://github.com/scade-platform/spm-gradle-plugin))**:

* `io.scade.gradle.plugins.swiftpm` - for generic Java/Kotlin projects  

* `io.scade.gradle.plugins.android.swiftpm` - for Java/Kotlin projects on the Android platform

For more details on plugins configuration please refer to the plugin's [README](https://github.com/scade-platform/spm-gradle-plugin/blob/main/README.md)

The **SwiftPM Plugin for Android** takes care of the installation of the [Swift Toolchain for Android](https://github.com/scade-platform/swift-android-toolchain) that allows to compile Swift code for the Android platform as well as packaging all required parts into a ready to use application. For more details, please follow the [Usage](#usage) section or take a look at [Switf4j Examples]([GitHub - scade-platform/swift4j-examples: Usage examples of the Swift4j Toolkit](https://github.com/scade-platform/swift4j-examples)).   

## Getting Started

### Prerequisites

TBD

### Usage

#### Swift code annotations

To make the Swift code available for the JVM platform, we first need to annotate our Swift code by macros defined in the **swift4j**. 

To do this, we add a dependency on the **swift4j** package into the `Package.swift` file:

```swift
let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/scade-platform/swift4j.git", from: "1.0.0")
  ]
  ...
)
```

Now, we can add a target dependency on the **SwiftJava** product from the **swift4j** package to all targets in our `Package.swift` file that are going to be exposed to Java/Kotlin. For example to expose a *swift4j-examples* target, do the following:

```swift
.target(
  name: "swift4j-examples",
  dependencies: [
    .product(name: "SwiftJava", package: "swift4j")              
  ]
)
```

**NOTE:** due to limitations of JNI, only Swift targets that are parts of dynamic libraries can be accessed from Java/Kotlin. 

After that we can annotate our code using Swift macro `@jvm`. For example:

```swift
import SwiftJava // import @jvm macro and supporting types 

// @jvm automatically exposes the annoted class together with
// all methods that can be exposed
@jvm 
public class GreetingService {
  func greet(name: String, _ response: (String) -> Void) {        
    response("Swift greets \(name)")
  }
}
```

And that is everything what is needed to expose the class `GreetingService`. After adding the macro `@jvm` to the class definition, all necessary bridging code will be generated for the class as well as for all methods that can be exposed. 

For every method that cannot be exposed a warning will be generated suggesting to add a `@nonjvm` macro to ignore export. The macro can be also used just to not expose some methods. For example:

```swift
@jvm 
public class GreetingService {
  ...
  @nonjvm 
  func greet(person: Person, _ response: (String) -> Void) {        
    response("Swift greets \(person.name)!")
  }
}
```

In this case the type `Person` used in the `greet` method's signature is not exposed to Java/Kotlin and hence the method cannot be exposed as well.  We can either ignore the whole method by adding  `@nonjvm` macro to it or expose the type `Person`. 

**NOTE**: due to some significant differences between Swift and JVM not all Swift types and constructs can be exposed to Java/Kotlin whereas some constructs are not supported yet and will be added in future releases. More details on exposable types and constructs can be found in the [Language Features Support](#language-features-support) section

#### Call Swift code from Java/Kotlin

The easiest way to integrate the exposed Swift code into the Java/Kotlin projects is to use one of the **[SwiftPM Gradle plugins]([GitHub - scade-platform/spm-gradle-plugin: Swift Package Manager Plugin for Gradle](https://github.com/scade-platform/spm-gradle-plugin))** depending on the target platform. 

For example, in order to use the exposed Swift code in an Android application, just add the `io.scade.gradle.plugins.android.swiftpm` plugin to your `build.gradle.kts` file:    

```kotlin
plugins {
  id("io.scade.gradle.plugins.swiftpm") version "1.0.3" 
}
```

together with the plugin's configuration section:

```kotlin
swiftpm { 
  // Path to the Swift package
  path = file("<PACKAGE LOCATION>")
  // Name of the package's product (dynamic) containing exposed Swift targets
  product = "<PRODUCT NAME>"
}
```

Now you can access all exposed classes from Java/Kotlin by importing them just like normal Java classes. The **swift4j** tool tries to generate bridgings as closed to Java coding conventions as possible while preserving the original Swift design. 

For example to call the previously exposed `GreetingService` from Kotlin do the following:

```kotlin
import swift4j_examples.GreetingService

// The Swift dynamic library has to be loaded once prior
// the use of any exposed type  
System.loadLibrary("swift4-examples")

// Create an instance of the exposed class 
val greetings = GreetingService()
// And call the 'greet' method passing a KotlinlLambda  
greetings.greet("Android") { resp ->
  print(resp)    
}
// Output: Swift greets Android!
```

In the code snippet above the exposed class imported from the package named by the name of the original Swift target, i.e. the `swift4-examples` (a hyphen is replaced by an undescore as it is not allowed in Java names). After the library is loaded, we can finally access all exposed and imported types as they would be originally written in Java or Kotlin. For example, Swift lambdas are mapped to Kotlin lambdas making it really easy to call Swift code that accepts callbacks.

#### Generate bridgings manually (without Gradle plugins)

TBD

## Language Features Support

Currently the following types can be exposed:

- Any non-generic class marked by `@jvm`  macro

- Any primitive type

- Arrays of exposed types

- Any lambda only containing exposed types in its signature
  
   

The following class members are supported if and only if its signatures only contain exposed types:

- Initialisers

- Instance methods
  
  - `async` methods are supported and are called asynchronously 

- Static methods
  
  
## Examples

[Switf4j Examples]([GitHub - scade-platform/swift4j-examples: Usage examples of the Swift4j Toolkit](https://github.com/scade-platform/swift4j-examples.git)) 


## License

Please see [LICENSE](LICENSE.txt) for more information.
