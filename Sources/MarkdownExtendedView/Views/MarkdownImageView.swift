// MarkdownImageView.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI
import Markdown

/// A view that displays an image from a markdown Image node.
///
/// When the `.images` feature is enabled, this view loads and displays
/// images using AsyncImage. When disabled, it shows the alt text.
struct MarkdownImageView: View {

    let image: Markdown.Image
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
                        .accessibilityLabel(image.plainText)

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
        Text("[\(image.plainText)]")
            .font(theme.bodyFont)
            .foregroundColor(theme.secondaryTextColor)
    }

    /// Error placeholder when image fails to load.
    private var errorPlaceholder: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(theme.secondaryTextColor)
            if !image.plainText.isEmpty {
                Text(image.plainText)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(theme.codeBackgroundColor.opacity(0.5))
        .cornerRadius(8)
    }

    /// Resolves the image URL from the source string.
    private var resolvedURL: URL? {
        guard let source = image.source else { return nil }

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
