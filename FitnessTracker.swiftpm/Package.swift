// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitnessTracker",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "FitnessTracker",
            path: "Sources"
        )
    ]
)
