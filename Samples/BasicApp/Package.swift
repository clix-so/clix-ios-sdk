// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "BasicApp",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .executable(
      name: "BasicApp",
      targets: ["BasicApp"]
    )
  ],
  dependencies: [
    .package(name: "Clix", path: "../../")
  ],
  targets: [
    .executableTarget(
      name: "BasicApp",
      dependencies: [
        .product(name: "Clix", package: "Clix")
      ],
      path: "Sources"
    )
  ]
)
