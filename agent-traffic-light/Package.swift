// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AgentTrafficLight",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AgentTrafficLight",
            targets: ["AgentTrafficLight"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AgentTrafficLight"
        ),
        .testTarget(
            name: "AgentTrafficLightTests",
            dependencies: ["AgentTrafficLight"]
        )
    ]
)
