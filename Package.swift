// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiVIP",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MiVIP",
            targets: ["MiVIPTarget"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Mitek-Systems/MiSnap-iOS", .exact("5.9.1"))
    ],
    targets: [
        .target(
            name: "MiVIPTarget",
            dependencies: [
                "MiVIPSdk",
                "MiVIPApi",
                "MiVIPLiveness",
                .product(name: "MiSnap", package: "MiSnap-iOS"),
                .product(name: "MiSnapUX", package: "MiSnap-iOS"),
                .product(name: "MiSnapFacialCapture", package: "MiSnap-iOS"),
                .product(name: "MiSnapFacialCaptureUX", package: "MiSnap-iOS"),
                .product(name: "MiSnapVoiceCapture", package: "MiSnap-iOS"),
                .product(name: "MiSnapVoiceCaptureUX", package: "MiSnap-iOS"),
                .product(name: "MiSnapNFC", package: "MiSnap-iOS"),
                .product(name: "MiSnapNFCUX", package: "MiSnap-iOS")
            ],
            path: "Sources/MiVIP"
        ),
        .binaryTarget(
            name: "MiVIPSdk",
            path: "SDKs/MiVIPSdk.xcframework"
        ),
        .binaryTarget(
            name: "MiVIPApi",
            path: "SDKs/MiVIPApi.xcframework"
        ),
        .binaryTarget(
            name: "MiVIPLiveness",
            path: "SDKs/MiVIPLiveness.xcframework"
        )
    ]
)
