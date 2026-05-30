// HighlightedCodeView.swift
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

/// A view that renders syntax-highlighted code.
///
/// This view tokenizes code using the ``SyntaxHighlighter`` and renders
/// each token with the appropriate color from the theme's ``SyntaxColors``.
struct HighlightedCodeView: View {

    let code: String
    let language: String?
    let theme: MarkdownTheme

    private let highlighter = SyntaxHighlighter()

    var body: some View {
        let tokens = highlighter.tokenize(code.trimmingCharacters(in: .newlines), language: language)
        let lines = splitIntoLines(tokens)

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, lineTokens in
                lineView(for: lineTokens)
            }
        }
    }

    @ViewBuilder
    private func lineView(for tokens: [Token]) -> some View {
        if tokens.isEmpty {
            Text(" ")
                .font(theme.codeBlockFont)
        } else {
            tokens.reduce(SwiftUI.Text("")) { result, token in
                result + SwiftUI.Text(token.text)
                    .foregroundColor(color(for: token.type))
            }
            .font(theme.codeBlockFont)
        }
    }

    private func color(for tokenType: TokenType) -> Color {
        switch tokenType {
        case .keyword:
            return theme.syntaxColors.keyword
        case .string:
            return theme.syntaxColors.string
        case .comment:
            return theme.syntaxColors.comment
        case .number:
            return theme.syntaxColors.number
        case .type:
            return theme.syntaxColors.type
        case .function:
            return theme.syntaxColors.function
        case .plain:
            return theme.syntaxColors.plain
        }
    }

    /// Splits tokens into lines, preserving token structure.
    private func splitIntoLines(_ tokens: [Token]) -> [[Token]] {
        var lines: [[Token]] = [[]]

        for token in tokens {
            let parts = token.text.components(separatedBy: "\n")
            for (index, part) in parts.enumerated() {
                if index > 0 {
                    lines.append([])
                }
                if !part.isEmpty {
                    lines[lines.count - 1].append(Token(text: part, type: token.type))
                }
            }
        }

        return lines
    }
}
