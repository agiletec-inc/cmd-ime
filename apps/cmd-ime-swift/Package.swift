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
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CmdIMESwift",
            dependencies: [],
            path: "Sources/CmdIMESwift"
        ),
        .testTarget(
            name: "CmdIMESwiftTests",
            dependencies: ["CmdIMESwift"],
            path: "Tests/CmdIMESwiftTests"
        ),
        .testTarget(
            name: "CmdIMESwiftUITests",
            dependencies: ["CmdIMESwift"],
            path: "Tests/CmdIMESwiftUITests"
        )
    ]
)
