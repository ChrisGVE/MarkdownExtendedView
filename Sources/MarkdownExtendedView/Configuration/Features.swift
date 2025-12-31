// Features.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import Foundation

/// Feature flags for enabling opt-in Markdown capabilities.
///
/// By default, all features that require network access or external resources
/// are disabled. Use the ``SwiftUI/View/markdownFeatures(_:)`` modifier to
/// enable specific features.
///
/// ## Example
///
/// ```swift
/// // Enable clickable links
/// MarkdownView(content)
///     .markdownFeatures(.links)
///
/// // Enable multiple features
/// MarkdownView(content)
///     .markdownFeatures([.links, .images])
/// ```
///
/// ## Privacy
///
/// Features like ``links`` and ``images`` are disabled by default to respect
/// user privacy. When enabled:
/// - **Links**: On iOS, opens URLs in an in-app browser (SFSafariViewController).
///   On macOS, opens in the default browser.
/// - **Images**: Loads images from remote URLs using AsyncImage.
/// - **Mermaid**: Renders diagrams using a WebView.
public struct MarkdownFeatures: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: - Feature Flags

    /// Enable clickable links.
    ///
    /// When enabled, `[text](url)` links become tappable:
    /// - **iOS**: Opens in SFSafariViewController (in-app browser)
    /// - **macOS**: Opens in the default browser
    ///
    /// Use ``SwiftUI/View/onLinkTap(_:)`` for custom link handling.
    public static let links = MarkdownFeatures(rawValue: 1 << 0)

    /// Enable image loading from URLs.
    ///
    /// When enabled, `![alt](url)` images are loaded using AsyncImage.
    /// Supports both remote (https://) and local (file://) URLs.
    public static let images = MarkdownFeatures(rawValue: 1 << 1)

    /// Enable Mermaid diagram rendering.
    ///
    /// When enabled, ```mermaid code blocks are rendered as diagrams
    /// using a WKWebView. This requires loading the Mermaid.js library.
    public static let mermaid = MarkdownFeatures(rawValue: 1 << 2)

    // MARK: - Convenience

    /// No features enabled (default).
    ///
    /// All opt-in features are disabled. This is the default state.
    public static let none: MarkdownFeatures = []

    /// All features enabled.
    ///
    /// Enables links, images, and mermaid diagram rendering.
    public static let all: MarkdownFeatures = [.links, .images, .mermaid]
}
