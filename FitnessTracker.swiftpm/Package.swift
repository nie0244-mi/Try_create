// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "FitnessTracker",
    platforms: [
        .iOS(.v16)
    ],
    targets: [
        .executableTarget(
            name: "FitnessTracker",
            path: "Sources"
        )
    ]
)
