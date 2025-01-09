// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ObservableAnchorTrackingSystem",
    platforms: [.visionOS(.v2)],
    products: [
        .library(
            name: "ObservableAnchorTrackingSystem",
            targets: ["ObservableAnchorTrackingSystem"]),
    ],
    targets: [
        .target(
            name: "ObservableAnchorTrackingSystem"),
    ]
)
