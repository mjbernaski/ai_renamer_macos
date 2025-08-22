// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIImageRenamer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AIImageRenamer",
            targets: ["AIImageRenamer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "AIImageRenamer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
            path: "Sources"
        ),
    ]
)
