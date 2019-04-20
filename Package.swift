// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManifestLoader",
    products: [
        .executable(name: "loader", targets: ["ManifestLoader"]),
        .library(name: "Definitions",
                 type: .dynamic,
                 targets: ["Definitions"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-package-manager.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ManifestLoader",
            dependencies: ["SwiftLoader", "Definitions"]),
        .testTarget(
            name: "ManifestLoaderTests",
            dependencies: ["ManifestLoader"]),
        
        .target(
            name: "SwiftLoader",
            dependencies: ["SPMUtility"]),
        .target(
            name: "Definitions",
            dependencies: []),
    ]
)
