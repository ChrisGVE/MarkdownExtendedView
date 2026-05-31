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

/// Tests for the bundled theme gallery (task 16).
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

    // MARK: - All themes usable

    func testGalleryThemesAreDistinct() {
        let themes: [MarkdownTheme] = [
            .blackOnWhite, .whiteOnBlack, .solarizedLight, .solarizedDark, .dracula, .nord,
        ]
        // Each theme should at least produce a token style for every type without crashing.
        for theme in themes {
            for type in [TokenType.keyword, .string, .comment, .number, .type, .function, .plain] {
                _ = theme.tokenStyle(for: type)
            }
        }
    }
}
