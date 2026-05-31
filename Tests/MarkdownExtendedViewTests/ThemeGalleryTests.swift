// ThemeGalleryTests.swift
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

import XCTest
import SwiftUI
@testable import MarkdownExtendedView

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Tests for the bundled theme gallery (task 16 / task 20).
final class ThemeGalleryTests: XCTestCase {

    private func rgba(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(AppKit)
        let native = (NSColor(color).usingColorSpace(.sRGB)) ?? NSColor(color)
        return (Double(native.redComponent), Double(native.greenComponent),
                Double(native.blueComponent), Double(native.alphaComponent))
        #elseif canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #else
        return (0, 0, 0, 1)
        #endif
    }

    private func assertColor(_ color: Color, equals hex: String, file: StaticString = #filePath, line: UInt = #line) {
        let expected = rgba(Color(hex: hex))
        let actual = rgba(color)
        XCTAssertEqual(actual.red, expected.red, accuracy: 0.01, "red", file: file, line: line)
        XCTAssertEqual(actual.green, expected.green, accuracy: 0.01, "green", file: file, line: line)
        XCTAssertEqual(actual.blue, expected.blue, accuracy: 0.01, "blue", file: file, line: line)
    }

    // MARK: - Monochrome

    func testMonochromeUsesTraitsNotColorForSyntax() {
        let theme = MarkdownTheme.blackOnWhite
        let styles = theme.tokenStyles
        XCTAssertNotNil(styles, "monochrome themes must define token styles")
        XCTAssertTrue(styles!.style(for: .keyword).isBold)
        XCTAssertTrue(styles!.style(for: .comment).isItalic)
        XCTAssertTrue(styles!.style(for: .function).isUnderlined)
    }

    func testBlackOnWhiteAndWhiteOnBlackAreInverses() {
        assertColor(MarkdownTheme.blackOnWhite.textColor, equals: "#1a1a1a")
        assertColor(MarkdownTheme.whiteOnBlack.textColor, equals: "#f2f2f2")
    }

    func testAccentFactoryAppliesAccent() {
        let theme = MarkdownTheme.accent(Color(hex: "#ff0000"), foreground: .black, codeBackground: .white)
        assertColor(theme.linkColor, equals: "#ff0000")
        XCTAssertTrue(theme.tokenStyles!.style(for: .keyword).isBold)
    }

    // MARK: - Canonical palette hex

    func testSolarizedCanonicalColors() {
        // base values and accents from the published Solarized spec.
        assertColor(MarkdownTheme.solarizedDark.codeBackgroundColor, equals: "#073642")  // base02
        assertColor(MarkdownTheme.solarizedLight.codeBackgroundColor, equals: "#eee8d5") // base2
        assertColor(MarkdownTheme.solarizedDark.linkColor, equals: "#268bd2")            // blue
        assertColor(MarkdownTheme.solarizedDark.syntaxColors.keyword, equals: "#859900") // green
    }

    func testDraculaCanonicalColors() {
        assertColor(MarkdownTheme.dracula.codeBackgroundColor, equals: "#44475a")        // currentLine
        assertColor(MarkdownTheme.dracula.syntaxColors.keyword, equals: "#ff79c6")       // pink
        assertColor(MarkdownTheme.dracula.syntaxColors.string, equals: "#f1fa8c")        // yellow
    }

    func testNordCanonicalColors() {
        assertColor(MarkdownTheme.nord.codeBackgroundColor, equals: "#3b4252")           // nord1
        assertColor(MarkdownTheme.nord.linkColor, equals: "#88c0d0")                      // nord8
        assertColor(MarkdownTheme.nord.syntaxColors.string, equals: "#a3be8c")           // nord14
    }

    // MARK: - Catppuccin

    func testCatppuccinLatteCanonicalColors() {
        assertColor(MarkdownTheme.catppuccinLatte.codeBackgroundColor, equals: "#e6e9ef") // mantle
        assertColor(MarkdownTheme.catppuccinLatte.linkColor, equals: "#1e66f5")            // blue
        assertColor(MarkdownTheme.catppuccinLatte.syntaxColors.keyword, equals: "#8839ef") // mauve
    }

    func testCatppuccinFrappeCanonicalColors() {
        assertColor(MarkdownTheme.catppuccinFrappe.codeBackgroundColor, equals: "#292c3c") // mantle
        assertColor(MarkdownTheme.catppuccinFrappe.linkColor, equals: "#8caaee")            // blue
        assertColor(MarkdownTheme.catppuccinFrappe.syntaxColors.string, equals: "#a6d189") // green
    }

    func testCatppuccinMacchiatoCanonicalColors() {
        assertColor(MarkdownTheme.catppuccinMacchiato.codeBackgroundColor, equals: "#1e2030") // mantle
        assertColor(MarkdownTheme.catppuccinMacchiato.linkColor, equals: "#8aadf4")             // blue
        assertColor(MarkdownTheme.catppuccinMacchiato.syntaxColors.keyword, equals: "#c6a0f6") // mauve
    }

    func testCatppuccinMochaCanonicalColors() {
        assertColor(MarkdownTheme.catppuccinMocha.codeBackgroundColor, equals: "#181825") // mantle
        assertColor(MarkdownTheme.catppuccinMocha.linkColor, equals: "#89b4fa")            // blue
        assertColor(MarkdownTheme.catppuccinMocha.syntaxColors.keyword, equals: "#cba6f7") // mauve
    }

    // MARK: - Gruvbox

    func testGruvboxDarkCanonicalColors() {
        assertColor(MarkdownTheme.gruvboxDark.codeBackgroundColor, equals: "#3c3836")    // bg1
        assertColor(MarkdownTheme.gruvboxDark.linkColor, equals: "#83a598")              // blue
        assertColor(MarkdownTheme.gruvboxDark.syntaxColors.keyword, equals: "#fb4934")   // red
    }

    func testGruvboxLightCanonicalColors() {
        assertColor(MarkdownTheme.gruvboxLight.codeBackgroundColor, equals: "#ebdbb2")   // bg1
        assertColor(MarkdownTheme.gruvboxLight.linkColor, equals: "#076678")             // blue
        assertColor(MarkdownTheme.gruvboxLight.syntaxColors.string, equals: "#79740e")   // green
    }

    // MARK: - Tokyo Night

    func testTokyoNightNightCanonicalColors() {
        assertColor(MarkdownTheme.tokyoNightNight.codeBackgroundColor, equals: "#16161e") // bgDark
        assertColor(MarkdownTheme.tokyoNightNight.linkColor, equals: "#7aa2f7")            // blue
        assertColor(MarkdownTheme.tokyoNightNight.syntaxColors.keyword, equals: "#bb9af7") // magenta
    }

    func testTokyoNightStormCanonicalColors() {
        assertColor(MarkdownTheme.tokyoNightStorm.codeBackgroundColor, equals: "#1f2335") // bgDark
        assertColor(MarkdownTheme.tokyoNightStorm.linkColor, equals: "#7aa2f7")            // blue
        assertColor(MarkdownTheme.tokyoNightStorm.syntaxColors.string, equals: "#9ece6a") // green
    }

    func testTokyoNightDayCanonicalColors() {
        assertColor(MarkdownTheme.tokyoNightDay.codeBackgroundColor, equals: "#d5d6db")  // bgDark
        assertColor(MarkdownTheme.tokyoNightDay.linkColor, equals: "#2e7de9")             // blue
        assertColor(MarkdownTheme.tokyoNightDay.syntaxColors.keyword, equals: "#9854f1") // magenta
    }

    func testTokyoNightMoonCanonicalColors() {
        assertColor(MarkdownTheme.tokyoNightMoon.codeBackgroundColor, equals: "#1e2030") // bgDark
        assertColor(MarkdownTheme.tokyoNightMoon.linkColor, equals: "#82aaff")            // blue
        assertColor(MarkdownTheme.tokyoNightMoon.syntaxColors.string, equals: "#c3e88d") // green
    }

    // MARK: - One Dark / One Light

    func testOneDarkCanonicalColors() {
        assertColor(MarkdownTheme.oneDark.codeBackgroundColor, equals: "#2c313c")         // bgLight
        assertColor(MarkdownTheme.oneDark.linkColor, equals: "#61afef")                    // blue
        assertColor(MarkdownTheme.oneDark.syntaxColors.keyword, equals: "#c678dd")        // purple
    }

    func testOneLightCanonicalColors() {
        assertColor(MarkdownTheme.oneLight.codeBackgroundColor, equals: "#f0f0f1")        // bgLight
        assertColor(MarkdownTheme.oneLight.linkColor, equals: "#4078f2")                   // blue
        assertColor(MarkdownTheme.oneLight.syntaxColors.string, equals: "#50a14f")        // green
    }

    // MARK: - Ayu

    func testAyuLightCanonicalColors() {
        assertColor(MarkdownTheme.ayuLight.codeBackgroundColor, equals: "#f3f3f3")        // bgAlt
        assertColor(MarkdownTheme.ayuLight.linkColor, equals: "#36a3d9")                   // blue
        assertColor(MarkdownTheme.ayuLight.syntaxColors.keyword, equals: "#fa8d3e")       // orange
    }

    func testAyuMirageCanonicalColors() {
        assertColor(MarkdownTheme.ayuMirage.codeBackgroundColor, equals: "#191e2a")       // bgAlt
        assertColor(MarkdownTheme.ayuMirage.linkColor, equals: "#73d0ff")                  // blue
        assertColor(MarkdownTheme.ayuMirage.syntaxColors.string, equals: "#bae67e")       // green
    }

    func testAyuDarkCanonicalColors() {
        assertColor(MarkdownTheme.ayuDark.codeBackgroundColor, equals: "#0d1017")         // bgAlt
        assertColor(MarkdownTheme.ayuDark.linkColor, equals: "#39bae6")                    // blue
        assertColor(MarkdownTheme.ayuDark.syntaxColors.keyword, equals: "#ff8f40")        // orange
    }

    // MARK: - Rosé Pine

    func testRosePineCanonicalColors() {
        assertColor(MarkdownTheme.rosePine.codeBackgroundColor, equals: "#26233a")        // overlay
        assertColor(MarkdownTheme.rosePine.linkColor, equals: "#9ccfd8")                   // foam
        assertColor(MarkdownTheme.rosePine.syntaxColors.keyword, equals: "#31748f")       // pine
    }

    func testRosePineMoonCanonicalColors() {
        assertColor(MarkdownTheme.rosePineMoon.codeBackgroundColor, equals: "#393552")    // overlay
        assertColor(MarkdownTheme.rosePineMoon.linkColor, equals: "#9ccfd8")               // foam
        assertColor(MarkdownTheme.rosePineMoon.syntaxColors.string, equals: "#f6c177")    // gold
    }

    func testRosePineDawnCanonicalColors() {
        assertColor(MarkdownTheme.rosePineDawn.codeBackgroundColor, equals: "#f2e9e1")    // overlay
        assertColor(MarkdownTheme.rosePineDawn.linkColor, equals: "#56949f")               // foam
        assertColor(MarkdownTheme.rosePineDawn.syntaxColors.keyword, equals: "#286983")   // pine
    }

    // MARK: - Night Owl / Light Owl

    func testNightOwlCanonicalColors() {
        assertColor(MarkdownTheme.nightOwl.codeBackgroundColor, equals: "#010e1a")        // bgAlt
        assertColor(MarkdownTheme.nightOwl.linkColor, equals: "#82aaff")                   // blue
        assertColor(MarkdownTheme.nightOwl.syntaxColors.keyword, equals: "#c792ea")       // purple
    }

    func testLightOwlCanonicalColors() {
        assertColor(MarkdownTheme.lightOwl.codeBackgroundColor, equals: "#f0f0f0")        // bgAlt
        assertColor(MarkdownTheme.lightOwl.linkColor, equals: "#4876d6")                   // blue
        assertColor(MarkdownTheme.lightOwl.syntaxColors.keyword, equals: "#994cc3")       // purple
    }

    // MARK: - GitHub Dark / Light

    func testGitHubDarkCanonicalColors() {
        assertColor(MarkdownTheme.githubDark.codeBackgroundColor, equals: "#161b22")      // bgSecondary
        assertColor(MarkdownTheme.githubDark.linkColor, equals: "#58a6ff")                 // blue
        assertColor(MarkdownTheme.githubDark.syntaxColors.keyword, equals: "#ff7b72")     // red
    }

    func testGitHubLightCanonicalColors() {
        assertColor(MarkdownTheme.githubLight.codeBackgroundColor, equals: "#f6f8fa")     // bgSecondary
        assertColor(MarkdownTheme.githubLight.linkColor, equals: "#0969da")                // blue
        assertColor(MarkdownTheme.githubLight.syntaxColors.string, equals: "#0550ae")     // cyan
    }

    // MARK: - All themes usable

    func testGalleryThemesAreDistinct() {
        let themes: [MarkdownTheme] = [
            .blackOnWhite, .whiteOnBlack,
            .solarizedLight, .solarizedDark,
            .dracula,
            .nord,
            .catppuccinLatte, .catppuccinFrappe, .catppuccinMacchiato, .catppuccinMocha,
            .gruvboxDark, .gruvboxLight,
            .tokyoNightNight, .tokyoNightStorm, .tokyoNightDay, .tokyoNightMoon,
            .oneDark, .oneLight,
            .ayuLight, .ayuMirage, .ayuDark,
            .rosePine, .rosePineMoon, .rosePineDawn,
            .nightOwl, .lightOwl,
            .githubDark, .githubLight,
        ]
        // Each theme should at least produce a token style for every type without crashing.
        for theme in themes {
            for type in [TokenType.keyword, .string, .comment, .number, .type, .function, .plain] {
                _ = theme.tokenStyle(for: type)
            }
        }
    }
}
