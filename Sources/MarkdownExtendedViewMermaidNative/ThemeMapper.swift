// ThemeMapper.swift
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
import MarkdownExtendedView
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Pure mapping from `MarkdownTheme` + `ColorScheme` to the C-ABI render options
/// (PRD §4.6 theme mapping, T4; Arbitration B color-mask).
///
/// Resolves the theme's three primary slots — background / foreground / accent —
/// to concrete `0xRRGGBBAA` for the given scheme and fills the `#[repr(C)]`
/// `MmdrOptions`. `base_theme = 0` (modern); the ~30 other fork `Theme` fields
/// keep their base-theme value (accepted by design — RNIT1 / D5). Reserved mask
/// bits 3–31 are zero (NEW-4). `Color.clear` (0x00000000) with its mask bit set
/// is a LEGAL override, not an alpha sentinel (Arbitration B).
public enum ThemeMapper {

    /// Build `MmdrOptions` for `theme` resolved against `colorScheme`.
    public static func options(
        for theme: MarkdownTheme,
        colorScheme: ColorScheme
    ) -> MmdrOptions {
        var options = MmdrOptions()
        options.abi_version = UInt32(MMDR_ABI_VERSION)
        options.struct_size = UInt32(MemoryLayout<MmdrOptions>.size)
        options.base_theme = 0 // Theme::modern()

        // All three primary slots are overridden (bits 0|1|2); high bits zero.
        options.color_override_mask = UInt32(MASK_BACKGROUND | MASK_FOREGROUND | MASK_ACCENT)
        options.background_rgba = rgba(theme.codeBackgroundColor, colorScheme)
        options.foreground_rgba = rgba(theme.textColor, colorScheme)
        options.accent_rgba = rgba(theme.linkColor, colorScheme)

        // Everything else stays 0 → the FFI applies its defaults (spacing,
        // aspect, 256 KB source cap, 5000-node cap, no timeout).
        return options
    }

    /// Pack an 8-bit-per-channel color as `0xRRGGBBAA`.
    static func pack(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> UInt32 {
        (UInt32(r) << 24) | (UInt32(g) << 16) | (UInt32(b) << 8) | UInt32(a)
    }

    /// Resolve a SwiftUI `Color` to `0xRRGGBBAA` for the given scheme. Adaptive
    /// colors (`.primary`, `.accentColor`, `Color(light:dark:)`) resolve to the
    /// scheme-appropriate concrete value.
    static func rgba(_ color: Color, _ scheme: ColorScheme) -> UInt32 {
        let c = components(color, scheme)
        return pack(
            r: channel(c.r), g: channel(c.g), b: channel(c.b), a: channel(c.a)
        )
    }

    /// Clamp a 0...1 component to a 0...255 byte.
    private static func channel(_ v: CGFloat) -> UInt8 {
        UInt8(max(0, min(1, v)) * 255 + 0.5)
    }

    // MARK: - Platform color resolution

    private typealias RGBA = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    #if canImport(UIKit)
    private static func components(_ color: Color, _ scheme: ColorScheme) -> RGBA {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        let resolved = UIColor(color).resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Non-RGB color space (e.g. monochrome): convert via sRGB.
            var w: CGFloat = 0, wa: CGFloat = 0
            if resolved.getWhite(&w, alpha: &wa) { return (w, w, w, wa) }
            return (0, 0, 0, 1)
        }
        return (r, g, b, a)
    }
    #elseif canImport(AppKit)
    private static func components(_ color: Color, _ scheme: ColorScheme) -> RGBA {
        // macOS 14+: resolve the dynamic NSColor under the requested appearance
        // (accurate per-scheme). macOS 13: resolve under the ambient appearance
        // — no deprecated `NSAppearance.current` is referenced, keeping the
        // build warning-free at the floor.
        if #available(macOS 14.0, *),
           let appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua) {
            var out: RGBA = (0, 0, 0, 1)
            appearance.performAsCurrentDrawingAppearance {
                out = resolveSRGB(NSColor(color))
            }
            return out
        }
        return resolveSRGB(NSColor(color))
    }

    private static func resolveSRGB(_ color: NSColor) -> RGBA {
        let c = color.usingColorSpace(.sRGB) ?? color
        return (c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent)
    }
    #else
    private static func components(_ color: Color, _ scheme: ColorScheme) -> RGBA {
        (0, 0, 0, 1)
    }
    #endif
}
