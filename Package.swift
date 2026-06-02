// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// The native Mermaid renderer (branch A, PRD §4.5) is wrapped as a LOCAL
// `binaryTarget(path:)` pointing at `Artifacts/MermaidFFI.xcframework`. That
// xcframework is a BUILD PRODUCT, built on demand via
// scripts/build-xcframework.sh and gitignored — it is NOT committed during
// development. SwiftPM validates EVERY declared binary target at plan time, so
// an unconditional `binaryTarget` would make a fresh clone (lightweight CI, an
// external SPM consumer) fail to build the CORE product too, because the
// artifact is absent. To keep the core product buildable everywhere with no
// artifact and no Rust toolchain, the native product/target/binaryTarget are
// included ONLY when `MEV_MERMAID_NATIVE` is set in the environment.
//
// Build/test the native product locally or in the native CI job:
//   ./scripts/build-xcframework.sh           # build the artifact on demand
//   MEV_MERMAID_NATIVE=1 swift build         # include the native product
//   MEV_MERMAID_NATIVE=1 swift test          # run the native test target
//
// Consumer opt-in over plain SPM (no env var) is a Phase-11 / publish concern,
// gated on the artifact being hosted (PRD §13-D3) — out of MVP scope (D2).
let buildNative = ProcessInfo.processInfo.environment["MEV_MERMAID_NATIVE"] != nil

var products: [Product] = [
    .library(
        name: "MarkdownExtendedView",
        targets: ["MarkdownExtendedView"]
    ),
]

var dependencies: [Package.Dependency] = [
    // Apple's official Markdown parser (CommonMark + GFM extensions)
    .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
    // Companion library for native LaTeX rendering in SwiftUI with extended symbol coverage
    .package(url: "https://github.com/ChrisGVE/ExtendedSwiftMath.git", from: "2.0.1"),
]

var targets: [Target] = [
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

if buildNative {
    // Optional opt-in product (branch A): the native, WebView-free Mermaid
    // renderer. The core product above stays binary- and dependency-free.
    // Name is PROVISIONAL (PRD §12-Q1).
    products.append(
        .library(
            name: "MarkdownExtendedViewMermaidNative",
            targets: ["MarkdownExtendedViewMermaidNative"]
        )
    )

    // Vector SVG display for the native Mermaid path. VERIFY gate (PRD §4.5):
    // SVGView 1.0.6 declares swift-tools-version:5.3 (≤ our 5.9) and a platform
    // floor of iOS14/macOS11 (≤ our iOS16/macOS13) — compatible.
    dependencies.append(
        .package(url: "https://github.com/exyte/SVGView.git", from: "1.0.6")
    )

    targets += [
        // Prebuilt Rust static lib, built LOCALLY from the submodule via
        // scripts/build-xcframework.sh, wrapped as a LOCAL binary target.
        // D2: local-path ONLY in MVP — no remote url:/checksum: form here
        // (that is Phase 11 / PRD §13-D3). The module imported in Swift is
        // `Cmmdr` (see the xcframework's module.modulemap).
        .binaryTarget(
            name: "CMermaidFFI",
            path: "Artifacts/MermaidFFI.xcframework"
        ),
        // Swift wrapper importing the C module and (later phases) displaying the
        // diagram natively. The ONLY target depending on SVGView + CMermaidFFI,
        // keeping core clean (branch A).
        .target(
            name: "MarkdownExtendedViewMermaidNative",
            dependencies: [
                "CMermaidFFI",
                "MarkdownExtendedView",
                .product(name: "SVGView", package: "SVGView"),
            ]
        ),
        .testTarget(
            name: "MarkdownExtendedViewMermaidNativeTests",
            dependencies: ["MarkdownExtendedViewMermaidNative"],
            // Snapshot references are read by path via #filePath, not bundled;
            // exclude them so SPM does not warn about unhandled files.
            exclude: ["Fixtures"]
        ),
    ]
}

let package = Package(
    name: "MarkdownExtendedView",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
