// LaTeXPreprocessor.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

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
        var segments: [Segment] = []
        var currentIndex = text.startIndex
        var textBuffer = ""

        while currentIndex < text.endIndex {
            // Check for display math ($$...$$) first
            if let displayMatch = findDisplayMath(in: text, from: currentIndex) {
                // Flush text buffer
                if !textBuffer.isEmpty {
                    segments.append(.text(textBuffer))
                    textBuffer = ""
                }
                segments.append(.latex(displayMatch.content, isBlock: true))
                currentIndex = displayMatch.endIndex
                continue
            }

            // Check for inline math ($...$)
            if let inlineMatch = findInlineMath(in: text, from: currentIndex) {
                // Flush text buffer
                if !textBuffer.isEmpty {
                    segments.append(.text(textBuffer))
                    textBuffer = ""
                }
                segments.append(.latex(inlineMatch.content, isBlock: false))
                currentIndex = inlineMatch.endIndex
                continue
            }

            // Regular character - add to buffer
            textBuffer.append(text[currentIndex])
            currentIndex = text.index(after: currentIndex)
        }

        // Flush remaining text buffer
        if !textBuffer.isEmpty {
            segments.append(.text(textBuffer))
        }

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

    // MARK: - Private Helpers

    private struct Match {
        let content: String
        let endIndex: String.Index
    }

    /// Find display math ($$...$$) starting at the given index.
    private static func findDisplayMath(in text: String, from startIndex: String.Index) -> Match? {
        // Check if we have "$$" at current position
        guard startIndex < text.endIndex else { return nil }
        let remaining = text[startIndex...]

        guard remaining.hasPrefix("$$") else { return nil }

        // Find closing "$$"
        let contentStart = text.index(startIndex, offsetBy: 2)
        guard contentStart < text.endIndex else { return nil }

        // Search for closing $$
        var searchIndex = contentStart
        while searchIndex < text.endIndex {
            let searchRemaining = text[searchIndex...]
            if searchRemaining.hasPrefix("$$") {
                let content = String(text[contentStart..<searchIndex])
                let endIndex = text.index(searchIndex, offsetBy: 2)
                return Match(content: content.trimmingCharacters(in: .whitespacesAndNewlines), endIndex: endIndex)
            }
            searchIndex = text.index(after: searchIndex)
        }

        return nil // No closing $$ found
    }

    /// Find inline math ($...$) starting at the given index.
    /// Does not match $$ (which is display math).
    private static func findInlineMath(in text: String, from startIndex: String.Index) -> Match? {
        // Check if we have "$" at current position (but not "$$")
        guard startIndex < text.endIndex else { return nil }
        let remaining = text[startIndex...]

        // Must start with single $ but not $$
        guard remaining.hasPrefix("$") && !remaining.hasPrefix("$$") else { return nil }

        // Find closing "$" (not "$$")
        let contentStart = text.index(after: startIndex)
        guard contentStart < text.endIndex else { return nil }

        // The content after $ shouldn't start with space (standard LaTeX rule)
        if text[contentStart].isWhitespace { return nil }

        // Search for closing $
        var searchIndex = contentStart
        while searchIndex < text.endIndex {
            let char = text[searchIndex]

            // Check for closing $ (not preceded by \ and not followed by another $)
            if char == "$" {
                // Check it's not escaped
                if searchIndex > contentStart {
                    let prevIndex = text.index(before: searchIndex)
                    if text[prevIndex] == "\\" {
                        searchIndex = text.index(after: searchIndex)
                        continue
                    }
                }

                // Check it's not $$ (would be display math)
                let nextIndex = text.index(after: searchIndex)
                if nextIndex < text.endIndex && text[nextIndex] == "$" {
                    searchIndex = text.index(after: searchIndex)
                    continue
                }

                // Check content doesn't end with space
                let prevIndex = text.index(before: searchIndex)
                if text[prevIndex].isWhitespace {
                    searchIndex = text.index(after: searchIndex)
                    continue
                }

                let content = String(text[contentStart..<searchIndex])
                // Don't match empty content
                if content.isEmpty {
                    searchIndex = text.index(after: searchIndex)
                    continue
                }

                return Match(content: content, endIndex: nextIndex)
            }

            // Don't allow newlines in inline math
            if char.isNewline {
                return nil
            }

            searchIndex = text.index(after: searchIndex)
        }

        return nil // No closing $ found
    }
}
