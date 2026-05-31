// CodableTheme.swift
// MarkdownExtendedView
//
// Copyright 2025 Christian C. Berclaz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

// MARK: - CodableSyntaxColors

/// A Codable mirror of ``SyntaxColors`` using ``ThemeColor`` instead of raw `Color`.
///
/// Provides a stable JSON representation of a syntax-highlighting color palette.
/// Convert to a runtime `SyntaxColors` value via ``syntaxColors``.
public struct CodableSyntaxColors: Codable, Sendable, Equatable {

    public var keyword:  ThemeColor
    public var string:   ThemeColor
    public var comment:  ThemeColor
    public var number:   ThemeColor
    public var type:     ThemeColor
    public var function: ThemeColor
    public var plain:    ThemeColor

    public init(
        keyword:  ThemeColor = .semantic(.primary),
        string:   ThemeColor = .semantic(.primary),
        comment:  ThemeColor = .semantic(.secondary),
        number:   ThemeColor = .semantic(.primary),
        type:     ThemeColor = .semantic(.primary),
        function: ThemeColor = .semantic(.primary),
        plain:    ThemeColor = .semantic(.primary)
    ) {
        self.keyword  = keyword
        self.string   = string
        self.comment  = comment
        self.number   = number
        self.type     = type
        self.function = function
        self.plain    = plain
    }

    /// Resolves this DTO to a runtime ``SyntaxColors``.
    public var syntaxColors: SyntaxColors {
        SyntaxColors(
            keyword:  keyword.color,
            string:   string.color,
            comment:  comment.color,
            number:   number.color,
            type:     type.color,
            function: function.color,
            plain:    plain.color
        )
    }
}

// MARK: - CodableTokenStyle

/// A Codable mirror of ``TokenStyle``.
///
/// Unlike the runtime `TokenStyle`, the optional color here is a ``ThemeColor``
/// so it can be losslessly encoded and decoded.
public struct CodableTokenStyle: Codable, Sendable, Equatable {

    /// The token color, or `nil` to inherit the surrounding code color.
    public var color: ThemeColor?
    /// Whether the token is bold.
    public var isBold: Bool
    /// Whether the token is italic.
    public var isItalic: Bool
    /// Whether the token is underlined.
    public var isUnderlined: Bool

    public init(
        color: ThemeColor? = nil,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false
    ) {
        self.color        = color
        self.isBold       = isBold
        self.isItalic     = isItalic
        self.isUnderlined = isUnderlined
    }

    /// Resolves this DTO to a runtime ``TokenStyle``.
    public var tokenStyle: TokenStyle {
        TokenStyle(color: color?.color, isBold: isBold, isItalic: isItalic, isUnderlined: isUnderlined)
    }
}

// MARK: - CodableTokenStyles

/// A Codable mirror of ``TokenStyles``.
///
/// Contains a ``CodableTokenStyle`` for every token type. Convert to a runtime
/// ``TokenStyles`` via ``tokenStyles``.
public struct CodableTokenStyles: Codable, Sendable, Equatable {

    public var keyword:  CodableTokenStyle
    public var string:   CodableTokenStyle
    public var comment:  CodableTokenStyle
    public var number:   CodableTokenStyle
    public var type:     CodableTokenStyle
    public var function: CodableTokenStyle
    public var plain:    CodableTokenStyle

    public init(
        keyword:  CodableTokenStyle = .init(),
        string:   CodableTokenStyle = .init(),
        comment:  CodableTokenStyle = .init(),
        number:   CodableTokenStyle = .init(),
        type:     CodableTokenStyle = .init(),
        function: CodableTokenStyle = .init(),
        plain:    CodableTokenStyle = .init()
    ) {
        self.keyword  = keyword
        self.string   = string
        self.comment  = comment
        self.number   = number
        self.type     = type
        self.function = function
        self.plain    = plain
    }

    /// Resolves this DTO to a runtime ``TokenStyles``.
    public var tokenStyles: TokenStyles {
        TokenStyles(
            keyword:  keyword.tokenStyle,
            string:   string.tokenStyle,
            comment:  comment.tokenStyle,
            number:   number.tokenStyle,
            type:     type.tokenStyle,
            function: function.tokenStyle,
            plain:    plain.tokenStyle
        )
    }
}

// MARK: - CodableMarkdownTheme

/// A fully Codable description of a ``MarkdownTheme``.
///
/// `CodableMarkdownTheme` mirrors every themeable slot of `MarkdownTheme`,
/// replacing opaque `Color` and `Font` values with their serializable
/// counterparts (``ThemeColor`` and ``FontDescriptor``).
///
/// ## One-way limitation
///
/// You can convert a `CodableMarkdownTheme` *to* a runtime `MarkdownTheme`
/// via ``.theme``, but the reverse is **not** possible: `Color` and `Font`
/// are opaque types whose internals cannot be read back. You must build the
/// DTO from known ``ThemeColor`` and ``FontDescriptor`` values — typically
/// when authoring a theme as JSON or constructing it programmatically.
///
/// ## JSON round-trip
///
/// ```swift
/// let encoder = JSONEncoder()
/// encoder.outputFormatting = .prettyPrinted
/// let data = try encoder.encode(myTheme)
/// let decoded = try JSONDecoder().decode(CodableMarkdownTheme.self, from: data)
/// let theme: MarkdownTheme = decoded.theme
/// ```
public struct CodableMarkdownTheme: Codable, Sendable, Equatable {

    // MARK: Typography

    /// Font for body text.
    public var bodyFont: FontDescriptor
    /// Font for H1 headings.
    public var heading1Font: FontDescriptor
    /// Font for H2 headings.
    public var heading2Font: FontDescriptor
    /// Font for H3 headings.
    public var heading3Font: FontDescriptor
    /// Font for H4 headings.
    public var heading4Font: FontDescriptor
    /// Font for H5 headings.
    public var heading5Font: FontDescriptor
    /// Font for H6 headings.
    public var heading6Font: FontDescriptor
    /// Font for inline code.
    public var codeFont: FontDescriptor
    /// Font for code blocks.
    public var codeBlockFont: FontDescriptor

    // MARK: Colors

    /// Primary text color.
    public var textColor: ThemeColor
    /// Secondary text color.
    public var secondaryTextColor: ThemeColor
    /// Link color.
    public var linkColor: ThemeColor
    /// Code background color.
    public var codeBackgroundColor: ThemeColor
    /// Block quote border color.
    public var blockQuoteBorderColor: ThemeColor
    /// Table border color.
    public var tableBorderColor: ThemeColor
    /// Table header background color.
    public var tableHeaderBackgroundColor: ThemeColor

    // MARK: Syntax / Token Styles

    /// Syntax highlighting colors.
    public var syntaxColors: CodableSyntaxColors
    /// Optional per-token font-trait styling.
    public var tokenStyles: CodableTokenStyles?

    // MARK: Additional Themeable Elements

    /// Strikethrough color, or `nil` to inherit ``textColor``.
    public var strikethroughColor: ThemeColor?
    /// Thematic break (horizontal rule) color.
    public var thematicBreakColor: ThemeColor
    /// Tint for checked task-list checkboxes.
    public var taskCheckboxColor: ThemeColor
    /// Background for `<mark>` highlighted text.
    public var highlightColor: ThemeColor
    /// Whether links are underlined.
    public var linkUnderline: Bool
    /// Padding inside table cells.
    public var tableCellPadding: CGFloat

    // MARK: Spacing

    /// Spacing between paragraphs.
    public var paragraphSpacing: CGFloat
    /// Spacing between list items.
    public var listItemSpacing: CGFloat
    /// Indentation for nested content.
    public var indentation: CGFloat
    /// Padding inside code blocks.
    public var codeBlockPadding: CGFloat

    // MARK: Init

    // swiftlint:disable function_body_length
    public init(
        bodyFont: FontDescriptor = .relative(.body),
        heading1Font: FontDescriptor = .relative(.largeTitle, weight: .bold),
        heading2Font: FontDescriptor = .relative(.title, weight: .bold),
        heading3Font: FontDescriptor = .relative(.title2, weight: .bold),
        heading4Font: FontDescriptor = .relative(.title3, weight: .bold),
        heading5Font: FontDescriptor = .relative(.headline),
        heading6Font: FontDescriptor = .relative(.subheadline, weight: .bold),
        codeFont: FontDescriptor = .relative(.body, design: .monospaced),
        codeBlockFont: FontDescriptor = .relative(.callout, design: .monospaced),
        textColor: ThemeColor = .semantic(.primary),
        secondaryTextColor: ThemeColor = .semantic(.secondary),
        linkColor: ThemeColor = .semantic(.accent),
        codeBackgroundColor: ThemeColor = .adaptive(
            light: .rgba(red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
            dark:  .rgba(red: 0.16, green: 0.16, blue: 0.16, alpha: 1)
        ),
        blockQuoteBorderColor: ThemeColor = .adaptive(
            light: .rgba(red: 0.75, green: 0.75, blue: 0.75, alpha: 1),
            dark:  .rgba(red: 0.40, green: 0.40, blue: 0.40, alpha: 1)
        ),
        tableBorderColor: ThemeColor = .adaptive(
            light: .rgba(red: 0.80, green: 0.80, blue: 0.80, alpha: 1),
            dark:  .rgba(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
        ),
        tableHeaderBackgroundColor: ThemeColor = .adaptive(
            light: .rgba(red: 0.90, green: 0.90, blue: 0.90, alpha: 1),
            dark:  .rgba(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        ),
        syntaxColors: CodableSyntaxColors = CodableSyntaxColors(),
        tokenStyles: CodableTokenStyles? = nil,
        strikethroughColor: ThemeColor? = nil,
        thematicBreakColor: ThemeColor = .adaptive(
            light: .rgba(red: 0.80, green: 0.80, blue: 0.80, alpha: 1),
            dark:  .rgba(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
        ),
        taskCheckboxColor: ThemeColor = .semantic(.accent),
        highlightColor: ThemeColor = .rgba(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.35),
        linkUnderline: Bool = true,
        tableCellPadding: CGFloat = 8,
        paragraphSpacing: CGFloat = 12,
        listItemSpacing: CGFloat = 4,
        indentation: CGFloat = 20,
        codeBlockPadding: CGFloat = 12
    ) {
        self.bodyFont                   = bodyFont
        self.heading1Font               = heading1Font
        self.heading2Font               = heading2Font
        self.heading3Font               = heading3Font
        self.heading4Font               = heading4Font
        self.heading5Font               = heading5Font
        self.heading6Font               = heading6Font
        self.codeFont                   = codeFont
        self.codeBlockFont              = codeBlockFont
        self.textColor                  = textColor
        self.secondaryTextColor         = secondaryTextColor
        self.linkColor                  = linkColor
        self.codeBackgroundColor        = codeBackgroundColor
        self.blockQuoteBorderColor      = blockQuoteBorderColor
        self.tableBorderColor           = tableBorderColor
        self.tableHeaderBackgroundColor = tableHeaderBackgroundColor
        self.syntaxColors               = syntaxColors
        self.tokenStyles                = tokenStyles
        self.strikethroughColor         = strikethroughColor
        self.thematicBreakColor         = thematicBreakColor
        self.taskCheckboxColor          = taskCheckboxColor
        self.highlightColor             = highlightColor
        self.linkUnderline              = linkUnderline
        self.tableCellPadding           = tableCellPadding
        self.paragraphSpacing           = paragraphSpacing
        self.listItemSpacing            = listItemSpacing
        self.indentation                = indentation
        self.codeBlockPadding           = codeBlockPadding
    }
    // swiftlint:enable function_body_length

    // MARK: Runtime conversion

    /// Converts this DTO to a runtime ``MarkdownTheme``.
    ///
    /// All ``ThemeColor`` values are resolved to SwiftUI `Color` and all
    /// ``FontDescriptor`` values are resolved to SwiftUI `Font`.
    public var theme: MarkdownTheme {
        MarkdownTheme(
            bodyFont:                   bodyFont.font,
            heading1Font:               heading1Font.font,
            heading2Font:               heading2Font.font,
            heading3Font:               heading3Font.font,
            heading4Font:               heading4Font.font,
            heading5Font:               heading5Font.font,
            heading6Font:               heading6Font.font,
            codeFont:                   codeFont.font,
            codeBlockFont:              codeBlockFont.font,
            textColor:                  textColor.color,
            secondaryTextColor:         secondaryTextColor.color,
            linkColor:                  linkColor.color,
            codeBackgroundColor:        codeBackgroundColor.color,
            blockQuoteBorderColor:      blockQuoteBorderColor.color,
            tableBorderColor:           tableBorderColor.color,
            tableHeaderBackgroundColor: tableHeaderBackgroundColor.color,
            syntaxColors:               syntaxColors.syntaxColors,
            tokenStyles:                tokenStyles?.tokenStyles,
            strikethroughColor:         strikethroughColor?.color,
            thematicBreakColor:         thematicBreakColor.color,
            taskCheckboxColor:          taskCheckboxColor.color,
            highlightColor:             highlightColor.color,
            linkUnderline:              linkUnderline,
            tableCellPadding:           tableCellPadding,
            paragraphSpacing:           paragraphSpacing,
            listItemSpacing:            listItemSpacing,
            indentation:                indentation,
            codeBlockPadding:           codeBlockPadding
        )
    }
}
