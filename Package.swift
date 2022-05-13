// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "feature-flag-manager",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FeatureFlag",
            targets: ["FeatureFlag"]),
        .library(
            name: "FeatureFlagProvider",
            targets: ["FeatureFlagProvider"]),
        .library(
            name: "FeatureFlagProviderFirebase",
            targets: ["FeatureFlagProviderFirebase"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FeatureFlag",
            dependencies: []),
        .testTarget(
            name: "FeatureFlagTests",
            dependencies: ["FeatureFlag"]),
        // Feature flag providers
        .target(
                name: "FeatureFlagProvider",
                dependencies: ["FeatureFlag"]),
        .testTarget(
            name: "FeatureFlagProviderTests",
            dependencies: ["FeatureFlagProvider"]),
        // Feature flag firebase provider
        .target(
            name: "FeatureFlagProviderFirebase",
            dependencies: ["FeatureFlag"]),
        .testTarget(
            name: "FeatureFlagProviderFirebaseTests",
            dependencies: ["FeatureFlagProviderFirebase"]),
    ]
)
