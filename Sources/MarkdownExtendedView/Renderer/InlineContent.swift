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

import Foundation
import SwiftUI
import Markdown

/// Visual style carried by an inline text run.
///
/// Styles accumulate as the flattener descends through nested markup, so a run
/// inside `**_bold italic_**` carries both `isBold` and `isItalic`. The
/// underline / highlight / baseline fields additionally carry the supported
/// inline-HTML subset (`<u>`, `<mark>`, `<sub>`, `<sup>`, …).
struct InlineStyle: Equatable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isStrikethrough: Bool = false
    var isCode: Bool = false
    var isUnderline: Bool = false
    var isHighlight: Bool = false
    var baseline: Baseline = .normal

    /// Vertical baseline shift for `<sub>` / `<sup>`.
    enum Baseline: Equatable {
        case normal
        case sub
        case sup
    }
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
        fragments(forChildren: Array(parent.children))
    }

    /// Produces the flattened fragments for an explicit list of inline siblings.
    ///
    /// Used when rendering a slice of a paragraph's inline children (e.g. a single
    /// line of a definition list) without a wrapping markup node.
    static func fragments(forChildren children: [any Markup]) -> [InlineFragment] {
        var pieces: [RawPiece] = []
        flattenSequence(children, baseStyle: InlineStyle(), into: &pieces)
        return resolveMath(pieces)
    }

    // MARK: Inline HTML

    /// A formatting effect contributed by a supported inline-HTML tag.
    private enum HTMLEffect: Equatable {
        case bold, italic, underline, strikethrough, code, highlight, sub, sup
    }

    /// Walks a sibling sequence, threading an inline-HTML tag stack so paired
    /// tags (`<b>`…`</b>`) style the text between them. Tags are flat siblings
    /// of the text they wrap in swift-markdown, not parents.
    private static func flattenSequence(_ markups: [any Markup], baseStyle: InlineStyle, into pieces: inout [RawPiece]) {
        var stack: [HTMLEffect] = []
        for markup in markups {
            if let inlineHTML = markup as? InlineHTML {
                applyInlineHTMLTag(inlineHTML.rawHTML, stack: &stack, into: &pieces)
            } else {
                flatten(markup, style: style(baseStyle, applying: stack), into: &pieces)
            }
        }
    }

    /// Folds the active inline-HTML effects onto a base style.
    private static func style(_ base: InlineStyle, applying stack: [HTMLEffect]) -> InlineStyle {
        var style = base
        for effect in stack {
            switch effect {
            case .bold: style.isBold = true
            case .italic: style.isItalic = true
            case .underline: style.isUnderline = true
            case .strikethrough: style.isStrikethrough = true
            case .code: style.isCode = true
            case .highlight: style.isHighlight = true
            case .sub: style.baseline = .sub
            case .sup: style.baseline = .sup
            }
        }
        return style
    }

    /// Interprets a single inline-HTML tag. Recognised formatting tags push/pop
    /// the effect stack, `<br>` emits a line break, and unknown or unsafe tags
    /// (`<script>`, `<span>`, …) are dropped — their text content still renders
    /// unstyled, and nothing is ever executed (output is native SwiftUI text).
    private static func applyInlineHTMLTag(_ rawHTML: String, stack: inout [HTMLEffect], into pieces: inout [RawPiece]) {
        guard let tag = parseTag(rawHTML) else { return }

        if tag.name == "br" {
            pieces.append(.lineBreak)
            return
        }
        if tag.name == "wbr" { return }

        guard let effect = effect(for: tag.name) else { return }

        if tag.isClosing {
            if let index = stack.lastIndex(of: effect) { stack.remove(at: index) }
        } else if !tag.isSelfClosing {
            stack.append(effect)
        }
    }

    /// Maps a tag name to its formatting effect, or `nil` if unsupported.
    private static func effect(for name: String) -> HTMLEffect? {
        switch name {
        case "b", "strong": return .bold
        case "i", "em": return .italic
        case "u", "ins": return .underline
        case "s", "strike", "del": return .strikethrough
        case "code", "kbd", "samp", "tt": return .code
        case "mark": return .highlight
        case "sub": return .sub
        case "sup": return .sup
        default: return nil
        }
    }

    /// Parses a tag token into its lowercased name and open/close/self-close form.
    private static func parseTag(_ rawHTML: String) -> (name: String, isClosing: Bool, isSelfClosing: Bool)? {
        var inner = rawHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inner.hasPrefix("<"), inner.hasSuffix(">") else { return nil }
        inner = String(inner.dropFirst().dropLast())

        var isClosing = false
        if inner.hasPrefix("/") {
            isClosing = true
            inner = String(inner.dropFirst())
        }

        var isSelfClosing = false
        if inner.hasSuffix("/") {
            isSelfClosing = true
            inner = String(inner.dropLast())
        }

        let name = inner.prefix { $0.isLetter || $0.isNumber }.lowercased()
        guard !name.isEmpty else { return nil }
        return (name, isClosing, isSelfClosing)
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
            flattenSequence(Array(strong.children), baseStyle: inner, into: &pieces)

        case let emphasis as Emphasis:
            var inner = style
            inner.isItalic = true
            flattenSequence(Array(emphasis.children), baseStyle: inner, into: &pieces)

        case let strikethrough as Strikethrough:
            var inner = style
            inner.isStrikethrough = true
            flattenSequence(Array(strikethrough.children), baseStyle: inner, into: &pieces)

        case let code as InlineCode:
            var inner = style
            inner.isCode = true
            pieces.append(.code(code.code, inner))

        case let link as Markdown.Link:
            // Resolve the link's own children independently so the link is a
            // single, self-contained flow item.
            var childPieces: [RawPiece] = []
            flattenSequence(Array(link.children), baseStyle: style, into: &childPieces)
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
                flattenSequence(Array(markup.children), baseStyle: style, into: &pieces)
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
        // `<mark>` needs a per-run background, which Text modifiers cannot express
        // through concatenation, so build that run from an AttributedString.
        if style.isHighlight {
            return highlightedText(string, style, theme: theme)
        }

        var text = SwiftUI.Text(string)
        if style.isCode { text = text.font(theme.codeFont) }
        if style.isBold { text = text.bold() }
        if style.isItalic { text = text.italic() }
        if style.isStrikethrough { text = text.strikethrough(true, color: theme.strikethroughColor) }
        if style.isUnderline { text = text.underline() }
        switch style.baseline {
        case .normal: break
        case .sub: text = text.baselineOffset(-3)
        case .sup: text = text.baselineOffset(5)
        }
        return text
    }

    /// Builds a highlighted (`<mark>`) run via AttributedString so a background
    /// colour can be applied alongside the other inline traits.
    private static func highlightedText(_ string: String, _ style: InlineStyle, theme: MarkdownTheme) -> SwiftUI.Text {
        var attributed = AttributedString(string)
        attributed.backgroundColor = theme.highlightColor

        var intent: InlinePresentationIntent = []
        if style.isBold { intent.insert(.stronglyEmphasized) }
        if style.isItalic { intent.insert(.emphasized) }
        if style.isStrikethrough { intent.insert(.strikethrough) }
        if !intent.isEmpty { attributed.inlinePresentationIntent = intent }
        if style.isUnderline { attributed.underlineStyle = .single }
        if style.isCode { attributed.font = theme.codeFont }

        return SwiftUI.Text(attributed)
    }
}
