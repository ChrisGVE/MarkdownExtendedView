// MarkdownExtendedView.swift
// MarkdownExtendedView
//
// A native SwiftUI Markdown renderer with LaTeX support.
// Uses Apple's swift-markdown for parsing and SwiftMath for LaTeX rendering.
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI
import Markdown

/// A SwiftUI view that renders Markdown content with LaTeX equation support.
///
/// Supports GitHub Flavored Markdown (GFM) including:
/// - Headings, paragraphs, and text formatting (bold, italic, strikethrough)
/// - Ordered and unordered lists with nesting
/// - Block quotes and code blocks
/// - Links and images
/// - Tables
/// - Inline LaTeX ($...$) and display LaTeX ($$...$$)
///
/// ## Example Usage
///
/// ```swift
/// MarkdownView(content: """
///     ## Quadratic Formula
///
///     The solutions to $ax^2 + bx + c = 0$ are:
///
///     $$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$$
///     """)
/// ```
///
/// ## Theming
///
/// ```swift
/// MarkdownView(content: markdownString)
///     .markdownTheme(.gitHub)
/// ```
public struct MarkdownView: View {

    // MARK: - Properties

    private let content: String
    private let baseURL: URL?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.markdownTheme) private var theme
    @Environment(\.markdownFeatures) private var features

    // MARK: - Initialization

    /// Creates a MarkdownView with the specified content.
    ///
    /// - Parameters:
    ///   - content: The Markdown string to render (may include LaTeX equations).
    ///   - baseURL: Optional base URL for resolving relative links and images.
    public init(_ content: String, baseURL: URL? = nil) {
        self.content = content
        self.baseURL = baseURL
    }

    /// Creates a MarkdownView with the specified content.
    ///
    /// - Parameters:
    ///   - content: The Markdown string to render (may include LaTeX equations).
    ///   - baseURL: Optional base URL for resolving relative links and images.
    public init(content: String, baseURL: URL? = nil) {
        self.content = content
        self.baseURL = baseURL
    }

    // MARK: - Body

    public var body: some View {
        MarkdownRenderer(
            document: parseMarkdown(content),
            theme: theme,
            baseURL: baseURL
        )
    }

    // MARK: - Parsing

    private func parseMarkdown(_ content: String) -> Document {
        var processedContent = content

        // Pre-process footnotes if enabled
        if features.contains(.footnotes) {
            let footnoteResult = FootnotePreprocessor().process(processedContent)
            processedContent = footnoteResult.processedMarkdown
        }

        // Pre-process content to handle LaTeX blocks before markdown parsing
        processedContent = LaTeXPreprocessor.process(processedContent)

        return Document(parsing: processedContent, options: [.parseBlockDirectives, .parseSymbolLinks])
    }
}

// MARK: - View Modifiers

public extension View {
    /// Applies a Markdown theme to all ``MarkdownView`` instances in the view hierarchy.
    ///
    /// Use this modifier to customize the appearance of Markdown content. The theme
    /// propagates to all nested views, so you can set it at a parent level.
    ///
    /// ```swift
    /// // Apply a built-in theme
    /// MarkdownView(content)
    ///     .markdownTheme(.gitHub)
    ///
    /// // Apply a custom theme
    /// var custom = MarkdownTheme.default
    /// custom.linkColor = .purple
    /// MarkdownView(content)
    ///     .markdownTheme(custom)
    ///
    /// // Apply to a container to theme all nested MarkdownViews
    /// VStack {
    ///     MarkdownView(intro)
    ///     MarkdownView(details)
    /// }
    /// .markdownTheme(.compact)
    /// ```
    ///
    /// - Parameter theme: The ``MarkdownTheme`` to apply.
    /// - Returns: A view with the theme applied to the environment.
    func markdownTheme(_ theme: MarkdownTheme) -> some View {
        environment(\.markdownTheme, theme)
    }
}

// MARK: - Preview

#if DEBUG
struct MarkdownView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MarkdownView("""
                # Welcome to MarkdownView

                This is a **native SwiftUI** Markdown renderer with *LaTeX* support.

                ## Features

                - GitHub Flavored Markdown
                - LaTeX equations: $E = mc^2$
                - Fenced code blocks
                - Tables and lists

                ## Math Example

                The quadratic formula:

                $$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$$

                ## Code Example

                ```swift
                let greeting = "Hello, World!"
                print(greeting)
                ```

                ## Table Example

                | Scale | Purpose |
                |-------|---------|
                | C/D   | Multiply |
                | A/B   | Squares |

                > This is a block quote with **formatting**.
                """)
            .padding()
        }
    }
}
#endif
