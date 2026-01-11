// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownExtendedView",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MarkdownExtendedView",
            targets: ["MarkdownExtendedView"]
        ),
    ],
    dependencies: [
        // Apple's official Markdown parser (CommonMark + GFM extensions)
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
        // Extended LaTeX rendering for SwiftUI (fork of SwiftMath with additional symbol coverage)
        .package(url: "https://github.com/ChrisGVE/ExtendedSwiftMath.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "MarkdownExtendedView",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "ExtendedSwiftMath", package: "ExtendedSwiftMath"),
            ]
        ),
        .testTarget(
            name: "MarkdownExtendedViewTests",
            dependencies: ["MarkdownExtendedView"]
        ),
    ]
)
