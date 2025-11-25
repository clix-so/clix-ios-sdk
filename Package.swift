// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "Clix",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "Clix",
      targets: ["Clix"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "10.0.0"..<"20.0.0"),
    .package(url: "https://github.com/onepiece-studio/mmkv.git", "1.3.0"..<"3.0.0"),
  ],
  targets: [
    .target(
      name: "Clix",
      dependencies: [
        .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
        .product(name: "MMKV", package: "mmkv"),
      ],
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
