// MermaidView.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI
import WebKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// A view that renders Mermaid diagrams using a WebView.
///
/// When the `.mermaid` feature is enabled, code blocks with language "mermaid"
/// are rendered using this view, which embeds the Mermaid.js library.
struct MermaidView: View {

    let code: String
    let theme: MarkdownTheme

    @State private var height: CGFloat = 200

    var body: some View {
        MermaidWebView(code: code, height: $height)
            .frame(height: height)
            .background(theme.codeBackgroundColor)
            .cornerRadius(8)
    }
}

// MARK: - Platform-Specific WebView

#if canImport(UIKit)

/// UIKit implementation of the Mermaid WebView.
struct MermaidWebView: UIViewRepresentable {

    let code: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(for: code)
        webView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MermaidWebView

        init(_ parent: MermaidWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Get the content height after rendering
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self?.parent.height = max(height, 100)
                    }
                }
            }
        }
    }
}

#elseif canImport(AppKit)

/// AppKit implementation of the Mermaid WebView.
struct MermaidWebView: NSViewRepresentable {

    let code: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(for: code)
        webView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MermaidWebView

        init(_ parent: MermaidWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Get the content height after rendering
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self?.parent.height = max(height, 100)
                    }
                }
            }
        }
    }
}

#endif

// MARK: - HTML Generation

/// Generates the HTML document for rendering a Mermaid diagram.
private func generateHTML(for code: String) -> String {
    // Escape the code for use in HTML/JavaScript
    let escapedCode = code
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "`", with: "\\`")
        .replacingOccurrences(of: "$", with: "\\$")

    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                display: flex;
                justify-content: center;
                align-items: flex-start;
                padding: 16px;
                background: transparent;
            }
            .mermaid {
                max-width: 100%;
            }
            .mermaid svg {
                max-width: 100%;
                height: auto;
            }
        </style>
    </head>
    <body>
        <div class="mermaid">
        \(escapedCode)
        </div>
        <script>
            mermaid.initialize({
                startOnLoad: true,
                theme: 'neutral',
                securityLevel: 'loose',
                flowchart: {
                    useMaxWidth: true,
                    htmlLabels: true
                }
            });
        </script>
    </body>
    </html>
    """
}

/// A placeholder view shown when mermaid is disabled.
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
