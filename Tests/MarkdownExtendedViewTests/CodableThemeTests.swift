// CodableThemeTests.swift
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

/// Tests for the Codable theme DTO layer (task 19).
final class CodableThemeTests: XCTestCase {

    // MARK: - Helpers

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private let decoder = JSONDecoder()

    /// Extracts sRGB components from a SwiftUI Color via the platform color type.
    /// Uses NSColor/UIColor — does NOT use Color.resolve(in:) which requires iOS 17+.
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

    private func assertColorComponents(
        _ color: Color,
        red expectedRed: Double,
        green expectedGreen: Double,
        blue expectedBlue: Double,
        alpha expectedAlpha: Double = 1.0,
        accuracy: Double = 0.01,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let c = rgba(color)
        XCTAssertEqual(c.red,   expectedRed,   accuracy: accuracy, "red",   file: file, line: line)
        XCTAssertEqual(c.green, expectedGreen, accuracy: accuracy, "green", file: file, line: line)
        XCTAssertEqual(c.blue,  expectedBlue,  accuracy: accuracy, "blue",  file: file, line: line)
        XCTAssertEqual(c.alpha, expectedAlpha, accuracy: accuracy, "alpha", file: file, line: line)
    }

    private func assertColorMatchesHex(
        _ color: Color,
        hex: String,
        accuracy: Double = 0.01,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = rgba(Color(hex: hex))
        let actual   = rgba(color)
        XCTAssertEqual(actual.red,   expected.red,   accuracy: accuracy, "red",   file: file, line: line)
        XCTAssertEqual(actual.green, expected.green, accuracy: accuracy, "green", file: file, line: line)
        XCTAssertEqual(actual.blue,  expected.blue,  accuracy: accuracy, "blue",  file: file, line: line)
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try encoder.encode(value)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - ThemeColor: Codable round-trips

    func testThemeColorHexRoundTrip() throws {
        let original = ThemeColor.hex("#268bd2")
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testThemeColorRGBARoundTrip() throws {
        let original = ThemeColor.rgba(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.75)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testThemeColorSemanticRoundTripForEveryCase() throws {
        for semantic in SemanticColor.allCases {
            let original = ThemeColor.semantic(semantic)
            let decoded  = try roundTrip(original)
            XCTAssertEqual(original, decoded, "semantic.\(semantic.rawValue) failed to round-trip")
        }
    }

    func testThemeColorAdaptiveRoundTrip() throws {
        let original = ThemeColor.adaptive(
            light: .hex("#ffffff"),
            dark:  .hex("#000000")
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testThemeColorAdaptiveNestedRoundTrip() throws {
        // Nested adaptive → adaptive scenario
        let original = ThemeColor.adaptive(
            light: .rgba(red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
            dark:  .adaptive(
                light: .hex("#111111"),
                dark:  .hex("#000000")
            )
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - ThemeColor: JSON encoding format

    func testThemeColorHexJSONShape() throws {
        let tc   = ThemeColor.hex("#ff0000")
        let data = try encoder.encode(tc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "hex")
        XCTAssertEqual(json?["value"] as? String, "#ff0000")
    }

    func testThemeColorRGBAJSONShape() throws {
        let tc   = ThemeColor.rgba(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5)
        let data = try encoder.encode(tc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "rgba")
        XCTAssertNotNil(json?["red"])
        XCTAssertNotNil(json?["green"])
        XCTAssertNotNil(json?["blue"])
        XCTAssertNotNil(json?["alpha"])
    }

    func testThemeColorSemanticJSONShape() throws {
        let tc   = ThemeColor.semantic(.primary)
        let data = try encoder.encode(tc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "semantic")
        XCTAssertEqual(json?["value"] as? String, "primary")
    }

    func testThemeColorAdaptiveJSONShape() throws {
        let tc   = ThemeColor.adaptive(light: .hex("#fff"), dark: .hex("#000"))
        let data = try encoder.encode(tc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "adaptive")
        XCTAssertNotNil(json?["light"])
        XCTAssertNotNil(json?["dark"])
    }

    // MARK: - ThemeColor: color resolution

    func testThemeColorHexResolvesToExpectedSRGBComponents() {
        let tc    = ThemeColor.hex("#6f42c1")
        let color = tc.color
        assertColorComponents(color,
                              red: 0x6f / 255,
                              green: 0x42 / 255,
                              blue: 0xc1 / 255)
    }

    func testThemeColorRGBAResolvesToExpectedComponents() {
        let tc    = ThemeColor.rgba(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9)
        let color = tc.color
        assertColorComponents(color, red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9)
    }

    func testThemeColorHexResolutionMatchesInternalColorHexInit() {
        let hex   = "#d73a49"
        let tc    = ThemeColor.hex(hex)
        assertColorMatchesHex(tc.color, hex: hex)
    }

    func testThemeColorRGBAResolutionMatchesHexEquivalent() {
        // #268bd2 = r:38 g:139 b:210 in 0-255
        let tc = ThemeColor.rgba(red: 38.0/255, green: 139.0/255, blue: 210.0/255, alpha: 1)
        assertColorMatchesHex(tc.color, hex: "#268bd2")
    }

    // MARK: - SemanticColor round-trips

    func testSemanticColorAllCasesRoundTrip() throws {
        for semantic in SemanticColor.allCases {
            let decoded = try roundTrip(semantic)
            XCTAssertEqual(semantic, decoded, "\(semantic.rawValue) did not round-trip")
        }
    }

    // MARK: - FontDescriptor: Codable round-trips

    func testFontDescriptorFixedSizeRoundTrip() throws {
        let original = FontDescriptor.fixed(16, weight: .bold, design: .monospaced)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testFontDescriptorRelativeStyleRoundTrip() throws {
        let original = FontDescriptor.relative(.headline, weight: .semibold, design: .serif)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testFontDescriptorCustomFamilyRoundTrip() throws {
        let original = FontDescriptor.custom("Georgia", size: 18)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testFontDescriptorDefaultValuesRoundTrip() throws {
        let original = FontDescriptor()
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testAllWeightDescriptorCasesRoundTrip() throws {
        for weight in WeightDescriptor.allCases {
            let fd      = FontDescriptor(weight: weight)
            let decoded = try roundTrip(fd)
            XCTAssertEqual(fd, decoded, "WeightDescriptor.\(weight.rawValue) failed")
        }
    }

    func testAllDesignDescriptorCasesRoundTrip() throws {
        for design in DesignDescriptor.allCases {
            let fd      = FontDescriptor(design: design)
            let decoded = try roundTrip(fd)
            XCTAssertEqual(fd, decoded, "DesignDescriptor.\(design.rawValue) failed")
        }
    }

    func testAllTextStyleDescriptorCasesRoundTrip() throws {
        for style in TextStyleDescriptor.allCases {
            let fd      = FontDescriptor.relative(style)
            let decoded = try roundTrip(fd)
            XCTAssertEqual(fd, decoded, "TextStyleDescriptor.\(style.rawValue) failed")
        }
    }

    // MARK: - FontDescriptor: font resolution

    func testFontDescriptorFixedResolvesToFont() {
        let fd   = FontDescriptor.fixed(20, weight: .bold)
        let font = fd.font
        // Font is opaque — we can only verify the call does not crash and returns a non-nil value.
        _ = font
    }

    func testFontDescriptorRelativeResolvesToFont() {
        let fd   = FontDescriptor.relative(.title2, weight: .semibold, design: .serif)
        let font = fd.font
        _ = font
    }

    func testFontDescriptorCustomFamilyResolvesToFont() {
        let fd   = FontDescriptor.custom("Helvetica", size: 14)
        let font = fd.font
        _ = font
    }

    // MARK: - CodableSyntaxColors round-trip

    func testCodableSyntaxColorsRoundTrip() throws {
        let original = CodableSyntaxColors(
            keyword:  .hex("#859900"),
            string:   .hex("#2aa198"),
            comment:  .hex("#586e75"),
            number:   .hex("#d33682"),
            type:     .hex("#b58900"),
            function: .hex("#268bd2"),
            plain:    .hex("#657b83")
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableSyntaxColorsResolves() {
        let dto = CodableSyntaxColors(keyword: .hex("#859900"), plain: .semantic(.primary))
        let sc  = dto.syntaxColors
        assertColorMatchesHex(sc.keyword, hex: "#859900")
    }

    // MARK: - CodableTokenStyle round-trip

    func testCodableTokenStyleRoundTripWithColor() throws {
        let original = CodableTokenStyle(color: .hex("#ff79c6"), isBold: true, isItalic: false, isUnderlined: true)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableTokenStyleRoundTripNoColor() throws {
        let original = CodableTokenStyle(color: nil, isBold: true, isItalic: true)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableTokenStyleResolves() {
        let dto   = CodableTokenStyle(color: .hex("#ff0000"), isBold: true)
        let style = dto.tokenStyle
        assertColorMatchesHex(style.color!, hex: "#ff0000")
        XCTAssertTrue(style.isBold)
    }

    // MARK: - CodableTokenStyles round-trip

    func testCodableTokenStylesRoundTrip() throws {
        let original = CodableTokenStyles(
            keyword:  CodableTokenStyle(color: .hex("#ff79c6"), isBold: true),
            comment:  CodableTokenStyle(color: .hex("#6272a4"), isItalic: true),
            function: CodableTokenStyle(color: .hex("#50fa7b"), isUnderlined: true)
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - CodableMarkdownTheme round-trip

    func testCodableMarkdownThemeDefaultRoundTrip() throws {
        let original = CodableMarkdownTheme()
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableMarkdownThemeCustomRoundTrip() throws {
        let original = CodableMarkdownTheme(
            bodyFont:          .fixed(16, weight: .regular),
            heading1Font:      .fixed(32, weight: .bold),
            linkColor:         .hex("#0366d6"),
            codeBackgroundColor: .hex("#f6f8fa"),
            syntaxColors: CodableSyntaxColors(
                keyword:  .hex("#d73a49"),
                string:   .hex("#005cc5"),
                comment:  .hex("#6a737d"),
                number:   .hex("#005cc5"),
                type:     .hex("#6f42c1"),
                function: .hex("#6f42c1"),
                plain:    .hex("#24292e")
            ),
            paragraphSpacing: 16,
            indentation: 24,
            codeBlockPadding: 16
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableMarkdownThemeWithTokenStylesRoundTrip() throws {
        let tokenStyles = CodableTokenStyles(
            keyword:  CodableTokenStyle(isBold: true),
            comment:  CodableTokenStyle(isItalic: true),
            function: CodableTokenStyle(isUnderlined: true)
        )
        let original = CodableMarkdownTheme(tokenStyles: tokenStyles, linkUnderline: false)
        let decoded  = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testCodableMarkdownThemeNilOptionalFields() throws {
        var original = CodableMarkdownTheme()
        original.strikethroughColor = nil
        original.tokenStyles        = nil
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
        XCTAssertNil(decoded.strikethroughColor)
        XCTAssertNil(decoded.tokenStyles)
    }

    // MARK: - CodableMarkdownTheme → MarkdownTheme conversion

    func testThemeConversionProducesUsableMarkdownTheme() throws {
        let codable = CodableMarkdownTheme(
            linkColor:            .hex("#268bd2"),
            codeBackgroundColor:  .hex("#073642"),
            paragraphSpacing:     16
        )
        let theme = codable.theme

        // Verify a couple of resolved colors match the expected hex.
        assertColorMatchesHex(theme.linkColor,           hex: "#268bd2")
        assertColorMatchesHex(theme.codeBackgroundColor, hex: "#073642")
        XCTAssertEqual(theme.paragraphSpacing, 16)
        XCTAssertEqual(theme.linkUnderline, true)
    }

    func testThemeConversionWithSemanticColors() throws {
        let codable = CodableMarkdownTheme(
            textColor:      .semantic(.primary),
            secondaryTextColor: .semantic(.secondary),
            linkColor:      .semantic(.accent)
        )
        let theme = codable.theme
        // Semantic colors resolve without crashing; exact values depend on system.
        _ = theme.textColor
        _ = theme.secondaryTextColor
        _ = theme.linkColor
    }

    func testThemeConversionPreservesSpacingAndFlags() throws {
        let codable = CodableMarkdownTheme(
            linkUnderline:    false,
            tableCellPadding: 4,
            paragraphSpacing: 20,
            listItemSpacing:  6,
            indentation:      28,
            codeBlockPadding: 8
        )
        let theme = codable.theme
        XCTAssertFalse(theme.linkUnderline)
        XCTAssertEqual(theme.tableCellPadding,  4)
        XCTAssertEqual(theme.paragraphSpacing,  20)
        XCTAssertEqual(theme.listItemSpacing,   6)
        XCTAssertEqual(theme.indentation,       28)
        XCTAssertEqual(theme.codeBlockPadding,  8)
    }

    func testThemeConversionTokenStylesNilWhenNotSet() throws {
        let codable = CodableMarkdownTheme()  // tokenStyles defaults to nil
        let theme   = codable.theme
        XCTAssertNil(theme.tokenStyles)
    }

    func testThemeConversionTokenStylesSetWhenProvided() throws {
        let ts = CodableTokenStyles(keyword: CodableTokenStyle(isBold: true))
        let codable = CodableMarkdownTheme(tokenStyles: ts)
        let theme   = codable.theme
        XCTAssertNotNil(theme.tokenStyles)
        XCTAssertTrue(theme.tokenStyles!.style(for: .keyword).isBold)
    }

    // MARK: - End-to-end: JSON → decode → convert → assert

    func testEndToEndJSONRoundTrip() throws {
        // Build a realistic theme resembling Solarized Dark.
        let original = CodableMarkdownTheme(
            bodyFont:            .fixed(16, weight: .regular),
            heading1Font:        .fixed(32, weight: .bold),
            heading2Font:        .fixed(24, weight: .bold),
            heading3Font:        .fixed(20, weight: .bold),
            textColor:           .hex("#839496"),
            secondaryTextColor:  .hex("#586e75"),
            linkColor:           .hex("#268bd2"),
            codeBackgroundColor: .hex("#073642"),
            syntaxColors: CodableSyntaxColors(
                keyword:  .hex("#859900"),
                string:   .hex("#2aa198"),
                comment:  .hex("#586e75"),
                number:   .hex("#d33682"),
                type:     .hex("#b58900"),
                function: .hex("#268bd2"),
                plain:    .hex("#839496")
            ),
            paragraphSpacing: 16,
            listItemSpacing:  4,
            indentation:      24,
            codeBlockPadding: 16
        )

        // Encode to JSON data.
        let data = try encoder.encode(original)
        XCTAssertFalse(data.isEmpty)

        // Decode back.
        let decoded = try decoder.decode(CodableMarkdownTheme.self, from: data)
        XCTAssertEqual(original, decoded)

        // Convert to runtime theme and assert key slots.
        let theme = decoded.theme
        assertColorMatchesHex(theme.linkColor,           hex: "#268bd2")
        assertColorMatchesHex(theme.codeBackgroundColor, hex: "#073642")
        assertColorMatchesHex(theme.syntaxColors.keyword, hex: "#859900")
        assertColorMatchesHex(theme.syntaxColors.string,  hex: "#2aa198")
        XCTAssertEqual(theme.paragraphSpacing, 16)
        XCTAssertEqual(theme.indentation, 24)
    }

    func testEndToEndJSONDataIsValidUTF8JSON() throws {
        let dto  = CodableMarkdownTheme()
        let data = try encoder.encode(dto)
        // Must be valid JSON we can deserialise as a top-level dictionary.
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertTrue(obj is [String: Any], "Encoded CodableMarkdownTheme must be a JSON object")
    }
}
