// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CmdIMEStore",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CmdIMEStoreCore", targets: ["CmdIMEStoreCore"])
    ],
    targets: [
        .target(name: "CmdIMEStoreCore"),
        .testTarget(name: "CmdIMEStoreCoreTests", dependencies: ["CmdIMEStoreCore"])
    ]
)
