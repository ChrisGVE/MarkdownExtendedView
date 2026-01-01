// TappableLinkView.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI
import Markdown

/// A tappable view that renders a markdown link with proper handling.
///
/// On iOS, tapping opens the link in an in-app browser (SFSafariViewController).
/// On macOS, tapping opens the link in the default browser.
/// A custom handler can be provided to override the default behavior.
struct TappableLinkView: View {

    let link: Markdown.Link
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

    /// Builds the Text from the link's children.
    private func buildLinkText() -> SwiftUI.Text {
        var result = SwiftUI.Text("")
        for child in link.children {
            if let textNode = child as? Markdown.Text {
                result = result + SwiftUI.Text(textNode.string)
            } else if child is Strong {
                let inner = extractPlainText(from: child)
                result = result + SwiftUI.Text(inner).bold()
            } else if child is Emphasis {
                let inner = extractPlainText(from: child)
                result = result + SwiftUI.Text(inner).italic()
            } else if let code = child as? InlineCode {
                result = result + SwiftUI.Text(code.code).font(theme.codeFont)
            } else if let plain = child as? any PlainTextConvertibleMarkup {
                result = result + SwiftUI.Text(plain.plainText)
            }
        }
        return result.font(theme.bodyFont)
    }

    /// Extracts plain text from markup.
    private func extractPlainText(from markup: any Markup) -> String {
        if let plain = markup as? any PlainTextConvertibleMarkup {
            return plain.plainText
        }
        return markup.children.map { extractPlainText(from: $0) }.joined()
    }

    /// The resolved URL from the link destination.
    private var resolvedURL: URL? {
        guard let destination = link.destination else { return nil }

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
