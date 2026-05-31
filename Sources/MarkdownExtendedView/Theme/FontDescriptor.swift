// FontDescriptor.swift
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

// MARK: - Supporting Enums

/// A Codable mapping to `Font.TextStyle`.
///
/// Maps every public `Font.TextStyle` case to a stable string token so that
/// themes encoded in JSON retain their relative-size semantics on decoding.
public enum TextStyleDescriptor: String, Codable, Sendable, Equatable, CaseIterable {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case subheadline
    case body
    case callout
    case footnote
    case caption
    case caption2

    /// The SwiftUI `Font.TextStyle` this descriptor names.
    public var textStyle: Font.TextStyle {
        switch self {
        case .largeTitle:   return .largeTitle
        case .title:        return .title
        case .title2:       return .title2
        case .title3:       return .title3
        case .headline:     return .headline
        case .subheadline:  return .subheadline
        case .body:         return .body
        case .callout:      return .callout
        case .footnote:     return .footnote
        case .caption:      return .caption
        case .caption2:     return .caption2
        }
    }
}

/// A Codable mapping to `Font.Weight`.
///
/// Covers all standard SwiftUI weight values. Serialized as a string token
/// that matches the SwiftUI property name (e.g. `"semibold"`).
public enum WeightDescriptor: String, Codable, Sendable, Equatable, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    /// The SwiftUI `Font.Weight` this descriptor names.
    public var weight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}

/// A Codable mapping to `Font.Design`.
///
/// Covers all standard SwiftUI design values.
public enum DesignDescriptor: String, Codable, Sendable, Equatable, CaseIterable {
    case `default`
    case serif
    case rounded
    case monospaced

    /// The SwiftUI `Font.Design` this descriptor names.
    public var design: Font.Design {
        switch self {
        case .default:    return .default
        case .serif:      return .serif
        case .rounded:    return .rounded
        case .monospaced: return .monospaced
        }
    }
}

// MARK: - FontDescriptor

/// A Codable description of a system font.
///
/// `FontDescriptor` models the subset of SwiftUI fonts that can be
/// reconstructed from a serialized description:
///
/// - System fonts at a **fixed size** (`size` is set, `relativeTextStyle` is `nil`)
/// - System fonts at a **relative text style** (e.g. `.body`, `.headline`)
/// - Optionally weighted and/or with a design variant (`.monospaced`, `.serif`, …)
/// - Custom font families by name and fixed size (`customFamily` is set)
///
/// ## Limitation
///
/// Only descriptors that follow the patterns above can be round-tripped.
/// An arbitrary opaque `Font` value created by SwiftUI (e.g. via chained
/// modifiers like `.italic()` or `.leading(.tight)`) cannot be converted
/// back to a `FontDescriptor` because `Font` is opaque.
///
/// ## JSON example
///
/// ```json
/// { "size": 16, "weight": "bold", "design": "monospaced" }
/// { "relativeTextStyle": "headline", "weight": "semibold" }
/// { "customFamily": "Georgia", "size": 18 }
/// ```
public struct FontDescriptor: Codable, Sendable, Equatable {

    // MARK: Stored properties

    /// Fixed point size. Mutually exclusive with `relativeTextStyle` (if both
    /// are set, `size` takes precedence).
    public var size: CGFloat?

    /// Relative text style. Used when `size` is `nil`.
    public var relativeTextStyle: TextStyleDescriptor?

    /// Font weight. Defaults to `.regular` when omitted.
    public var weight: WeightDescriptor

    /// Font design variant. Defaults to `.default` when omitted.
    public var design: DesignDescriptor

    /// Custom font family name. When set, the font is constructed via
    /// `Font.custom(_:size:)` with the given `size` (or 14 pt as a fallback).
    /// `weight` and `design` are ignored because `Font.custom` does not expose
    /// those axes for arbitrary families.
    public var customFamily: String?

    // MARK: Init

    public init(
        size: CGFloat? = nil,
        relativeTextStyle: TextStyleDescriptor? = nil,
        weight: WeightDescriptor = .regular,
        design: DesignDescriptor = .default,
        customFamily: String? = nil
    ) {
        self.size = size
        self.relativeTextStyle = relativeTextStyle
        self.weight = weight
        self.design = design
        self.customFamily = customFamily
    }

    // MARK: SwiftUI resolution

    /// Builds the SwiftUI `Font` described by this descriptor.
    ///
    /// Resolution priority:
    /// 1. If `customFamily` is set → `Font.custom(_:size:)` with `size` (fallback 14).
    /// 2. If `size` is set → `Font.system(size:weight:design:)`.
    /// 3. Otherwise → `Font.system(_:design:)` with `relativeTextStyle` (fallback `.body`)
    ///    followed by `.weight(_:)`.
    public var font: Font {
        if let family = customFamily {
            return Font.custom(family, size: size ?? 14)
        }
        if let fixedSize = size {
            return Font.system(size: fixedSize, weight: weight.weight, design: design.design)
        }
        let style = relativeTextStyle?.textStyle ?? .body
        return Font.system(style, design: design.design).weight(weight.weight)
    }
}

// MARK: - Convenience factories

public extension FontDescriptor {

    /// A descriptor for a system font at a fixed point size with optional traits.
    static func fixed(
        _ size: CGFloat,
        weight: WeightDescriptor = .regular,
        design: DesignDescriptor = .default
    ) -> FontDescriptor {
        FontDescriptor(size: size, weight: weight, design: design)
    }

    /// A descriptor for a relative system text style with optional traits.
    static func relative(
        _ style: TextStyleDescriptor,
        weight: WeightDescriptor = .regular,
        design: DesignDescriptor = .default
    ) -> FontDescriptor {
        FontDescriptor(relativeTextStyle: style, weight: weight, design: design)
    }

    /// A descriptor for a custom font family at a fixed size.
    static func custom(_ family: String, size: CGFloat) -> FontDescriptor {
        FontDescriptor(size: size, customFamily: family)
    }
}
