// MermaidRenderResult.swift
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

import CoreGraphics
import Foundation

/// Which output format the native renderer produces (PRD §4.6, D1).
///
/// The prebuilt binary carries BOTH paths; this selects which FFI entry point
/// the adapter calls. Default is `.vectorSVG` for crispness at any zoom.
public enum MermaidDisplayFormat: Sendable, Hashable {
    /// Vector SVG (`mmdr_render_svg`) — handed to the SVGView sanitizer/display.
    case vectorSVG
    /// Raster PNG (`mmdr_render_png`) — wrapped in `Data` for `UIImage`/`NSImage`.
    case rasterPNG
}

/// The decoded payload of a successful native render (PRD §4.6).
///
/// `.svg` carries UTF-8 SVG text; `.png` carries raw binary PNG bytes (NEVER
/// decode PNG as UTF-8 — wrap in `Data`).
public enum MermaidRenderPayload: Sendable, Hashable {
    case svg(String)
    case png(Data)
}

/// The result of a native Mermaid render, mapped from the FFI `MmdrStatus`
/// (PRD §4.6). The status→case mapping is identical for both render functions.
public enum MermaidRenderResult: Sendable {
    /// `MmdrStatus_Ok` (0). `intrinsicSize` is `.zero` until §F6 viewBox sizing
    /// lands (Task 16); the adapter does not parse the SVG geometry yet.
    case success(payload: MermaidRenderPayload, intrinsicSize: CGSize)
    /// `MmdrStatus_ErrUnsupported` (5) — diagram type outside the MVP allowlist.
    case unsupported(type: String?)
    /// `MmdrStatus` 1–4 (parser errors). `line`/`col` are `nil` when the FFI
    /// reports `loc_valid == 0`.
    case parseError(message: String, line: Int?, col: Int?)
    /// `MmdrStatus` 99 (panic, redacted payload) plus the defensive map-only
    /// 6/7 (UTF-8/null guards) and 8/9 (version/size, too-large). Status 10
    /// (`ErrTimeout`) is never emitted by Rust in MVP — its branch is a
    /// defensive no-op here (the MVP timeout is Swift-side; Task 15).
    case renderError(message: String)
}
