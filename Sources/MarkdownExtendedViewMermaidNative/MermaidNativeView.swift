// MermaidNativeView.swift
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
import SVGView
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Native, WebView-free SwiftUI display of a Mermaid diagram, in either the
/// vector (SVGView, default) or raster (PNG) format (PRD §4.7, D1).
///
/// The render runs off the main actor; the result is held in `@State` and
/// displayed once ready. The vector path runs the SVG through `SVGSanitizer`
/// before handing it to `SVGView` (egress guard, PRD §4.7a). The raster path's
/// egress is locked structurally in Rust (PRD §4.7b). Sizing comes from the
/// SVG `viewBox` with an 80-pt minimum-height floor (F6).
///
/// This view is the display layer only. The registered-renderer seam + the F2
/// tri-state fallback + accessibility + caching wire in at Phase 8 (Task 11);
/// theme→options mapping at Task 13. Until then a non-success status shows a
/// minimal source-text fallback.
public struct MermaidNativeView: View {

    private let code: String
    private let theme: MarkdownTheme
    private let format: MermaidDisplayFormat

    @State private var result: MermaidRenderResult?

    public init(
        code: String,
        theme: MarkdownTheme,
        format: MermaidDisplayFormat = .vectorSVG
    ) {
        self.code = code
        self.theme = theme
        self.format = format
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(theme.codeBackgroundColor)
            .cornerRadius(8)
            .task(id: TaskKey(code: code, format: format)) {
                await renderOffMain()
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch result {
        case let .success(payload, _):
            payloadView(payload)
        case .none:
            // Render in flight — reserve the floor height to avoid a jump.
            Color.clear.frame(height: SVGSizing.minimumHeight)
        case .some:
            // Any non-success status: minimal source-text fallback for now
            // (the full F2 tri-state fallback lands at Task 11).
            fallback
        }
    }

    @ViewBuilder
    private func payloadView(_ payload: MermaidRenderPayload) -> some View {
        switch payload {
        case let .svg(svg):
            // SVGView's default SVGLinker.none returns nil from load(src:) —
            // a runtime backstop in addition to the sanitizer (PRD §4.7a).
            let sanitized = SVGSanitizer.sanitize(svg)
            sized(SVGView(string: sanitized), aspect: SVGSizing.intrinsicSize(fromSVG: sanitized)?.aspectRatio)
        case let .png(data):
            if let image = platformImage(from: data) {
                // The image carries its own pixel aspect; fit to width.
                sized(image.resizable(), aspect: nil)
            } else {
                fallback
            }
        }
    }

    /// Fit `view` to the container width with an 80-pt minimum-height floor
    /// (F6-AC5). When the intrinsic `aspect` (width/height) is known, the
    /// height follows it; otherwise the view sizes itself above the floor.
    @ViewBuilder
    private func sized(_ view: some View, aspect: CGFloat?) -> some View {
        if let aspect, aspect > 0 {
            view
                .aspectRatio(aspect, contentMode: .fit)
                .frame(maxWidth: .infinity, minHeight: SVGSizing.minimumHeight)
        } else {
            view
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, minHeight: SVGSizing.minimumHeight)
        }
    }

    private var fallback: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code.trimmingCharacters(in: .newlines))
                .font(theme.codeBlockFont)
                .foregroundColor(theme.textColor)
                .padding(theme.codeBlockPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Rendering

    private func renderOffMain() async {
        let code = self.code
        let format = self.format
        let rendered = await Task.detached(priority: .userInitiated) {
            MermaidNativeRenderer.render(code: code, format: format)
        }.value
        result = rendered
    }

    /// Wrap PNG `Data` in a SwiftUI `Image` per platform.
    private func platformImage(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
        #elseif canImport(AppKit)
        guard let ns = NSImage(data: data) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }

    /// Re-runs the render only when the source or format changes.
    private struct TaskKey: Equatable {
        let code: String
        let format: MermaidDisplayFormat
    }
}
