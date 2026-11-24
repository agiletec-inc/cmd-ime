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
            path: "Sources/CmdIMESwift",
            resources: [.copy("Resources/Localizable.xcstrings")] +
                ["en", "ja", "ko", "vi", "zh-Hans", "zh-Hant"].map {
                    .process("Resources/\($0).lproj/Localizable.strings")
                }
        ),
        .testTarget(
            name: "CmdIMESwiftTests",
            dependencies: ["CmdIMESwift"],
            path: "Tests/CmdIMESwiftTests"
        )
    ]
)
