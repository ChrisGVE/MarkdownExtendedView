// MermaidView.swift
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

/// A view that renders Mermaid diagrams through the native, WebView-free
/// renderer when one is registered (PRD §4.6 seam), and otherwise shows the
/// diagram source.
///
/// Phase 9 removed the WebKit path entirely (F4): the package no longer fetches
/// remote JavaScript, runs no WebView, and makes zero network requests for
/// diagrams. When a native renderer is registered — via
/// `enableNativeMermaidRendering()` from the optional
/// `MarkdownExtendedViewMermaidNative` product, or per-subtree via
/// `.mermaidRenderer(_:)` — diagrams render natively. Absent both, the safe
/// default is source-text rendering (`MermaidPlaceholderView`); never a crash,
/// never a blank box, never a link to the native module.
struct MermaidView: View {

    let code: String
    let theme: MarkdownTheme

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.mermaidRenderer) private var injectedRenderer

    var body: some View {
        // Registered-renderer seam (PRD §4.6): an env-injected renderer takes
        // precedence over the process-wide registry; absent both, the safe
        // default is the source-text view.
        if let renderer = injectedRenderer ?? MermaidRendererRegistry.shared.current {
            renderer.makeDiagramView(
                code: code,
                theme: theme,
                colorScheme: colorScheme,
                availableWidth: nil
            )
        } else {
            MermaidPlaceholderView(code: code, theme: theme)
        }
    }
}

/// The source-text view shown when Mermaid rendering is unavailable: either the
/// `.mermaid` feature is disabled, or no native renderer is registered (the
/// safe default — PRD §4.6). Displays the diagram source so content is never
/// lost.
struct MermaidPlaceholderView: View {

    let code: String
    let theme: MarkdownTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(theme.secondaryTextColor)
                Text("Mermaid Diagram")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .newlines))
                    .font(theme.codeBlockFont)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding(theme.codeBlockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.codeBackgroundColor)
        .cornerRadius(8)
    }
}
