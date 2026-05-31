// MarkdownRenderer.swift
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

/// Renders a parsed Markdown document to SwiftUI views.
struct MarkdownRenderer: View {

    let document: Document
    let theme: MarkdownTheme
    let baseURL: URL?

    @Environment(\.markdownFeatures) private var features
    @Environment(\.markdownLinkHandler) private var linkHandler

    var body: some View {
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        VStack(alignment: .leading, spacing: theme.paragraphSpacing) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
                renderBlockNode(node)
            }
        }
        // Allow selecting and copying rendered text (task 14). Applies to the
        // SwiftUI Text descendants; math (a UIView/NSView) and code blocks remain
        // selectable within their own representations.
        .textSelection(.enabled)
    }

    // MARK: - Block Grouping (HTML <details>)

    /// A top-level render node: a raw markup block, a `<details>` disclosure
    /// group, or a definition list folded from consecutive term/definition
    /// paragraphs.
    enum BlockNode {
        case markup(any Markup)
        case details(summary: String, body: [BlockNode])
        case definitionList([Paragraph])
    }

    /// Folds `<details>` … `</details>` HTML-block runs into disclosure nodes.
    ///
    /// swift-markdown emits `<details>`/`<summary>` and the closing `</details>`
    /// as separate `HTMLBlock` siblings around the (normally parsed) body blocks.
    /// This pass groups the body between matched markers, tracking nesting depth,
    /// and extracts the summary label. Unmatched or malformed markers fall back to
    /// rendering the blocks as-is.
    static func groupBlocks(_ blocks: [any Markup]) -> [BlockNode] {
        var nodes: [BlockNode] = []
        var index = 0

        while index < blocks.count {
            let block = blocks[index]
            if let html = block as? HTMLBlock, isDetailsOpen(html.rawHTML) {
                // Self-contained: <details>…</details> within a single HTML block
                // (compact form with no blank line). Parse the inner body as
                // Markdown so it still renders richly.
                if html.rawHTML.range(of: "</details>", options: .caseInsensitive) != nil {
                    let inner = detailsInnerBody(html.rawHTML)
                    let bodyBlocks = Array(Document(parsing: inner).children)
                    nodes.append(.details(summary: extractSummary(html.rawHTML), body: groupBlocks(bodyBlocks)))
                    index += 1
                    continue
                }

                // Find the matching close, honouring nested <details>.
                var depth = 1
                var cursor = index + 1
                while cursor < blocks.count && depth > 0 {
                    if let inner = blocks[cursor] as? HTMLBlock {
                        if isDetailsOpen(inner.rawHTML) { depth += 1 }
                        else if isDetailsClose(inner.rawHTML) { depth -= 1 }
                    }
                    if depth == 0 { break }
                    cursor += 1
                }

                if depth == 0 {
                    let bodyBlocks = Array(blocks[(index + 1)..<cursor])
                    nodes.append(.details(summary: extractSummary(html.rawHTML), body: groupBlocks(bodyBlocks)))
                    index = cursor + 1
                    continue
                }
                // No matching close: fall through and render as a normal block.
            }

            if let paragraph = block as? Paragraph, isDefinitionParagraph(paragraph) {
                // Coalesce consecutive definition paragraphs into one list.
                var items: [Paragraph] = [paragraph]
                var cursor = index + 1
                while cursor < blocks.count,
                      let next = blocks[cursor] as? Paragraph,
                      isDefinitionParagraph(next) {
                    items.append(next)
                    cursor += 1
                }
                nodes.append(.definitionList(items))
                index = cursor
                continue
            }

            nodes.append(.markup(block))
            index += 1
        }

        return nodes
    }

    /// Whether a paragraph follows the definition-list shape: a term line
    /// followed by one or more lines beginning with `:`.
    static func isDefinitionParagraph(_ paragraph: Paragraph) -> Bool {
        let lines = plainLines(of: paragraph)
        guard lines.count >= 2,
              let first = lines.first,
              !first.trimmingCharacters(in: .whitespaces).hasPrefix(":") else {
            return false
        }
        return lines.dropFirst().contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix(":") }
    }

    /// The plain text of each line of a paragraph (split at soft/hard breaks).
    private static func plainLines(of paragraph: Paragraph) -> [String] {
        var lines: [String] = []
        var current = ""
        for child in paragraph.children {
            if child is SoftBreak || child is LineBreak {
                lines.append(current)
                current = ""
            } else if let plain = child as? any PlainTextConvertibleMarkup {
                current += plain.plainText
            }
        }
        lines.append(current)
        return lines
    }

    /// Whether `rawHTML` contains the named tag with a real tag boundary after
    /// the name (so `<details>` matches but `<detailspanel>` does not).
    private static func containsTag(_ rawHTML: String, name: String, closing: Bool) -> Bool {
        let prefix = closing ? "</" : "<"
        // `\s` (not an explicit `\t\r\n` class) — `String.range(of:options:.regularExpression)`
        // does not honour `\n` inside a character class, but does honour `\s`.
        let pattern = "\(prefix)\(name)(?=[\\s/>])"
        return rawHTML.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func isDetailsOpen(_ rawHTML: String) -> Bool {
        containsTag(rawHTML, name: "details", closing: false)
    }

    private static func isDetailsClose(_ rawHTML: String) -> Bool {
        containsTag(rawHTML, name: "details", closing: true)
            && !containsTag(rawHTML, name: "details", closing: false)
    }

    /// Extracts the inner body of a self-contained `<details>…</details>` block:
    /// the text after `</summary>` (or after the opening `<details>` tag) up to
    /// the last `</details>`.
    static func detailsInnerBody(_ rawHTML: String) -> String {
        let start: String.Index
        if let summaryEnd = rawHTML.range(of: "</summary>", options: .caseInsensitive) {
            start = summaryEnd.upperBound
        } else if let openTag = rawHTML.range(of: "<details", options: .caseInsensitive),
                  let tagEnd = rawHTML.range(of: ">", range: openTag.upperBound..<rawHTML.endIndex) {
            start = tagEnd.upperBound
        } else {
            start = rawHTML.startIndex
        }
        guard let close = rawHTML.range(of: "</details>", options: [.caseInsensitive, .backwards]),
              start <= close.lowerBound else {
            return ""
        }
        return String(rawHTML[start..<close.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extracts the plain-text summary label from a `<details>` open block.
    static func extractSummary(_ rawHTML: String) -> String {
        // Match `<summary>` or `<summary …attrs…>` (boundary-aware, so
        // `<summaryx>` does not match and attributes are not treated as text).
        // Attribute values may legally contain `>`; allow it only inside quotes
        // so the open tag isn't truncated mid-attribute (which would garble the
        // extracted label — worse than the safe "Details" fallback).
        guard let open = rawHTML.range(of: #"<summary(\s(?:[^>"']|"[^"]*"|'[^']*')*)?>"#, options: [.regularExpression, .caseInsensitive]),
              let close = rawHTML.range(of: "</summary>", options: .caseInsensitive),
              open.upperBound <= close.lowerBound else {
            return "Details"
        }
        let inner = String(rawHTML[open.upperBound..<close.lowerBound])
        let stripped = stripTags(inner).trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.isEmpty ? "Details" : stripped
    }

    /// Removes any `<...>` tags from a string.
    private static func stripTags(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func renderBlockNode(_ node: BlockNode) -> AnyView {
        switch node {
        case .markup(let markup):
            return renderBlock(markup)
        case .details(let summary, let body):
            return AnyView(
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: theme.paragraphSpacing) {
                        ForEach(Array(body.enumerated()), id: \.offset) { _, child in
                            renderBlockNode(child)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    SwiftUI.Text(summary)
                        .font(theme.bodyFont.bold())
                        .foregroundColor(theme.textColor)
                }
                .accentColor(theme.linkColor)
            )
        case .definitionList(let paragraphs):
            return AnyView(renderDefinitionList(paragraphs))
        }
    }

    // MARK: - Definition List Rendering

    @ViewBuilder
    private func renderDefinitionList(_ paragraphs: [Paragraph]) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                let lines = inlineLines(of: paragraph)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    renderDefinitionLine(line)
                }
            }
        }
    }

    @ViewBuilder
    private func renderDefinitionLine(_ line: [any Markup]) -> some View {
        if isDefinitionLine(line) {
            // Definition: drop the leading ":" marker and indent.
            let fragments = Self.stripLeadingColon(InlineFlattener.fragments(forChildren: line))
            renderInlineFragments(fragments)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
                .padding(.leading, theme.indentation)
        } else {
            // Term: rendered in bold.
            renderInlineFragments(InlineFlattener.fragments(forChildren: line))
                .font(theme.bodyFont.bold())
                .foregroundColor(theme.textColor)
        }
    }

    /// Splits a paragraph's inline children into lines at soft/hard breaks.
    private func inlineLines(of paragraph: Paragraph) -> [[any Markup]] {
        var lines: [[any Markup]] = []
        var current: [any Markup] = []
        for child in paragraph.children {
            if child is SoftBreak || child is LineBreak {
                lines.append(current)
                current = []
            } else {
                current.append(child)
            }
        }
        lines.append(current)
        return lines
    }

    /// Whether a line begins with the `:` definition marker.
    private func isDefinitionLine(_ line: [any Markup]) -> Bool {
        guard let first = line.first as? any PlainTextConvertibleMarkup else { return false }
        return first.plainText.trimmingCharacters(in: .whitespaces).hasPrefix(":")
    }

    /// Removes the leading `:` (and surrounding whitespace) from the first text
    /// fragment of a definition line.
    static func stripLeadingColon(_ fragments: [InlineFragment]) -> [InlineFragment] {
        var result = fragments
        for index in result.indices {
            if case .text(let string, let style) = result[index] {
                var trimmed = string.drop { $0 == " " || $0 == "\t" }
                if trimmed.first == ":" {
                    trimmed = trimmed.dropFirst().drop { $0 == " " || $0 == "\t" }
                }
                result[index] = .text(String(trimmed), style)
                break
            }
        }
        return result
    }

    /// Whether clickable links are enabled.
    private var linksEnabled: Bool {
        features.contains(.links)
    }

    /// Whether syntax highlighting is enabled.
    private var syntaxHighlightingEnabled: Bool {
        features.contains(.syntaxHighlighting)
    }

    /// Whether Mermaid diagram rendering is enabled.
    private var mermaidEnabled: Bool {
        features.contains(.mermaid)
    }

    // MARK: - Block Rendering

    private func renderBlock(_ markup: any Markup) -> AnyView {
        if let heading = markup as? Heading {
            return AnyView(renderHeading(heading))
        } else if let paragraph = markup as? Paragraph {
            return AnyView(renderParagraph(paragraph))
        } else if let codeBlock = markup as? CodeBlock {
            return AnyView(renderCodeBlock(codeBlock))
        } else if let blockQuote = markup as? BlockQuote {
            return AnyView(renderBlockQuote(blockQuote))
        } else if let orderedList = markup as? OrderedList {
            return AnyView(renderOrderedList(orderedList))
        } else if let unorderedList = markup as? UnorderedList {
            return AnyView(renderUnorderedList(unorderedList))
        } else if let table = markup as? Markdown.Table {
            return AnyView(renderTable(table))
        } else if markup is ThematicBreak {
            return AnyView(
                Rectangle()
                    .fill(theme.thematicBreakColor)
                    .frame(height: 1)
                    .padding(.vertical, 8)
            )
        } else if let htmlBlock = markup as? HTMLBlock {
            return AnyView(
                SwiftUI.Text(htmlBlock.rawHTML)
                    .font(theme.codeFont)
                    .foregroundColor(theme.secondaryTextColor)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Heading

    @ViewBuilder
    private func renderHeading(_ heading: Heading) -> some View {
        renderInlineChildren(heading)
            .font(theme.headingFont(level: heading.level))
            .foregroundColor(theme.textColor)
            .padding(.top, heading.level == 1 ? 16 : 8)
            .padding(.bottom, 4)
    }

    // MARK: - Paragraph

    @ViewBuilder
    private func renderParagraph(_ paragraph: Paragraph) -> some View {
        // Fast path only for a paragraph that is a *single* self-contained
        // display-math block. Paragraphs mixing display math with text or
        // containing multiple `$$…$$` blocks fall through to the inline path,
        // which segments math correctly (the fast path would otherwise corrupt
        // e.g. `$$x$$ and $$y$$` into invalid LaTeX).
        if let latex = Self.displayMathContent(paragraph.plainText) {
            LaTeXView(latex: latex, isBlock: true, theme: theme)
        } else {
            renderInlineChildren(paragraph)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
        }
    }

    /// If `plainText` is a single self-contained display-math block (`$$…$$`
    /// with no interior `$$`), returns the inner LaTeX; otherwise `nil` so the
    /// caller falls back to inline rendering (which handles mixed/multiple math).
    static func displayMathContent(_ plainText: String) -> String? {
        guard plainText.hasPrefix("$$"), plainText.hasSuffix("$$"), plainText.count > 4 else {
            return nil
        }
        let inner = plainText.dropFirst(2).dropLast(2)
        guard !inner.contains("$$") else { return nil }
        return inner.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Code Block

    @ViewBuilder
    private func renderCodeBlock(_ codeBlock: CodeBlock) -> some View {
        if codeBlock.language == "mermaid" {
            renderMermaidBlock(codeBlock)
        } else {
            renderRegularCodeBlock(codeBlock)
        }
    }

    @ViewBuilder
    private func renderMermaidBlock(_ codeBlock: CodeBlock) -> some View {
        if mermaidEnabled {
            MermaidView(code: codeBlock.code, theme: theme)
        } else {
            MermaidPlaceholderView(code: codeBlock.code, theme: theme)
        }
    }

    @ViewBuilder
    private func renderRegularCodeBlock(_ codeBlock: CodeBlock) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if syntaxHighlightingEnabled && codeBlock.language != nil {
                HighlightedCodeView(
                    code: codeBlock.code,
                    language: codeBlock.language,
                    theme: theme
                )
            } else {
                Text(codeBlock.code.trimmingCharacters(in: .newlines))
                    .font(theme.codeBlockFont)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding(theme.codeBlockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.codeBackgroundColor)
        .cornerRadius(8)
    }

    // MARK: - Block Quote

    @ViewBuilder
    private func renderBlockQuote(_ blockQuote: BlockQuote) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.blockQuoteBorderColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: theme.paragraphSpacing / 2) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    renderBlock(child)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Lists

    /// Bullet styles for different nesting levels in unordered lists.
    private static let bulletStyles = ["•", "◦", "▪", "▸"]

    /// Returns the bullet character for a given nesting depth.
    private func bulletForDepth(_ depth: Int) -> String {
        Self.bulletStyles[depth % Self.bulletStyles.count]
    }

    @ViewBuilder
    private func renderOrderedList(_ list: OrderedList, depth: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                renderListItem(item, bullet: "\(index + Int(list.startIndex)).", depth: depth)
            }
        }
        .padding(.leading, depth > 0 ? theme.indentation : 0)
    }

    @ViewBuilder
    private func renderUnorderedList(_ list: UnorderedList, depth: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                if item.checkbox != nil {
                    renderTaskListItem(item, depth: depth)
                } else {
                    renderListItem(item, bullet: bulletForDepth(depth), depth: depth)
                }
            }
        }
        .padding(.leading, depth > 0 ? theme.indentation : 0)
    }

    @ViewBuilder
    private func renderListItem(_ item: ListItem, bullet: String, depth: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(bullet)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: theme.listItemSpacing) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderListChildBlock(child, depth: depth)
                }
            }
        }
    }

    @ViewBuilder
    private func renderTaskListItem(_ item: ListItem, depth: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: item.checkbox?.isChecked == true ? "checkmark.square.fill" : "square")
                .font(theme.bodyFont)
                .foregroundColor(item.checkbox?.isChecked == true ? theme.taskCheckboxColor : theme.secondaryTextColor)
                .frame(width: 20, alignment: .trailing)
                .accessibilityLabel(item.checkbox?.isChecked == true ? "Checked task" : "Unchecked task")

            VStack(alignment: .leading, spacing: theme.listItemSpacing) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderListChildBlock(child, depth: depth)
                }
            }
        }
    }

    /// Renders a child block within a list item, handling nested lists specially.
    private func renderListChildBlock(_ markup: any Markup, depth: Int) -> AnyView {
        if let nestedOrdered = markup as? OrderedList {
            return AnyView(renderOrderedList(nestedOrdered, depth: depth + 1))
        } else if let nestedUnordered = markup as? UnorderedList {
            return AnyView(renderUnorderedList(nestedUnordered, depth: depth + 1))
        } else {
            return renderBlock(markup)
        }
    }

    // MARK: - Table

    @ViewBuilder
    private func renderTable(_ table: Markdown.Table) -> some View {
        let cellArrays = extractTableCells(from: table)

        VStack(spacing: 0) {
            // Header row
            if !cellArrays.header.isEmpty {
                renderTableCellRow(cells: cellArrays.header, isHeader: true)
            }

            // Body rows
            ForEach(Array(cellArrays.body.enumerated()), id: \.offset) { _, rowCells in
                renderTableCellRow(cells: rowCells, isHeader: false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(theme.tableBorderColor, lineWidth: 1)
        )
        .cornerRadius(4)
    }

    /// Extracts cells from a table into arrays for easier SwiftUI rendering.
    private func extractTableCells(from table: Markdown.Table) -> (header: [Markdown.Table.Cell], body: [[Markdown.Table.Cell]]) {
        let header: [Markdown.Table.Cell] = Array(table.head.cells)
        let body: [[Markdown.Table.Cell]] = table.body.rows.map { Array($0.cells) }
        return (header, body)
    }

    @ViewBuilder
    private func renderTableCellRow(cells: [Markdown.Table.Cell], isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                renderInlineChildren(cell)
                    .font(isHeader ? theme.bodyFont.bold() : theme.bodyFont)
                    .foregroundColor(theme.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(theme.tableCellPadding)
                    .background(isHeader ? theme.tableHeaderBackgroundColor : Color.clear)

                if index < cells.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            Rectangle()
                .stroke(theme.tableBorderColor, lineWidth: 0.5)
        )
    }

    // MARK: - Inline Rendering

    /// Whether image loading is enabled.
    private var imagesEnabled: Bool {
        features.contains(.images)
    }

    /// Renders the inline children of `parent`, preserving styling across LaTeX,
    /// links, and images.
    @ViewBuilder
    private func renderInlineChildren(_ parent: any Markup) -> some View {
        let fragments = InlineFlattener.fragments(for: parent)
        renderInlineFragments(fragments)
    }

    /// Chooses between the fast single-`Text` path and the flow-layout path.
    ///
    /// The flow path is only needed when a real subview (LaTeX, an enabled image,
    /// or an enabled link) must sit inline; otherwise a single concatenated
    /// `Text` wraps naturally and is cheaper.
    @ViewBuilder
    private func renderInlineFragments(_ fragments: [InlineFragment]) -> some View {
        if needsFlowLayout(fragments) {
            renderFlow(fragments)
        } else {
            InlineTextRenderer.text(fragments, theme: theme)
        }
    }

    /// Whether any fragment requires a dedicated inline subview.
    private func needsFlowLayout(_ fragments: [InlineFragment]) -> Bool {
        fragments.contains { fragment in
            switch fragment {
            case .latex: return true
            case .image: return imagesEnabled
            case .link: return linksEnabled
            default: return false
            }
        }
    }

    /// Render-ready flow item: either coalesced text or a standalone subview.
    private enum FlowItem {
        case text(SwiftUI.Text)
        case latex(String, isBlock: Bool)
        case image(source: String?, alt: String)
        case link(destination: String?, content: [InlineFragment])
    }

    /// Renders fragments in a wrapping flow layout, coalescing adjacent text /
    /// break / disabled-feature fragments into single `Text` runs.
    @ViewBuilder
    private func renderFlow(_ fragments: [InlineFragment]) -> some View {
        let items = buildFlowItems(fragments)
        FlowLayout(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                renderFlowItem(item)
            }
        }
    }

    /// Coalesces fragments into flow items. Text, breaks, and disabled
    /// images/links merge into a running `Text`; LaTeX and enabled
    /// images/links break the run into their own items.
    private func buildFlowItems(_ fragments: [InlineFragment]) -> [FlowItem] {
        var items: [FlowItem] = []
        var pending: SwiftUI.Text?

        func flush() {
            if let pending { items.append(.text(pending)) }
            pending = nil
        }
        func append(_ text: SwiftUI.Text) {
            pending = pending.map { $0 + text } ?? text
        }

        for fragment in fragments {
            switch fragment {
            case .latex(let latex, let isBlock):
                flush()
                items.append(.latex(latex, isBlock: isBlock))
            case .image(let source, let alt):
                if imagesEnabled {
                    flush()
                    items.append(.image(source: source, alt: alt))
                } else {
                    append(InlineTextRenderer.text(for: fragment, theme: theme))
                }
            case .link(let destination, let content):
                if linksEnabled {
                    flush()
                    items.append(.link(destination: destination, content: content))
                } else {
                    append(InlineTextRenderer.text(for: fragment, theme: theme))
                }
            default:
                append(InlineTextRenderer.text(for: fragment, theme: theme))
            }
        }
        flush()
        return items
    }

    @ViewBuilder
    private func renderFlowItem(_ item: FlowItem) -> some View {
        switch item {
        case .text(let text):
            text
        case .latex(let latex, let isBlock):
            LaTeXView(latex: latex, isBlock: isBlock, theme: theme)
        case .image(let source, let alt):
            MarkdownImageView(source: source, altText: alt, theme: theme, baseURL: baseURL)
        case .link(let destination, let content):
            TappableLinkView(
                destination: destination,
                content: content,
                theme: theme,
                linkHandler: linkHandler,
                baseURL: baseURL
            )
        }
    }
}

// MARK: - Flow Layout

/// A flow layout for mixed inline text and views that wraps to the container
/// width.
///
/// Each subview is measured at its ideal size; a subview wider than the
/// container is re-measured at the full width so long text wraps internally
/// (multiple lines) instead of overflowing. Items that do not fit the remaining
/// space on the current line move to the next line. The reported width never
/// exceeds the proposed container width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = measuredSizes(maxWidth: maxWidth, subviews: subviews)
        return Self.frames(forItemSizes: sizes, maxWidth: maxWidth, spacing: spacing).totalSize
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Measure against the actual container width so wrapping decisions and
        // the sizes used for placement stay consistent (even when the parent
        // proposed an unspecified width during sizing).
        let sizes = measuredSizes(maxWidth: bounds.width, subviews: subviews)
        let result = Self.frames(forItemSizes: sizes, maxWidth: bounds.width, spacing: spacing)

        for (index, subview) in subviews.enumerated() where index < result.positions.count {
            let position = result.positions[index]
            let size = sizes[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }

    /// Measures each subview, clamping over-wide subviews to the container width
    /// so they wrap their own content.
    private func measuredSizes(maxWidth: CGFloat, subviews: Subviews) -> [CGSize] {
        return subviews.map { subview in
            let ideal = subview.sizeThatFits(.unspecified)
            if maxWidth.isFinite && ideal.width > maxWidth {
                return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }
            return ideal
        }
    }

    /// Pure line-breaking core: lays out fixed-size items left-to-right, wrapping
    /// to a new line when an item would exceed `maxWidth`. Exposed for testing.
    ///
    /// - Parameters:
    ///   - sizes: The size of each item, in order.
    ///   - maxWidth: The available container width (`.infinity` for unconstrained).
    ///   - spacing: Horizontal/vertical gap between items.
    /// - Returns: The top-left position of each item and the total bounding size
    ///   (clamped to `maxWidth` when finite).
    static func frames(forItemSizes sizes: [CGSize], maxWidth: CGFloat, spacing: CGFloat) -> (positions: [CGPoint], totalSize: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for size in sizes {
            // Wrap when the item does not fit the remaining width (but never on
            // an empty line, where it must be placed regardless).
            if currentX > 0 && currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxLineWidth = max(maxLineWidth, currentX - spacing)
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = maxWidth.isFinite ? min(maxLineWidth, maxWidth) : maxLineWidth
        return (positions, CGSize(width: max(totalWidth, 0), height: max(totalHeight, 0)))
    }
}
