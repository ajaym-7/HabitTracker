// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HabitTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HabitTracker", targets: ["HabitTracker"])
    ],
    targets: [
        .executableTarget(
            name: "HabitTracker",
            path: "Sources/HabitTracker"
        ),
        .testTarget(
            name: "HabitTrackerTests",
            dependencies: ["HabitTracker"],
            path: "Tests/HabitTrackerTests"
        )
    ]
)
