// LaTeXPreprocessor.swift
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

import Foundation

/// Handles LaTeX detection and extraction from Markdown content.
///
/// Since swift-markdown doesn't recognize LaTeX syntax ($...$ and $$...$$),
/// this preprocessor identifies LaTeX regions for special handling during rendering.
enum LaTeXPreprocessor {

    // MARK: - Public API

    /// Process content for markdown parsing.
    ///
    /// Currently returns content as-is since we handle LaTeX during rendering.
    /// This method is a hook for future preprocessing if needed.
    ///
    /// - Parameter content: The raw Markdown content.
    /// - Returns: Processed content ready for markdown parsing.
    static func process(_ content: String) -> String {
        // For now, return as-is. LaTeX is handled during text rendering.
        return content
    }

    /// Extracts LaTeX segments from a text string.
    ///
    /// Identifies both inline ($...$) and display ($$...$$) LaTeX and returns
    /// an array of segments, each marked as either text or LaTeX.
    ///
    /// - Parameter text: The text to scan for LaTeX.
    /// - Returns: Array of segments in order.
    static func extractSegments(from text: String) -> [Segment] {
        segmentsWithRanges(Array(text)).map { ranged in
            ranged.isLaTeX
                ? .latex(ranged.content, isBlock: ranged.isBlock)
                : .text(ranged.content)
        }
    }

    /// Scans a character array for LaTeX, returning ordered segments annotated
    /// with the character range they occupy in the source array.
    ///
    /// This is the single source of truth for LaTeX boundary detection. Both the
    /// string-based ``extractSegments(from:)`` and the style-preserving inline
    /// flattener build on it; the ranges let callers map segments back onto
    /// per-character styling.
    ///
    /// - Parameter characters: The source characters to scan.
    /// - Returns: Text and LaTeX segments in order. Text segments carry their
    ///   verbatim content; LaTeX segments carry the inner equation (display math
    ///   is trimmed, inline math is raw) and the full delimited range.
    static func segmentsWithRanges(_ characters: [Character]) -> [RangedSegment] {
        var segments: [RangedSegment] = []
        let count = characters.count
        var index = 0
        var textStart = 0

        func flushText(upTo end: Int) {
            guard textStart < end else { return }
            segments.append(RangedSegment(
                range: textStart..<end,
                isLaTeX: false,
                content: String(characters[textStart..<end]),
                isBlock: false
            ))
        }

        while index < count {
            if let match = findDisplayMath(characters, from: index) {
                flushText(upTo: index)
                segments.append(RangedSegment(range: index..<match.end, isLaTeX: true, content: match.content, isBlock: true))
                index = match.end
                textStart = index
                continue
            }

            if let match = findInlineMath(characters, from: index) {
                flushText(upTo: index)
                segments.append(RangedSegment(range: index..<match.end, isLaTeX: true, content: match.content, isBlock: false))
                index = match.end
                textStart = index
                continue
            }

            index += 1
        }

        flushText(upTo: count)
        return segments
    }

    /// Checks if a string contains any LaTeX.
    ///
    /// - Parameter text: The text to check.
    /// - Returns: True if the text contains LaTeX delimiters.
    static func containsLaTeX(_ text: String) -> Bool {
        text.contains("$")
    }

    // MARK: - Types

    /// A segment of text that is either plain text or LaTeX.
    enum Segment: Equatable {
        /// Plain text content.
        case text(String)
        /// LaTeX content with flag for block (display) vs inline.
        case latex(String, isBlock: Bool)
    }

    /// A segment annotated with the character range it occupies in the source.
    struct RangedSegment: Equatable {
        /// The half-open range of source character indices this segment spans
        /// (including delimiters for LaTeX segments).
        let range: Range<Int>
        /// Whether this segment is a LaTeX equation.
        let isLaTeX: Bool
        /// Text content (verbatim) or the inner equation for LaTeX segments.
        let content: String
        /// For LaTeX segments, whether it is display (block) math.
        let isBlock: Bool
    }

    // MARK: - Private Helpers

    private struct Match {
        let content: String
        let end: Int
    }

    /// Find display math ($$...$$) starting at the given character index.
    private static func findDisplayMath(_ characters: [Character], from start: Int) -> Match? {
        let count = characters.count
        guard start + 1 < count, characters[start] == "$", characters[start + 1] == "$" else { return nil }

        let contentStart = start + 2
        guard contentStart < count else { return nil }

        var search = contentStart
        while search < count {
            if characters[search] == "$", search + 1 < count, characters[search + 1] == "$" {
                let content = String(characters[contentStart..<search])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return Match(content: content, end: search + 2)
            }
            search += 1
        }

        return nil // No closing $$ found
    }

    /// Find inline math ($...$) starting at the given character index.
    /// Does not match $$ (which is display math).
    private static func findInlineMath(_ characters: [Character], from start: Int) -> Match? {
        let count = characters.count
        guard start < count, characters[start] == "$" else { return nil }

        // Must start with single $ but not $$
        if start + 1 < count, characters[start + 1] == "$" { return nil }

        let contentStart = start + 1
        guard contentStart < count else { return nil }

        // The content after $ shouldn't start with space (standard LaTeX rule)
        if characters[contentStart].isWhitespace { return nil }

        var search = contentStart
        while search < count {
            let character = characters[search]

            if character == "$" {
                // Check it's not escaped.
                if search > contentStart, characters[search - 1] == "\\" {
                    search += 1
                    continue
                }

                // Check it's not $$ (would be display math).
                if search + 1 < count, characters[search + 1] == "$" {
                    search += 1
                    continue
                }

                // Check content doesn't end with space.
                if characters[search - 1].isWhitespace {
                    search += 1
                    continue
                }

                let content = String(characters[contentStart..<search])
                if content.isEmpty {
                    search += 1
                    continue
                }

                return Match(content: content, end: search + 1)
            }

            // Don't allow newlines in inline math.
            if character.isNewline { return nil }

            search += 1
        }

        return nil // No closing $ found
    }
}
