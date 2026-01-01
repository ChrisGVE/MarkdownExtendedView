// Features.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import Foundation
import SwiftUI

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

    /// Enable syntax highlighting for code blocks.
    ///
    /// When enabled, code blocks with language specifiers (e.g., ```swift)
    /// are rendered with syntax highlighting for keywords, strings, comments,
    /// and other language constructs.
    public static let syntaxHighlighting = MarkdownFeatures(rawValue: 1 << 3)

    /// Enable footnote processing.
    ///
    /// When enabled, footnote syntax (`[^1]` and `[^1]: definition`) is
    /// processed and rendered as numbered superscripts with a footnotes
    /// section at the end of the document.
    public static let footnotes = MarkdownFeatures(rawValue: 1 << 4)

    // MARK: - Convenience

    /// No features enabled (default).
    ///
    /// All opt-in features are disabled. This is the default state.
    public static let none: MarkdownFeatures = []

    /// All features enabled.
    ///
    /// Enables links, images, mermaid diagrams, syntax highlighting, and footnotes.
    public static let all: MarkdownFeatures = [.links, .images, .mermaid, .syntaxHighlighting, .footnotes]
}

// MARK: - Environment Keys

/// Environment key for enabled Markdown features.
private struct MarkdownFeaturesKey: EnvironmentKey {
    static let defaultValue: MarkdownFeatures = .none
}

/// Environment key for custom link tap handler.
private struct MarkdownLinkHandlerKey: EnvironmentKey {
    static let defaultValue: ((URL) -> Void)? = nil
}

public extension EnvironmentValues {

    /// The enabled Markdown features for ``MarkdownView`` instances.
    ///
    /// Set this value using the ``SwiftUI/View/markdownFeatures(_:)`` modifier:
    ///
    /// ```swift
    /// MarkdownView(content)
    ///     .markdownFeatures([.links, .images])
    /// ```
    ///
    /// The features propagate through the view hierarchy.
    var markdownFeatures: MarkdownFeatures {
        get { self[MarkdownFeaturesKey.self] }
        set { self[MarkdownFeaturesKey.self] = newValue }
    }

    /// A custom handler for link taps in ``MarkdownView``.
    ///
    /// When set, this handler is called instead of the default link behavior.
    /// Use the ``SwiftUI/View/onLinkTap(_:)`` modifier to set this:
    ///
    /// ```swift
    /// MarkdownView(content)
    ///     .markdownFeatures(.links)
    ///     .onLinkTap { url in
    ///         // Custom handling
    ///     }
    /// ```
    var markdownLinkHandler: ((URL) -> Void)? {
        get { self[MarkdownLinkHandlerKey.self] }
        set { self[MarkdownLinkHandlerKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {

    /// Enables specific Markdown features for this view hierarchy.
    ///
    /// By default, all opt-in features are disabled. Use this modifier to
    /// enable features like clickable links or image loading.
    ///
    /// ```swift
    /// // Enable links only
    /// MarkdownView(content)
    ///     .markdownFeatures(.links)
    ///
    /// // Enable multiple features
    /// MarkdownView(content)
    ///     .markdownFeatures([.links, .images])
    /// ```
    ///
    /// - Parameter features: The features to enable.
    /// - Returns: A view with the specified features enabled.
    func markdownFeatures(_ features: MarkdownFeatures) -> some View {
        environment(\.markdownFeatures, features)
    }

    /// Sets a custom handler for link taps in Markdown content.
    ///
    /// When a link is tapped and the ``MarkdownFeatures/links`` feature is enabled,
    /// this handler is called instead of the default behavior (opening in browser).
    ///
    /// ```swift
    /// MarkdownView(content)
    ///     .markdownFeatures(.links)
    ///     .onLinkTap { url in
    ///         // Custom link handling
    ///         print("User tapped: \(url)")
    ///     }
    /// ```
    ///
    /// - Parameter handler: A closure that receives the tapped URL.
    /// - Returns: A view with the custom link handler set.
    func onLinkTap(_ handler: @escaping (URL) -> Void) -> some View {
        environment(\.markdownLinkHandler, handler)
    }
}
