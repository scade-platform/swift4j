// swift-tools-version:5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Java",
    platforms: [.macOS(.v13)],

    products: [
        .library(name: "Java", type: .static, targets: ["Java"]),
        .library(name: "SwiftJava", targets: ["SwiftJava"]),
        
        .executable(name: "swift4j", targets: ["swift4j"]),

        .plugin(name: "swift4j-plugin", targets: ["swift4j-plugin"]),
        .plugin(name: "generate-java-bridging", targets: ["generate-java-bridging"])
    ],

    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
      .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],

    targets: [
        .systemLibrary(name: "CJNI"),
        
        .target(name: "Java",
                dependencies: ["CJNI"]),

        .target(name: "SwiftSyntaxExtensions",
                dependencies: [
                  .product(name: "SwiftSyntax", package: "swift-syntax")
                ]),

        .macro(name: "SwiftJavaMacros",
               dependencies: [
                  "SwiftSyntaxExtensions",
                   .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                   .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
               ]),

        .target(name: "SwiftJava", 
                dependencies: [
                  "Java",
                  "SwiftJavaMacros"
                ]),

        .executableTarget(name: "swift4j",
                         dependencies: [
                          "SwiftSyntaxExtensions",
                          .product(name: "ArgumentParser", package: "swift-argument-parser"),
                          .product(name: "SwiftParser", package: "swift-syntax")
                         ]),

        .plugin(name: "swift4j-plugin",
                capability: .buildTool(),
                dependencies: ["swift4j"]),

        
        .plugin(name: "generate-java-bridging",
                capability: .command(
                  intent: .custom(verb: "generate-java-bridging",
                                  description: "Generate Java bridging proxies for the Swift classes"),
                  permissions: []),
                dependencies: ["swift4j"]
               )

/*
        .testTarget(name: "SwiftJavaTests",
              dependencies: [
                  "SwiftJavaMacros",
                  .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
              ]
          )
*/
    ]
)

