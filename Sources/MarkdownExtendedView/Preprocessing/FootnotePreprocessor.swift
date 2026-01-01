// FootnotePreprocessor.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import Foundation

/// Result of footnote preprocessing.
public struct FootnoteProcessingResult: Sendable {

    /// The processed markdown with footnotes transformed.
    public let processedMarkdown: String

    /// Whether any footnotes were found.
    public let hasFootnotes: Bool

    /// The number of footnotes found.
    public let footnoteCount: Int

    /// Map of footnote identifiers to their content.
    public let footnotes: [String: String]

    /// Ordered list of footnote identifiers as they appear in text.
    public let orderedReferences: [String]
}

/// Pre-processes markdown to handle footnote syntax.
///
/// Since swift-markdown doesn't expose footnote nodes from cmark-gfm,
/// this preprocessor handles footnote syntax by:
/// 1. Extracting footnote definitions (`[^id]: content`)
/// 2. Replacing inline references (`[^id]`) with superscript numbers
/// 3. Appending a footnotes section at the end
///
/// ## Usage
///
/// ```swift
/// let preprocessor = FootnotePreprocessor()
/// let result = preprocessor.process(markdownString)
/// // Use result.processedMarkdown with swift-markdown parser
/// ```
public struct FootnotePreprocessor: Sendable {

    /// Superscript digits for footnote numbers.
    private static let superscriptDigits: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
    ]

    public init() {}

    /// Processes markdown text and handles footnote syntax.
    ///
    /// - Parameter markdown: The original markdown text.
    /// - Returns: Processing result with transformed markdown and footnote data.
    public func process(_ markdown: String) -> FootnoteProcessingResult {
        // Step 1: Find all code blocks to exclude them from processing
        let codeBlockRanges = findCodeBlockRanges(in: markdown)

        // Step 2: Extract footnote definitions
        let (definitionStripped, definitions) = extractDefinitions(
            from: markdown,
            excludingRanges: codeBlockRanges
        )

        // Step 3: Find and replace inline references
        let (processed, orderedRefs) = replaceReferences(
            in: definitionStripped,
            definitions: definitions,
            excludingRanges: findCodeBlockRanges(in: definitionStripped)
        )

        // Step 4: If we have footnotes, append the footnotes section
        guard !orderedRefs.isEmpty else {
            return FootnoteProcessingResult(
                processedMarkdown: markdown,
                hasFootnotes: false,
                footnoteCount: 0,
                footnotes: definitions,
                orderedReferences: []
            )
        }

        let footnotesSection = buildFootnotesSection(
            orderedRefs: orderedRefs,
            definitions: definitions
        )

        let finalMarkdown = processed.trimmingCharacters(in: .whitespacesAndNewlines)
            + "\n\n" + footnotesSection

        return FootnoteProcessingResult(
            processedMarkdown: finalMarkdown,
            hasFootnotes: true,
            footnoteCount: orderedRefs.count,
            footnotes: definitions,
            orderedReferences: orderedRefs
        )
    }

    // MARK: - Private Methods

    /// Finds ranges of code blocks to exclude from footnote processing.
    private func findCodeBlockRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []

        // Match fenced code blocks (``` or ~~~)
        let fencedPattern = #"(?m)^(`{3,}|~{3,}).*$[\s\S]*?^\1\s*$"#
        if let regex = try? NSRegularExpression(pattern: fencedPattern, options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)
            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        }

        // Match indented code blocks (4 spaces or tab at start of line)
        let indentedPattern = #"(?m)^(?: {4}|\t).+$"#
        if let regex = try? NSRegularExpression(pattern: indentedPattern, options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)
            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        }

        return ranges
    }

    /// Checks if an index is within any of the excluded ranges.
    private func isInExcludedRange(_ index: String.Index, ranges: [Range<String.Index>]) -> Bool {
        for range in ranges {
            if range.contains(index) {
                return true
            }
        }
        return false
    }

    /// Extracts footnote definitions from markdown.
    private func extractDefinitions(
        from markdown: String,
        excludingRanges: [Range<String.Index>]
    ) -> (strippedMarkdown: String, definitions: [String: String]) {
        var definitions: [String: String] = [:]
        var strippedLines: [String] = []
        let lines = markdown.components(separatedBy: "\n")

        // Pattern for footnote definition: [^id]: content
        let definitionPattern = #"^\[\^([^\]]+)\]:\s*(.*)$"#
        let definitionRegex = try? NSRegularExpression(pattern: definitionPattern, options: [])

        var currentFootnoteId: String?
        var currentFootnoteContent: [String] = []

        for (lineIndex, line) in lines.enumerated() {
            // Calculate approximate position to check exclusion
            let lineStart = lines[0..<lineIndex].joined(separator: "\n").count
            let approximateIndex = markdown.index(
                markdown.startIndex,
                offsetBy: min(lineStart, markdown.count - 1),
                limitedBy: markdown.endIndex
            ) ?? markdown.startIndex

            // Skip lines in code blocks
            if isInExcludedRange(approximateIndex, ranges: excludingRanges) {
                if let id = currentFootnoteId {
                    definitions[id] = currentFootnoteContent.joined(separator: " ")
                    currentFootnoteId = nil
                    currentFootnoteContent = []
                }
                strippedLines.append(line)
                continue
            }

            // Check for footnote definition start
            if let regex = definitionRegex,
               let match = regex.firstMatch(
                   in: line,
                   options: [],
                   range: NSRange(line.startIndex..., in: line)
               ) {
                // Save previous footnote if any
                if let id = currentFootnoteId {
                    definitions[id] = currentFootnoteContent.joined(separator: " ")
                }

                // Start new footnote
                if let idRange = Range(match.range(at: 1), in: line),
                   let contentRange = Range(match.range(at: 2), in: line) {
                    currentFootnoteId = String(line[idRange])
                    currentFootnoteContent = [String(line[contentRange]).trimmingCharacters(in: .whitespaces)]
                }
                continue // Don't add definition line to output
            }

            // Check for continuation of multi-line footnote (indented lines)
            if currentFootnoteId != nil && (line.hasPrefix("    ") || line.hasPrefix("\t")) {
                let content = line.trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    currentFootnoteContent.append(content)
                }
                continue // Don't add continuation line to output
            }

            // End of footnote if we hit a non-continuation line
            if let id = currentFootnoteId {
                definitions[id] = currentFootnoteContent.joined(separator: " ")
                currentFootnoteId = nil
                currentFootnoteContent = []
            }

            strippedLines.append(line)
        }

        // Handle final footnote
        if let id = currentFootnoteId {
            definitions[id] = currentFootnoteContent.joined(separator: " ")
        }

        return (strippedLines.joined(separator: "\n"), definitions)
    }

    /// Replaces footnote references with superscript numbers.
    private func replaceReferences(
        in markdown: String,
        definitions: [String: String],
        excludingRanges: [Range<String.Index>]
    ) -> (processedMarkdown: String, orderedReferences: [String]) {
        var orderedRefs: [String] = []
        var refToNumber: [String: Int] = [:]
        var result = markdown

        // Pattern for inline footnote reference: [^id]
        // But NOT followed by : (which would be a definition)
        let referencePattern = #"\[\^([^\]]+)\](?!:)"#
        guard let regex = try? NSRegularExpression(pattern: referencePattern, options: []) else {
            return (markdown, [])
        }

        // Find all matches first
        var matches: [(range: Range<String.Index>, id: String)] = []
        let nsRange = NSRange(result.startIndex..., in: result)

        regex.enumerateMatches(in: result, options: [], range: nsRange) { match, _, _ in
            guard let match = match,
                  let fullRange = Range(match.range, in: result),
                  let idRange = Range(match.range(at: 1), in: result) else {
                return
            }

            // Check if this match is in an excluded range
            if isInExcludedRange(fullRange.lowerBound, ranges: excludingRanges) {
                return
            }

            let id = String(result[idRange])
            matches.append((range: fullRange, id: id))
        }

        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            let id = match.id

            // Assign number if not already assigned
            if refToNumber[id] == nil {
                orderedRefs.append(id)
                refToNumber[id] = orderedRefs.count
            }

            let number = refToNumber[id]!
            let superscript = toSuperscript(number)

            result.replaceSubrange(match.range, with: superscript)
        }

        // Return refs in order of first appearance
        return (result, orderedRefs)
    }

    /// Converts a number to superscript string.
    private func toSuperscript(_ number: Int) -> String {
        let digits = String(number)
        var result = ""
        for char in digits {
            if let superChar = Self.superscriptDigits[char] {
                result.append(superChar)
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// Builds the footnotes section to append.
    private func buildFootnotesSection(
        orderedRefs: [String],
        definitions: [String: String]
    ) -> String {
        var lines: [String] = []
        lines.append("---")
        lines.append("")

        for (index, id) in orderedRefs.enumerated() {
            let number = index + 1
            let content = definitions[id] ?? "*[undefined]*"
            lines.append("\(toSuperscript(number)) \(content)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
