// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FormJyotish",
    platforms: [.macOS(.v14)],
    targets: [.executableTarget(name: "FormJyotish", path: "app")]
)
