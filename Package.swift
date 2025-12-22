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
        // Native LaTeX rendering for SwiftUI
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.3"),
    ],
    targets: [
        .target(
            name: "MarkdownExtendedView",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftMath", package: "SwiftMath"),
            ]
        ),
        .testTarget(
            name: "MarkdownExtendedViewTests",
            dependencies: ["MarkdownExtendedView"]
        ),
    ]
)
