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
        // Pre-process content to handle LaTeX blocks before markdown parsing
        let processedContent = LaTeXPreprocessor.process(content)
        return Document(parsing: processedContent, options: [.parseBlockDirectives, .parseSymbolLinks])
    }
}

// MARK: - View Modifiers

public extension View {
    /// Applies a Markdown theme to the view hierarchy.
    ///
    /// - Parameter theme: The theme to apply.
    /// - Returns: A view with the theme applied.
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
                - Code blocks with syntax highlighting
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
