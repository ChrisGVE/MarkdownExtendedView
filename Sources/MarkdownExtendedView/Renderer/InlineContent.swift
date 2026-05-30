// InlineContent.swift
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

/// Visual style carried by an inline text run.
///
/// Styles accumulate as the flattener descends through nested markup, so a run
/// inside `**_bold italic_**` carries both `isBold` and `isItalic`.
struct InlineStyle: Equatable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isStrikethrough: Bool = false
    var isCode: Bool = false
}

/// A flattened, render-ready piece of inline content.
///
/// The flattener turns the recursive swift-markdown inline tree into a flat,
/// value-typed list of fragments. This makes inline rendering testable (the
/// SwiftUI view tree is opaque) and lets a single render path handle styled
/// text, LaTeX, links, and images simultaneously — instead of the previous
/// mutually-exclusive LaTeX / links / images paths that dropped styling.
enum InlineFragment: Equatable {
    /// Plain text with an accumulated style.
    case text(String, InlineStyle)
    /// A LaTeX equation (inline or display).
    case latex(String, isBlock: Bool)
    /// An image with its source URL string and alt text.
    case image(source: String?, alt: String)
    /// A link with its destination and the (already flattened) styled content.
    case link(destination: String?, content: [InlineFragment])
    /// A soft line break (rendered as a space).
    case softBreak
    /// A hard line break (rendered as a newline).
    case lineBreak
}

// MARK: - Flattener

/// Flattens a swift-markdown inline tree into `[InlineFragment]`.
///
/// LaTeX is detected at the character level across adjacent text runs, so math
/// that markdown split into multiple nodes (e.g. `$a_1 + a_2$`, where the
/// underscores form an emphasis span) is still recognised as a single equation
/// while the surrounding text keeps its bold / italic / code styling.
enum InlineFlattener {

    /// Produces the flattened fragments for the inline children of `parent`.
    static func fragments(for parent: any Markup) -> [InlineFragment] {
        var pieces: [RawPiece] = []
        for child in parent.children {
            flatten(child, style: InlineStyle(), into: &pieces)
        }
        return resolveMath(pieces)
    }

    // MARK: Intermediate representation

    /// A raw piece before LaTeX resolution. Text pieces are math-scannable and
    /// get merged across boundaries; everything else is opaque to the scanner.
    private enum RawPiece {
        case text(String, InlineStyle)
        case code(String, InlineStyle)
        case image(source: String?, alt: String)
        case link(destination: String?, content: [InlineFragment])
        case softBreak
        case lineBreak
    }

    // MARK: Recursive flatten

    private static func flatten(_ markup: any Markup, style: InlineStyle, into pieces: inout [RawPiece]) {
        switch markup {
        case let text as Markdown.Text:
            pieces.append(.text(text.string, style))

        case let strong as Strong:
            var inner = style
            inner.isBold = true
            for child in strong.children { flatten(child, style: inner, into: &pieces) }

        case let emphasis as Emphasis:
            var inner = style
            inner.isItalic = true
            for child in emphasis.children { flatten(child, style: inner, into: &pieces) }

        case let strikethrough as Strikethrough:
            var inner = style
            inner.isStrikethrough = true
            for child in strikethrough.children { flatten(child, style: inner, into: &pieces) }

        case let code as InlineCode:
            var inner = style
            inner.isCode = true
            pieces.append(.code(code.code, inner))

        case let link as Markdown.Link:
            // Resolve the link's own children independently so the link is a
            // single, self-contained flow item.
            var childPieces: [RawPiece] = []
            for child in link.children { flatten(child, style: style, into: &childPieces) }
            pieces.append(.link(destination: link.destination, content: resolveMath(childPieces)))

        case let image as Markdown.Image:
            pieces.append(.image(source: image.source, alt: image.plainText))

        case is SoftBreak:
            pieces.append(.softBreak)

        case is LineBreak:
            pieces.append(.lineBreak)

        default:
            // Unknown inline container: descend preserving the current style.
            if markup.childCount > 0 {
                for child in markup.children { flatten(child, style: style, into: &pieces) }
            } else if let plain = markup as? any PlainTextConvertibleMarkup {
                pieces.append(.text(plain.plainText, style))
            }
        }
    }

    // MARK: LaTeX resolution

    /// Merges adjacent text pieces, scans them for LaTeX, and emits the final
    /// fragment list. Non-text pieces flush the pending text buffer so math is
    /// never scanned across a link / image / code / break boundary.
    private static func resolveMath(_ pieces: [RawPiece]) -> [InlineFragment] {
        var out: [InlineFragment] = []
        var buffer: [(Character, InlineStyle)] = []

        func flush() {
            guard !buffer.isEmpty else { return }
            out.append(contentsOf: scanMath(buffer))
            buffer.removeAll(keepingCapacity: true)
        }

        for piece in pieces {
            switch piece {
            case .text(let string, let style):
                for character in string { buffer.append((character, style)) }
            case .code(let string, let style):
                flush()
                out.append(.text(string, style))
            case .image(let source, let alt):
                flush()
                out.append(.image(source: source, alt: alt))
            case .link(let destination, let content):
                flush()
                out.append(.link(destination: destination, content: content))
            case .softBreak:
                flush()
                out.append(.softBreak)
            case .lineBreak:
                flush()
                out.append(.lineBreak)
            }
        }
        flush()
        return out
    }

    /// Scans one contiguous styled-text buffer for LaTeX, preserving styling on
    /// the surrounding text runs.
    private static func scanMath(_ buffer: [(Character, InlineStyle)]) -> [InlineFragment] {
        let characters = buffer.map { $0.0 }
        let segments = LaTeXPreprocessor.segmentsWithRanges(characters)
        var out: [InlineFragment] = []
        for segment in segments {
            if segment.isLaTeX {
                out.append(.latex(segment.content, isBlock: segment.isBlock))
            } else {
                appendStyledText(buffer, range: segment.range, into: &out)
            }
        }
        return out
    }

    /// Splits a text range into runs of equal style, emitting one `.text`
    /// fragment per run.
    private static func appendStyledText(_ buffer: [(Character, InlineStyle)], range: Range<Int>, into out: inout [InlineFragment]) {
        guard !range.isEmpty else { return }
        var runStart = range.lowerBound
        var index = range.lowerBound + 1
        while index < range.upperBound {
            if buffer[index].1 != buffer[runStart].1 {
                out.append(.text(string(buffer, runStart, index), buffer[runStart].1))
                runStart = index
            }
            index += 1
        }
        out.append(.text(string(buffer, runStart, range.upperBound), buffer[runStart].1))
    }

    private static func string(_ buffer: [(Character, InlineStyle)], _ start: Int, _ end: Int) -> String {
        String(buffer[start..<end].map { $0.0 })
    }
}

// MARK: - Text rendering

/// Builds a single concatenated `SwiftUI.Text` from inline fragments.
///
/// Used both for the plain-text render path (no LaTeX / images / enabled links)
/// and for the coalesced runs inside the flow layout, as well as for link
/// content inside ``TappableLinkView``.
enum InlineTextRenderer {

    /// Concatenates `fragments` into one `Text`.
    static func text(_ fragments: [InlineFragment], theme: MarkdownTheme) -> SwiftUI.Text {
        fragments.reduce(SwiftUI.Text("")) { $0 + text(for: $1, theme: theme) }
    }

    /// Renders a single fragment to `Text`. Atoms that need a real view
    /// (LaTeX, images, enabled links) are handled by the caller; here they fall
    /// back to a textual representation.
    static func text(for fragment: InlineFragment, theme: MarkdownTheme) -> SwiftUI.Text {
        switch fragment {
        case .text(let string, let style):
            return styled(string, style, theme: theme)
        case .latex(let latex, _):
            return SwiftUI.Text(latex).font(theme.codeFont)
        case .image(_, let alt):
            return SwiftUI.Text("[\(alt)]").foregroundColor(theme.secondaryTextColor)
        case .link(_, let content):
            return text(content, theme: theme).foregroundColor(theme.linkColor)
        case .softBreak:
            return SwiftUI.Text(" ")
        case .lineBreak:
            return SwiftUI.Text("\n")
        }
    }

    /// Applies an ``InlineStyle`` to a string. Font and colour for plain runs are
    /// inherited from the surrounding context; only code runs override the font.
    static func styled(_ string: String, _ style: InlineStyle, theme: MarkdownTheme) -> SwiftUI.Text {
        var text = SwiftUI.Text(string)
        if style.isCode { text = text.font(theme.codeFont) }
        if style.isBold { text = text.bold() }
        if style.isItalic { text = text.italic() }
        if style.isStrikethrough { text = text.strikethrough() }
        return text
    }
}
