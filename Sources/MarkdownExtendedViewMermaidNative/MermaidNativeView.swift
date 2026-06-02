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
    @Environment(\.colorScheme) private var colorScheme

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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .task(id: TaskKey(code: code, format: format, colorScheme: colorScheme)) {
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
        case .unsupported:
            // F2-AC2: diagram type outside the MVP allowlist.
            fallback(note: "This diagram type isn't supported yet.")
        case let .parseError(message, line, col):
            // F2-AC1: parse error, with location when reported.
            fallback(note: parseErrorNote(message, line: line, col: col))
        case .renderError:
            // F2-AC4: render/internal error (redacted) — show the source.
            fallback(note: "Couldn't render diagram.")
        }
    }

    private func parseErrorNote(_ message: String, line: Int?, col: Int?) -> String {
        let base = message.isEmpty ? "Couldn't parse diagram" : message
        switch (line, col) {
        case let (line?, col?): return "\(base) (line \(line), column \(col))"
        case let (line?, nil): return "\(base) (line \(line))"
        default: return base
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
                fallback(note: "Couldn't render diagram.")
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

    /// F2 source-text fallback: a contextual note above the diagram source, in
    /// the same chrome as a successful render. Never a crash or a blank box.
    private func fallback(note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                Text(note)
            }
            .font(theme.bodyFont)
            .foregroundColor(theme.secondaryTextColor)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .newlines))
                    .font(theme.codeBlockFont)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding(theme.codeBlockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Accessibility label for the diagram (F7-AC1/AC4). On success it announces
    /// the diagram type and its title (or trimmed source); other states announce
    /// the failure with the source for context.
    private var accessibilityLabel: String {
        switch result {
        case .success:
            return MermaidAccessibility.label(for: code)
        case .none:
            return "Rendering Mermaid diagram"
        case .unsupported:
            return "Unsupported \(MermaidAccessibility.label(for: code))"
        case .parseError, .renderError:
            return "Failed to render \(MermaidAccessibility.label(for: code))"
        }
    }

    // MARK: - Rendering

    private func renderOffMain() async {
        let code = self.code
        let format = self.format
        let options = ThemeMapper.options(for: theme, colorScheme: colorScheme)
        let rendered = await Task.detached(priority: .userInitiated) {
            MermaidNativeRenderer.render(code: code, format: format, options: options)
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

    /// Re-runs the render when the source, format, or color scheme changes
    /// (the scheme flips the resolved theme RGBA — Task 13).
    private struct TaskKey: Equatable {
        let code: String
        let format: MermaidDisplayFormat
        let colorScheme: ColorScheme
    }
}
