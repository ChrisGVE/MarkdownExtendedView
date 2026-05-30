// TappableLinkView.swift
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
import Markdown

/// A tappable view that renders a markdown link with proper handling.
///
/// On iOS, tapping opens the link in an in-app browser (SFSafariViewController).
/// On macOS, tapping opens the link in the default browser.
/// A custom handler can be provided to override the default behavior.
struct TappableLinkView: View {

    /// The raw link destination string from the markdown.
    let destination: String?
    /// The flattened, styled content of the link.
    let content: [InlineFragment]
    let theme: MarkdownTheme
    let linkHandler: ((URL) -> Void)?
    let baseURL: URL?
    var textTransform: ((SwiftUI.Text) -> SwiftUI.Text)?

    #if canImport(UIKit)
    @State private var showingSafari = false
    #endif

    var body: some View {
        linkText
            .foregroundColor(theme.linkColor)
            .underline()
            .onTapGesture {
                handleTap()
            }
        #if canImport(UIKit)
            .sheet(isPresented: $showingSafari) {
                if let url = resolvedURL {
                    SafariView(url: url)
                }
            }
        #endif
    }

    /// The text content of the link with optional transform applied.
    private var linkText: some View {
        let text = buildLinkText()
        if let transform = textTransform {
            return AnyView(transform(text))
        } else {
            return AnyView(text)
        }
    }

    /// Builds the Text from the link's flattened content, preserving styling
    /// (bold / italic / code) on the link label.
    private func buildLinkText() -> SwiftUI.Text {
        InlineTextRenderer.text(content, theme: theme).font(theme.bodyFont)
    }

    /// The resolved URL from the link destination.
    private var resolvedURL: URL? {
        guard let destination = destination else { return nil }

        // Try to create URL directly
        if let url = URL(string: destination) {
            // If it's a relative URL and we have a base URL, resolve it
            if url.scheme == nil, let base = baseURL {
                return URL(string: destination, relativeTo: base)?.absoluteURL
            }
            return url
        }

        return nil
    }

    /// Handles the tap gesture on the link.
    private func handleTap() {
        guard let url = resolvedURL else { return }

        // If custom handler is provided, use it
        if let handler = linkHandler {
            handler(url)
            return
        }

        // Default behavior differs by platform
        #if canImport(UIKit)
        // On iOS, show in-app browser for http/https URLs
        if url.scheme == "http" || url.scheme == "https" {
            showingSafari = true
        } else {
            // For other schemes (mailto:, tel:, etc.), use system handler
            Task { @MainActor in
                LinkOpener.openInBrowser(url)
            }
        }
        #elseif canImport(AppKit)
        // On macOS, open in default browser
        Task { @MainActor in
            LinkOpener.openInBrowser(url)
        }
        #endif
    }
}
