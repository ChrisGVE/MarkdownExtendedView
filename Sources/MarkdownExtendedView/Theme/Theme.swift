// Theme.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI

// MARK: - Theme

/// A theme for customizing the appearance of rendered Markdown content.
///
/// `MarkdownTheme` provides comprehensive control over typography, colors, and spacing
/// for all Markdown elements. You can use one of the built-in themes or create a custom
/// theme by modifying properties.
///
/// ## Using Built-in Themes
///
/// ```swift
/// MarkdownView(content)
///     .markdownTheme(.gitHub)
/// ```
///
/// ## Creating a Custom Theme
///
/// ```swift
/// var theme = MarkdownTheme.default
/// theme.linkColor = .purple
/// theme.paragraphSpacing = 16
///
/// MarkdownView(content)
///     .markdownTheme(theme)
/// ```
///
/// ## Available Properties
///
/// ### Typography
/// - ``bodyFont``: Main paragraph text
/// - ``heading1Font`` through ``heading6Font``: Heading levels
/// - ``codeFont``: Inline code spans
/// - ``codeBlockFont``: Fenced code blocks
///
/// ### Colors
/// - ``textColor``: Primary text color
/// - ``secondaryTextColor``: De-emphasized text (e.g., image alt text)
/// - ``linkColor``: Hyperlink color
/// - ``codeBackgroundColor``: Background for code blocks
/// - ``blockQuoteBorderColor``: Left border of block quotes
/// - ``tableBorderColor``: Table cell borders
/// - ``tableHeaderBackgroundColor``: Table header row background
///
/// ### Spacing
/// - ``paragraphSpacing``: Vertical space between block elements
/// - ``listItemSpacing``: Space between list items
/// - ``indentation``: Indent for nested content
/// - ``codeBlockPadding``: Internal padding of code blocks
public struct MarkdownTheme: Sendable {

    // MARK: - Text Styles

    /// Font for body text.
    public var bodyFont: Font
    /// Font for H1 headings.
    public var heading1Font: Font
    /// Font for H2 headings.
    public var heading2Font: Font
    /// Font for H3 headings.
    public var heading3Font: Font
    /// Font for H4 headings.
    public var heading4Font: Font
    /// Font for H5 headings.
    public var heading5Font: Font
    /// Font for H6 headings.
    public var heading6Font: Font
    /// Font for inline code.
    public var codeFont: Font
    /// Font for code blocks.
    public var codeBlockFont: Font

    // MARK: - Colors

    /// Primary text color.
    public var textColor: Color
    /// Secondary text color (for less emphasis).
    public var secondaryTextColor: Color
    /// Link color.
    public var linkColor: Color
    /// Code background color.
    public var codeBackgroundColor: Color
    /// Block quote border color.
    public var blockQuoteBorderColor: Color
    /// Table border color.
    public var tableBorderColor: Color
    /// Table header background color.
    public var tableHeaderBackgroundColor: Color

    // MARK: - Spacing

    /// Spacing between paragraphs.
    public var paragraphSpacing: CGFloat
    /// Spacing between list items.
    public var listItemSpacing: CGFloat
    /// Indentation for nested content.
    public var indentation: CGFloat
    /// Padding inside code blocks.
    public var codeBlockPadding: CGFloat

    // MARK: - Initialization

    public init(
        bodyFont: Font = .body,
        heading1Font: Font = .largeTitle.bold(),
        heading2Font: Font = .title.bold(),
        heading3Font: Font = .title2.bold(),
        heading4Font: Font = .title3.bold(),
        heading5Font: Font = .headline,
        heading6Font: Font = .subheadline.bold(),
        codeFont: Font = .system(.body, design: .monospaced),
        codeBlockFont: Font = .system(.callout, design: .monospaced),
        textColor: Color = .primary,
        secondaryTextColor: Color = .secondary,
        linkColor: Color = .accentColor,
        codeBackgroundColor: Color = Color(white: 0.95),
        blockQuoteBorderColor: Color = Color(white: 0.75),
        tableBorderColor: Color = Color(white: 0.80),
        tableHeaderBackgroundColor: Color = Color(white: 0.90),
        paragraphSpacing: CGFloat = 12,
        listItemSpacing: CGFloat = 4,
        indentation: CGFloat = 20,
        codeBlockPadding: CGFloat = 12
    ) {
        self.bodyFont = bodyFont
        self.heading1Font = heading1Font
        self.heading2Font = heading2Font
        self.heading3Font = heading3Font
        self.heading4Font = heading4Font
        self.heading5Font = heading5Font
        self.heading6Font = heading6Font
        self.codeFont = codeFont
        self.codeBlockFont = codeBlockFont
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.linkColor = linkColor
        self.codeBackgroundColor = codeBackgroundColor
        self.blockQuoteBorderColor = blockQuoteBorderColor
        self.tableBorderColor = tableBorderColor
        self.tableHeaderBackgroundColor = tableHeaderBackgroundColor
        self.paragraphSpacing = paragraphSpacing
        self.listItemSpacing = listItemSpacing
        self.indentation = indentation
        self.codeBlockPadding = codeBlockPadding
    }

    /// Returns the font for the specified heading level.
    public func headingFont(level: Int) -> Font {
        switch level {
        case 1: return heading1Font
        case 2: return heading2Font
        case 3: return heading3Font
        case 4: return heading4Font
        case 5: return heading5Font
        case 6: return heading6Font
        default: return heading6Font
        }
    }
}

// MARK: - Built-in Themes

public extension MarkdownTheme {

    /// The default theme that adapts to system appearance.
    ///
    /// Uses system semantic fonts (`Font.body`, `Font.title`, etc.) and colors
    /// (`Color.primary`, `Color.accentColor`) that automatically adapt to
    /// light/dark mode and accessibility settings.
    static let `default` = MarkdownTheme()

    /// A GitHub-style theme with fixed font sizes.
    ///
    /// Mimics GitHub's Markdown rendering with specific pixel-based font sizes
    /// and GitHub's signature blue link color. Best for content that should
    /// match GitHub's visual style.
    static let gitHub = MarkdownTheme(
        bodyFont: .system(size: 16),
        heading1Font: .system(size: 32, weight: .bold),
        heading2Font: .system(size: 24, weight: .bold),
        heading3Font: .system(size: 20, weight: .bold),
        heading4Font: .system(size: 16, weight: .bold),
        heading5Font: .system(size: 14, weight: .bold),
        heading6Font: .system(size: 13, weight: .bold),
        codeFont: .system(size: 14, design: .monospaced),
        codeBlockFont: .system(size: 13, design: .monospaced),
        linkColor: Color(red: 0.0, green: 0.4, blue: 0.8),
        codeBackgroundColor: Color(red: 0.96, green: 0.97, blue: 0.98),
        paragraphSpacing: 16,
        listItemSpacing: 4,
        indentation: 24,
        codeBlockPadding: 16
    )

    /// A compact theme optimized for smaller displays or dense content.
    ///
    /// Uses smaller fonts and reduced spacing to fit more content in limited space.
    /// Ideal for sidebars, tooltips, or mobile interfaces where space is at a premium.
    static let compact = MarkdownTheme(
        bodyFont: .callout,
        heading1Font: .title2.bold(),
        heading2Font: .title3.bold(),
        heading3Font: .headline,
        heading4Font: .subheadline.bold(),
        heading5Font: .footnote.bold(),
        heading6Font: .caption.bold(),
        codeFont: .system(.caption, design: .monospaced),
        codeBlockFont: .system(.caption2, design: .monospaced),
        paragraphSpacing: 8,
        listItemSpacing: 2,
        indentation: 16,
        codeBlockPadding: 8
    )
}

// MARK: - Environment Key

private struct MarkdownThemeKey: EnvironmentKey {
    static let defaultValue = MarkdownTheme.default
}

public extension EnvironmentValues {
    /// The current Markdown theme used by ``MarkdownView`` instances.
    ///
    /// Set this value using the ``SwiftUI/View/markdownTheme(_:)`` modifier:
    ///
    /// ```swift
    /// MarkdownView(content)
    ///     .markdownTheme(.gitHub)
    /// ```
    ///
    /// The theme propagates through the view hierarchy, so you can set it
    /// at a parent level to affect all nested Markdown views.
    var markdownTheme: MarkdownTheme {
        get { self[MarkdownThemeKey.self] }
        set { self[MarkdownThemeKey.self] = newValue }
    }
}
