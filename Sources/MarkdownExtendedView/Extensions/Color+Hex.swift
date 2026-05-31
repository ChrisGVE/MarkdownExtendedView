// Color+Hex.swift
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

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {

    /// Creates a color from a hexadecimal string.
    ///
    /// Accepts `RGB`, `RGBA`, `RRGGBB`, and `RRGGBBAA` forms, with or without a
    /// leading `#`. Invalid strings fall back to black so a malformed token in a
    /// theme definition degrades visibly rather than crashing.
    ///
    /// ```swift
    /// Color(hex: "#6f42c1")
    /// Color(hex: "1a1b26")
    /// Color(hex: "#fff")
    /// ```
    ///
    /// - Parameter hex: The hexadecimal color string.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red, green, blue, alpha: Double
        switch sanitized.count {
        case 3: // RGB (12-bit)
            red = Double((value >> 8) & 0xF) / 15
            green = Double((value >> 4) & 0xF) / 15
            blue = Double(value & 0xF) / 15
            alpha = 1
        case 4: // RGBA (16-bit)
            red = Double((value >> 12) & 0xF) / 15
            green = Double((value >> 8) & 0xF) / 15
            blue = Double((value >> 4) & 0xF) / 15
            alpha = Double(value & 0xF) / 15
        case 6: // RRGGBB (24-bit)
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        case 8: // RRGGBBAA (32-bit)
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        default:
            red = 0; green = 0; blue = 0; alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Creates a color that resolves to `light` in light mode and `dark` in dark
    /// mode, so a theme adapts to the system appearance automatically.
    ///
    /// On platforms without a dynamic color provider the `light` color is used.
    ///
    /// - Parameters:
    ///   - light: The color used in light appearance.
    ///   - dark: The color used in dark appearance.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }

    /// Convenience for an adaptive color from two hex strings.
    init(lightHex: String, darkHex: String) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }
}
