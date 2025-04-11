# Swift4j Toolkit

The **swift4j** toolkit is a set of libraries and tools making possible a seamless interoperability between Swift and Java/Kotlin. Besides the **swift4j** Swift package presented in this repository there are also a set of Gradle plugins and the Swift Toolchain for Android allowing smooth integration of the Swift libraries into the desktop and mobile applications written in Java/Kotlin.       

## Quick Example

Using the *swift4j* Toolkit we can access, for example, the following Swift class:

```swift
@jvm class Arrays {
  static func mapReversed(_ arr: [Int], mapping: (Int) -> Int) -> [Int] {
    return arr.reversed().map(mapping)
  } 
}

```

from Kotlin:


```kotlin
val arr = longArrayOf(1, 2, 3)
Arrays.mapReversed(arr) {
  it + 1
}
```

by just adding a single `@jvm` annotation to the Swift class. 

## Description

The **swift4j** packages contains of a set of libraries and tools drastically simplifying interoperability between Swift and JVM. The central part of the package is built around the Swift macro system and the Swift package plugins, both are based on the library abstracting away the details of the Java Native Interfaces (JNI), that is used for the communication between JVM and the native code. 

The main goal of the **swift4j** package is to annotate the Swift code and generate bridgings for the Swift/JVM interoperability. In order to simplify the integration into the native Java/Kotlin development enviroments there are two [SwiftPM Gradle](https://github.com/scade-platform/spm-gradle-plugin) plugins:

* `io.scade.gradle.plugins.swiftpm` - for generic Java/Kotlin projects  

* `io.scade.gradle.plugins.android.swiftpm` - for Java/Kotlin projects on the Android platform

The **SwiftPM Gradle** plugin for Android takes care of the installation of the [Swift for Android](https://github.com/scade-platform/swift-android-toolchain) that allows to compile Swift code for the Android platform as well as packaging all required parts into a ready to use application. For more details, please follow the [Usage](#usage) section or take a look at [swift4j-examples](https://github.com/scade-platform/swift4j-examples).   

For more details on plugins configuration please refer to the plugin's [README](https://github.com/scade-platform/spm-gradle-plugin/blob/main/README.md)


## Getting Started

### Prerequisites

- macOS, Linux
	- Swift >= 5.9
	- Java >= 1.8

- Android
	- NDK 25.x (can be installed from the Android Studio)
	- [Swift for Android](https://github.com/scade-platform/swift-android-toolchain) >= 5.10 (will be installed automatically when used with the SwiftPM Gradle plugin)
 
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

Now, we can add a target dependency on the **Swift4j** product from the **swift4j** package to all targets in our `Package.swift` file that are going to be exposed to Java/Kotlin. For example to expose a *swift4j-examples* target, do the following:

```swift
.target(
  name: "swift4j-examples",
  dependencies: [
    .product(name: "Swift4j", package: "swift4j")              
  ]
)
```

**NOTE:** due to limitations of JNI, only Swift targets that are parts of dynamic libraries can be accessed from Java/Kotlin. 

After that we can annotate our code using Swift macro `@jvm`. For example:

```swift
import Swift4j // import @jvm macro and supporting types 

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

The easiest way to integrate the exposed Swift code into the Java/Kotlin projects is to use one of the [SwiftPM Gradle](https://github.com/scade-platform/spm-gradle-plugin) plugins depending on the target platform.

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
// And call the 'greet' method passing a Kotlin lambda  
greetings.greet("Android") { resp ->
  print(resp)    
}
// Output: Swift greets Android!
```

In the code snippet above the exposed class imported from the package named by the name of the original Swift target, i.e. the `swift4-examples` (a hyphen is replaced by an undescore as it is not allowed in Java names). After the library is loaded, we can finally access all exposed and imported types as they would be originally written in Java or Kotlin. For example, Swift lambdas are mapped to Kotlin lambdas making it really easy to call Swift code that accepts callbacks.

#### Generate bridgings manually (without Gradle plugins)

It is also possible to generate Java bridgings without the SwiftPM Gradle plugins using either the *swift4j-cli* CLI tool or the Swift package command line plugin. Both are included in the *swift4j* package.

**NOTE:** the CLI tool generates bridgings from Swift files only while the SPM plugin generates for the whole product  

To generate bridgings using the CLI tool, execute the following command:

```shell
swift4j-cli --package <JAVA_PACKAGE> --java-version <JAVA_VERSION> -o <OUTPUT_FOLDER> <INPUT SWIFT FILES>
```

Parameters:
	
- **JAVA_PACKAGE** (required): Java package name for the generated classes
- **JAVA_VERSION** (optional): Java version the generated source has to be compatible with (default: 11). For Android has to be adjusted depending on the minimal API level
- **OUTPUT_FOLDER** (optional): Output folder (default: outputs classes to the standart output)	 

To generate bridgings using the SPM package plugin, execute the following command in the folder where your `Package.swift` is located:

```shell
swift package plugin generate-java-bridging --product <PRODUCT> --java-version <JAVA_VERSION>
```

Parameters:
- **PRODUCT** (required): Product name from your package for which the bridgings has to be generated 
- **JAVA_VERSION** (optional): Same as for the CLI version 

The SPM plugin recursively iterates over all targets of the product and generates bridgings for all classes marked by the `@jvm` macro. It uses a target name as a Java package name for all classes within the target. That's why it does not need a Java package name as an input. The generated classes are written into the Swift package's build folder (default: `.build/plugins/generate-java-bridging/outputs`). For every target a separate folder is created in the output folder.

After the generation, the briging files can be built and used as normal Java sources in any Java/Kotlin project by including them into the source tree. The binary can be built using the standard Swift build process for the target platform and can be then included into the final product.


## Language Features Support

Non-generic types (marked by `@jvm` macro):

- Classes

- Structs

- Enums without associated types

- Nested types (if parent type is also exposed)

Built-in types:

- Primitive types

- Arrays of exposed types

- Lambdas (if all signature types are exposed)
  
Non-private type members (if and only if its signatures only contain exposed types):

- Initialisers

- Instance methods
  
  - `async` methods (called asynchronously)
  - `inout` parameters

- Static methods

- Properties

  
Work in Progress:

- Overloading

- Error handling (`throws`)

- Extensions
  
## Examples

[swift4j-examples](https://github.com/scade-platform/swift4j-examples) 


## Contact

[Join our Discord channel](https://discord.gg/seAYea9r)


## License

Please see [LICENSE](LICENSE.txt) for more information.
