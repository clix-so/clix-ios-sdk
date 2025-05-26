// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "Clix",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    .library(
      name: "Clix",
      targets: ["Clix"]
    ),
    .executable(
      name: "BasicApp",
      targets: ["BasicApp"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
  ],
  targets: [
    .target(
      name: "Clix",
      dependencies: [
        .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
      ],
      path: "Sources",
      swiftSettings: [
        .define("DEBUG", .when(configuration: .debug)),
        .define("RELEASE", .when(configuration: .release)),
      ]
    ),
    .executableTarget(
      name: "BasicApp",
      dependencies: ["Clix"],
      path: "Samples/BasicApp/Sources"
    ),
    .testTarget(
      name: "ClixTests",
      dependencies: ["Clix"],
      path: "Tests"
    ),
  ]
)
