// swift-tools-version: 5.10

import PackageDescription
let package = Package(
    name: "CmdIMESwift",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CmdIMESwift", targets: ["CmdIMESwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "CmdIMESwift",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/CmdIMESwift"
        ),
        .testTarget(
            name: "CmdIMESwiftTests",
            dependencies: ["CmdIMESwift"],
            path: "Tests/CmdIMESwiftTests"
        )
    ]
)
