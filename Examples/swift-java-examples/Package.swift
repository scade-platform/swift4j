// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-java-examples",
    platforms: [.macOS(.v10_15)],

    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-java-examples",
            type: .dynamic,
            targets: ["swift-java-examples"]),
    ],

    dependencies: [
      .package(path: "../../")
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "swift-java-examples",
            dependencies: [.product(name: "SwiftJava", package: "swift-java")],
            plugins: [
              .plugin(name: "swift4j-plugin", package: "swift-java")
            ]
        ),
    ]
)
