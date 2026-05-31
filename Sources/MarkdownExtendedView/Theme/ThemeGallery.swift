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
//   Solarized (MIT, Ethan Schoonover), Dracula (MIT), Nord (MIT),
//   Catppuccin (MIT), Gruvbox (MIT, morhetz), Tokyo Night (MIT, enkia),
//   One Dark / One Light (MIT, Atom), Ayu (MIT, dempfi),
//   Rosé Pine (MIT), Night Owl (MIT, sdras), GitHub Dark (MIT, Primer).
//
// Monokai: the original scheme (Wimer Hazenberg) carries no open-source
// licence; Monokai Pro is commercial. Both are excluded.

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

    // MARK: Catppuccin (MIT — catppuccin/catppuccin)
    //
    // Four flavours: Latte (light), Frappé, Macchiato, Mocha (darkest).
    // Canonical palette: https://github.com/catppuccin/catppuccin#-palette

    private enum CatppuccinLatte {
        static let base = "#eff1f5"
        static let mantle = "#e6e9ef"
        static let crust = "#dce0e8"
        static let text = "#4c4f69"
        static let subtext1 = "#5c5f77"
        static let subtext0 = "#6c6f85"
        static let overlay0 = "#9ca0b0"
        static let blue = "#1e66f5"
        static let lavender = "#7287fd"
        static let sapphire = "#209fb5"
        static let sky = "#04a5e5"
        static let teal = "#179299"
        static let green = "#40a02b"
        static let yellow = "#df8e1d"
        static let peach = "#fe640b"
        static let maroon = "#e64553"
        static let red = "#d20f39"
        static let mauve = "#8839ef"
        static let pink = "#ea76cb"
        static let flamingo = "#dd7878"
        static let rosewater = "#dc8a78"
    }

    private enum CatppuccinFrappe {
        static let base = "#303446"
        static let mantle = "#292c3c"
        static let crust = "#232634"
        static let text = "#c6d0f5"
        static let subtext1 = "#b5bfe2"
        static let subtext0 = "#a5adce"
        static let overlay0 = "#737994"
        static let blue = "#8caaee"
        static let lavender = "#babbf1"
        static let sapphire = "#85c1dc"
        static let sky = "#99d1db"
        static let teal = "#81c8be"
        static let green = "#a6d189"
        static let yellow = "#e5c890"
        static let peach = "#ef9f76"
        static let maroon = "#ea999c"
        static let red = "#e78284"
        static let mauve = "#ca9ee6"
        static let pink = "#f4b8e4"
        static let flamingo = "#eebebe"
        static let rosewater = "#f2d5cf"
    }

    private enum CatppuccinMacchiato {
        static let base = "#24273a"
        static let mantle = "#1e2030"
        static let crust = "#181926"
        static let text = "#cad3f5"
        static let subtext1 = "#b8c0e0"
        static let subtext0 = "#a5adcb"
        static let overlay0 = "#6e738d"
        static let blue = "#8aadf4"
        static let lavender = "#b7bdf8"
        static let sapphire = "#7dc4e4"
        static let sky = "#91d7e3"
        static let teal = "#8bd5ca"
        static let green = "#a6da95"
        static let yellow = "#eed49f"
        static let peach = "#f5a97f"
        static let maroon = "#ee99a0"
        static let red = "#ed8796"
        static let mauve = "#c6a0f6"
        static let pink = "#f5bde6"
        static let flamingo = "#f0c6c6"
        static let rosewater = "#f4dbd6"
    }

    private enum CatppuccinMocha {
        static let base = "#1e1e2e"
        static let mantle = "#181825"
        static let crust = "#11111b"
        static let text = "#cdd6f4"
        static let subtext1 = "#bac2de"
        static let subtext0 = "#a6adc8"
        static let overlay0 = "#6c7086"
        static let blue = "#89b4fa"
        static let lavender = "#b4befe"
        static let sapphire = "#74c7ec"
        static let sky = "#89dceb"
        static let teal = "#94e2d5"
        static let green = "#a6e3a1"
        static let yellow = "#f9e2af"
        static let peach = "#fab387"
        static let maroon = "#eba0ac"
        static let red = "#f38ba8"
        static let mauve = "#cba6f7"
        static let pink = "#f5c2e7"
        static let flamingo = "#f2cdcd"
        static let rosewater = "#f5e0dc"
    }

    /// Catppuccin Latte (light flavour).
    static let catppuccinLatte = MarkdownTheme(
        textColor: Color(hex: CatppuccinLatte.text),
        secondaryTextColor: Color(hex: CatppuccinLatte.subtext0),
        linkColor: Color(hex: CatppuccinLatte.blue),
        codeBackgroundColor: Color(hex: CatppuccinLatte.mantle),
        blockQuoteBorderColor: Color(hex: CatppuccinLatte.lavender),
        tableBorderColor: Color(hex: CatppuccinLatte.overlay0),
        tableHeaderBackgroundColor: Color(hex: CatppuccinLatte.crust),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: CatppuccinLatte.mauve),
            string: Color(hex: CatppuccinLatte.green),
            comment: Color(hex: CatppuccinLatte.overlay0),
            number: Color(hex: CatppuccinLatte.peach),
            type: Color(hex: CatppuccinLatte.yellow),
            function: Color(hex: CatppuccinLatte.blue),
            plain: Color(hex: CatppuccinLatte.text)
        ),
        thematicBreakColor: Color(hex: CatppuccinLatte.overlay0),
        taskCheckboxColor: Color(hex: CatppuccinLatte.green)
    )

    /// Catppuccin Frappé.
    static let catppuccinFrappe = MarkdownTheme(
        textColor: Color(hex: CatppuccinFrappe.text),
        secondaryTextColor: Color(hex: CatppuccinFrappe.subtext0),
        linkColor: Color(hex: CatppuccinFrappe.blue),
        codeBackgroundColor: Color(hex: CatppuccinFrappe.mantle),
        blockQuoteBorderColor: Color(hex: CatppuccinFrappe.lavender),
        tableBorderColor: Color(hex: CatppuccinFrappe.overlay0),
        tableHeaderBackgroundColor: Color(hex: CatppuccinFrappe.crust),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: CatppuccinFrappe.mauve),
            string: Color(hex: CatppuccinFrappe.green),
            comment: Color(hex: CatppuccinFrappe.overlay0),
            number: Color(hex: CatppuccinFrappe.peach),
            type: Color(hex: CatppuccinFrappe.yellow),
            function: Color(hex: CatppuccinFrappe.blue),
            plain: Color(hex: CatppuccinFrappe.text)
        ),
        thematicBreakColor: Color(hex: CatppuccinFrappe.overlay0),
        taskCheckboxColor: Color(hex: CatppuccinFrappe.green)
    )

    /// Catppuccin Macchiato.
    static let catppuccinMacchiato = MarkdownTheme(
        textColor: Color(hex: CatppuccinMacchiato.text),
        secondaryTextColor: Color(hex: CatppuccinMacchiato.subtext0),
        linkColor: Color(hex: CatppuccinMacchiato.blue),
        codeBackgroundColor: Color(hex: CatppuccinMacchiato.mantle),
        blockQuoteBorderColor: Color(hex: CatppuccinMacchiato.lavender),
        tableBorderColor: Color(hex: CatppuccinMacchiato.overlay0),
        tableHeaderBackgroundColor: Color(hex: CatppuccinMacchiato.crust),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: CatppuccinMacchiato.mauve),
            string: Color(hex: CatppuccinMacchiato.green),
            comment: Color(hex: CatppuccinMacchiato.overlay0),
            number: Color(hex: CatppuccinMacchiato.peach),
            type: Color(hex: CatppuccinMacchiato.yellow),
            function: Color(hex: CatppuccinMacchiato.blue),
            plain: Color(hex: CatppuccinMacchiato.text)
        ),
        thematicBreakColor: Color(hex: CatppuccinMacchiato.overlay0),
        taskCheckboxColor: Color(hex: CatppuccinMacchiato.green)
    )

    /// Catppuccin Mocha (darkest flavour).
    static let catppuccinMocha = MarkdownTheme(
        textColor: Color(hex: CatppuccinMocha.text),
        secondaryTextColor: Color(hex: CatppuccinMocha.subtext0),
        linkColor: Color(hex: CatppuccinMocha.blue),
        codeBackgroundColor: Color(hex: CatppuccinMocha.mantle),
        blockQuoteBorderColor: Color(hex: CatppuccinMocha.lavender),
        tableBorderColor: Color(hex: CatppuccinMocha.overlay0),
        tableHeaderBackgroundColor: Color(hex: CatppuccinMocha.crust),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: CatppuccinMocha.mauve),
            string: Color(hex: CatppuccinMocha.green),
            comment: Color(hex: CatppuccinMocha.overlay0),
            number: Color(hex: CatppuccinMocha.peach),
            type: Color(hex: CatppuccinMocha.yellow),
            function: Color(hex: CatppuccinMocha.blue),
            plain: Color(hex: CatppuccinMocha.text)
        ),
        thematicBreakColor: Color(hex: CatppuccinMocha.overlay0),
        taskCheckboxColor: Color(hex: CatppuccinMocha.green)
    )

    // MARK: Gruvbox (MIT — morhetz)
    //
    // Canonical palette: https://github.com/morhetz/gruvbox#palette

    private enum GruvboxDark {
        static let bg0Hard = "#1d2021"
        static let bg0 = "#282828"
        static let bg1 = "#3c3836"
        static let bg2 = "#504945"
        static let bg4 = "#7c6f64"
        static let fg1 = "#ebdbb2"
        static let fg4 = "#a89984"
        static let red = "#fb4934"
        static let green = "#b8bb26"
        static let yellow = "#fabd2f"
        static let blue = "#83a598"
        static let purple = "#d3869b"
        static let aqua = "#8ec07c"
        static let orange = "#fe8019"
        static let gray = "#928374"
    }

    private enum GruvboxLight {
        static let bg0Hard = "#f9f5d7"
        static let bg0 = "#fbf1c7"
        static let bg1 = "#ebdbb2"
        static let bg2 = "#d5c4a1"
        static let bg4 = "#a89984"
        static let fg1 = "#3c3836"
        static let fg4 = "#7c6f64"
        static let red = "#9d0006"
        static let green = "#79740e"
        static let yellow = "#b57614"
        static let blue = "#076678"
        static let purple = "#8f3f71"
        static let aqua = "#427b58"
        static let orange = "#af3a03"
        static let gray = "#928374"
    }

    /// Gruvbox Dark.
    static let gruvboxDark = MarkdownTheme(
        textColor: Color(hex: GruvboxDark.fg1),
        secondaryTextColor: Color(hex: GruvboxDark.fg4),
        linkColor: Color(hex: GruvboxDark.blue),
        codeBackgroundColor: Color(hex: GruvboxDark.bg1),
        blockQuoteBorderColor: Color(hex: GruvboxDark.orange),
        tableBorderColor: Color(hex: GruvboxDark.bg4),
        tableHeaderBackgroundColor: Color(hex: GruvboxDark.bg1),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: GruvboxDark.red),
            string: Color(hex: GruvboxDark.green),
            comment: Color(hex: GruvboxDark.gray),
            number: Color(hex: GruvboxDark.purple),
            type: Color(hex: GruvboxDark.yellow),
            function: Color(hex: GruvboxDark.blue),
            plain: Color(hex: GruvboxDark.fg1)
        ),
        thematicBreakColor: Color(hex: GruvboxDark.bg4),
        taskCheckboxColor: Color(hex: GruvboxDark.green)
    )

    /// Gruvbox Light.
    static let gruvboxLight = MarkdownTheme(
        textColor: Color(hex: GruvboxLight.fg1),
        secondaryTextColor: Color(hex: GruvboxLight.fg4),
        linkColor: Color(hex: GruvboxLight.blue),
        codeBackgroundColor: Color(hex: GruvboxLight.bg1),
        blockQuoteBorderColor: Color(hex: GruvboxLight.orange),
        tableBorderColor: Color(hex: GruvboxLight.bg4),
        tableHeaderBackgroundColor: Color(hex: GruvboxLight.bg1),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: GruvboxLight.red),
            string: Color(hex: GruvboxLight.green),
            comment: Color(hex: GruvboxLight.gray),
            number: Color(hex: GruvboxLight.purple),
            type: Color(hex: GruvboxLight.yellow),
            function: Color(hex: GruvboxLight.blue),
            plain: Color(hex: GruvboxLight.fg1)
        ),
        thematicBreakColor: Color(hex: GruvboxLight.bg4),
        taskCheckboxColor: Color(hex: GruvboxLight.green)
    )

    // MARK: Tokyo Night (MIT — enkia)
    //
    // Canonical values from enkia/tokyo-night-vscode-theme theme JSON files.
    // Four variants: Night, Storm, Day, Moon.

    private enum TokyoNightNight {
        static let bg = "#1a1b26"
        static let bgDark = "#16161e"
        static let bgHighlight = "#2f3549"
        static let fg = "#a9b1d6"
        static let fgDark = "#787c99"
        static let comment = "#565f89"
        static let blue = "#7aa2f7"
        static let cyan = "#7dcfff"
        static let teal = "#73daca"
        static let green = "#9ece6a"
        static let yellow = "#e0af68"
        static let orange = "#ff9e64"
        static let red = "#f7768e"
        static let magenta = "#bb9af7"
        static let purple = "#9d7cd8"
    }

    private enum TokyoNightStorm {
        static let bg = "#24283b"
        static let bgDark = "#1f2335"
        static let bgHighlight = "#364a82"
        static let fg = "#c0caf5"
        static let fgDark = "#737aa2"
        static let comment = "#565f89"
        static let blue = "#7aa2f7"
        static let cyan = "#7dcfff"
        static let teal = "#73daca"
        static let green = "#9ece6a"
        static let yellow = "#e0af68"
        static let orange = "#ff9e64"
        static let red = "#f7768e"
        static let magenta = "#bb9af7"
        static let purple = "#9d7cd8"
    }

    private enum TokyoNightDay {
        static let bg = "#e1e2e7"
        static let bgDark = "#d5d6db"
        static let bgHighlight = "#b6bfe2"
        static let fg = "#3760bf"
        static let fgDark = "#6172b0"
        static let comment = "#848cb5"
        static let blue = "#2e7de9"
        static let cyan = "#007197"
        static let teal = "#007197"
        static let green = "#587539"
        static let yellow = "#8c6c3e"
        static let orange = "#b15c00"
        static let red = "#f52a65"
        static let magenta = "#9854f1"
        static let purple = "#7847bd"
    }

    private enum TokyoNightMoon {
        static let bg = "#222436"
        static let bgDark = "#1e2030"
        static let bgHighlight = "#2f334d"
        static let fg = "#c8d3f5"
        static let fgDark = "#828bb8"
        static let comment = "#636da6"
        static let blue = "#82aaff"
        static let cyan = "#86e1fc"
        static let teal = "#4fd6be"
        static let green = "#c3e88d"
        static let yellow = "#ffc777"
        static let orange = "#ff966c"
        static let red = "#ff757f"
        static let magenta = "#c099ff"
        static let purple = "#fca7ea"
    }

    /// Tokyo Night (Night variant).
    static let tokyoNightNight = MarkdownTheme(
        textColor: Color(hex: TokyoNightNight.fg),
        secondaryTextColor: Color(hex: TokyoNightNight.fgDark),
        linkColor: Color(hex: TokyoNightNight.blue),
        codeBackgroundColor: Color(hex: TokyoNightNight.bgDark),
        blockQuoteBorderColor: Color(hex: TokyoNightNight.teal),
        tableBorderColor: Color(hex: TokyoNightNight.comment),
        tableHeaderBackgroundColor: Color(hex: TokyoNightNight.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: TokyoNightNight.magenta),
            string: Color(hex: TokyoNightNight.green),
            comment: Color(hex: TokyoNightNight.comment),
            number: Color(hex: TokyoNightNight.orange),
            type: Color(hex: TokyoNightNight.cyan),
            function: Color(hex: TokyoNightNight.blue),
            plain: Color(hex: TokyoNightNight.fg)
        ),
        thematicBreakColor: Color(hex: TokyoNightNight.comment),
        taskCheckboxColor: Color(hex: TokyoNightNight.teal)
    )

    /// Tokyo Night Storm (slightly lighter background than Night).
    static let tokyoNightStorm = MarkdownTheme(
        textColor: Color(hex: TokyoNightStorm.fg),
        secondaryTextColor: Color(hex: TokyoNightStorm.fgDark),
        linkColor: Color(hex: TokyoNightStorm.blue),
        codeBackgroundColor: Color(hex: TokyoNightStorm.bgDark),
        blockQuoteBorderColor: Color(hex: TokyoNightStorm.teal),
        tableBorderColor: Color(hex: TokyoNightStorm.comment),
        tableHeaderBackgroundColor: Color(hex: TokyoNightStorm.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: TokyoNightStorm.magenta),
            string: Color(hex: TokyoNightStorm.green),
            comment: Color(hex: TokyoNightStorm.comment),
            number: Color(hex: TokyoNightStorm.orange),
            type: Color(hex: TokyoNightStorm.cyan),
            function: Color(hex: TokyoNightStorm.blue),
            plain: Color(hex: TokyoNightStorm.fg)
        ),
        thematicBreakColor: Color(hex: TokyoNightStorm.comment),
        taskCheckboxColor: Color(hex: TokyoNightStorm.teal)
    )

    /// Tokyo Night Day (light variant).
    static let tokyoNightDay = MarkdownTheme(
        textColor: Color(hex: TokyoNightDay.fg),
        secondaryTextColor: Color(hex: TokyoNightDay.fgDark),
        linkColor: Color(hex: TokyoNightDay.blue),
        codeBackgroundColor: Color(hex: TokyoNightDay.bgDark),
        blockQuoteBorderColor: Color(hex: TokyoNightDay.teal),
        tableBorderColor: Color(hex: TokyoNightDay.comment),
        tableHeaderBackgroundColor: Color(hex: TokyoNightDay.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: TokyoNightDay.magenta),
            string: Color(hex: TokyoNightDay.green),
            comment: Color(hex: TokyoNightDay.comment),
            number: Color(hex: TokyoNightDay.orange),
            type: Color(hex: TokyoNightDay.cyan),
            function: Color(hex: TokyoNightDay.blue),
            plain: Color(hex: TokyoNightDay.fg)
        ),
        thematicBreakColor: Color(hex: TokyoNightDay.comment),
        taskCheckboxColor: Color(hex: TokyoNightDay.teal)
    )

    /// Tokyo Night Moon.
    static let tokyoNightMoon = MarkdownTheme(
        textColor: Color(hex: TokyoNightMoon.fg),
        secondaryTextColor: Color(hex: TokyoNightMoon.fgDark),
        linkColor: Color(hex: TokyoNightMoon.blue),
        codeBackgroundColor: Color(hex: TokyoNightMoon.bgDark),
        blockQuoteBorderColor: Color(hex: TokyoNightMoon.teal),
        tableBorderColor: Color(hex: TokyoNightMoon.comment),
        tableHeaderBackgroundColor: Color(hex: TokyoNightMoon.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: TokyoNightMoon.magenta),
            string: Color(hex: TokyoNightMoon.green),
            comment: Color(hex: TokyoNightMoon.comment),
            number: Color(hex: TokyoNightMoon.orange),
            type: Color(hex: TokyoNightMoon.cyan),
            function: Color(hex: TokyoNightMoon.blue),
            plain: Color(hex: TokyoNightMoon.fg)
        ),
        thematicBreakColor: Color(hex: TokyoNightMoon.comment),
        taskCheckboxColor: Color(hex: TokyoNightMoon.teal)
    )

    // MARK: One Dark / One Light (MIT — Atom/atom-community)
    //
    // Canonical values from atom/one-dark-syntax variables.less
    // and atom/one-light-syntax variables.less.

    private enum OneDark {
        static let bg = "#282c34"
        static let bgLight = "#2c313c"
        static let fg = "#abb2bf"
        static let fgMuted = "#5c6370"
        static let red = "#e06c75"
        static let orange = "#d19a66"
        static let yellow = "#e5c07b"
        static let green = "#98c379"
        static let cyan = "#56b6c2"
        static let blue = "#61afef"
        static let purple = "#c678dd"
        static let white = "#ffffff"
    }

    private enum OneLight {
        static let bg = "#fafafa"
        static let bgLight = "#f0f0f1"
        static let fg = "#383a42"
        static let fgMuted = "#a0a1a7"
        static let red = "#e45649"
        static let orange = "#986801"
        static let yellow = "#c18401"
        static let green = "#50a14f"
        static let cyan = "#0184bc"
        static let blue = "#4078f2"
        static let purple = "#a626a4"
    }

    /// One Dark.
    static let oneDark = MarkdownTheme(
        textColor: Color(hex: OneDark.fg),
        secondaryTextColor: Color(hex: OneDark.fgMuted),
        linkColor: Color(hex: OneDark.blue),
        codeBackgroundColor: Color(hex: OneDark.bgLight),
        blockQuoteBorderColor: Color(hex: OneDark.purple),
        tableBorderColor: Color(hex: OneDark.fgMuted),
        tableHeaderBackgroundColor: Color(hex: OneDark.bgLight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: OneDark.purple),
            string: Color(hex: OneDark.green),
            comment: Color(hex: OneDark.fgMuted),
            number: Color(hex: OneDark.orange),
            type: Color(hex: OneDark.yellow),
            function: Color(hex: OneDark.blue),
            plain: Color(hex: OneDark.fg)
        ),
        thematicBreakColor: Color(hex: OneDark.fgMuted),
        taskCheckboxColor: Color(hex: OneDark.green)
    )

    /// One Light.
    static let oneLight = MarkdownTheme(
        textColor: Color(hex: OneLight.fg),
        secondaryTextColor: Color(hex: OneLight.fgMuted),
        linkColor: Color(hex: OneLight.blue),
        codeBackgroundColor: Color(hex: OneLight.bgLight),
        blockQuoteBorderColor: Color(hex: OneLight.purple),
        tableBorderColor: Color(hex: OneLight.fgMuted),
        tableHeaderBackgroundColor: Color(hex: OneLight.bgLight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: OneLight.purple),
            string: Color(hex: OneLight.green),
            comment: Color(hex: OneLight.fgMuted),
            number: Color(hex: OneLight.orange),
            type: Color(hex: OneLight.yellow),
            function: Color(hex: OneLight.blue),
            plain: Color(hex: OneLight.fg)
        ),
        thematicBreakColor: Color(hex: OneLight.fgMuted),
        taskCheckboxColor: Color(hex: OneLight.green)
    )

    // MARK: Ayu (MIT — dempfi)
    //
    // Canonical values from dempfi/ayu-vim / ayu-colors package.
    // Three variants: Light, Mirage, Dark.

    private enum AyuLight {
        static let bg = "#fafafa"
        static let bgAlt = "#f3f3f3"
        static let fg = "#575f66"
        static let fgMuted = "#abb0b6"
        static let red = "#f07171"
        static let orange = "#fa8d3e"
        static let yellow = "#f2ae49"
        static let green = "#86b300"
        static let teal = "#4cbf99"
        static let blue = "#36a3d9"
        static let indigo = "#a37acc"
        static let pink = "#f07178"
        static let accent = "#ff9940"
    }

    private enum AyuMirage {
        static let bg = "#1f2430"
        static let bgAlt = "#191e2a"
        static let fg = "#cccac2"
        static let fgMuted = "#707a8c"
        static let red = "#f28779"
        static let orange = "#ffa759"
        static let yellow = "#ffd580"
        static let green = "#bae67e"
        static let teal = "#5ccfe6"
        static let blue = "#73d0ff"
        static let indigo = "#d4bfff"
        static let pink = "#f28779"
        static let accent = "#ffcc66"
    }

    private enum AyuDark {
        static let bg = "#0a0e14"
        static let bgAlt = "#0d1017"
        static let fg = "#b3b1ad"
        static let fgMuted = "#3d424d"
        static let red = "#ff3333"
        static let orange = "#ff8f40"
        static let yellow = "#e7c547"
        static let green = "#b8cc52"
        static let teal = "#95e6cb"
        static let blue = "#39bae6"
        static let indigo = "#a2aabc"
        static let pink = "#f07178"
        static let accent = "#e6b450"
    }

    /// Ayu Light.
    static let ayuLight = MarkdownTheme(
        textColor: Color(hex: AyuLight.fg),
        secondaryTextColor: Color(hex: AyuLight.fgMuted),
        linkColor: Color(hex: AyuLight.blue),
        codeBackgroundColor: Color(hex: AyuLight.bgAlt),
        blockQuoteBorderColor: Color(hex: AyuLight.accent),
        tableBorderColor: Color(hex: AyuLight.fgMuted),
        tableHeaderBackgroundColor: Color(hex: AyuLight.bgAlt),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: AyuLight.orange),
            string: Color(hex: AyuLight.green),
            comment: Color(hex: AyuLight.fgMuted),
            number: Color(hex: AyuLight.yellow),
            type: Color(hex: AyuLight.teal),
            function: Color(hex: AyuLight.blue),
            plain: Color(hex: AyuLight.fg)
        ),
        thematicBreakColor: Color(hex: AyuLight.fgMuted),
        taskCheckboxColor: Color(hex: AyuLight.green)
    )

    /// Ayu Mirage.
    static let ayuMirage = MarkdownTheme(
        textColor: Color(hex: AyuMirage.fg),
        secondaryTextColor: Color(hex: AyuMirage.fgMuted),
        linkColor: Color(hex: AyuMirage.blue),
        codeBackgroundColor: Color(hex: AyuMirage.bgAlt),
        blockQuoteBorderColor: Color(hex: AyuMirage.accent),
        tableBorderColor: Color(hex: AyuMirage.fgMuted),
        tableHeaderBackgroundColor: Color(hex: AyuMirage.bgAlt),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: AyuMirage.orange),
            string: Color(hex: AyuMirage.green),
            comment: Color(hex: AyuMirage.fgMuted),
            number: Color(hex: AyuMirage.yellow),
            type: Color(hex: AyuMirage.teal),
            function: Color(hex: AyuMirage.blue),
            plain: Color(hex: AyuMirage.fg)
        ),
        thematicBreakColor: Color(hex: AyuMirage.fgMuted),
        taskCheckboxColor: Color(hex: AyuMirage.green)
    )

    /// Ayu Dark.
    static let ayuDark = MarkdownTheme(
        textColor: Color(hex: AyuDark.fg),
        secondaryTextColor: Color(hex: AyuDark.fgMuted),
        linkColor: Color(hex: AyuDark.blue),
        codeBackgroundColor: Color(hex: AyuDark.bgAlt),
        blockQuoteBorderColor: Color(hex: AyuDark.accent),
        tableBorderColor: Color(hex: AyuDark.fgMuted),
        tableHeaderBackgroundColor: Color(hex: AyuDark.bgAlt),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: AyuDark.orange),
            string: Color(hex: AyuDark.green),
            comment: Color(hex: AyuDark.fgMuted),
            number: Color(hex: AyuDark.yellow),
            type: Color(hex: AyuDark.teal),
            function: Color(hex: AyuDark.blue),
            plain: Color(hex: AyuDark.fg)
        ),
        thematicBreakColor: Color(hex: AyuDark.fgMuted),
        taskCheckboxColor: Color(hex: AyuDark.green)
    )

    // MARK: Rosé Pine (MIT — rose-pine)
    //
    // Canonical palette: https://github.com/rose-pine/rose-pine-theme#-palette
    // Three variants: main (dark), moon, dawn (light).

    private enum RosePineMain {
        static let base = "#191724"
        static let surface = "#1f1d2e"
        static let overlay = "#26233a"
        static let muted = "#6e6a86"
        static let subtle = "#908caa"
        static let text = "#e0def4"
        static let love = "#eb6f92"
        static let gold = "#f6c177"
        static let rose = "#ebbcba"
        static let pine = "#31748f"
        static let foam = "#9ccfd8"
        static let iris = "#c4a7e7"
        static let highlightLow = "#21202e"
        static let highlightMed = "#403d52"
        static let highlightHigh = "#524f67"
    }

    private enum RosePineMoon {
        static let base = "#232136"
        static let surface = "#2a273f"
        static let overlay = "#393552"
        static let muted = "#6e6a86"
        static let subtle = "#908caa"
        static let text = "#e0def4"
        static let love = "#eb6f92"
        static let gold = "#f6c177"
        static let rose = "#ea9a97"
        static let pine = "#3e8fb0"
        static let foam = "#9ccfd8"
        static let iris = "#c4a7e7"
        static let highlightLow = "#2a283e"
        static let highlightMed = "#44415a"
        static let highlightHigh = "#56526e"
    }

    private enum RosePineDawn {
        static let base = "#faf4ed"
        static let surface = "#fffaf3"
        static let overlay = "#f2e9e1"
        static let muted = "#9893a5"
        static let subtle = "#797593"
        static let text = "#575279"
        static let love = "#b4637a"
        static let gold = "#ea9d34"
        static let rose = "#d7827e"
        static let pine = "#286983"
        static let foam = "#56949f"
        static let iris = "#907aa9"
        static let highlightLow = "#f4ede8"
        static let highlightMed = "#dfdad9"
        static let highlightHigh = "#cecacd"
    }

    /// Rosé Pine (dark, main variant).
    static let rosePine = MarkdownTheme(
        textColor: Color(hex: RosePineMain.text),
        secondaryTextColor: Color(hex: RosePineMain.subtle),
        linkColor: Color(hex: RosePineMain.foam),
        codeBackgroundColor: Color(hex: RosePineMain.overlay),
        blockQuoteBorderColor: Color(hex: RosePineMain.pine),
        tableBorderColor: Color(hex: RosePineMain.muted),
        tableHeaderBackgroundColor: Color(hex: RosePineMain.overlay),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: RosePineMain.pine),
            string: Color(hex: RosePineMain.gold),
            comment: Color(hex: RosePineMain.muted),
            number: Color(hex: RosePineMain.rose),
            type: Color(hex: RosePineMain.foam),
            function: Color(hex: RosePineMain.iris),
            plain: Color(hex: RosePineMain.text)
        ),
        thematicBreakColor: Color(hex: RosePineMain.muted),
        taskCheckboxColor: Color(hex: RosePineMain.foam)
    )

    /// Rosé Pine Moon.
    static let rosePineMoon = MarkdownTheme(
        textColor: Color(hex: RosePineMoon.text),
        secondaryTextColor: Color(hex: RosePineMoon.subtle),
        linkColor: Color(hex: RosePineMoon.foam),
        codeBackgroundColor: Color(hex: RosePineMoon.overlay),
        blockQuoteBorderColor: Color(hex: RosePineMoon.pine),
        tableBorderColor: Color(hex: RosePineMoon.muted),
        tableHeaderBackgroundColor: Color(hex: RosePineMoon.overlay),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: RosePineMoon.pine),
            string: Color(hex: RosePineMoon.gold),
            comment: Color(hex: RosePineMoon.muted),
            number: Color(hex: RosePineMoon.rose),
            type: Color(hex: RosePineMoon.foam),
            function: Color(hex: RosePineMoon.iris),
            plain: Color(hex: RosePineMoon.text)
        ),
        thematicBreakColor: Color(hex: RosePineMoon.muted),
        taskCheckboxColor: Color(hex: RosePineMoon.foam)
    )

    /// Rosé Pine Dawn (light variant).
    static let rosePineDawn = MarkdownTheme(
        textColor: Color(hex: RosePineDawn.text),
        secondaryTextColor: Color(hex: RosePineDawn.subtle),
        linkColor: Color(hex: RosePineDawn.foam),
        codeBackgroundColor: Color(hex: RosePineDawn.overlay),
        blockQuoteBorderColor: Color(hex: RosePineDawn.pine),
        tableBorderColor: Color(hex: RosePineDawn.muted),
        tableHeaderBackgroundColor: Color(hex: RosePineDawn.overlay),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: RosePineDawn.pine),
            string: Color(hex: RosePineDawn.gold),
            comment: Color(hex: RosePineDawn.muted),
            number: Color(hex: RosePineDawn.rose),
            type: Color(hex: RosePineDawn.foam),
            function: Color(hex: RosePineDawn.iris),
            plain: Color(hex: RosePineDawn.text)
        ),
        thematicBreakColor: Color(hex: RosePineDawn.muted),
        taskCheckboxColor: Color(hex: RosePineDawn.foam)
    )

    // MARK: Night Owl (MIT — sdras)
    //
    // Canonical values from sdras/night-owl-vscode-theme theme JSON.
    // Two variants: Night Owl (dark) and Light Owl (light).

    private enum NightOwlDark {
        static let bg = "#011627"
        static let bgAlt = "#010e1a"
        static let bgHighlight = "#0d2a4e"
        static let fg = "#d6deeb"
        static let fgAlt = "#7986a8"
        static let comment = "#637777"
        static let red = "#ef5350"
        static let orange = "#f78c6c"
        static let yellow = "#ffcb8b"
        static let green = "#addb67"
        static let teal = "#80cbc4"
        static let cyan = "#7fdbca"
        static let blue = "#82aaff"
        static let purple = "#c792ea"
        static let pink = "#f07178"
    }

    private enum NightOwlLight {
        static let bg = "#fbfbfb"
        static let bgAlt = "#f0f0f0"
        static let bgHighlight = "#e0e0e0"
        static let fg = "#403f53"
        static let fgAlt = "#90a7b2"
        static let comment = "#989fb1"
        static let red = "#d3423e"
        static let orange = "#aa0982"
        static let yellow = "#bc5454"
        static let green = "#4876d6"
        static let teal = "#0c969b"
        static let cyan = "#0c969b"
        static let blue = "#4876d6"
        static let purple = "#994cc3"
        static let pink = "#d3423e"
    }

    /// Night Owl (dark).
    static let nightOwl = MarkdownTheme(
        textColor: Color(hex: NightOwlDark.fg),
        secondaryTextColor: Color(hex: NightOwlDark.fgAlt),
        linkColor: Color(hex: NightOwlDark.blue),
        codeBackgroundColor: Color(hex: NightOwlDark.bgAlt),
        blockQuoteBorderColor: Color(hex: NightOwlDark.teal),
        tableBorderColor: Color(hex: NightOwlDark.comment),
        tableHeaderBackgroundColor: Color(hex: NightOwlDark.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: NightOwlDark.purple),
            string: Color(hex: NightOwlDark.yellow),
            comment: Color(hex: NightOwlDark.comment),
            number: Color(hex: NightOwlDark.orange),
            type: Color(hex: NightOwlDark.cyan),
            function: Color(hex: NightOwlDark.blue),
            plain: Color(hex: NightOwlDark.fg)
        ),
        thematicBreakColor: Color(hex: NightOwlDark.comment),
        taskCheckboxColor: Color(hex: NightOwlDark.green)
    )

    /// Light Owl (light variant of Night Owl).
    static let lightOwl = MarkdownTheme(
        textColor: Color(hex: NightOwlLight.fg),
        secondaryTextColor: Color(hex: NightOwlLight.fgAlt),
        linkColor: Color(hex: NightOwlLight.blue),
        codeBackgroundColor: Color(hex: NightOwlLight.bgAlt),
        blockQuoteBorderColor: Color(hex: NightOwlLight.teal),
        tableBorderColor: Color(hex: NightOwlLight.comment),
        tableHeaderBackgroundColor: Color(hex: NightOwlLight.bgHighlight),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: NightOwlLight.purple),
            string: Color(hex: NightOwlLight.green),
            comment: Color(hex: NightOwlLight.comment),
            number: Color(hex: NightOwlLight.yellow),
            type: Color(hex: NightOwlLight.cyan),
            function: Color(hex: NightOwlLight.blue),
            plain: Color(hex: NightOwlLight.fg)
        ),
        thematicBreakColor: Color(hex: NightOwlLight.comment),
        taskCheckboxColor: Color(hex: NightOwlLight.teal)
    )

    // MARK: GitHub Dark (MIT — Primer)
    //
    // Canonical values from primer/github-vscode-theme.
    // Two variants: GitHub Dark and GitHub Light.

    private enum GitHubDarkPalette {
        static let bg = "#0d1117"
        static let bgSecondary = "#161b22"
        static let bgTertiary = "#21262d"
        static let border = "#30363d"
        static let fg = "#e6edf3"
        static let fgMuted = "#8b949e"
        static let fgSubtle = "#6e7681"
        static let red = "#ff7b72"
        static let orange = "#ffa657"
        static let yellow = "#e3b341"
        static let green = "#3fb950"
        static let teal = "#39d353"
        static let cyan = "#a5d6ff"
        static let blue = "#58a6ff"
        static let purple = "#d2a8ff"
        static let pink = "#f778ba"
    }

    private enum GitHubLightPalette {
        static let bg = "#ffffff"
        static let bgSecondary = "#f6f8fa"
        static let bgTertiary = "#eaeef2"
        static let border = "#d0d7de"
        static let fg = "#1f2328"
        static let fgMuted = "#636c76"
        static let fgSubtle = "#6e7781"
        static let red = "#cf222e"
        static let orange = "#953800"
        static let yellow = "#9a6700"
        static let green = "#1a7f37"
        static let teal = "#1a7f37"
        static let cyan = "#0550ae"
        static let blue = "#0969da"
        static let purple = "#8250df"
        static let pink = "#bf3989"
    }

    /// GitHub Dark.
    static let githubDark = MarkdownTheme(
        textColor: Color(hex: GitHubDarkPalette.fg),
        secondaryTextColor: Color(hex: GitHubDarkPalette.fgMuted),
        linkColor: Color(hex: GitHubDarkPalette.blue),
        codeBackgroundColor: Color(hex: GitHubDarkPalette.bgSecondary),
        blockQuoteBorderColor: Color(hex: GitHubDarkPalette.border),
        tableBorderColor: Color(hex: GitHubDarkPalette.border),
        tableHeaderBackgroundColor: Color(hex: GitHubDarkPalette.bgTertiary),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: GitHubDarkPalette.red),
            string: Color(hex: GitHubDarkPalette.cyan),
            comment: Color(hex: GitHubDarkPalette.fgSubtle),
            number: Color(hex: GitHubDarkPalette.blue),
            type: Color(hex: GitHubDarkPalette.orange),
            function: Color(hex: GitHubDarkPalette.purple),
            plain: Color(hex: GitHubDarkPalette.fg)
        ),
        thematicBreakColor: Color(hex: GitHubDarkPalette.border),
        taskCheckboxColor: Color(hex: GitHubDarkPalette.green)
    )

    /// GitHub Light.
    static let githubLight = MarkdownTheme(
        textColor: Color(hex: GitHubLightPalette.fg),
        secondaryTextColor: Color(hex: GitHubLightPalette.fgMuted),
        linkColor: Color(hex: GitHubLightPalette.blue),
        codeBackgroundColor: Color(hex: GitHubLightPalette.bgSecondary),
        blockQuoteBorderColor: Color(hex: GitHubLightPalette.border),
        tableBorderColor: Color(hex: GitHubLightPalette.border),
        tableHeaderBackgroundColor: Color(hex: GitHubLightPalette.bgTertiary),
        syntaxColors: SyntaxColors(
            keyword: Color(hex: GitHubLightPalette.red),
            string: Color(hex: GitHubLightPalette.cyan),
            comment: Color(hex: GitHubLightPalette.fgSubtle),
            number: Color(hex: GitHubLightPalette.blue),
            type: Color(hex: GitHubLightPalette.orange),
            function: Color(hex: GitHubLightPalette.purple),
            plain: Color(hex: GitHubLightPalette.fg)
        ),
        thematicBreakColor: Color(hex: GitHubLightPalette.border),
        taskCheckboxColor: Color(hex: GitHubLightPalette.green)
    )
}
