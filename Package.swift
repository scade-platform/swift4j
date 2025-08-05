// swift-tools-version:5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Java",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    
    products: [
        .library(name: "Java", type: .static, targets: ["Java"]),
        .library(name: "Swift4j", targets: ["Swift4j"]),

        .executable(name: "swift4j-cli", targets: ["swift4j-cli"]),

        .plugin(name: "swift4j-plugin", targets: ["swift4j-plugin"]),
        .plugin(name: "generate-java-bridging", targets: ["generate-java-bridging"])
    ],

    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
      .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],

    targets: [
        .systemLibrary(name: "CJNI"),
        
        .target(name: "CAndroid"),

        .target(name: "Java",
                dependencies: [
                  "CJNI",
                  .target(name: "CAndroid", condition: .when(platforms: [.android])),
                ]),

        .target(name: "SwiftSyntaxExtensions",
                dependencies: [
                  .product(name: "SwiftSyntax", package: "swift-syntax")
                ]),

        .macro(name: "Swift4jMacros",
               dependencies: [
                  "SwiftSyntaxExtensions",
                   .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                   .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
               ]),

        .target(name: "Swift4j",
                dependencies: [
                  "Java",
                  "Swift4jMacros"
                ]),

        .executableTarget(name: "swift4j-cli",
                         dependencies: [
                          "SwiftSyntaxExtensions",
                          .product(name: "ArgumentParser", package: "swift-argument-parser"),
                          .product(name: "SwiftParser", package: "swift-syntax")
                         ]),

        .plugin(name: "swift4j-plugin",
                capability: .buildTool(),
                dependencies: ["swift4j-cli"]),

        
        .plugin(name: "generate-java-bridging",
                capability: .command(
                  intent: .custom(verb: "generate-java-bridging",
                                  description: "Generate Java bridging proxies for the Swift classes"),
                  permissions: []),
                dependencies: ["swift4j-cli"]
               )
    ]
)

