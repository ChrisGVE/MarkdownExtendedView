// ThemeGallery.swift
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

// MARK: - Theme Gallery
//
// A curated set of ready-to-use themes. Two families:
//
// 1. Monochrome / typographic — convey syntax through bold / italic / underline
//    (via TokenStyles) instead of color, for distraction-free reading.
// 2. Named palettes — popular editor colour schemes. Each palette centralises
//    its canonical hex values in a `Palette` enum (role -> hex), so the values
//    are a single source of truth and can later be extracted to the planned
//    ThemeKit package. Hex values are taken from each palette's published spec.
//
// All bundled palettes here are released under permissive licences:
//   Solarized (MIT, Ethan Schoonover), Dracula (MIT), Nord (MIT).

public extension MarkdownTheme {

    // MARK: Monochrome / Typographic

    /// Builds a monochrome theme where syntax is conveyed by font traits only.
    ///
    /// - Parameters:
    ///   - foreground: The single text/code colour.
    ///   - codeBackground: The code-block background.
    static func monochrome(foreground: Color, codeBackground: Color) -> MarkdownTheme {
        let tokenStyles = TokenStyles(
            keyword: TokenStyle(color: foreground, isBold: true),
            string: TokenStyle(color: foreground, isItalic: true),
            comment: TokenStyle(color: foreground, isItalic: true),
            number: TokenStyle(color: foreground),
            type: TokenStyle(color: foreground, isBold: true),
            function: TokenStyle(color: foreground, isUnderlined: true),
            plain: TokenStyle(color: foreground)
        )
        return MarkdownTheme(
            textColor: foreground,
            secondaryTextColor: foreground.opacity(0.6),
            linkColor: foreground,
            codeBackgroundColor: codeBackground,
            blockQuoteBorderColor: foreground.opacity(0.4),
            tableBorderColor: foreground.opacity(0.4),
            tableHeaderBackgroundColor: foreground.opacity(0.08),
            syntaxColors: SyntaxColors(
                keyword: foreground, string: foreground, comment: foreground,
                number: foreground, type: foreground, function: foreground, plain: foreground
            ),
            tokenStyles: tokenStyles,
            thematicBreakColor: foreground.opacity(0.4),
            taskCheckboxColor: foreground,
            linkUnderline: true
        )
    }

    /// Accent-on-monochrome: text is `foreground`, but keywords/types/functions
    /// pick up an accent colour while still using traits.
    static func accent(_ accent: Color, foreground: Color, codeBackground: Color) -> MarkdownTheme {
        let tokenStyles = TokenStyles(
            keyword: TokenStyle(color: accent, isBold: true),
            string: TokenStyle(color: foreground, isItalic: true),
            comment: TokenStyle(color: foreground.opacity(0.6), isItalic: true),
            number: TokenStyle(color: accent),
            type: TokenStyle(color: accent, isBold: true),
            function: TokenStyle(color: accent),
            plain: TokenStyle(color: foreground)
        )
        return MarkdownTheme(
            textColor: foreground,
            secondaryTextColor: foreground.opacity(0.6),
            linkColor: accent,
            codeBackgroundColor: codeBackground,
            blockQuoteBorderColor: accent,
            tableBorderColor: foreground.opacity(0.4),
            tableHeaderBackgroundColor: accent.opacity(0.12),
            syntaxColors: SyntaxColors(
                keyword: accent, string: foreground, comment: foreground.opacity(0.6),
                number: accent, type: accent, function: accent, plain: foreground
            ),
            tokenStyles: tokenStyles,
            thematicBreakColor: foreground.opacity(0.4),
            taskCheckboxColor: accent
        )
    }

    /// Black text on a light surface, syntax by traits only.
    static let blackOnWhite = MarkdownTheme.monochrome(
        foreground: Color(hex: "#1a1a1a"),
        codeBackground: Color(hex: "#f2f2f2")
    )

    /// White text on a dark surface, syntax by traits only.
    static let whiteOnBlack = MarkdownTheme.monochrome(
        foreground: Color(hex: "#f2f2f2"),
        codeBackground: Color(hex: "#1a1a1a")
    )

    // MARK: Solarized (MIT — Ethan Schoonover)

    private enum Solarized {
        static let base03 = "#002b36"
        static let base02 = "#073642"
        static let base01 = "#586e75"
        static let base00 = "#657b83"
        static let base0 = "#839496"
        static let base1 = "#93a1a1"
        static let base2 = "#eee8d5"
        static let base3 = "#fdf6e3"
        static let yellow = "#b58900"
        static let orange = "#cb4b16"
        static let red = "#dc322f"
        static let magenta = "#d33682"
        static let violet = "#6c71c4"
        static let blue = "#268bd2"
        static let cyan = "#2aa198"
        static let green = "#859900"
    }

    private static func solarizedSyntax() -> SyntaxColors {
        SyntaxColors(
            keyword: Color(hex: Solarized.green),
            string: Color(hex: Solarized.cyan),
            comment: Color(hex: Solarized.base01),
            number: Color(hex: Solarized.magenta),
            type: Color(hex: Solarized.yellow),
            function: Color(hex: Solarized.blue),
            plain: Color(hex: Solarized.base00)
        )
    }

    /// Solarized Light.
    static let solarizedLight = MarkdownTheme(
        textColor: Color(hex: Solarized.base00),
        secondaryTextColor: Color(hex: Solarized.base1),
        linkColor: Color(hex: Solarized.blue),
        codeBackgroundColor: Color(hex: Solarized.base2),
        blockQuoteBorderColor: Color(hex: Solarized.base1),
        tableBorderColor: Color(hex: Solarized.base1),
        tableHeaderBackgroundColor: Color(hex: Solarized.base2),
        syntaxColors: solarizedSyntax(),
        thematicBreakColor: Color(hex: Solarized.base1),
        taskCheckboxColor: Color(hex: Solarized.blue)
    )

    /// Solarized Dark.
    static let solarizedDark = MarkdownTheme(
        textColor: Color(hex: Solarized.base0),
        secondaryTextColor: Color(hex: Solarized.base01),
        linkColor: Color(hex: Solarized.blue),
        codeBackgroundColor: Color(hex: Solarized.base02),
        blockQuoteBorderColor: Color(hex: Solarized.base01),
        tableBorderColor: Color(hex: Solarized.base01),
        tableHeaderBackgroundColor: Color(hex: Solarized.base02),
        syntaxColors: solarizedSyntax(),
        thematicBreakColor: Color(hex: Solarized.base01),
        taskCheckboxColor: Color(hex: Solarized.blue)
    )

    // MARK: Dracula (MIT)

    private enum Dracula {
        static let background = "#282a36"
        static let currentLine = "#44475a"
        static let foreground = "#f8f8f2"
        static let comment = "#6272a4"
        static let cyan = "#8be9fd"
        static let green = "#50fa7b"
        static let orange = "#ffb86c"
        static let pink = "#ff79c6"
        static let purple = "#bd93f9"
        static let red = "#ff5555"
        static let yellow = "#f1fa8c"
    }

    /// Dracula.
    static let dracula = MarkdownTheme(
        textColor: Color(hex: Dracula.foreground),
        secondaryTextColor: Color(hex: Dracula.comment),
        linkColor: Color(hex: Dracula.cyan),
        codeBackgroundColor: Color(hex: Dracula.currentLine),
        blockQuoteBorderColor: Color(hex: Dracula.purple),
        tableBorderColor: Color(hex: Dracula.comment),
        tableHeaderBackgroundColor: Color(hex: Dracula.currentLine),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: Dracula.pink),
            string: Color(hex: Dracula.yellow),
            comment: Color(hex: Dracula.comment),
            number: Color(hex: Dracula.purple),
            type: Color(hex: Dracula.cyan),
            function: Color(hex: Dracula.green),
            plain: Color(hex: Dracula.foreground)
        ),
        thematicBreakColor: Color(hex: Dracula.comment),
        taskCheckboxColor: Color(hex: Dracula.green)
    )

    // MARK: Nord (MIT)

    private enum Nord {
        static let nord0 = "#2e3440"
        static let nord1 = "#3b4252"
        static let nord3 = "#4c566a"
        static let nord4 = "#d8dee9"
        static let nord6 = "#eceff4"
        static let nord7 = "#8fbcbb"
        static let nord8 = "#88c0d0"
        static let nord9 = "#81a1c1"
        static let nord10 = "#5e81ac"
        static let nord11 = "#bf616a"
        static let nord13 = "#ebcb8b"
        static let nord14 = "#a3be8c"
        static let nord15 = "#b48ead"
    }

    /// Nord.
    static let nord = MarkdownTheme(
        textColor: Color(hex: Nord.nord4),
        secondaryTextColor: Color(hex: Nord.nord3),
        linkColor: Color(hex: Nord.nord8),
        codeBackgroundColor: Color(hex: Nord.nord1),
        blockQuoteBorderColor: Color(hex: Nord.nord10),
        tableBorderColor: Color(hex: Nord.nord3),
        tableHeaderBackgroundColor: Color(hex: Nord.nord1),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: Nord.nord9),
            string: Color(hex: Nord.nord14),
            comment: Color(hex: Nord.nord3),
            number: Color(hex: Nord.nord15),
            type: Color(hex: Nord.nord7),
            function: Color(hex: Nord.nord8),
            plain: Color(hex: Nord.nord4)
        ),
        thematicBreakColor: Color(hex: Nord.nord3),
        taskCheckboxColor: Color(hex: Nord.nord14)
    )
}
