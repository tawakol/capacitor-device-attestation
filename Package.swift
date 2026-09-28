// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorDeviceAttestation",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorDeviceAttestation",
            targets: ["DeviceAttestationPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "DeviceAttestationPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/DeviceAttestationPlugin"),
        .testTarget(
            name: "DeviceAttestationPluginTests",
            dependencies: ["DeviceAttestationPlugin"],
            path: "ios/Tests/DeviceAttestationPluginTests")
    ]
)