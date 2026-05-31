// ThemeColor.swift
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

// MARK: - SemanticColor

/// Named system/semantic colors that can be described in a Codable context.
///
/// Each case maps to the corresponding SwiftUI `Color` value. These are
/// the colors that cannot be expressed as a simple hex value but can still
/// be transported as a stable string token.
public enum SemanticColor: String, Codable, Sendable, Equatable, CaseIterable {
    case primary
    case secondary
    case accent
    case clear
    case red
    case green
    case blue
    case orange
    case yellow
    case pink
    case purple
    case gray
    case black
    case white

    /// Resolves this semantic color to its SwiftUI `Color` counterpart.
    public var color: Color {
        switch self {
        case .primary:   return .primary
        case .secondary: return .secondary
        case .accent:    return .accentColor
        case .clear:     return .clear
        case .red:       return .red
        case .green:     return .green
        case .blue:      return .blue
        case .orange:    return .orange
        case .yellow:    return .yellow
        case .pink:      return .pink
        case .purple:    return .purple
        case .gray:      return .gray
        case .black:     return .black
        case .white:     return .white
        }
    }
}

// MARK: - ThemeColor

/// A Codable description of a SwiftUI color.
///
/// `ThemeColor` is the serialization-layer counterpart to SwiftUI's opaque
/// `Color` type. It covers three practical cases:
///
/// - `.hex(String)` — an sRGB color expressed as a CSS hex string
///   (`#rrggbb`, `#rrggbbaa`, or 3/4 digit shorthand).
/// - `.rgba(red:green:blue:alpha:)` — sRGB components as Doubles in 0 … 1.
/// - `.semantic(SemanticColor)` — a system/semantic color referenced by name
///   (e.g. `.primary`, `.accentColor`). These adapt to appearance automatically
///   at runtime but are opaque to the serialization layer.
/// - `.adaptive(light:dark:)` — two child `ThemeColor` values whose runtime
///   resolution switches on the current color scheme. Use this to express the
///   light/dark pairs that appear throughout the default `MarkdownTheme`.
///
/// ## JSON format
///
/// A tagged-object encoding is used for unambiguous round-tripping:
///
/// ```json
/// { "type": "hex",   "value": "#268bd2" }
/// { "type": "rgba",  "red": 0.0, "green": 0.55, "blue": 0.82, "alpha": 1.0 }
/// { "type": "semantic", "value": "primary" }
/// { "type": "adaptive", "light": { "type": "hex", "value": "#ffffff" },
///                        "dark":  { "type": "hex", "value": "#000000" } }
/// ```
///
/// ## Limitation
///
/// An arbitrary runtime `Color` (e.g. one created with `.opacity()` or via
/// dynamic-member-lookup) cannot be converted back to a `ThemeColor` because
/// `Color` is opaque. Only colors that were originally constructed from a
/// `ThemeColor` (or from a known hex / semantic name) can round-trip.
public indirect enum ThemeColor: Codable, Sendable, Equatable {

    case hex(String)
    case rgba(red: Double, green: Double, blue: Double, alpha: Double)
    case semantic(SemanticColor)
    case adaptive(light: ThemeColor, dark: ThemeColor)

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case type, value, red, green, blue, alpha, light, dark
    }

    private enum TypeTag: String, Codable {
        case hex, rgba, semantic, adaptive
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hex(let string):
            try c.encode(TypeTag.hex, forKey: .type)
            try c.encode(string, forKey: .value)
        case let .rgba(r, g, b, a):
            try c.encode(TypeTag.rgba, forKey: .type)
            try c.encode(r, forKey: .red)
            try c.encode(g, forKey: .green)
            try c.encode(b, forKey: .blue)
            try c.encode(a, forKey: .alpha)
        case .semantic(let name):
            try c.encode(TypeTag.semantic, forKey: .type)
            try c.encode(name, forKey: .value)
        case let .adaptive(light, dark):
            try c.encode(TypeTag.adaptive, forKey: .type)
            try c.encode(light, forKey: .light)
            try c.encode(dark, forKey: .dark)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try c.decode(TypeTag.self, forKey: .type)
        switch tag {
        case .hex:
            let value = try c.decode(String.self, forKey: .value)
            self = .hex(value)
        case .rgba:
            let r = try c.decode(Double.self, forKey: .red)
            let g = try c.decode(Double.self, forKey: .green)
            let b = try c.decode(Double.self, forKey: .blue)
            let a = try c.decode(Double.self, forKey: .alpha)
            self = .rgba(red: r, green: g, blue: b, alpha: a)
        case .semantic:
            let name = try c.decode(SemanticColor.self, forKey: .value)
            self = .semantic(name)
        case .adaptive:
            let light = try c.decode(ThemeColor.self, forKey: .light)
            let dark  = try c.decode(ThemeColor.self, forKey: .dark)
            self = .adaptive(light: light, dark: dark)
        }
    }

    // MARK: SwiftUI resolution

    /// Resolves this descriptor to a SwiftUI `Color`.
    ///
    /// For `.adaptive`, delegates to the internal `Color(light:dark:)` helper
    /// which installs a dynamic appearance observer so the color updates
    /// automatically when the user switches between light and dark mode.
    public var color: Color {
        switch self {
        case .hex(let string):
            return Color(hex: string)
        case let .rgba(r, g, b, a):
            return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        case .semantic(let name):
            return name.color
        case let .adaptive(light, dark):
            return Color(light: light.color, dark: dark.color)
        }
    }
}
