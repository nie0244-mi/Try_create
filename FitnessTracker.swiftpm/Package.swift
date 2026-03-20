// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitnessTracker",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .executableTarget(
            name: "FitnessTracker",
            path: ".",
            exclude: ["Package.swift"]
        )
    ]
)
