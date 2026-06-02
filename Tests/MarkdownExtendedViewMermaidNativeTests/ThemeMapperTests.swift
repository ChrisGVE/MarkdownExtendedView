// ThemeMapperTests.swift
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

import Cmmdr
import SwiftUI
import XCTest

import MarkdownExtendedView
@testable import MarkdownExtendedViewMermaidNative

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// A light/dark adaptive color built from platform primitives (the library's
/// own `Color(light:dark:)` is `@usableFromInline`, not visible here).
private func adaptiveColor(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
    #if canImport(UIKit)
    return Color(UIColor { traits in
        let c = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
    #elseif canImport(AppKit)
    return Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let c = isDark ? dark : light
        return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
    })
    #else
    return Color(red: light.0, green: light.1, blue: light.2)
    #endif
}

/// Theme → MmdrOptions mapping (PRD §4.6 / T4 / Arbitration B).
final class ThemeMapperTests: XCTestCase {

    func testPackOrderIsRRGGBBAA() {
        XCTAssertEqual(ThemeMapper.pack(r: 0x11, g: 0x22, b: 0x33, a: 0x44), 0x1122_3344)
        XCTAssertEqual(ThemeMapper.pack(r: 255, g: 0, b: 0, a: 255), 0xFF00_00FF)
    }

    func testExplicitOpaqueColorResolvesExactly() {
        let red = ThemeMapper.rgba(Color(red: 1, green: 0, blue: 0), .light)
        XCTAssertEqual(red, 0xFF00_00FF)
        let green = ThemeMapper.rgba(Color(red: 0, green: 1, blue: 0), .light)
        XCTAssertEqual(green, 0x00FF_00FF)
    }

    func testColorClearIsLegalZeroOverride() {
        // Arbitration B: 0x00000000 is a legal value when its mask bit is set,
        // NOT an alpha sentinel.
        XCTAssertEqual(ThemeMapper.rgba(Color.clear, .light), 0x0000_0000)
    }

    func testOptionsGuardFieldsAndMask() {
        let opts = ThemeMapper.options(for: MarkdownTheme(), colorScheme: .light)
        XCTAssertEqual(opts.abi_version, UInt32(MMDR_ABI_VERSION))
        XCTAssertEqual(opts.struct_size, UInt32(MemoryLayout<MmdrOptions>.size))
        XCTAssertEqual(opts.base_theme, 0, "default base theme = modern")
        // All three primary slots set; reserved high bits zero (NEW-4).
        XCTAssertEqual(opts.color_override_mask, 0b111)
        // Untouched fields default to 0 → FFI applies its own defaults.
        XCTAssertEqual(opts.node_spacing, 0)
        XCTAssertEqual(opts.max_source_bytes, 0)
        XCTAssertEqual(opts.timeout_ms, 0)
    }

    func testAdaptiveColorDivergesByScheme() throws {
        // Per-scheme NSColor resolution needs macOS 14+ (performAsCurrentDrawing
        // Appearance); UIKit resolves on every supported version.
        #if canImport(AppKit)
        guard #available(macOS 14.0, *) else {
            throw XCTSkip("per-scheme NSColor resolution requires macOS 14+")
        }
        #endif
        let adaptive = adaptiveColor(light: (1, 1, 1), dark: (0, 0, 0))
        let light = ThemeMapper.rgba(adaptive, .light)
        let dark = ThemeMapper.rgba(adaptive, .dark)
        XCTAssertNotEqual(light, dark, "adaptive color must resolve differently per scheme")
        // Light ≈ white, dark ≈ black (alpha 0xFF in both).
        XCTAssertEqual(light, 0xFFFF_FFFF)
        XCTAssertEqual(dark, 0x0000_00FF)
    }

    func testThemeOptionsDifferAcrossSchemesForDefaultTheme() throws {
        #if canImport(AppKit)
        guard #available(macOS 14.0, *) else {
            throw XCTSkip("per-scheme NSColor resolution requires macOS 14+")
        }
        #endif
        let theme = MarkdownTheme() // codeBackgroundColor is adaptive (light/dark)
        let light = ThemeMapper.options(for: theme, colorScheme: .light)
        let dark = ThemeMapper.options(for: theme, colorScheme: .dark)
        XCTAssertNotEqual(light.background_rgba, dark.background_rgba)
    }
}
