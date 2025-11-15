// swift-tools-version: 5.10

import PackageDescription
import Foundation

let packageDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
let rustTargetRoot = "\(packageDirectory)/../cmd-ime-rust/src-tauri/target"
let rustReleasePath = "\(rustTargetRoot)/release"
let rustDebugPath = "\(rustTargetRoot)/debug"
let linkerFlags = ["-L", rustReleasePath, "-L", rustDebugPath]

let package = Package(
    name: "CmdIMESwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CmdIMESwift", targets: ["CmdIMESwift"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CmdIMERuntime",
            path: "Sources/CmdIMERuntime",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .unsafeFlags(linkerFlags),
                .linkedLibrary("cmd_ime_rust_lib")
            ]
        ),
        .executableTarget(
            name: "CmdIMESwift",
            dependencies: ["CmdIMERuntime"],
            path: "Sources/CmdIMESwift",
            linkerSettings: [
                .unsafeFlags(linkerFlags),
                .linkedLibrary("cmd_ime_rust_lib")
            ]
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
