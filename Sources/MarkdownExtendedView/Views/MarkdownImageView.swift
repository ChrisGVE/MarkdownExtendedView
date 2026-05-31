// MarkdownImageView.swift
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

/// A view that displays an image from a markdown Image node.
///
/// When the `.images` feature is enabled, this view loads and displays
/// images using AsyncImage. When disabled, it shows the alt text.
struct MarkdownImageView: View {

    /// The raw image source URL string from the markdown.
    let source: String?
    /// The image alt text.
    let altText: String
    let theme: MarkdownTheme
    let baseURL: URL?

    @Environment(\.markdownFeatures) private var features

    var body: some View {
        if features.contains(.images), let url = resolvedURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)

                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityLabel(altText)

                case .failure:
                    errorPlaceholder

                @unknown default:
                    errorPlaceholder
                }
            }
        } else {
            altTextView
        }
    }

    /// The alt text fallback when images are disabled or unavailable.
    private var altTextView: some View {
        Text("[\(altText)]")
            .font(theme.bodyFont)
            .foregroundColor(theme.secondaryTextColor)
            .accessibilityLabel(altText.isEmpty ? "Image" : "Image: \(altText)")
    }

    /// Error placeholder when image fails to load.
    private var errorPlaceholder: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(theme.secondaryTextColor)
            if !altText.isEmpty {
                Text(altText)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(theme.codeBackgroundColor.opacity(0.5))
        .cornerRadius(8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(altText.isEmpty ? "Image failed to load" : "Image failed to load: \(altText)")
    }

    /// Resolves the image URL from the source string.
    private var resolvedURL: URL? {
        guard let source = source else { return nil }

        // Try to create URL directly
        if let url = URL(string: source) {
            // If it's a relative URL and we have a base URL, resolve it
            if url.scheme == nil, let base = baseURL {
                return URL(string: source, relativeTo: base)?.absoluteURL
            }
            return url
        }

        return nil
    }
}
