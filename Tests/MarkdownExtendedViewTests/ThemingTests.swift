// ThemingTests.swift
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

/// Tests for token styling (task 17) and theming improvements (task 13).
final class ThemingTests: XCTestCase {

    /// Extracts sRGB components from a Color via the platform color type.
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

    // MARK: - Color(hex:)

    func testHexSixDigits() {
        let c = rgba(Color(hex: "#6f42c1"))
        XCTAssertEqual(c.red, 0x6f / 255, accuracy: 0.01)
        XCTAssertEqual(c.green, 0x42 / 255, accuracy: 0.01)
        XCTAssertEqual(c.blue, 0xc1 / 255, accuracy: 0.01)
    }

    func testHexThreeDigitShorthand() {
        let c = rgba(Color(hex: "#fff"))
        XCTAssertEqual(c.red, 1, accuracy: 0.01)
        XCTAssertEqual(c.green, 1, accuracy: 0.01)
        XCTAssertEqual(c.blue, 1, accuracy: 0.01)
    }

    func testHexWithAlpha() {
        let c = rgba(Color(hex: "#00000080"))
        XCTAssertEqual(c.alpha, 0x80 / 255, accuracy: 0.02)
    }

    func testHexWithoutHashPrefix() {
        let c = rgba(Color(hex: "ff0000"))
        XCTAssertEqual(c.red, 1, accuracy: 0.01)
        XCTAssertEqual(c.green, 0, accuracy: 0.01)
    }

    // MARK: - TokenStyle / TokenStyles

    func testTokenStylesFromColorsIsColorOnly() {
        let colors = SyntaxColors.gitHub
        let styles = TokenStyles(colors: colors)
        let keyword = styles.style(for: .keyword)
        XCTAssertNotNil(keyword.color)
        XCTAssertFalse(keyword.isBold)
        XCTAssertFalse(keyword.isItalic)
    }

    func testMonochromeTokenStyleCarriesTraits() {
        let mono = TokenStyles(
            keyword: TokenStyle(isBold: true),
            comment: TokenStyle(isItalic: true)
        )
        XCTAssertNil(mono.style(for: .keyword).color, "monochrome keyword should not set a color")
        XCTAssertTrue(mono.style(for: .keyword).isBold)
        XCTAssertTrue(mono.style(for: .comment).isItalic)
    }

    // MARK: - MarkdownTheme.tokenStyle(for:)

    func testThemeFallsBackToSyntaxColorsWhenNoTokenStyles() {
        var theme = MarkdownTheme.default
        theme.tokenStyles = nil
        let style = theme.tokenStyle(for: .keyword)
        XCTAssertNotNil(style.color, "Should derive a color-only style from syntaxColors")
        XCTAssertFalse(style.isBold)
    }

    func testThemeUsesTokenStylesWhenSet() {
        var theme = MarkdownTheme.default
        theme.tokenStyles = TokenStyles(keyword: TokenStyle(isBold: true, isUnderlined: true))
        let style = theme.tokenStyle(for: .keyword)
        XCTAssertTrue(style.isBold)
        XCTAssertTrue(style.isUnderlined)
    }

    // MARK: - New themeable elements

    func testNewThemeablePropertiesHaveDefaults() {
        let theme = MarkdownTheme.default
        XCTAssertTrue(theme.linkUnderline)
        XCTAssertEqual(theme.tableCellPadding, 8)
        XCTAssertNil(theme.strikethroughColor)
    }

    func testThemePropertiesAreMutable() {
        var theme = MarkdownTheme.default
        theme.linkUnderline = false
        theme.tableCellPadding = 4
        theme.taskCheckboxColor = Color(hex: "#00ff00")
        XCTAssertFalse(theme.linkUnderline)
        XCTAssertEqual(theme.tableCellPadding, 4)
    }
}
