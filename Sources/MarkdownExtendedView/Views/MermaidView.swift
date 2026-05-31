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
import WebKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// The pinned Mermaid.js asset and its Subresource Integrity hash.
///
/// Pinning to an exact, immutable version plus an SRI hash means the WebView
/// only executes the JavaScript we vetted: jsDelivr serves an immutable file for
/// a fully-qualified version, and the browser refuses to run it if its hash does
/// not match. This closes the supply-chain hole of fetching a mutable
/// `mermaid/dist/mermaid.min.js` on every render.
///
/// - Note: This is the interim hardening of the existing WebView path while a
///   native (WebView-free) renderer is developed. Bump both fields together when
///   updating; regenerate the hash with
///   `openssl dgst -sha384 -binary mermaid.min.js | openssl base64 -A`.
enum MermaidAsset {
    static let version = "11.15.0"
    static let scriptURL = "https://cdn.jsdelivr.net/npm/mermaid@\(version)/dist/mermaid.min.js"
    static let integrity = "sha384-yQ4mmBBT+vhTAwjFH0toJXNYJ6O4usWnt6EPIdWwrRvx2V/n5lXuDZQwQFeSFydF"
}

/// A view that renders Mermaid diagrams using a WebView.
///
/// When the `.mermaid` feature is enabled, code blocks with language "mermaid"
/// are rendered using this view, which embeds the Mermaid.js library. If the
/// library fails to load (e.g. offline) or the diagram fails to render, a
/// fallback with the source and a retry control is shown instead.
struct MermaidView: View {

    let code: String
    let theme: MarkdownTheme

    @State private var height: CGFloat = 200
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                MermaidFailureView(code: code, theme: theme) {
                    // Retry: switch back to the WebView, which remounts and
                    // reloads from scratch.
                    loadFailed = false
                }
            } else {
                MermaidWebView(code: code, height: $height, loadFailed: $loadFailed)
                    .frame(height: height)
            }
        }
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
    @Binding var loadFailed: Bool

    func makeCoordinator() -> MermaidWebCoordinator {
        MermaidWebCoordinator(height: $height, loadFailed: $loadFailed)
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
        context.coordinator.loadIfNeeded(code: code, into: webView)
    }
}

#elseif canImport(AppKit)

/// AppKit implementation of the Mermaid WebView.
struct MermaidWebView: NSViewRepresentable {

    let code: String
    @Binding var height: CGFloat
    @Binding var loadFailed: Bool

    func makeCoordinator() -> MermaidWebCoordinator {
        MermaidWebCoordinator(height: $height, loadFailed: $loadFailed)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.loadIfNeeded(code: code, into: webView)
    }
}

#endif

// MARK: - Coordinator

/// Shared navigation delegate for the Mermaid WebView across UIKit and AppKit.
///
/// Responsibilities:
/// - Reloads the document only when the diagram source changes (avoids a full
///   HTML reload on every SwiftUI update).
/// - Restricts navigation to the initial in-memory load so untrusted diagram
///   content cannot pivot the WebView elsewhere.
/// - Detects load/render failures (offline, blocked script, parse error) and
///   reports them so the SwiftUI layer can show a retry fallback.
final class MermaidWebCoordinator: NSObject, WKNavigationDelegate {

    private let height: Binding<CGFloat>
    private let loadFailed: Binding<Bool>
    private var lastLoadedCode: String?
    private var pollAttempts = 0

    /// Maximum number of 100 ms polls (~2 s) to wait for Mermaid to finish.
    private static let maxPollAttempts = 20

    init(height: Binding<CGFloat>, loadFailed: Binding<Bool>) {
        self.height = height
        self.loadFailed = loadFailed
    }

    /// Loads the document only if the source changed since the last load.
    func loadIfNeeded(code: String, into webView: WKWebView) {
        guard code != lastLoadedCode else { return }
        lastLoadedCode = code
        pollAttempts = 0
        webView.loadHTMLString(generateHTML(for: code), baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pollAttempts = 0
        pollRenderState(in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reportFailure()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        reportFailure()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Allow only the initial in-memory document load (.other). Cancel link
        // activations, form submissions, and any other navigation so untrusted
        // diagram content cannot pivot the WebView elsewhere.
        decisionHandler(navigationAction.navigationType == .other ? .allow : .cancel)
    }

    /// Polls the page for the render status flag set by the injected script.
    ///
    /// Mermaid renders asynchronously, so `didFinish` fires before the SVG
    /// exists. The injected script tags `document.body` with `data-mermaid`
    /// = `ok` / `error`; if the external script never loaded (offline) the
    /// attribute stays absent and we time out into the failure state.
    private func pollRenderState(in webView: WKWebView) {
        let javaScript = """
        (function() {
            var state = document.body.getAttribute('data-mermaid');
            if (state === 'ok') { return document.body.scrollHeight; }
            if (state === 'error') { return -2; }
            return -1;
        })();
        """
        webView.evaluateJavaScript(javaScript) { [weak self, weak webView] result, _ in
            guard let self = self else { return }
            let value = (result as? NSNumber)?.doubleValue ?? -1

            if value >= 0 {
                self.loadFailed.wrappedValue = false
                self.height.wrappedValue = max(CGFloat(value), 100)
                return
            }

            if value == -2 {
                self.reportFailure()
                return
            }

            // Still pending: poll again until the timeout.
            self.pollAttempts += 1
            guard self.pollAttempts < Self.maxPollAttempts, let webView = webView else {
                self.reportFailure()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak webView] in
                guard let webView = webView else { return }
                self.pollRenderState(in: webView)
            }
        }
    }

    private func reportFailure() {
        // Allow the next update (e.g. a retry remount or source change) to reload.
        lastLoadedCode = nil
        loadFailed.wrappedValue = true
    }
}

// MARK: - HTML Generation

/// Generates the HTML document for rendering a Mermaid diagram.
///
/// The diagram source is HTML-escaped and rendered with Mermaid's `strict`
/// security level so that untrusted Markdown cannot inject executable markup
/// into the WebView. A Content-Security-Policy restricts the page to the pinned
/// Mermaid script and inline styles, blocking arbitrary network access. The
/// pinned script is loaded with a Subresource Integrity hash.
func generateHTML(for code: String) -> String {
    // HTML-escape the diagram source so it is treated as text content, not
    // markup. Mermaid reads the element's text, so escaping `&`, `<`, and `>`
    // preserves the diagram while preventing raw `<script>`/HTML injection.
    // `&` must be replaced first to avoid double-escaping the entities below.
    let escapedCode = code
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")

    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'unsafe-inline'; img-src data: blob:; font-src data:;">
        <script src="\(MermaidAsset.scriptURL)" integrity="\(MermaidAsset.integrity)" crossorigin="anonymous"></script>
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
            // Render explicitly so success/failure can be signalled back to the
            // native layer via a body attribute. If the pinned external script
            // failed to load (offline / SRI mismatch), `mermaid` is undefined and
            // this throws, leaving the attribute absent — detected as a timeout.
            try {
                mermaid.initialize({
                    startOnLoad: false,
                    theme: 'neutral',
                    securityLevel: 'strict',
                    flowchart: {
                        useMaxWidth: true,
                        htmlLabels: false
                    }
                });
                mermaid.run({ querySelector: '.mermaid' })
                    .then(function() { document.body.setAttribute('data-mermaid', 'ok'); })
                    .catch(function() { document.body.setAttribute('data-mermaid', 'error'); });
            } catch (error) {
                document.body.setAttribute('data-mermaid', 'error');
            }
        </script>
    </body>
    </html>
    """
}

// MARK: - Failure Fallback

/// Shown when the Mermaid diagram cannot be rendered (offline, blocked script,
/// or a parse error). Displays the source and offers a retry.
struct MermaidFailureView: View {

    let code: String
    let theme: MarkdownTheme
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(theme.secondaryTextColor)
                Text("Couldn't render diagram")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(theme.bodyFont)
                }
                .buttonStyle(.borderless)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .newlines))
                    .font(theme.codeBlockFont)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding(theme.codeBlockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
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
