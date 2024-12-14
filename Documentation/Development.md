# Swift4j Package

## Structure

The structure of the package is as following:

- `Sources/CJNI` and `Sources/Java` - abstraction layer over the JNI
- `Sources/SwiftJava` and `Sources/SwiftJavaMacros` - macros generating the bridging code on the Swift side
- `Sources/swift4j` - CLI tool generating the Java bridging code on the Java side 
- `Plugins/generate-java-bridging` - SPM command line plugin around the CLI tool 