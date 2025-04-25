// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Clix",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Clix",
            targets: ["Clix"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Clix",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "ClixTests",
            dependencies: ["Clix"],
            path: "Tests"
        ),
    ]
)
