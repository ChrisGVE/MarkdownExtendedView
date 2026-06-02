// NativeMermaidRenderer.swift
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

import MarkdownExtendedView
import SwiftUI

/// The native renderer that the optional product registers into core's
/// `MermaidRendererRegistry` seam (PRD §4.6). It vends a `MermaidNativeView`,
/// keeping SVGView + the prebuilt binary entirely inside this product.
public struct NativeMermaidRenderer: MermaidRendering {

    /// The display format the registered renderer produces; default = vector
    /// SVG for crispness (D1).
    public let format: MermaidDisplayFormat

    public init(format: MermaidDisplayFormat = .vectorSVG) {
        self.format = format
    }

    @MainActor
    public func makeDiagramView(
        code: String,
        theme: MarkdownTheme,
        colorScheme: ColorScheme,
        availableWidth: CGFloat?
    ) -> AnyView {
        // colorScheme/availableWidth are consumed by theme mapping (Task 13)
        // and sizing refinement (Task 16); the view reads the environment for
        // both today, so the registered render is correct regardless.
        AnyView(MermaidNativeView(code: code, theme: theme, format: format))
    }
}

/// The single canonical opt-in (PRD §4.6 / NF-05): call once at app launch to
/// route every `MermaidView` through the native, WebView-free renderer.
/// Idempotent and thread-safe. Until this is called (or a renderer is injected
/// via `.mermaidRenderer(_:)`), `MermaidView` uses its safe default.
///
/// - Parameter format: `.vectorSVG` (default) or `.rasterPNG`.
public func enableNativeMermaidRendering(format: MermaidDisplayFormat = .vectorSVG) {
    MermaidRendererRegistry.shared.register(NativeMermaidRenderer(format: format))
}
